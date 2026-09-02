defmodule Mix.Tasks.Courses.AddVideoTest do
  use Urielm.DataCase

  import ExUnit.CaptureIO

  alias Mix.Tasks.Courses.AddVideo
  alias Urielm.Learning
  alias Urielm.Learning.{Course, Lesson}
  alias Urielm.Repo

  @url "https://www.youtube.com/watch?v=DJZISqryDfw"

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("courses.add_video")

    Application.put_env(:urielm, :youtube_oembed_fetcher, fn _url ->
      {:ok,
       %{
         "title" => "The Only Codex Course You Need in 2026 (4.5 Hours)",
         "author_name" => "Nick Saraev",
         "author_url" => "https://www.youtube.com/@nicksaraev"
       }}
    end)

    on_exit(fn ->
      Mix.shell(previous_shell)
      Application.delete_env(:urielm, :youtube_oembed_fetcher)
      Mix.Task.reenable("courses.add_video")
    end)
  end

  test "valid URL inserts a one-video course from oEmbed metadata" do
    {course, lesson} = AddVideo.run([@url])

    assert course.title == "The Only Codex Course You Need in 2026 (4.5 Hours)"
    assert course.slug == "the-only-codex-course-you-need-in-2026-4-5-hours"
    assert course.description == "A video course by Nick Saraev."

    assert lesson.course_id == course.id
    assert lesson.title == course.title
    assert lesson.slug == course.slug
    assert lesson.lesson_number == 1
    assert lesson.youtube_video_id == "DJZISqryDfw"
    assert lesson.resources_md == "- [Watch on YouTube](#{@url})"

    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Inserted course video:"
    assert message =~ "/courses/#{course.slug}/lessons/#{lesson.slug}"
  end

  test "--title and --slug override generated course and lesson fields" do
    {course, lesson} =
      AddVideo.run([
        @url,
        "--title",
        "Custom Course",
        "--slug",
        "custom-course",
        "--lesson-title",
        "Custom Lesson",
        "--lesson-slug",
        "custom-lesson"
      ])

    assert course.title == "Custom Course"
    assert course.slug == "custom-course"
    assert lesson.title == "Custom Lesson"
    assert lesson.slug == "custom-lesson"
  end

  test "markdown fields can be loaded from files" do
    description_path = temp_file("Description from file")
    notes_path = temp_file("Notes from file")
    resources_path = temp_file("- [Resource](https://example.com)")
    timestamps_path = temp_file("00:00 Intro")

    {course, lesson} =
      AddVideo.run([
        @url,
        "--description-file",
        description_path,
        "--notes-file",
        notes_path,
        "--resources-file",
        resources_path,
        "--timestamps-file",
        timestamps_path
      ])

    assert course.description == "Description from file"
    assert lesson.notes_md == "Notes from file"
    assert lesson.resources_md == "- [Resource](https://example.com)"
    assert lesson.timestamps_md == "00:00 Intro"
  end

  test "existing YouTube video id is idempotent" do
    {course, lesson} = AddVideo.run([@url])
    flush_shell_messages()

    {existing_course, existing_lesson} = AddVideo.run(["https://youtu.be/DJZISqryDfw"])

    assert existing_course.id == course.id
    assert existing_lesson.id == lesson.id
    assert Repo.aggregate(Course, :count) == 1
    assert Repo.aggregate(Lesson, :count) == 1

    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Already exists:"
  end

  test "duplicate generated course slug appends video id" do
    {:ok, _course} =
      Learning.create_course(%{
        title: "The Only Codex Course You Need in 2026 (4.5 Hours)",
        slug: "the-only-codex-course-you-need-in-2026-4-5-hours"
      })

    {course, _lesson} = AddVideo.run([@url])

    assert course.slug == "the-only-codex-course-you-need-in-2026-4-5-hours-djzisqrydfw"
  end

  test "custom slug collision fails" do
    {:ok, _course} = Learning.create_course(%{title: "Existing", slug: "existing"})

    assert_raise Mix.Error, "Course slug already exists: existing", fn ->
      AddVideo.run([@url, "--slug", "existing"])
    end
  end

  test "invalid YouTube URL raises a clear error" do
    assert_raise Mix.Error, "Could not extract YouTube video ID from URL", fn ->
      AddVideo.run(["https://example.com/not-youtube"])
    end
  end

  test "missing URL prints usage and raises" do
    assert_raise Mix.Error, fn ->
      capture_io(:stderr, fn -> AddVideo.run([]) end)
    end

    assert_received {:mix_shell, :error, [message]}
    assert message =~ "Usage: mix courses.add_video YOUTUBE_URL"
  end

  defp temp_file(content) do
    path = Path.join(System.tmp_dir!(), "course-video-#{System.unique_integer()}.md")
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
