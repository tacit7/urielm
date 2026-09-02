defmodule Mix.Tasks.Videos.Update do
  @moduledoc """
  Updates editable fields on a standalone video identified by slug.
  """

  use Mix.Task

  alias Urielm.Content
  alias Urielm.Repo

  @shortdoc "Updates a video by slug"
  @requirements ["app.config"]
  @valid_visibilities ["public", "signed_in", "subscriber"]
  @valid_formats ["standard", "short"]

  @impl Mix.Task
  def run(args) do
    {opts, slugs, invalid} =
      OptionParser.parse(args,
        strict: [
          title: :string,
          slug: :string,
          youtube_url: :string,
          tiktok_url: :string,
          format: :string,
          description: :string,
          description_file: :string,
          resources: :string,
          resources_file: :string,
          author_name: :string,
          author_url: :string,
          author_bio: :string,
          author_bio_file: :string,
          visibility: :string,
          publish: :boolean,
          unpublish: :boolean
        ],
        aliases: [
          y: :youtube_url,
          t: :tiktok_url
        ]
      )

    with [video_slug] <- slugs,
         [] <- invalid,
         :ok <- validate_opts(opts) do
      start_dependencies!()
      update_video!(video_slug, opts)
    else
      {:error, message} -> fail!(message)
      _invalid -> fail!(usage())
    end
  end

  defp validate_opts(opts) do
    cond do
      opts == [] ->
        {:error, usage()}

      Keyword.has_key?(opts, :description) and Keyword.has_key?(opts, :description_file) ->
        {:error, "Use either --description or --description-file, not both"}

      Keyword.has_key?(opts, :resources) and Keyword.has_key?(opts, :resources_file) ->
        {:error, "Use either --resources or --resources-file, not both"}

      Keyword.has_key?(opts, :author_bio) and Keyword.has_key?(opts, :author_bio_file) ->
        {:error, "Use either --author-bio or --author-bio-file, not both"}

      Keyword.get(opts, :publish, false) and Keyword.get(opts, :unpublish, false) ->
        {:error, "Use either --publish or --unpublish, not both"}

      true ->
        with :ok <- validate_visibility(Keyword.get(opts, :visibility)),
             :ok <- validate_format(Keyword.get(opts, :format)) do
          :ok
        end
    end
  end

  defp validate_visibility(nil), do: :ok

  defp validate_visibility(visibility) do
    if visibility in @valid_visibilities,
      do: :ok,
      else: {:error, "Invalid visibility: #{visibility}"}
  end

  defp validate_format(nil), do: :ok

  defp validate_format(format) do
    if format in @valid_formats, do: :ok, else: {:error, "Invalid format: #{format}"}
  end

  defp update_video!(video_slug, opts) do
    case Content.get_video_by_slug(video_slug) do
      nil ->
        fail!("Video not found: #{video_slug}")

      video ->
        attrs = attrs_from_opts(opts)

        case Content.update_video(video, attrs) do
          {:ok, updated} ->
            Mix.shell().info("""
            Updated video:
            Title: #{updated.title}
            Slug: #{updated.slug}
            URL: /videos/#{updated.slug}
            """)

            updated

          {:error, %Ecto.Changeset{} = changeset} ->
            fail!("Could not update video:\n#{format_errors(changeset)}")
        end
    end
  end

  defp attrs_from_opts(opts) do
    %{}
    |> maybe_put(:title, Keyword.get(opts, :title))
    |> maybe_put(:slug, Keyword.get(opts, :slug))
    |> maybe_put(:youtube_url, Keyword.get(opts, :youtube_url))
    |> maybe_put(:tiktok_url, Keyword.get(opts, :tiktok_url))
    |> maybe_put(:format, Keyword.get(opts, :format))
    |> maybe_put(:description_md, Keyword.get(opts, :description))
    |> maybe_put(:description_md, read_file_opt(opts, :description_file))
    |> maybe_put(:resources_md, Keyword.get(opts, :resources))
    |> maybe_put(:resources_md, read_file_opt(opts, :resources_file))
    |> maybe_put(:author_name, Keyword.get(opts, :author_name))
    |> maybe_put(:author_url, Keyword.get(opts, :author_url))
    |> maybe_put(:author_bio_md, Keyword.get(opts, :author_bio))
    |> maybe_put(:author_bio_md, read_file_opt(opts, :author_bio_file))
    |> maybe_put(:visibility, Keyword.get(opts, :visibility))
    |> maybe_publish(opts)
  end

  defp read_file_opt(opts, key) do
    case Keyword.get(opts, key) do
      nil -> nil
      path -> File.read!(path)
    end
  end

  defp maybe_put(attrs, _key, nil), do: attrs
  defp maybe_put(attrs, key, value), do: Map.put(attrs, key, value)

  defp maybe_publish(attrs, opts) do
    cond do
      Keyword.get(opts, :publish, false) ->
        Map.put(attrs, :published_at, DateTime.utc_now() |> DateTime.truncate(:second))

      Keyword.get(opts, :unpublish, false) ->
        Map.put(attrs, :published_at, nil)

      true ->
        attrs
    end
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
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("\n", fn {field, messages} ->
      "#{field}: #{Enum.join(messages, ", ")}"
    end)
  end

  defp usage do
    "Usage: mix videos.update VIDEO_SLUG [--title TITLE] [--slug SLUG] [--description-file PATH] [--resources-file PATH] [--visibility public|signed_in|subscriber] [--publish|--unpublish]"
  end

  defp fail!(message) do
    Mix.shell().error(message)
    Mix.raise(message)
  end
end
