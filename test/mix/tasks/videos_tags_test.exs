defmodule Mix.Tasks.Videos.TagsTest do
  use Urielm.DataCase

  import ExUnit.CaptureIO
  import Urielm.Fixtures

  alias Mix.Tasks.Videos.Tags
  alias Urielm.Content

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("videos.tags")

    on_exit(fn ->
      Mix.shell(previous_shell)
      Mix.Task.reenable("videos.tags")
    end)
  end

  test "replaces and normalizes all video tags" do
    video = video_fixture()
    assert {:ok, _video} = Content.set_video_tags(video, ["Old"])

    updated = Tags.run([video.slug, "--tags", "Agents, Career, agents"])

    assert Enum.map(updated.tag_records, & &1.slug) == ["agents", "career"]
    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Updated video tags:"
    assert message =~ "Tags: Agents, Career"
  end

  test "an empty tags value clears all tags" do
    video = video_fixture()
    assert {:ok, _video} = Content.set_video_tags(video, ["Agents"])

    updated = Tags.run([video.slug, "--tags", ""])

    assert updated.tag_records == []
    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Tags: No tags"
  end

  test "missing video raises a clear error" do
    assert_raise Mix.Error, "Video not found: missing", fn ->
      Tags.run(["missing", "--tags", "Agents"])
    end

    assert_received {:mix_shell, :error, ["Video not found: missing"]}
  end

  test "missing slug or tags option prints usage" do
    assert_raise Mix.Error, fn -> capture_io(:stderr, fn -> Tags.run([]) end) end
    assert_received {:mix_shell, :error, [message]}
    assert message =~ "Usage: mix videos.tags VIDEO_SLUG"

    Mix.Task.reenable("videos.tags")
    assert_raise Mix.Error, fn -> Tags.run(["some-video"]) end
    assert_received {:mix_shell, :error, [message]}
    assert message =~ "Usage: mix videos.tags VIDEO_SLUG"
  end

  test "invalid normalized tag leaves existing tags unchanged" do
    video = video_fixture()
    assert {:ok, _video} = Content.set_video_tags(video, ["Agents"])

    assert_raise Mix.Error, fn -> Tags.run([video.slug, "--tags", "!!!"]) end

    assert Enum.map(Content.list_video_tags(video.id), & &1.slug) == ["agents"]
    assert_received {:mix_shell, :error, ["Could not update video tags: :blank_tag"]}
  end
end
