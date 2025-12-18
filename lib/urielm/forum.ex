defmodule Urielm.Forum do
  @moduledoc """
  Context for forum operations: threads, comments, votes, and moderation.

  ## Soft Delete Behavior
  - Threads: `is_removed=true` hides from feeds, preserves content for audit
  - Comments: `is_removed=true` hides from queries, preserves tree structure and replies
  - Votes: Preserved on removed content (score reflects historical votes)
  - No tombstones rendered (removed content completely hidden)
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.TrustLevel
  alias Flop

  alias Urielm.Forum.{
    Category,
    Board,
    Thread,
    Comment,
    Vote,
    ThreadLink,
    SavedThread,
    SavedComment,
    Tag,
    ThreadTag,
    Report,
    Subscription,
    Notification,
    TopicRead,
    TopicNotificationSetting
  }

  @max_comment_depth 8

  # Categories

  def list_categories(opts \\ []) do
    hidden = Keyword.get(opts, :hidden, false)

    from(c in Category)
    |> where([c], c.is_hidden == ^hidden)
    |> order_by([c], c.position)
    |> Repo.all()
  end

  # Convenience: categories with boards preloaded
  def list_categories_with_boards(opts \\ []) do
    list_categories(opts)
    |> Repo.preload(:boards)
  end

  def get_category!(id) do
    Repo.get!(Category, id)
  end

  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  # Boards

  def list_boards(category_id, opts \\ []) do
    hidden = Keyword.get(opts, :hidden, false)

    from(b in Board)
    |> where([b], b.category_id == ^category_id and b.is_hidden == ^hidden)
    |> preload(:category)
    |> Repo.all()
  end

  def get_board!(slug) do
    Repo.get_by!(Board, slug: slug)
    |> Repo.preload(:category)
  end

  def create_board(attrs \\ %{}) do
    %Board{}
    |> Board.changeset(attrs)
    |> Repo.insert()
  end

  # Threads

  def list_threads(board_id, opts \\ []) do
    sort = Keyword.get(opts, :sort, :new)

    query =
      from(t in Thread)
      |> where([t], t.board_id == ^board_id and t.is_removed == false)
      |> thread_preloads()

    query =
      case sort do
        :new -> order_by(query, [t], desc: t.inserted_at, desc: t.id)
        :top -> order_by(query, [t], desc: t.score, desc: t.inserted_at, desc: t.id)
        :latest -> order_by(query, [t], desc: t.updated_at, desc: t.id)
        _ -> order_by(query, [t], desc: t.updated_at, desc: t.id)
      end

    query
    |> apply_pagination(opts)
    |> Repo.all()
  end

  @doc """
  Flop-powered pagination for threads. Returns {:ok, results, meta} or {:error, meta}.
  Accepts Flop params such as page/page_size and order_by/order_directions.
  """
  def paginate_threads(board_id, params \\ %{}) do
    base =
      from(t in Thread)
      |> where([t], t.board_id == ^board_id and t.is_removed == false)
      |> thread_preloads()

    Flop.validate_and_run(base, params, for: Thread, repo: Repo)
  end

  def get_thread!(id) do
    thread = Repo.get!(Thread, id)
    comments = list_comments_with_authors(id)

    thread
    |> preload_thread_meta()
    |> Map.put(:comments, comments)
  end

  defp list_comments_with_authors(thread_id) do
    from(c in Comment)
    |> where([c], c.thread_id == ^thread_id and c.is_removed == false)
    |> order_by([c], c.inserted_at)
    |> preload(:author)
    |> Repo.all()
  end

  def create_thread(board_id, author_id, attrs \\ %{}) do
    user = Repo.get!(Urielm.Accounts.User, author_id)
    config = TrustLevel.get_config(user.trust_level)
    max_topics_per_day = config.max_new_topics_per_day

    with_rate_limit(author_id, "create_thread", max_topics_per_day, 86_400, fn ->
      insert_thread(board_id, author_id, attrs)
    end)
  end

  defp insert_thread(board_id, author_id, attrs) do
    attrs = Urielm.Params.normalize(attrs)

    %Thread{}
    |> Thread.changeset(Map.merge(attrs, %{"board_id" => board_id, "author_id" => author_id}))
    |> Repo.insert()
  end

  def update_thread(%Thread{} = thread, attrs) do
    attrs = Urielm.Params.normalize(attrs)

    thread
    |> Thread.changeset(attrs)
    |> Repo.update()
  end

  def edit_thread(%Thread{} = thread, body, user) do
    if authorized?(user, thread.author_id) do
      update_thread(thread, %{body: body, edited_at: DateTime.utc_now()})
    else
      {:error, :unauthorized}
    end
  end

  def remove_thread(%Thread{} = thread, %{id: user_id} = user) do
    if authorized?(user, thread.author_id) do
      update_thread(thread, %{is_removed: true, removed_by_id: user_id})
    else
      {:error, :unauthorized}
    end
  end

  def mark_as_solved(%Thread{} = thread, comment_id, %{id: user_id} = user) do
    if authorized?(user, thread.author_id) do
      update_thread(thread, %{
        is_solved: true,
        solved_comment_id: comment_id,
        solved_at: DateTime.utc_now(),
        solved_by_id: user_id
      })
    else
      {:error, :unauthorized}
    end
  end

  def unmark_as_solved(%Thread{} = thread, user) do
    if authorized?(user, thread.author_id) do
      update_thread(thread, %{
        is_solved: false,
        solved_comment_id: nil,
        solved_at: nil,
        solved_by_id: nil
      })
    else
      {:error, :unauthorized}
    end
  end

  # Comments

  def list_comments(thread_id, _opts \\ []) do
    from(c in Comment)
    |> where([c], c.thread_id == ^thread_id and c.is_removed == false)
    |> order_by([c], c.inserted_at)
    |> preload([:author])
    |> Repo.all()
  end

  def get_comment!(id) do
    Repo.get!(Comment, id)
    |> Repo.preload(:author)
  end

  def create_comment(thread_id, author_id, attrs \\ %{}) do
    user = Repo.get!(Urielm.Accounts.User, author_id)
    config = TrustLevel.get_config(user.trust_level)
    max_posts_per_minute = config.max_posts_per_minute

    parent_id = Map.get(attrs, "parent_id") || Map.get(attrs, :parent_id)

    with :ok <- validate_comment_depth(parent_id) do
      with_rate_limit(author_id, "create_comment", max_posts_per_minute, 60, fn ->
        %Comment{}
        |> Comment.changeset(
          Map.merge(Urielm.Params.normalize(attrs), %{
            "thread_id" => thread_id,
            "author_id" => author_id
          })
        )
        |> Repo.insert()
        |> case do
          {:ok, comment} ->
            update_thread_comment_count(thread_id)
            {:ok, comment}

          error ->
            error
        end
      end)
    else
      {:error, :max_depth_exceeded} -> {:error, :max_depth_exceeded}
    end
  end

  defp validate_comment_depth(nil), do: :ok

  defp validate_comment_depth(parent_id) do
    depth = calculate_depth(parent_id, 0)

    if depth >= @max_comment_depth do
      {:error, :max_depth_exceeded}
    else
      :ok
    end
  end

  defp calculate_depth(nil, depth), do: depth

  defp calculate_depth(comment_id, depth) do
    case Repo.get(Comment, comment_id) do
      nil -> depth
      %Comment{parent_id: parent_id} -> calculate_depth(parent_id, depth + 1)
    end
  end

  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  def edit_comment(%Comment{} = comment, body, user) do
    if authorized?(user, comment.author_id) do
      update_comment(comment, %{body: body, edited_at: DateTime.utc_now()})
    else
      {:error, :unauthorized}
    end
  end

  def remove_comment(%Comment{} = comment, %{id: user_id} = user) do
    if authorized?(user, comment.author_id) do
      update_comment(comment, %{is_removed: true, removed_by_id: user_id})
    else
      {:error, :unauthorized}
    end
  end

  # Votes

  def cast_vote(user_id, target_type, target_id, value)
      when is_integer(value) and value in [-1, 1] do
    Repo.transaction(fn ->
      # Fetch existing vote if any
      existing_vote =
        Repo.get_by(Vote, user_id: user_id, target_type: target_type, target_id: target_id)

      # Calculate delta (change in score)
      delta =
        case {existing_vote, value} do
          {nil, v} -> v
          {%Vote{value: old_v}, new_v} -> new_v - old_v
        end

      # Update or insert vote
      vote_attrs = %{
        user_id: user_id,
        target_type: target_type,
        target_id: target_id,
        value: value
      }

      result =
        case existing_vote do
          nil ->
            %Vote{}
            |> Vote.changeset(vote_attrs)
            |> Repo.insert()

          vote ->
            vote
            |> Vote.changeset(vote_attrs)
            |> Repo.update()
        end

      # Apply delta to target's score
      apply_vote_delta(target_type, target_id, delta, result)

      result
    end)
  end

  def cast_vote(_user_id, _target_type, _target_id, _value) do
    changeset =
      Vote.changeset(%Vote{}, %{user_id: nil, target_type: "", target_id: nil, value: 0})

    {:error, changeset}
  end

  def unvote(user_id, target_type, target_id) do
    case Repo.get_by(Vote, user_id: user_id, target_type: target_type, target_id: target_id) do
      nil ->
        {:ok, nil}

      vote ->
        Repo.transaction(fn ->
          old_value = vote.value
          Repo.delete(vote)
          apply_vote_delta(target_type, target_id, -old_value, {:ok, vote})
        end)
    end
  end

  def get_user_vote(user_id, target_type, target_id) do
    Repo.get_by(Vote, user_id: user_id, target_type: target_type, target_id: target_id)
  end

  # Thread Links

  def create_thread_link(thread_id, link_type, link_id) do
    %ThreadLink{}
    |> ThreadLink.changeset(%{thread_id: thread_id, link_type: link_type, link_id: link_id})
    |> Repo.insert()
  end

  def get_thread_by_link(link_type, link_id) do
    ThreadLink
    |> where([tl], tl.link_type == ^link_type and tl.link_id == ^link_id)
    |> preload(:thread)
    |> Repo.one()
    |> case do
      nil -> nil
      %ThreadLink{thread: thread} -> thread
    end
  end

  def get_or_create_lesson_thread(lesson_id, board_id) do
    case get_thread_by_link("lesson", lesson_id) do
      %Thread{} = thread ->
        {:ok, thread}

      nil ->
        # Create a new thread for the lesson
        lesson = Urielm.Learning.get_lesson!(lesson_id)
        title = "Discussion: #{lesson.title}"
        slug = Urielm.Slugify.slugify(title)

        case create_thread(board_id, 1, %{
               "title" => title,
               "slug" => slug,
               "body" => "Discuss this lesson in the forum."
             }) do
          {:ok, thread} ->
            {:ok, _link} = create_thread_link(thread.id, "lesson", lesson_id)
            {:ok, thread}

          error ->
            error
        end
    end
  end

  def list_lesson_threads(lesson_id, opts \\ []) do
    from(t in Thread,
      join: tl in ThreadLink,
      on: t.id == tl.thread_id,
      where: tl.link_type == "lesson" and tl.link_id == ^lesson_id,
      where: t.is_removed == false,
      preload: [:author, :board],
      order_by: [desc: t.inserted_at, desc: t.id]
    )
    |> apply_pagination(opts, 10)
    |> Repo.all()
  end

  # Saves/Bookmarks

  def save_thread(user_id, thread_id) do
    %SavedThread{}
    |> SavedThread.changeset(%{user_id: user_id, thread_id: thread_id})
    |> Repo.insert()
  end

  def unsave_thread(user_id, thread_id) do
    case Repo.get_by(SavedThread, user_id: user_id, thread_id: thread_id) do
      nil -> {:error, :not_found}
      saved -> Repo.delete(saved)
    end
  end

  def is_thread_saved?(user_id, thread_id) do
    Repo.exists?(
      from(st in SavedThread, where: st.user_id == ^user_id and st.thread_id == ^thread_id)
    )
  end

  def toggle_save_thread(user_id, thread_id) do
    if is_thread_saved?(user_id, thread_id) do
      unsave_thread(user_id, thread_id)
    else
      save_thread(user_id, thread_id)
    end
  end

  def list_saved_threads(user_id, opts \\ []) do
    from(t in Thread,
      join: st in SavedThread,
      on: st.thread_id == t.id,
      where: st.user_id == ^user_id,
      where: t.is_removed == false,
      preload: [:author, :board],
      order_by: [desc: st.inserted_at, desc: t.id]
    )
    |> apply_pagination(opts)
    |> Repo.all()
  end

  @doc """
  Flop pagination for a user's saved threads.
  Returns {:ok, {threads, meta}} or {:error, meta}.
  """
  def paginate_saved_threads(user_id, params \\ %{}) do
    base =
      from(t in Thread,
        join: st in SavedThread,
        on: st.thread_id == t.id,
        where: st.user_id == ^user_id and t.is_removed == false,
        preload: [:author, :board],
        order_by: [desc: st.inserted_at, desc: t.id]
      )

    Flop.validate_and_run(base, params, for: Thread, repo: Repo)
  end

  def count_saved_threads(user_id) do
    from(st in SavedThread, where: st.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  # Saved Comments/Bookmarks

  def save_comment(user_id, comment_id) do
    %SavedComment{}
    |> SavedComment.changeset(%{user_id: user_id, comment_id: comment_id})
    |> Repo.insert()
  end

  def unsave_comment(user_id, comment_id) do
    case Repo.get_by(SavedComment, user_id: user_id, comment_id: comment_id) do
      nil -> {:error, :not_found}
      saved -> Repo.delete(saved)
    end
  end

  def is_comment_saved?(user_id, comment_id) do
    Repo.exists?(
      from(sc in SavedComment, where: sc.user_id == ^user_id and sc.comment_id == ^comment_id)
    )
  end

  def toggle_save_comment(user_id, comment_id) do
    if is_comment_saved?(user_id, comment_id) do
      unsave_comment(user_id, comment_id)
    else
      save_comment(user_id, comment_id)
    end
  end

  def list_saved_comments(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(c in Comment,
      join: sc in SavedComment,
      on: sc.comment_id == c.id,
      where: sc.user_id == ^user_id,
      where: c.is_removed == false,
      limit: ^limit,
      offset: ^offset,
      preload: [:author, thread: :board],
      order_by: [desc: sc.inserted_at]
    )
    |> Repo.all()
  end

  def count_saved_comments(user_id) do
    from(sc in SavedComment, where: sc.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  # Tags/Flair

  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  def get_tag!(id) do
    Repo.get!(Tag, id)
  end

  def get_tag_by_slug(slug) do
    Repo.get_by(Tag, slug: slug)
  end

  def list_tags(opts \\ []) do
    from(t in Tag)
    |> order_by([t], t.name)
    |> apply_pagination(opts, 50)
    |> Repo.all()
  end

  def add_tag_to_thread(thread_id, tag_id) do
    %ThreadTag{}
    |> ThreadTag.changeset(%{thread_id: thread_id, tag_id: tag_id})
    |> Repo.insert()
  end

  def remove_tag_from_thread(thread_id, tag_id) do
    case Repo.get_by(ThreadTag, thread_id: thread_id, tag_id: tag_id) do
      nil -> {:error, :not_found}
      thread_tag -> Repo.delete(thread_tag)
    end
  end

  def list_thread_tags(thread_id) do
    from(tt in ThreadTag,
      where: tt.thread_id == ^thread_id,
      join: t in Tag,
      on: tt.tag_id == t.id,
      select: t
    )
    |> Repo.all()
  end

  def list_threads_by_tag(tag_id, opts \\ []) do
    from(t in Thread,
      join: tt in ThreadTag,
      on: tt.thread_id == t.id,
      where: tt.tag_id == ^tag_id,
      where: t.is_removed == false,
      preload: [:author, :board],
      order_by: [desc: t.inserted_at, desc: t.id]
    )
    |> apply_pagination(opts)
    |> Repo.all()
  end

  # Reporting/Moderation

  def create_report(user_id, target_type, target_id, attrs \\ %{}) do
    %Report{}
    |> Report.changeset(
      Map.merge(attrs, %{user_id: user_id, target_type: target_type, target_id: target_id})
    )
    |> Repo.insert()
  end

  def list_reports(opts \\ []) do
    status = Keyword.get(opts, :status, "pending")

    from(r in Report)
    |> where([r], r.status == ^status)
    |> preload(:user)
    |> order_by([r], desc: r.inserted_at, desc: r.id)
    |> apply_pagination(opts, 50)
    |> Repo.all()
  end

  def get_report!(id) do
    Repo.get!(Report, id)
    |> Repo.preload([:user, :reviewed_by])
  end

  def review_report(%Report{} = report, reviewer_id, status, resolution_notes \\ nil) do
    report
    |> Report.changeset(%{
      status: status,
      reviewed_by_id: reviewer_id,
      resolved_at: DateTime.utc_now(),
      resolution_notes: resolution_notes
    })
    |> Repo.update()
  end

  def count_pending_reports do
    from(r in Report, where: r.status == "pending")
    |> Repo.aggregate(:count)
  end

  def list_reports_by_target(target_type, target_id) do
    from(r in Report,
      where: r.target_type == ^target_type and r.target_id == ^target_id,
      preload: :user,
      order_by: [desc: r.inserted_at, desc: r.id]
    )
    |> Repo.all()
  end

  def update_report_notes(%Report{} = report, notes) do
    report
    |> Report.changeset(%{resolution_notes: notes})
    |> Repo.update()
  end

  # Subscriptions

  def subscribe_to_thread(user_id, thread_id) do
    %Subscription{}
    |> Subscription.changeset(%{user_id: user_id, thread_id: thread_id})
    |> Repo.insert()
  end

  def unsubscribe_from_thread(user_id, thread_id) do
    case Repo.get_by(Subscription, user_id: user_id, thread_id: thread_id) do
      nil -> {:error, :not_found}
      subscription -> Repo.delete(subscription)
    end
  end

  def is_subscribed?(user_id, thread_id) do
    Repo.exists?(
      from(s in Subscription, where: s.user_id == ^user_id and s.thread_id == ^thread_id)
    )
  end

  def list_subscriptions(user_id, opts \\ []) do
    from(t in Thread,
      join: s in Subscription,
      on: s.thread_id == t.id,
      where: s.user_id == ^user_id,
      where: t.is_removed == false,
      preload: [:author, :board],
      order_by: [desc: s.inserted_at, desc: t.id]
    )
    |> apply_pagination(opts)
    |> Repo.all()
  end

  def count_subscriptions(user_id) do
    from(s in Subscription, where: s.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  # Notifications

  def create_notification(user_id, subject_type, subject_id, opts \\ %{}) do
    attrs =
      Map.merge(opts, %{
        user_id: user_id,
        subject_type: subject_type,
        subject_id: subject_id
      })

    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  def list_notifications(user_id, opts \\ []) do
    unread_only = Keyword.get(opts, :unread_only, false)

    query =
      from(n in Notification,
        where: n.user_id == ^user_id,
        preload: [:actor, :thread],
        order_by: [desc: n.inserted_at, desc: n.id]
      )

    query =
      if unread_only do
        where(query, [n], is_nil(n.read_at))
      else
        query
      end

    query
    |> apply_pagination(opts)
    |> Repo.all()
  end

  # ---- helpers

  defp apply_pagination(query, opts, default_limit \\ 20) do
    limit = Keyword.get(opts, :limit, default_limit)
    offset = Keyword.get(opts, :offset, 0)

    from(q in query, limit: ^limit, offset: ^offset)
  end

  def mark_notification_as_read(notification_id) do
    case Repo.get(Notification, notification_id) do
      nil ->
        {:error, :not_found}

      notification ->
        notification
        |> Notification.changeset(%{read_at: DateTime.utc_now()})
        |> Repo.update()
    end
  end

  def mark_all_notifications_as_read(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])
  end

  def count_unread_notifications(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at)
    )
    |> Repo.aggregate(:count)
  end

  def notify_thread_subscribers(thread_id, actor_id, subject_type, message) do
    subscribers =
      from(s in Subscription,
        where: s.thread_id == ^thread_id and s.user_id != ^actor_id,
        select: s.user_id
      )
      |> Repo.all()

    Enum.each(subscribers, fn user_id ->
      create_notification(user_id, subject_type, thread_id, %{
        actor_id: actor_id,
        thread_id: thread_id,
        message: message
      })
    end)

    {:ok, length(subscribers)}
  end

  # Search

  def search_threads(query, opts \\ []) do
    board_id = Keyword.get(opts, :board_id)
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    base_query =
      from(t in Thread)
      |> where([t], t.is_removed == false)
      |> thread_preloads()

    query_string = String.trim(query)

    if String.length(query_string) > 0 do
      # Use full-text search with tsquery
      query_pattern = "%#{query_string}%"

      base_query
      |> where(
        [t],
        fragment("? @@ plainto_tsquery('english', ?)", t.search_vector, ^query_string) or
          ilike(t.title, ^query_pattern) or
          ilike(t.body, ^query_pattern)
      )
      |> order_by(
        [t],
        fragment("ts_rank(?, plainto_tsquery('english', ?)) DESC", t.search_vector, ^query_string)
      )
      |> then(&if is_nil(board_id), do: &1, else: where(&1, [t], t.board_id == ^board_id))
      |> limit(^limit)
      |> offset(^offset)
      |> Repo.all()
    else
      []
    end
  end

  @doc """
  Flop pagination for search results over threads.
  Keeps existing ranking/order; Flop applies paging and generates meta.
  Returns {:ok, {threads, meta}} or {:error, meta}.
  """
  def paginate_search_threads(query, params \\ %{}, opts \\ []) do
    board_id = Keyword.get(opts, :board_id)

    base_query =
      from(t in Thread)
      |> where([t], t.is_removed == false)
      |> thread_preloads()

    query_string = String.trim(to_string(query))

    q =
      if String.length(query_string) > 0 do
        pattern = "%#{query_string}%"

        base_query
        |> where(
          [t],
          fragment("? @@ plainto_tsquery('english', ?)", t.search_vector, ^query_string) or
            ilike(t.title, ^pattern) or
            ilike(t.body, ^pattern)
        )
        |> order_by([t],
          desc:
            fragment(
              "ts_rank(?, plainto_tsquery('english', ?)) DESC",
              t.search_vector,
              ^query_string
            ),
          desc: t.id
        )
        |> then(&if is_nil(board_id), do: &1, else: where(&1, [t], t.board_id == ^board_id))
      else
        # empty query returns no results
        from(t in base_query, where: false)
      end

    Flop.validate_and_run(q, params, for: Thread, repo: Repo)
  end

  # Topic Reads - Track which topics users have read

  def mark_thread_read(user_id, thread_id) do
    %TopicRead{}
    |> TopicRead.changeset(%{
      user_id: user_id,
      thread_id: thread_id,
      last_read_at: DateTime.utc_now()
    })
    |> Repo.insert(
      on_conflict: {:replace, [:last_read_at]},
      conflict_target: [:user_id, :thread_id]
    )
  end

  def is_thread_unread?(user_id, thread_id) do
    read = Repo.get_by(TopicRead, user_id: user_id, thread_id: thread_id)
    read == nil
  end

  def list_unread_threads(user_id, board_id, opts \\ []) do
    from(t in Thread,
      left_join: tr in TopicRead,
      on: tr.user_id == ^user_id and tr.thread_id == t.id,
      where: t.board_id == ^board_id and t.is_removed == false,
      where: is_nil(tr.id),
      preload: [:author, :board],
      order_by: [desc: t.inserted_at, desc: t.id]
    )
    |> apply_pagination(opts)
    |> Repo.all()
  end

  @doc """
  Flop pagination for a user's unread threads in a board.
  Returns {:ok, {threads, meta}} or {:error, meta}.
  """
  def paginate_unread_threads(user_id, board_id, params \\ %{}) do
    base =
      from(t in Thread,
        left_join: tr in TopicRead,
        on: tr.user_id == ^user_id and tr.thread_id == t.id,
        where: t.board_id == ^board_id and t.is_removed == false and is_nil(tr.id),
        preload: [:author, :board],
        order_by: [desc: t.inserted_at, desc: t.id]
      )

    Flop.validate_and_run(base, params, for: Thread, repo: Repo)
  end

  def list_new_threads(_user_id, board_id, opts \\ []) do
    days = Keyword.get(opts, :days, 1)

    cutoff = DateTime.utc_now() |> DateTime.add(-days * 86400, :second)

    from(t in Thread,
      where: t.board_id == ^board_id and t.is_removed == false and t.inserted_at > ^cutoff,
      preload: [:author, :board],
      order_by: [desc: t.inserted_at, desc: t.id]
    )
    |> apply_pagination(opts)
    |> Repo.all()
  end

  @doc """
  Flop pagination for newly created threads in a board within a time window.
  Returns {:ok, {threads, meta}} or {:error, meta}.
  """
  def paginate_new_threads(board_id, params \\ %{}, opts \\ []) do
    days = Keyword.get(opts, :days, 1)
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 86400, :second)

    base =
      from(t in Thread,
        where: t.board_id == ^board_id and t.is_removed == false and t.inserted_at > ^cutoff,
        preload: [:author, :board],
        order_by: [desc: t.inserted_at, desc: t.id]
      )

    Flop.validate_and_run(base, params, for: Thread, repo: Repo)
  end

  def list_latest_threads(board_id, opts \\ []) do
    from(t in Thread,
      where: t.board_id == ^board_id and t.is_removed == false,
      preload: [:author, :board],
      order_by: [desc: t.updated_at, desc: t.id]
    )
    |> apply_pagination(opts)
    |> Repo.all()
  end

  # Notification Settings

  def set_notification_level(user_id, thread_id, level) do
    %TopicNotificationSetting{}
    |> TopicNotificationSetting.changeset(%{
      user_id: user_id,
      thread_id: thread_id,
      notification_level: level
    })
    |> Repo.insert(
      on_conflict: {:replace, [:notification_level]},
      conflict_target: [:user_id, :thread_id]
    )
  end

  def get_notification_level(user_id, thread_id) do
    case Repo.get_by(TopicNotificationSetting, user_id: user_id, thread_id: thread_id) do
      nil -> "watching"
      setting -> setting.notification_level
    end
  end

  def is_watching?(user_id, thread_id) do
    get_notification_level(user_id, thread_id) == "watching"
  end

  def is_tracking?(user_id, thread_id) do
    get_notification_level(user_id, thread_id) == "tracking"
  end

  def is_muted?(user_id, thread_id) do
    get_notification_level(user_id, thread_id) == "muted"
  end

  # User Profiles

  def list_threads_by_author(author_id, opts \\ []) do
    from(t in Thread)
    |> where([t], t.author_id == ^author_id and t.is_removed == false)
    |> thread_preloads()
    |> order_by([t], desc: t.inserted_at, desc: t.id)
    |> apply_pagination(opts)
    |> Repo.all()
  end

  @doc """
  Flop pagination for threads by a specific author.
  Returns {:ok, {threads, meta}} or {:error, meta}.
  """
  def paginate_threads_by_author(author_id, params \\ %{}) do
    base =
      from(t in Thread)
      |> where([t], t.author_id == ^author_id and t.is_removed == false)
      |> thread_preloads()
      |> order_by([t], desc: t.inserted_at, desc: t.id)

    Flop.validate_and_run(base, params, for: Thread, repo: Repo)
  end

  def list_comments_by_author(author_id, opts \\ []) do
    from(c in Comment)
    |> where([c], c.author_id == ^author_id and c.is_removed == false)
    |> preload([:author, thread: :board])
    |> order_by([c], desc: c.inserted_at, desc: c.id)
    |> apply_pagination(opts)
    |> Repo.all()
  end

  @doc """
  Flop pagination for comments by a specific author.
  Returns {:ok, {comments, meta}} or {:error, meta}.
  """
  def paginate_comments_by_author(author_id, params \\ %{}) do
    base =
      from(c in Comment)
      |> where([c], c.author_id == ^author_id and c.is_removed == false)
      |> preload([:author, thread: :board])
      |> order_by([c], desc: c.inserted_at, desc: c.id)

    Flop.validate_and_run(base, params, for: Comment, repo: Repo)
  end

  def count_threads_by_author(author_id) do
    from(t in Thread, where: t.author_id == ^author_id and t.is_removed == false)
    |> Repo.aggregate(:count)
  end

  def count_comments_by_author(author_id) do
    from(c in Comment, where: c.author_id == ^author_id and c.is_removed == false)
    |> Repo.aggregate(:count)
  end

  # --- internal helpers

  defp apply_vote_delta("thread", target_id, delta, {:ok, _}) do
    from(t in Thread, where: t.id == ^target_id)
    |> Repo.update_all(inc: [score: delta])
  end

  defp apply_vote_delta("comment", target_id, delta, {:ok, _}) do
    from(c in Comment, where: c.id == ^target_id)
    |> Repo.update_all(inc: [score: delta])
  end

  defp apply_vote_delta(_other, _target_id, _delta, error), do: Repo.rollback(error)

  # Helpers

  defp update_thread_comment_count(thread_id) do
    count =
      from(c in Comment, where: c.thread_id == ^thread_id and c.is_removed == false)
      |> Repo.aggregate(:count)

    from(t in Thread, where: t.id == ^thread_id)
    |> Repo.update_all(set: [comment_count: count])
  end

  # Generic rate limit wrapper; -1 means unlimited
  defp with_rate_limit(_user_id, _action, -1, _window_seconds, fun) when is_function(fun, 0) do
    fun.()
  end

  defp with_rate_limit(user_id, action, max_requests, window_seconds, fun)
       when is_function(fun, 0) do
    case Urielm.RateLimiter.check_limit("user:#{user_id}", action,
           max_requests: max_requests,
           window_seconds: window_seconds
         ) do
      {:ok, _remaining} -> fun.()
      {:error, :rate_limited} -> {:error, :rate_limited}
    end
  end

  # --- small internal helpers (refactor)

  # Common thread preloads used across queries
  defp thread_preloads(query), do: preload(query, [:author, :board])

  # Preload thread metadata for struct (post-fetch)
  defp preload_thread_meta(%Thread{} = thread), do: Repo.preload(thread, [:author, :board])

  # Authorization helper for owner-or-admin checks
  defp authorized?(%{id: id, is_admin: true}, _owner_id) when not is_nil(id), do: true
  defp authorized?(%{id: id, is_admin: _}, owner_id) when not is_nil(id), do: id == owner_id
  defp authorized?(_user, _owner_id), do: false
end
