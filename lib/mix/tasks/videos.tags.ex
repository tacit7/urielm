defmodule Mix.Tasks.Videos.Tags do
  @moduledoc """
  Replaces every tag on a video identified by slug.
  """

  use Mix.Task

  alias Urielm.Content
  alias Urielm.Repo

  @shortdoc "Replaces all tags on a video"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, slugs, invalid} = OptionParser.parse(args, strict: [tags: :string])

    with [slug] <- slugs,
         [] <- invalid,
         true <- Keyword.has_key?(opts, :tags) do
      start_dependencies!()
      replace_tags!(slug, Keyword.fetch!(opts, :tags))
    else
      _invalid -> fail!(usage())
    end
  end

  defp replace_tags!(slug, tags_value) do
    case Content.get_video_by_slug(slug) do
      nil ->
        fail!("Video not found: #{slug}")

      video ->
        case Content.set_video_tags(video, parse_tags(tags_value)) do
          {:ok, tagged_video} ->
            names = Enum.map_join(tagged_video.tag_records, ", ", & &1.name)
            summary = if names == "", do: "No tags", else: names

            Mix.shell().info("""
            Updated video tags:
            Slug: #{tagged_video.slug}
            Tags: #{summary}
            """)

            tagged_video

          {:error, reason} ->
            fail!("Could not update video tags: #{format_error(reason)}")
        end
    end
  end

  defp parse_tags(tags) do
    tags
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
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

  defp format_error(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> inspect()
  end

  defp format_error(reason), do: inspect(reason)

  defp usage, do: ~s(Usage: mix videos.tags VIDEO_SLUG --tags "Agents, Career")

  defp fail!(message) do
    Mix.shell().error(message)
    Mix.raise(message)
  end
end
