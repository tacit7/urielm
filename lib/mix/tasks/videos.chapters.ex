defmodule Mix.Tasks.Videos.Chapters do
  @moduledoc """
  Replaces a video's overview with linked YouTube chapters.
  """

  use Mix.Task

  alias Urielm.Content
  alias Urielm.Repo

  @shortdoc "Updates a video's chapter list"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} =
      OptionParser.parse(args,
        strict: [
          file: :string,
          title: :string
        ]
      )

    with [video_slug] <- argv,
         [] <- invalid do
      start_dependencies!()
      update_chapters!(video_slug, chapter_text!(opts), Keyword.get(opts, :title, "Chapters"))
    else
      _invalid -> fail!(usage())
    end
  end

  defp chapter_text!(opts) do
    case Keyword.get(opts, :file) do
      nil -> IO.read(:stdio, :eof)
      path -> File.read!(path)
    end
  end

  defp update_chapters!(video_slug, chapter_text, title) do
    case Content.get_video_by_slug(video_slug) do
      nil ->
        fail!("Video not found: #{video_slug}")

      %{youtube_url: nil} ->
        fail!("Video has no YouTube URL: #{video_slug}")

      %{youtube_url: ""} ->
        fail!("Video has no YouTube URL: #{video_slug}")

      video ->
        chapters = parse_chapters!(chapter_text)
        markdown = render_markdown(title, video.youtube_url, chapters)

        case Content.update_video(video, %{description_md: markdown}) do
          {:ok, updated} ->
            Mix.shell().info("""
            Updated video chapters:
            Slug: #{updated.slug}
            Chapters: #{length(chapters)}
            """)

            updated

          {:error, %Ecto.Changeset{} = changeset} ->
            fail!("Could not update video chapters:\n#{format_errors(changeset)}")
        end
    end
  end

  defp parse_chapters!(chapter_text) do
    chapters =
      chapter_text
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&parse_chapter!/1)

    cond do
      chapters == [] ->
        fail!("No chapters found")

      not ascending?(chapters) ->
        fail!("Chapter timestamps must be in ascending order")

      true ->
        chapters
    end
  end

  defp parse_chapter!(line) do
    case Regex.run(~r/^(\d{1,2}:\d{2}(?::\d{2})?)\s+(.+)$/, line) do
      [_, timestamp, label] ->
        %{timestamp: normalize_timestamp(timestamp), seconds: seconds!(timestamp), label: label}

      _match ->
        fail!("Invalid chapter line: #{line}")
    end
  end

  defp normalize_timestamp(timestamp) do
    parts = String.split(timestamp, ":")

    case parts do
      [minutes, seconds] -> "00:#{pad2(minutes)}:#{seconds}"
      [hours, minutes, seconds] -> "#{pad2(hours)}:#{minutes}:#{seconds}"
    end
  end

  defp seconds!(timestamp) do
    parts =
      timestamp
      |> String.split(":")
      |> Enum.map(&String.to_integer/1)

    valid? =
      case parts do
        [_minutes, seconds] -> seconds < 60
        [_hours, minutes, seconds] -> minutes < 60 and seconds < 60
      end

    if valid? do
      case parts do
        [minutes, seconds] -> minutes * 60 + seconds
        [hours, minutes, seconds] -> hours * 3600 + minutes * 60 + seconds
      end
    else
      fail!("Invalid timestamp: #{timestamp}")
    end
  end

  defp ascending?(chapters) do
    seconds = Enum.map(chapters, & &1.seconds)
    seconds == Enum.sort(seconds)
  end

  defp render_markdown(title, _youtube_url, chapters) do
    lines =
      Enum.map(chapters, fn chapter ->
        "- [#{chapter.timestamp} #{chapter.label}](#t=#{chapter.seconds}s)"
      end)

    "## #{title}\n\n#{Enum.join(lines, "\n")}\n"
  end

  defp pad2(value), do: value |> String.pad_leading(2, "0")

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

  defp usage, do: "Usage: mix videos.chapters VIDEO_SLUG [--file chapters.txt]"

  defp fail!(message) do
    Mix.shell().error(message)
    Mix.raise(message)
  end
end
