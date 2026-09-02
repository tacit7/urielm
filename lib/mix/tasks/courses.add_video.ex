defmodule Mix.Tasks.Courses.AddVideo do
  @moduledoc """
  Adds a one-video course from public YouTube oEmbed metadata.
  """

  use Mix.Task

  import Ecto.Query, only: [from: 2]

  alias Urielm.Learning
  alias Urielm.Learning.Lesson
  alias Urielm.Repo

  @shortdoc "Adds a one-video course from a YouTube URL"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, urls} =
      OptionParser.parse!(args,
        strict: [
          title: :string,
          slug: :string,
          description: :string,
          description_file: :string,
          lesson_title: :string,
          lesson_slug: :string,
          notes: :string,
          notes_file: :string,
          resources: :string,
          resources_file: :string,
          timestamps: :string,
          timestamps_file: :string
        ]
      )

    validate_opts!(opts)
    url = one_url!(urls)
    video_id = youtube_id!(url)

    start_dependencies!()

    case existing_lesson(video_id) do
      %Lesson{} = lesson ->
        lesson = Repo.preload(lesson, :course)

        Mix.shell().info("""
        Already exists:
        Course: #{lesson.course.title}
        Lesson: #{lesson.title}
        URL: #{lesson_path(lesson.course, lesson)}
        """)

        {lesson.course, lesson}

      nil ->
        insert_course_and_lesson(url, video_id, opts)
    end
  end

  defp validate_opts!(opts) do
    cond do
      Keyword.has_key?(opts, :description) and Keyword.has_key?(opts, :description_file) ->
        fail!("Use either --description or --description-file, not both")

      Keyword.has_key?(opts, :notes) and Keyword.has_key?(opts, :notes_file) ->
        fail!("Use either --notes or --notes-file, not both")

      Keyword.has_key?(opts, :resources) and Keyword.has_key?(opts, :resources_file) ->
        fail!("Use either --resources or --resources-file, not both")

      Keyword.has_key?(opts, :timestamps) and Keyword.has_key?(opts, :timestamps_file) ->
        fail!("Use either --timestamps or --timestamps-file, not both")

      true ->
        :ok
    end
  end

  defp insert_course_and_lesson(url, video_id, opts) do
    metadata = fetch_metadata!(url)
    title = opts[:title] || metadata_title!(metadata)
    slug = resolve_course_slug!(opts[:slug], title, video_id)
    lesson_title = opts[:lesson_title] || title
    lesson_slug = opts[:lesson_slug] || slug

    Repo.transaction(fn ->
      course =
        case Learning.create_course(%{
               title: title,
               slug: slug,
               description: description(opts, metadata)
             }) do
          {:ok, course} -> course
          {:error, reason} -> Repo.rollback(reason)
        end

      lesson =
        case Learning.create_lesson(%{
               course_id: course.id,
               title: lesson_title,
               slug: lesson_slug,
               lesson_number: 1,
               youtube_video_id: video_id,
               notes_md: markdown_opt(opts, :notes, :notes_file, ""),
               resources_md:
                 markdown_opt(opts, :resources, :resources_file, default_resources(url)),
               timestamps_md: markdown_opt(opts, :timestamps, :timestamps_file, "")
             }) do
          {:ok, lesson} -> lesson
          {:error, reason} -> Repo.rollback(reason)
        end

      {course, lesson}
    end)
    |> case do
      {:ok, {course, lesson}} ->
        Mix.shell().info("""
        Inserted course video:
        Course: #{course.title}
        Lesson: #{lesson.title}
        URL: #{lesson_path(course, lesson)}
        """)

        {course, lesson}

      {:error, %Ecto.Changeset{} = changeset} ->
        fail!("Could not insert course video:\n#{format_errors(changeset)}")

      {:error, reason} ->
        fail!("Could not insert course video:\n#{inspect(reason)}")
    end
  end

  defp description(opts, metadata) do
    cond do
      Keyword.has_key?(opts, :description) ->
        Keyword.fetch!(opts, :description)

      path = Keyword.get(opts, :description_file) ->
        File.read!(path)

      author = metadata["author_name"] ->
        "A video course by #{author}."

      true ->
        ""
    end
  end

  defp markdown_opt(opts, value_key, file_key, default) do
    cond do
      Keyword.has_key?(opts, value_key) -> Keyword.fetch!(opts, value_key)
      path = Keyword.get(opts, file_key) -> File.read!(path)
      true -> default
    end
  end

  defp default_resources(url), do: "- [Watch on YouTube](#{url})"

  defp existing_lesson(video_id) do
    Repo.one(from(l in Lesson, where: l.youtube_video_id == ^video_id, limit: 1))
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

  defp one_url!([url]), do: url

  defp one_url!(_urls) do
    fail!(
      "Usage: mix courses.add_video YOUTUBE_URL [--title TITLE] [--slug SLUG] [--description-file PATH] [--notes-file PATH] [--resources-file PATH] [--timestamps-file PATH]"
    )
  end

  defp resolve_course_slug!(custom_slug, _title, _video_id) when is_binary(custom_slug) do
    slug = String.trim(custom_slug)

    cond do
      slug == "" ->
        fail!("Custom slug cannot be blank")

      course_slug_taken?(slug) ->
        fail!("Course slug already exists: #{slug}")

      true ->
        slug
    end
  end

  defp resolve_course_slug!(_custom_slug, title, video_id) do
    slug = slugify(title)

    cond do
      slug == "" -> fail!("Generated slug was empty")
      course_slug_taken?(slug) -> "#{slug}-#{String.downcase(video_id)}"
      true -> slug
    end
  end

  defp course_slug_taken?(slug), do: Learning.get_course_by_slug(slug) != nil

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp youtube_id!(url) do
    uri = URI.parse(url)
    params = URI.decode_query(uri.query || "")
    path_parts = uri.path |> to_string() |> String.split("/", trim: true)

    id =
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

    if is_binary(id) and Regex.match?(~r/^[a-zA-Z0-9_-]{11}$/, id) do
      id
    else
      fail!("Could not extract YouTube video ID from URL")
    end
  end

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

  defp lesson_path(course, lesson), do: "/courses/#{course.slug}/lessons/#{lesson.slug}"

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
