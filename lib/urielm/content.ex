defmodule Urielm.Content do
  @moduledoc """
  The Content context for managing references and other content.
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.Content.Prompt
  alias Urielm.Content.Post

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
  Gets a single prompt.

  Raises `Ecto.NoResultsError` if the Prompt does not exist.

  ## Examples

      iex> get_prompt!(123)
      %Prompt{}

      iex> get_prompt!(456)
      ** (Ecto.NoResultsError)

  """
  def get_prompt!(id), do: Repo.get!(Prompt, id)

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
    * `:tags` - Filter by tags (list, optional)
    * `:limit` - Maximum number of results (default: 20)
    * `:offset` - Number of results to skip (default: 0)

  ## Examples

      iex> search_prompts("tiktok hooks")
      [%Prompt{rank: 0.8, ...}, ...]

      iex> search_prompts("", category: "coding")
      [%Prompt{}, ...]

      iex> search_prompts("email", tags: ["marketing"])
      [%Prompt{}, ...]

  """
  def search_prompts(search_text, opts \\ %{}) do
    query_text = search_text |> to_string() |> String.trim()
    base = base_query(opts)

    cond do
      query_text == "" ->
        # No search term, just return filtered results alphabetically
        from(p in base, order_by: [asc: p.title])
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
      case Map.get(opts, :tags) do
        nil -> base
        [] -> base
        tags -> from(p in base, where: fragment("? && ?", p.tags, ^tags))
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
      ]
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
      ]
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
    Repo.all(from p in Post, order_by: [desc: p.inserted_at])
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
end
