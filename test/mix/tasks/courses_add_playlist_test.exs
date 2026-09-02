defmodule Mix.Tasks.Courses.AddPlaylistTest do
  use Urielm.DataCase

  alias Mix.Tasks.Courses.AddPlaylist
  alias Urielm.Learning
  alias Urielm.Learning.{Course, Lesson}
  alias Urielm.Repo

  @playlist_id "PLcGFJNFn5qEB1Va8whwT5VGGQvggDBJ4U"
  @video_ids ["uv0p9dpLH2I", "f3TO_dm5Agc", "hoBKAH7ePBs"]

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("courses.add_playlist")

    Application.put_env(:urielm, :youtube_oembed_fetcher, fn url ->
      cond do
        String.contains?(url, "playlist?list=") ->
          {:ok,
           %{
             "title" => "OpenAI Codex Full Course: AI Coding Agent Tutorial with Python Examples",
             "author_name" => "Artem Istranin"
           }}

        video_id = video_id_from_url(url) ->
          {:ok, %{"title" => "Lesson #{Enum.find_index(@video_ids, &(&1 == video_id)) + 1}"}}

        true ->
          {:error, "unknown URL"}
      end
    end)

    on_exit(fn ->
      Mix.shell(previous_shell)
      Application.delete_env(:urielm, :youtube_oembed_fetcher)
      Mix.Task.reenable("courses.add_playlist")
    end)
  end

  test "creates one course with lessons in the provided order" do
    {course, lessons} = AddPlaylist.run([@playlist_id | @video_ids])

    assert course.title ==
             "OpenAI Codex Full Course: AI Coding Agent Tutorial with Python Examples"

    assert course.youtube_playlist_id == @playlist_id
    assert course.description == "A video course by Artem Istranin."
    assert length(lessons) == 3

    persisted_lessons = Learning.list_lessons(course.id)
    assert Enum.map(persisted_lessons, & &1.youtube_video_id) == @video_ids
    assert Enum.map(persisted_lessons, & &1.lesson_number) == [1, 2, 3]
    assert Repo.aggregate(Course, :count) == 1

    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Upserted playlist course:"
    assert message =~ "Lessons: 3"
  end

  test "re-running the playlist is idempotent by video id" do
    {course, lessons} = AddPlaylist.run([@playlist_id | @video_ids])
    flush_shell_messages()

    {same_course, same_lessons} = AddPlaylist.run([@playlist_id | @video_ids])

    assert same_course.id == course.id
    assert Enum.map(same_lessons, & &1.id) == Enum.map(lessons, & &1.id)
    assert Repo.aggregate(Course, :count) == 1
    assert Repo.aggregate(Lesson, :count) == 3
  end

  test "existing playlist course receives only missing videos" do
    {:ok, course} =
      Learning.create_course(%{
        title: "Existing Playlist",
        slug: "existing-playlist",
        youtube_playlist_id: @playlist_id
      })

    {:ok, lesson} =
      Learning.create_lesson(%{
        course_id: course.id,
        title: "Existing Lesson",
        slug: "existing-lesson",
        lesson_number: 1,
        youtube_video_id: List.first(@video_ids)
      })

    {_course, lessons} = AddPlaylist.run([@playlist_id | @video_ids])

    assert List.first(lessons).id == lesson.id
    assert Learning.list_lessons(course.id) |> Enum.map(& &1.youtube_video_id) == @video_ids
    assert Repo.aggregate(Course, :count) == 1
    assert Repo.aggregate(Lesson, :count) == 3
  end

  test "--videos-file appends video IDs from a file" do
    path = temp_file(Enum.join(@video_ids, "\n"))

    {course, _lessons} = AddPlaylist.run([@playlist_id, "--videos-file", path])

    assert Learning.list_lessons(course.id) |> Enum.map(& &1.youtube_video_id) == @video_ids
  end

  test "invalid playlist input raises a clear error" do
    assert_raise Mix.Error, "Could not extract YouTube playlist ID", fn ->
      AddPlaylist.run(["https://example.com/playlist", "uv0p9dpLH2I"])
    end
  end

  defp video_id_from_url(url) do
    uri = URI.parse(url)
    URI.decode_query(uri.query || "")["v"]
  end

  defp temp_file(content) do
    path = Path.join(System.tmp_dir!(), "course-playlist-#{System.unique_integer()}.txt")
    File.write!(path, content)
    path
  end

  defp flush_shell_messages do
    receive do
      {:mix_shell, _level, _message} -> flush_shell_messages()
    after
      0 -> :ok
    end
  end
end
