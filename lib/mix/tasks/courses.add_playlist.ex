defmodule Mix.Tasks.Courses.AddPlaylist do
  @moduledoc """
  Adds a multi-lesson course from a YouTube playlist and ordered video IDs.
  """

  use Mix.Task

  import Ecto.Query, only: [from: 2]

  alias Urielm.Learning
  alias Urielm.Learning.{Course, Lesson}
  alias Urielm.Repo

  @shortdoc "Adds a course from a YouTube playlist and ordered video IDs"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, positional} =
      OptionParser.parse!(args,
        strict: [
          title: :string,
          slug: :string,
          description: :string,
          description_file: :string,
          videos_file: :string
        ]
      )

    validate_opts!(opts)
    {playlist, video_ids} = playlist_and_videos!(positional, opts)
    playlist_id = playlist_id!(playlist)
    video_ids = normalize_video_ids!(video_ids)

    start_dependencies!()
    insert_playlist_course(playlist_id, video_ids, opts)
  end

  defp validate_opts!(opts) do
    if Keyword.has_key?(opts, :description) and Keyword.has_key?(opts, :description_file) do
      fail!("Use either --description or --description-file, not both")
    end
  end

  defp playlist_and_videos!([playlist | video_ids], opts) do
    file_video_ids =
      opts
      |> Keyword.get(:videos_file)
      |> read_video_ids_file()

    {playlist, video_ids ++ file_video_ids}
  end

  defp playlist_and_videos!(_positional, _opts) do
    fail!(
      "Usage: mix courses.add_playlist PLAYLIST_ID_OR_URL VIDEO_ID... [--title TITLE] [--slug SLUG] [--description-file PATH] [--videos-file PATH]"
    )
  end

  defp read_video_ids_file(nil), do: []

  defp read_video_ids_file(path) do
    path
    |> File.read!()
    |> String.split(~r/\R/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
  end

  defp normalize_video_ids!(video_ids) do
    ids =
      video_ids
      |> Enum.map(&youtube_video_id!/1)
      |> Enum.uniq()

    if ids == [] do
      fail!("Provide at least one YouTube video ID")
    end

    ids
  end

  defp insert_playlist_course(playlist_id, video_ids, opts) do
    playlist_metadata = fetch_metadata!(playlist_url(playlist_id))
    video_metadata = Enum.map(video_ids, &{&1, fetch_metadata!(video_url(&1))})

    Repo.transaction(fn ->
      course = get_or_create_course!(playlist_id, playlist_metadata, opts)
      existing_lessons = lessons_by_video_id(video_ids)
      next_lesson_number = next_lesson_number(course.id)

      {lessons, _next_number} =
        Enum.reduce(video_metadata, {[], next_lesson_number}, fn {video_id, metadata},
                                                                 {lessons, lesson_number} ->
          case Map.get(existing_lessons, video_id) do
            %Lesson{course_id: course_id} = lesson when course_id == course.id ->
              {[Repo.preload(lesson, :course) | lessons], lesson_number}

            %Lesson{} = lesson ->
              Repo.rollback(
                "Video #{video_id} already belongs to another course: #{lesson.course_id}"
              )

            nil ->
              lesson = create_lesson!(course, metadata_title!(metadata), video_id, lesson_number)
              {[lesson | lessons], lesson_number + 1}
          end
        end)

      {course, Enum.reverse(lessons)}
    end)
    |> case do
      {:ok, {course, lessons}} ->
        Mix.shell().info("""
        Upserted playlist course:
        Course: #{course.title}
        Lessons: #{length(lessons)}
        URL: /courses/#{course.slug}
        """)

        {course, lessons}

      {:error, %Ecto.Changeset{} = changeset} ->
        fail!("Could not insert playlist course:\n#{format_errors(changeset)}")

      {:error, reason} ->
        fail!("Could not insert playlist course:\n#{inspect(reason)}")
    end
  end

  defp get_or_create_course!(playlist_id, metadata, opts) do
    case Repo.get_by(Course, youtube_playlist_id: playlist_id) do
      %Course{} = course ->
        course

      nil ->
        title = opts[:title] || metadata_title!(metadata)
        slug = resolve_course_slug!(opts[:slug], title, playlist_id)

        attrs = %{
          title: title,
          slug: slug,
          description: description(opts, metadata),
          youtube_playlist_id: playlist_id
        }

        case Learning.create_course(attrs) do
          {:ok, course} -> course
          {:error, reason} -> Repo.rollback(reason)
        end
    end
  end

  defp create_lesson!(course, title, video_id, lesson_number) do
    slug = resolve_lesson_slug!(course.id, slugify(title), video_id)

    attrs = %{
      course_id: course.id,
      title: title,
      slug: slug,
      lesson_number: lesson_number,
      youtube_video_id: video_id,
      notes_md: "",
      resources_md: default_resources(video_url(video_id)),
      timestamps_md: ""
    }

    case Learning.create_lesson(attrs) do
      {:ok, lesson} -> lesson
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp lessons_by_video_id(video_ids) do
    from(l in Lesson, where: l.youtube_video_id in ^video_ids)
    |> Repo.all()
    |> Map.new(&{&1.youtube_video_id, &1})
  end

  defp next_lesson_number(course_id) do
    query = from(l in Lesson, where: l.course_id == ^course_id, select: max(l.lesson_number))
    (Repo.one(query) || 0) + 1
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

  defp default_resources(url), do: "- [Watch on YouTube](#{url})"

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

  defp resolve_course_slug!(custom_slug, _title, _playlist_id) when is_binary(custom_slug) do
    slug = String.trim(custom_slug)

    cond do
      slug == "" -> fail!("Custom slug cannot be blank")
      course_slug_taken?(slug) -> fail!("Course slug already exists: #{slug}")
      true -> slug
    end
  end

  defp resolve_course_slug!(_custom_slug, title, playlist_id) do
    slug = slugify(title)

    cond do
      slug == "" -> fail!("Generated slug was empty")
      course_slug_taken?(slug) -> "#{slug}-#{String.downcase(playlist_id)}"
      true -> slug
    end
  end

  defp resolve_lesson_slug!(course_id, slug, video_id) do
    cond do
      slug == "" -> fail!("Generated lesson slug was empty")
      lesson_slug_taken?(course_id, slug) -> "#{slug}-#{String.downcase(video_id)}"
      true -> slug
    end
  end

  defp course_slug_taken?(slug), do: Learning.get_course_by_slug(slug) != nil

  defp lesson_slug_taken?(course_id, slug) do
    Learning.get_lesson_by_slug(course_id, slug) != nil
  end

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp playlist_id!(playlist) do
    uri = URI.parse(playlist)
    params = URI.decode_query(uri.query || "")

    id =
      cond do
        is_binary(params["list"]) and params["list"] != "" -> params["list"]
        Regex.match?(~r/^[a-zA-Z0-9_-]+$/, playlist) -> playlist
        true -> nil
      end

    if is_binary(id), do: id, else: fail!("Could not extract YouTube playlist ID")
  end

  defp youtube_video_id!(value) do
    uri = URI.parse(value)
    params = URI.decode_query(uri.query || "")
    path_parts = uri.path |> to_string() |> String.split("/", trim: true)

    id =
      cond do
        is_binary(params["v"]) and params["v"] != "" -> params["v"]
        uri.host in ["youtu.be", "www.youtu.be"] and path_parts != [] -> List.first(path_parts)
        Regex.match?(~r/^[a-zA-Z0-9_-]{11}$/, value) -> value
        true -> nil
      end

    if is_binary(id) and Regex.match?(~r/^[a-zA-Z0-9_-]{11}$/, id) do
      id
    else
      fail!("Could not extract YouTube video ID from #{value}")
    end
  end

  defp playlist_url(playlist_id), do: "https://www.youtube.com/playlist?list=#{playlist_id}"

  defp video_url(video_id), do: "https://www.youtube.com/watch?v=#{video_id}"

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
