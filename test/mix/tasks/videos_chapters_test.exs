defmodule Mix.Tasks.Videos.ChaptersTest do
  use Urielm.DataCase

  import ExUnit.CaptureIO
  import Urielm.Fixtures

  alias Mix.Tasks.Videos.Chapters

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("videos.chapters")

    on_exit(fn ->
      Mix.shell(previous_shell)
      Mix.Task.reenable("videos.chapters")
    end)
  end

  test "updates description with linked chapters from a file" do
    video = video_fixture(%{youtube_url: "https://www.youtube.com/watch?v=WAFUMBLOjHo"})
    path = chapter_file("00:00 Intro\n00:26 Herdr + Firstmate\n01:37:55 It works!\n")

    updated = Chapters.run([video.slug, "--file", path])

    assert updated.description_md =~ "## Chapters"

    assert updated.description_md =~ "- [00:00:00 Intro](#t=0s)"

    assert updated.description_md =~ "- [00:00:26 Herdr + Firstmate](#t=26s)"

    assert updated.description_md =~ "- [01:37:55 It works!](#t=5875s)"

    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Updated video chapters:"
    assert message =~ "Chapters: 3"
  end

  test "uses local timestamp links" do
    video = video_fixture(%{youtube_url: "https://youtu.be/WAFUMBLOjHo"})
    path = chapter_file("00:00 Intro\n")

    updated = Chapters.run([video.slug, "--file", path])

    assert updated.description_md =~ "#t=0s"
  end

  test "accepts chapter text on stdin" do
    video = video_fixture(%{youtube_url: "https://www.youtube.com/watch?v=WAFUMBLOjHo"})

    updated =
      capture_io("00:00 Intro\n00:10 Next\n", fn ->
        Chapters.run([video.slug])
      end)

    assert updated.description_md =~ "00:00:10 Next"
  end

  test "rejects descending timestamps" do
    video = video_fixture()
    path = chapter_file("00:10 Later\n00:05 Earlier\n")

    assert_raise Mix.Error, "Chapter timestamps must be in ascending order", fn ->
      Chapters.run([video.slug, "--file", path])
    end
  end

  test "rejects invalid chapter lines" do
    video = video_fixture()
    path = chapter_file("Intro without timestamp\n")

    assert_raise Mix.Error, "Invalid chapter line: Intro without timestamp", fn ->
      Chapters.run([video.slug, "--file", path])
    end
  end

  test "missing video raises a clear error" do
    path = chapter_file("00:00 Intro\n")

    assert_raise Mix.Error, "Video not found: missing", fn ->
      Chapters.run(["missing", "--file", path])
    end
  end

  test "missing slug with no stdin content prints usage" do
    assert_raise Mix.Error, fn -> capture_io(:stderr, fn -> Chapters.run([]) end) end
    assert_received {:mix_shell, :error, [message]}
    assert message =~ "Usage: mix videos.chapters VIDEO_SLUG"
  end

  defp chapter_file(content) do
    path = Path.join(System.tmp_dir!(), "video-chapters-#{System.unique_integer()}.txt")
    File.write!(path, content)
    path
  end
end
