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
  alias Urielm.Forum.{Category, Board, Thread, Comment, Vote}

  @max_comment_depth 8

  # Categories

  def list_categories(opts \\ []) do
    hidden = Keyword.get(opts, :hidden, false)

    from(c in Category)
    |> where([c], c.is_hidden == ^hidden)
    |> order_by([c], c.position)
    |> Repo.all()
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
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    query =
      from(t in Thread)
      |> where([t], t.board_id == ^board_id and t.is_removed == false)
      |> preload([:author, :board])

    query =
      case sort do
        :new -> order_by(query, [t], desc: t.inserted_at)
        :top -> order_by(query, [t], desc: t.score)
      end

    query
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  def get_thread!(id) do
    thread = Repo.get!(Thread, id)
    comments = list_comments_with_authors(id)

    thread
    |> Repo.preload([:author, :board])
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
    %Thread{}
    |> Thread.changeset(Map.merge(attrs, %{"board_id" => board_id, "author_id" => author_id}))
    |> Repo.insert()
  end

  def update_thread(%Thread{} = thread, attrs) do
    thread
    |> Thread.changeset(attrs)
    |> Repo.update()
  end

  def remove_thread(%Thread{} = thread, %{id: user_id, is_admin: is_admin} = _user) do
    cond do
      is_admin ->
        update_thread(thread, %{is_removed: true, removed_by_id: user_id})

      thread.author_id == user_id ->
        update_thread(thread, %{is_removed: true, removed_by_id: user_id})

      true ->
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
    parent_id = Map.get(attrs, "parent_id") || Map.get(attrs, :parent_id)

    with :ok <- validate_comment_depth(parent_id) do
      %Comment{}
      |> Comment.changeset(Map.merge(attrs, %{"thread_id" => thread_id, "author_id" => author_id}))
      |> Repo.insert()
      |> case do
        {:ok, comment} ->
          update_thread_comment_count(thread_id)
          {:ok, comment}

        error ->
          error
      end
    else
      {:error, :max_depth_exceeded} ->
        {:error, :max_depth_exceeded}
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

  def remove_comment(%Comment{} = comment, %{id: user_id, is_admin: is_admin} = _user) do
    cond do
      is_admin ->
        update_comment(comment, %{is_removed: true, removed_by_id: user_id})

      comment.author_id == user_id ->
        update_comment(comment, %{is_removed: true, removed_by_id: user_id})

      true ->
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
      case {target_type, result} do
        {"thread", {:ok, _}} ->
          from(t in Thread, where: t.id == ^target_id)
          |> Repo.update_all(inc: [score: delta])

        {"comment", {:ok, _}} ->
          from(c in Comment, where: c.id == ^target_id)
          |> Repo.update_all(inc: [score: delta])

        {_, error} ->
          Repo.rollback(error)
      end

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

          case target_type do
            "thread" ->
              from(t in Thread, where: t.id == ^target_id)
              |> Repo.update_all(inc: [score: -old_value])

            "comment" ->
              from(c in Comment, where: c.id == ^target_id)
              |> Repo.update_all(inc: [score: -old_value])
          end
        end)
    end
  end

  def get_user_vote(user_id, target_type, target_id) do
    Repo.get_by(Vote, user_id: user_id, target_type: target_type, target_id: target_id)
  end

  # Helpers

  defp update_thread_comment_count(thread_id) do
    count =
      from(c in Comment, where: c.thread_id == ^thread_id and c.is_removed == false)
      |> Repo.aggregate(:count)

    from(t in Thread, where: t.id == ^thread_id)
    |> Repo.update_all(set: [comment_count: count])
  end
end
