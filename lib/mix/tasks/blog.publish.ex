defmodule Mix.Tasks.Blog.Publish do
  @moduledoc """
  Creates or updates a blog post from a metadata-backed Markdown file.

      mix blog.publish path/to/article.md --author USERNAME
      mix blog.publish path/to/article.md --author USERNAME --draft
      mix blog.publish path/to/article.md --author USERNAME --hero-image /images/article.png

  The file must start with an HTML comment containing `Title`, `Slug`, and
  `Excerpt` fields. A leading H1 and byline are removed from the stored body
  because the blog layout renders those elements.
  """

  use Mix.Task

  alias Urielm.Accounts
  alias Urielm.Content
  alias Urielm.Content.Post
  alias Urielm.Repo

  @shortdoc "Creates or updates a blog post from Markdown"
  @requirements ["app.config"]
  @required_metadata ~w(title slug excerpt)

  @impl Mix.Task
  def run(args) do
    {opts, paths} =
      OptionParser.parse!(args,
        strict: [author: :string, draft: :boolean, hero_image: :string],
        aliases: []
      )

    path = one_path!(paths)
    author_username = required_author!(opts[:author])
    article = read_article!(path)

    start_dependencies!()

    author =
      Accounts.get_user_by_username(author_username) ||
        fail!("Author not found: #{author_username}")

    existing = Repo.get_by(Post, slug: article.slug)
    attrs = post_attrs(article, author.id, existing, opts)

    {action, result} =
      case existing do
        %Post{} = post -> {:updated, Content.update_post(post, attrs)}
        nil -> {:created, Content.create_post(attrs)}
      end

    case result do
      {:ok, post} ->
        report_success(action, post)
        post

      {:error, %Ecto.Changeset{} = changeset} ->
        fail!("Could not save blog post:\n#{format_errors(changeset)}")
    end
  end

  defp one_path!([path]), do: path

  defp one_path!(_paths) do
    fail!("Usage: mix blog.publish PATH --author USERNAME [--draft] [--hero-image URL]")
  end

  defp required_author!(author) when is_binary(author) do
    case String.trim(author) do
      "" -> fail!("--author USERNAME is required")
      username -> username
    end
  end

  defp required_author!(_author), do: fail!("--author USERNAME is required")

  defp read_article!(path) do
    contents =
      case File.read(path) do
        {:ok, contents} -> contents
        {:error, reason} -> fail!("Could not read #{path}: #{:file.format_error(reason)}")
      end

    case Regex.run(~r/\A\s*(<!--\s*(.*?)-->)\s*/s, contents) do
      [matched, _comment, metadata_text] ->
        metadata = parse_metadata(metadata_text)
        validate_metadata!(metadata)

        title = metadata["title"]

        %{
          title: title,
          slug: metadata["slug"],
          excerpt: metadata["excerpt"],
          body: contents |> String.replace_prefix(matched, "") |> clean_body(title)
        }

      _ ->
        fail!("Missing publishing metadata at the start of #{path}")
    end
  end

  defp parse_metadata(metadata_text) do
    metadata_text
    |> String.split(~r/\R/)
    |> Enum.reduce(%{}, fn line, metadata ->
      case Regex.run(~r/^\s*([A-Za-z][A-Za-z ]*):\s*(.+?)\s*$/, line) do
        [_line, key, value] -> Map.put(metadata, normalize_key(key), value)
        _ -> metadata
      end
    end)
  end

  defp normalize_key(key) do
    key
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end

  defp validate_metadata!(metadata) do
    missing = Enum.reject(@required_metadata, &present?(metadata[&1]))

    if missing != [] do
      fail!("Missing publishing metadata: #{Enum.join(missing, ", ")}")
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_value), do: false

  defp clean_body(body, title) do
    title_pattern = Regex.escape(title)

    body
    |> String.trim_leading()
    |> String.replace(
      ~r/\A#\s+#{title_pattern}[ \t]*\r?\n+(?:By[ \t]+[^\r\n]+[ \t]*\r?\n+)?/i,
      ""
    )
    |> String.trim_leading()
  end

  defp post_attrs(article, author_id, existing, opts) do
    attrs = %{
      title: article.title,
      slug: article.slug,
      excerpt: article.excerpt,
      body: article.body,
      author_id: author_id,
      status: if(opts[:draft], do: "draft", else: "published"),
      published_at: published_at(existing, opts)
    }

    case opts[:hero_image] do
      nil -> attrs
      hero_image -> Map.put(attrs, :hero_image, hero_image)
    end
  end

  defp published_at(existing, opts) do
    cond do
      opts[:draft] -> nil
      match?(%Post{published_at: %DateTime{}}, existing) -> existing.published_at
      true -> DateTime.utc_now() |> DateTime.truncate(:second)
    end
  end

  defp report_success(action, post) do
    label =
      cond do
        post.status == "draft" -> "Saved draft:"
        action == :updated -> "Updated blog post:"
        true -> "Published blog post:"
      end

    Mix.shell().info("""
    #{label}
    Title: #{post.title}
    Slug: #{post.slug}
    URL: /blog/#{post.slug}
    """)
  end

  defp start_dependencies! do
    [:postgrex, :ecto_sql]
    |> Enum.each(fn app ->
      case Application.ensure_all_started(app) do
        {:ok, _apps} -> :ok
        {:error, reason} -> fail!("Could not start #{app}: #{inspect(reason)}")
      end
    end)

    case Repo.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> fail!("Could not start repo: #{inspect(reason)}")
    end
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("\n", fn {field, messages} ->
      "#{field}: #{Enum.join(messages, ", ")}"
    end)
  end

  defp fail!(message) do
    Mix.shell().error(message)
    Mix.raise(message)
  end
end
