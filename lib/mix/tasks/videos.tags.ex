defmodule Mix.Tasks.Videos.Tags do
  @moduledoc """
  Replaces tags for an existing standalone video.
  """

  use Mix.Task

  alias Urielm.Content
  alias Urielm.Content.Video
  alias Urielm.Repo

  @shortdoc "Replaces tags for an existing video"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, args} = OptionParser.parse!(args, strict: [tags: :string])
    start_dependencies!()

    {video_ref, tags_value} = video_ref_and_tags!(args, opts)
    video = fetch_video!(video_ref)
    tag_names = parse_tags(tags_value)

    case Content.replace_video_tags(video.id, tag_names) do
      {:ok, tags} ->
        Mix.shell().info("""
        Updated video tags:
        Title: #{video.title}
        Slug: #{video.slug}
        Tags: #{format_tags(tags)}
        """)

        tags

      {:error, {:tag, reason}} ->
        fail!("Could not tag video:\n#{format_tag_error(reason)}")
    end
  end

  defp video_ref_and_tags!([video_ref, tags_value], _opts), do: {video_ref, tags_value}

  defp video_ref_and_tags!([video_ref], opts) do
    case Keyword.fetch(opts, :tags) do
      {:ok, tags_value} -> {video_ref, tags_value}
      :error -> usage!()
    end
  end

  defp video_ref_and_tags!(_args, _opts), do: usage!()

  defp usage! do
    fail!("Usage: mix videos.tags VIDEO_SLUG_OR_URL TAGS")
  end

  defp fetch_video!(video_ref) do
    case Repo.get_by(Video, slug: video_ref) || Repo.get_by(Video, youtube_url: video_ref) do
      %Video{} = video -> video
      nil -> fail!("Video not found: #{video_ref}")
    end
  end

  defp parse_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp start_dependencies! do
    [:ssl, :postgrex, :ecto_sql]
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

  defp format_tags([]), do: "(none)"
  defp format_tags(tags), do: tags |> Enum.map(& &1.name) |> Enum.join(", ")

  defp format_tag_error(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("\n", fn {field, messages} ->
      "#{field}: #{Enum.join(messages, ", ")}"
    end)
  end

  defp format_tag_error(reason), do: inspect(reason)

  defp fail!(message) do
    Mix.shell().error(message)
    Mix.raise(message)
  end
end
