defmodule Mix.Tasks.Videos.Add do
  @moduledoc """
  Adds a standalone YouTube video from public oEmbed metadata.
  """

  use Mix.Task

  import Ecto.Query, only: [from: 2]

  alias Urielm.Content
  alias Urielm.Content.Video
  alias Urielm.Repo

  @shortdoc "Adds a standalone YouTube video from a URL"
  @requirements ["app.config"]
  @valid_visibilities ["public", "signed_in", "subscriber"]

  @impl Mix.Task
  def run(args) do
    {opts, urls} =
      OptionParser.parse!(args,
        strict: [
          draft: :boolean,
          visibility: :string,
          title: :string,
          slug: :string,
          tags: :string
        ]
      )

    url = one_url!(urls)
    visibility = Keyword.get(opts, :visibility, "public")

    if visibility not in @valid_visibilities do
      fail!("Invalid visibility: #{visibility}")
    end

    start_dependencies!()

    case Repo.get_by(Video, youtube_url: url) do
      %Video{} = video ->
        Mix.shell().info("""
        Already exists:
        Title: #{video.title}
        Slug: #{video.slug}
        URL: #{video_path(video)}
        """)

        video

      nil ->
        insert_video(url, opts, visibility)
    end
  end

  defp insert_video(url, opts, visibility) do
    metadata = fetch_metadata!(url)
    title = opts[:title] || metadata_title!(metadata)
    slug = resolve_slug!(opts[:slug], title, url)

    attrs = %{
      title: title,
      slug: slug,
      youtube_url: url,
      description_md: "",
      resources_md: "",
      author_name: metadata["author_name"],
      author_url: metadata["author_url"],
      author_bio_md: "",
      visibility: visibility,
      format: "standard",
      published_at: published_at(opts)
    }

    case Content.create_video(attrs, tag_names: parse_tags(Keyword.get(opts, :tags))) do
      {:ok, video} ->
        Mix.shell().info("""
        Inserted video:
        Title: #{video.title}
        Slug: #{video.slug}
        URL: #{video_path(video)}
        """)

        video

      {:error, %Ecto.Changeset{} = changeset} ->
        fail!("Could not insert video:\n#{format_errors(changeset)}")

      {:error, reason} ->
        fail!("Could not insert video tags:\n#{inspect(reason)}")
    end
  end

  defp one_url!([url]), do: url

  defp one_url!(_urls) do
    fail!(
      "Usage: mix videos.add YOUTUBE_URL [--draft] [--visibility public|signed_in|subscriber] [--title TITLE] [--slug SLUG] [--tags TAGS]"
    )
  end

  defp parse_tags(nil), do: []

  defp parse_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp fetch_metadata!(url) do
    case fetcher().(url) do
      {:ok, %{} = metadata} -> metadata
      {:error, reason} -> fail!("Metadata could not be fetched: #{reason}")
      other -> fail!("YouTube returned unexpected metadata: #{inspect(other)}")
    end
  end

  defp fetcher do
    Application.get_env(:urielm, :youtube_oembed_fetcher, &fetch_youtube_oembed/1)
  end

  defp fetch_youtube_oembed(url) do
    request_url = "https://www.youtube.com/oembed?url=#{URI.encode_www_form(url)}&format=json"

    case Req.get(request_url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: %{} = body}} ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        decode_metadata(body)

      {:ok, %{status: status}} ->
        {:error, "YouTube oEmbed returned HTTP #{status}"}

      {:error, reason} ->
        {:error, Exception.message(reason)}
    end
  end

  defp decode_metadata(body) do
    case Jason.decode(body) do
      {:ok, %{} = metadata} -> {:ok, metadata}
      {:ok, _} -> {:error, "YouTube returned unexpected metadata"}
      {:error, _} -> {:error, "YouTube returned invalid JSON"}
    end
  end

  defp metadata_title!(%{"title" => title}) when is_binary(title) do
    case String.trim(title) do
      "" -> fail!("Video title could not be found")
      title -> title
    end
  end

  defp metadata_title!(_metadata), do: fail!("Video title could not be found")

  defp start_dependencies! do
    [:ssl, :postgrex, :ecto_sql, :req]
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

  defp resolve_slug!(custom_slug, _title, _url) when is_binary(custom_slug) do
    slug = String.trim(custom_slug)

    cond do
      slug == "" ->
        fail!("Custom slug cannot be blank")

      slug_taken?(slug) ->
        fail!("Slug already exists: #{slug}")

      true ->
        slug
    end
  end

  defp resolve_slug!(_custom_slug, title, url) do
    slug = slugify(title)

    cond do
      slug == "" ->
        fail!("Generated slug was empty")

      slug_taken?(slug) ->
        "#{slug}-#{youtube_id_suffix(url)}"

      true ->
        slug
    end
  end

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp slug_taken?(slug) do
    Repo.exists?(from(v in Video, where: v.slug == ^slug))
  end

  defp youtube_id_suffix(url) do
    url
    |> youtube_id()
    |> case do
      nil -> :crypto.hash(:sha256, url) |> Base.url_encode64(padding: false)
      id -> id
    end
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "")
    |> String.slice(0, 8)
  end

  defp youtube_id(url) do
    uri = URI.parse(url)
    params = URI.decode_query(uri.query || "")
    path_parts = uri.path |> to_string() |> String.split("/", trim: true)

    cond do
      is_binary(params["v"]) and params["v"] != "" ->
        params["v"]

      uri.host in ["youtu.be", "www.youtu.be"] and path_parts != [] ->
        List.first(path_parts)

      List.first(path_parts) in ["embed", "shorts", "live"] ->
        Enum.at(path_parts, 1)

      true ->
        nil
    end
  end

  defp published_at(opts) do
    if Keyword.get(opts, :draft, false) do
      nil
    else
      DateTime.utc_now() |> DateTime.truncate(:second)
    end
  end

  defp video_path(video), do: "/videos/#{video.slug}"

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
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
