defmodule Mix.Tasks.Videos.UpdateTest do
  use Urielm.DataCase

  import ExUnit.CaptureIO
  import Urielm.Fixtures

  alias Mix.Tasks.Videos.Update
  alias Urielm.Content

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("videos.update")

    on_exit(fn ->
      Mix.shell(previous_shell)
      Mix.Task.reenable("videos.update")
    end)
  end

  test "updates basic video fields by slug" do
    video = video_fixture()

    updated =
      Update.run([
        video.slug,
        "--title",
        "Updated Title",
        "--visibility",
        "signed_in",
        "--format",
        "short",
        "--description",
        "Updated overview"
      ])

    assert updated.title == "Updated Title"
    assert updated.visibility == "signed_in"
    assert updated.format == "short"
    assert updated.description_md == "Updated overview"

    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Updated video:"
    assert message =~ "/videos/#{video.slug}"
  end

  test "updates markdown fields from files" do
    video = video_fixture()
    tmp_dir = System.tmp_dir!()
    description_path = Path.join(tmp_dir, "video-description-#{System.unique_integer()}.md")
    resources_path = Path.join(tmp_dir, "video-resources-#{System.unique_integer()}.md")

    File.write!(description_path, "Description from file")
    File.write!(resources_path, "- [Resource](https://example.com)")

    updated =
      Update.run([
        video.slug,
        "--description-file",
        description_path,
        "--resources-file",
        resources_path
      ])

    assert updated.description_md == "Description from file"
    assert updated.resources_md == "- [Resource](https://example.com)"
  end

  test "publish and unpublish update published_at" do
    draft = video_fixture(%{published_at: nil})

    published = Update.run([draft.slug, "--publish"])
    assert published.published_at

    unpublished = Update.run([draft.slug, "--unpublish"])
    assert unpublished.published_at == nil
  end

  test "renames a video slug" do
    video = video_fixture()

    updated = Update.run([video.slug, "--slug", "renamed-video"])

    assert updated.slug == "renamed-video"
    assert Content.get_video_by_slug(video.slug) == nil
    assert Content.get_video_by_slug("renamed-video")
  end

  test "missing video raises a clear error" do
    assert_raise Mix.Error, "Video not found: missing", fn ->
      Update.run(["missing", "--title", "Nope"])
    end

    assert_received {:mix_shell, :error, ["Video not found: missing"]}
  end

  test "invalid options fail before update" do
    video = video_fixture()

    assert_raise Mix.Error, "Invalid visibility: premium", fn ->
      Update.run([video.slug, "--visibility", "premium"])
    end

    assert_raise Mix.Error, "Use either --publish or --unpublish, not both", fn ->
      Update.run([video.slug, "--publish", "--unpublish"])
    end
  end

  test "missing update options prints usage" do
    assert_raise Mix.Error, fn -> capture_io(:stderr, fn -> Update.run([]) end) end
    assert_received {:mix_shell, :error, [message]}
    assert message =~ "Usage: mix videos.update VIDEO_SLUG"
  end
end
