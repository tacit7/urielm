defmodule Urielm.Content do
  @moduledoc """
  The Content context for managing references and other content.
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.Content.Prompt
  alias Urielm.Content.Post
  alias Urielm.Content.Like
  alias Urielm.Content.Comment
  alias Urielm.Accounts.SavedPrompt

  @doc """
  Returns the list of prompts.

  ## Examples

      iex> list_prompts()
      [%Prompt{}, ...]

  """
  def list_prompts(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(p in Prompt, order_by: [desc: p.inserted_at], limit: ^limit, offset: ^offset)
    |> Repo.all()
  end

  @doc """
  Returns the list of prompts filtered by category.

  ## Examples

      iex> list_prompts_by_category("coding")
      [%Prompt{}, ...]

  """
  def list_prompts_by_category(category, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(p in Prompt,
      where: p.category == ^category,
      order_by: [desc: p.inserted_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc """
  Gets a single prompt with tag_records preloaded.

  Raises `Ecto.NoResultsError` if the Prompt does not exist.

  ## Examples

      iex> get_prompt!(123)
      %Prompt{}

      iex> get_prompt!(456)
      ** (Ecto.NoResultsError)

  """
  def get_prompt!(id) do
    Repo.get!(Prompt, id)
    |> Repo.preload(:tag_records)
  end

  @doc """
  Creates a prompt.

  ## Examples

      iex> create_prompt(%{field: value})
      {:ok, %Prompt{}}

      iex> create_prompt(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_prompt(attrs \\ %{}) do
    %Prompt{}
    |> Prompt.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a prompt.

  ## Examples

      iex> update_prompt(prompt, %{field: new_value})
      {:ok, %Prompt{}}

      iex> update_prompt(prompt, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_prompt(%Prompt{} = prompt, attrs) do
    prompt
    |> Prompt.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a prompt.

  ## Examples

      iex> delete_prompt(prompt)
      {:ok, %Prompt{}}

      iex> delete_prompt(prompt)
      {:error, %Ecto.Changeset{}}

  """
  def delete_prompt(%Prompt{} = prompt) do
    Repo.delete(prompt)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking prompt changes.

  ## Examples

      iex> change_prompt(prompt)
      %Ecto.Changeset{data: %Prompt{}}

  """
  def change_prompt(%Prompt{} = prompt, attrs \\ %{}) do
    Prompt.changeset(prompt, attrs)
  end

  @doc """
  Returns a list of unique categories from all prompts.

  ## Examples

      iex> list_categories()
      ["coding", "n8n", "prompts"]

  """
  def list_categories do
    Repo.all(
      from(p in Prompt,
        select: p.category,
        distinct: true,
        order_by: p.category
      )
    )
  end

  @doc """
  Search prompts using full-text search with fuzzy fallback.

  ## Options

    * `:category` - Filter by category (optional)
    * `:tag_ids` - Filter by tag IDs via join table (list, optional)
    * `:limit` - Maximum number of results (default: 20)
    * `:offset` - Number of results to skip (default: 0)

  ## Examples

      iex> search_prompts("tiktok hooks")
      [%Prompt{rank: 0.8, ...}, ...]

      iex> search_prompts("", category: "coding")
      [%Prompt{}, ...]

      iex> search_prompts("email", tag_ids: [1, 2, 3])
      [%Prompt{}, ...]

  """
  def search_prompts(search_text, opts \\ %{}) do
    query_text = search_text |> to_string() |> String.trim()
    base = base_query(opts)

    cond do
      query_text == "" ->
        # No search term, just return filtered results alphabetically
        from(p in base, order_by: [asc: p.title], preload: :tag_records)
        |> apply_pagination(opts)
        |> Repo.all()

      true ->
        # Try full-text search first
        results = full_text_search(query_text, base, opts)

        if results == [] do
          # Fallback to fuzzy search if no results
          fuzzy_search(query_text, base, opts)
        else
          results
        end
    end
  end

  # Build base query with category and tag filters
  defp base_query(opts) do
    base = from(p in Prompt)

    base =
      case Map.get(opts, :category) do
        nil -> base
        "all" -> base
        category -> from(p in base, where: p.category == ^category)
      end

    base =
      case Map.get(opts, :tag_ids) do
        nil ->
          base

        [] ->
          base

        tag_ids ->
          from(p in base,
            join: pt in assoc(p, :prompt_tags),
            where: pt.tag_id in ^tag_ids,
            distinct: true
          )
      end

    base
  end

  # Full-text search using tsvector
  defp full_text_search(query_text, base, opts) do
    from(p in base,
      where:
        fragment(
          "search_vector @@ plainto_tsquery('simple', ?)",
          ^query_text
        ),
      select_merge: %{
        rank:
          fragment(
            "ts_rank(search_vector, plainto_tsquery('simple', ?))",
            ^query_text
          )
      },
      order_by: [
        desc:
          fragment(
            "ts_rank(search_vector, plainto_tsquery('simple', ?))",
            ^query_text
          )
      ],
      preload: :tag_records
    )
    |> apply_pagination(opts)
    |> Repo.all()
  end

  # Fuzzy search using trigram similarity
  defp fuzzy_search(query_text, base, opts) do
    from(p in base,
      where: fragment("similarity(?, ?) > 0.2", p.title, ^query_text),
      select_merge: %{
        rank: fragment("similarity(?, ?)", p.title, ^query_text)
      },
      order_by: [
        desc: fragment("similarity(?, ?)", p.title, ^query_text)
      ],
      preload: :tag_records
    )
    |> apply_pagination(opts)
    |> Repo.all()
  end

  # Apply limit and offset to query
  defp apply_pagination(query, opts) do
    limit = Map.get(opts, :limit, 20)
    offset = Map.get(opts, :offset, 0)

    from(p in query, limit: ^limit, offset: ^offset)
  end

  # Post functions

  @doc """
  Returns the list of published blog posts.

  ## Examples

      iex> list_published_posts()
      [%Post{}, ...]

  """
  def list_published_posts do
    Post
    |> Post.published()
    |> order_by([p], desc: p.published_at)
    |> Repo.all()
  end

  @doc """
  Gets a single published post by slug.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post_by_slug!("my-first-post")
      %Post{}

      iex> get_post_by_slug!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  def get_post_by_slug!(slug) do
    Post
    |> Post.published()
    |> Repo.get_by!(slug: slug)
  end

  @doc """
  Returns the list of all posts (including drafts).

  """
  def list_all_posts do
    Repo.all(from(p in Post, order_by: [desc: p.inserted_at]))
  end

  @doc """
  Gets a single post by ID.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  """
  def get_post!(id), do: Repo.get!(Post, id)

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  # Like functions

  @doc """
  Creates or deletes a like for a prompt by a user.
  Returns :ok and updated prompt if successful.
  """
  def toggle_like(user_id, prompt_id) do
    case Repo.get_by(Like, user_id: user_id, prompt_id: prompt_id) do
      nil ->
        # Create like
        with {:ok, _} <- Repo.insert(%Like{user_id: user_id, prompt_id: prompt_id}),
             {:ok, prompt} <- update_prompt_likes_count(prompt_id) do
          {:ok, prompt}
        end

      like ->
        # Delete like
        with {:ok, _} <- Repo.delete(like),
             {:ok, prompt} <- update_prompt_likes_count(prompt_id) do
          {:ok, prompt}
        end
    end
  end

  @doc """
  Checks if a user has liked a prompt.
  """
  def user_liked_prompt?(user_id, prompt_id) do
    Repo.exists?(from(l in Like, where: l.user_id == ^user_id and l.prompt_id == ^prompt_id))
  end

  # Save functions

  @doc """
  Creates or deletes a saved prompt for a user.
  Returns :ok and updated prompt if successful.
  """
  def toggle_save(user_id, prompt_id) do
    case Repo.get_by(SavedPrompt, user_id: user_id, prompt_id: prompt_id) do
      nil ->
        # Create saved prompt
        with {:ok, _} <- Repo.insert(%SavedPrompt{user_id: user_id, prompt_id: prompt_id}),
             {:ok, prompt} <- update_prompt_saves_count(prompt_id) do
          {:ok, prompt}
        end

      saved ->
        # Delete saved prompt
        with {:ok, _} <- Repo.delete(saved),
             {:ok, prompt} <- update_prompt_saves_count(prompt_id) do
          {:ok, prompt}
        end
    end
  end

  @doc """
  Checks if a user has saved a prompt.
  """
  def user_saved_prompt?(user_id, prompt_id) do
    Repo.exists?(
      from(sp in SavedPrompt, where: sp.user_id == ^user_id and sp.prompt_id == ^prompt_id)
    )
  end

  # Comment functions

  @doc """
  Creates a comment on a prompt.
  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, comment} ->
        # Update comment count
        update_prompt_comments_count(comment.prompt_id)
        {:ok, comment}

      error ->
        error
    end
  end

  @doc """
  Gets a single comment.
  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Updates a comment.
  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment (soft delete).
  """
  def delete_comment(%Comment{} = comment) do
    comment
    |> Comment.changeset(%{deleted_at: DateTime.utc_now()})
    |> Repo.update()
    |> case do
      {:ok, comment} ->
        update_prompt_comments_count(comment.prompt_id)
        {:ok, comment}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.
  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  @doc """
  Gets a prompt with its comments for display.
  """
  def get_prompt_with_comments(prompt_id) do
    prompt = Repo.get!(Prompt, prompt_id) |> Repo.preload(:tag_records)

    comments =
      from(c in Comment,
        where: c.prompt_id == ^prompt_id and is_nil(c.deleted_at) and is_nil(c.parent_id),
        order_by: [desc: c.inserted_at],
        preload: [:user, :replies]
      )
      |> Repo.all()

    Map.put(prompt, :comments, comments)
  end

  # Helper functions

  defp update_prompt_likes_count(prompt_id) do
    count = Repo.aggregate(from(l in Like, where: l.prompt_id == ^prompt_id), :count)

    prompt = Repo.get!(Prompt, prompt_id)
    update_prompt(prompt, %{likes_count: count})
  end

  defp update_prompt_saves_count(prompt_id) do
    count = Repo.aggregate(from(sp in SavedPrompt, where: sp.prompt_id == ^prompt_id), :count)

    prompt = Repo.get!(Prompt, prompt_id)
    update_prompt(prompt, %{saves_count: count})
  end

  defp update_prompt_comments_count(prompt_id) do
    count =
      Repo.aggregate(
        from(c in Comment, where: c.prompt_id == ^prompt_id and is_nil(c.deleted_at)),
        :count
      )

    prompt = Repo.get!(Prompt, prompt_id)
    update_prompt(prompt, %{comments_count: count})
  end

  # Video functions

  alias Urielm.Content.Video
  alias Urielm.Content.VideoCompletion

  @doc """
  Gets a single video by slug.

  Raises `Ecto.NoResultsError` if the Video does not exist.

  ## Examples

      iex> get_video_by_slug!("intro-to-elixir")
      %Video{}

  """
  def get_video(id) do
    Repo.get(Video, id)
  end

  def get_video_by_slug!(slug) do
    Repo.get_by!(Video, slug: slug)
    |> Repo.preload(:thread)
  end

  @doc """
  Returns the list of published videos.

  ## Examples

      iex> list_published_videos()
      [%Video{}, ...]

  """
  def list_published_videos(opts \\ []) do
    limit = Keyword.get(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)

    query = from(v in Video,
      where: not is_nil(v.published_at),
      order_by: [desc: v.published_at, desc: v.id],
      offset: ^offset
    )

    query = if limit, do: from(q in query, limit: ^limit), else: query

    Repo.all(query)
  end

  @doc """
  Checks if a video is published.

  ## Examples

      iex> video_published?(%Video{published_at: ~U[2024-01-01 00:00:00Z]})
      true

      iex> video_published?(%Video{published_at: nil})
      false

  """
  def video_published?(%Video{published_at: nil}), do: false
  def video_published?(%Video{published_at: _}), do: true

  @doc """
  Creates a video.

  ## Examples

      iex> create_video(%{title: "My Video", slug: "my-video", ...})
      {:ok, %Video{}}

      iex> create_video(%{title: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_video(attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a video.

  ## Examples

      iex> update_video(video, %{title: "New Title"})
      {:ok, %Video{}}

  """
  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Checks if a user can view a video based on visibility and user status.

  Rules:
  - public: anyone can view
  - signed_in: requires authenticated user
  - subscriber: requires active subscription or admin
  - admins can always view

  ## Examples

      iex> can_view_video?(nil, %Video{visibility: "public"})
      true

      iex> can_view_video?(nil, %Video{visibility: "signed_in"})
      false

  """
  def can_view_video?(_user, %Video{visibility: "public"}), do: true

  def can_view_video?(%{is_admin: true}, _video), do: true

  def can_view_video?(%{} = _user, %Video{visibility: "signed_in"}), do: true

  def can_view_video?(%{} = user, %Video{visibility: "subscriber"}) do
    Urielm.Billing.active_subscription?(user)
  end

  def can_view_video?(nil, _video), do: false

  # Video completion functions

  @doc """
  Checks if a user has completed a video.

  ## Examples

      iex> completed_video?(%User{id: 1}, %Video{id: "abc"})
      true

  """
  def completed_video?(%{id: user_id}, %Video{id: video_id}) do
    Repo.exists?(
      from vc in VideoCompletion,
        where: vc.user_id == ^user_id and vc.video_id == ^video_id
    )
  end

  def completed_video?(nil, _video), do: false

  @doc """
  Marks a video as complete for a user.

  Upserts completion record with current timestamp.

  ## Examples

      iex> mark_video_complete(%User{id: 1}, %Video{id: "abc"})
      {:ok, %VideoCompletion{}}

  """
  def mark_video_complete(%{id: user_id}, %Video{id: video_id}) do
    attrs = %{
      user_id: user_id,
      video_id: video_id,
      completed_at: DateTime.utc_now()
    }

    %VideoCompletion{}
    |> VideoCompletion.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:completed_at]},
      conflict_target: [:user_id, :video_id]
    )
  end

  @doc """
  Removes completion mark for a video.

  ## Examples

      iex> unmark_video_complete(%User{id: 1}, %Video{id: "abc"})
      {:ok, 1}

  """
  def unmark_video_complete(%{id: user_id}, %Video{id: video_id}) do
    {count, _} =
      from(vc in VideoCompletion,
        where: vc.user_id == ^user_id and vc.video_id == ^video_id
      )
      |> Repo.delete_all()

    {:ok, count}
  end
end
