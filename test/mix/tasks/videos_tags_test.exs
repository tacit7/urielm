defmodule Mix.Tasks.Videos.TagsTest do
  use Urielm.DataCase

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

  test "replaces tags for a video by slug" do
    video = Urielm.Fixtures.video_fixture(%{slug: "existing-video"})
    {:ok, old_tag} = Content.find_or_create_tag("Old")
    {:ok, _video_tag} = Content.tag_video(video.id, old_tag.id)

    tags = Tags.run(["existing-video", "AI, Tutorial"])

    assert Enum.map(tags, & &1.slug) == ["ai", "tutorial"]
    assert Enum.map(Content.list_video_tags(video.id), & &1.slug) == ["ai", "tutorial"]
  end

  test "replaces tags for a video by URL with --tags" do
    video = Urielm.Fixtures.video_fixture(%{youtube_url: "https://youtu.be/abcDEF12345"})

    tags = Tags.run(["https://youtu.be/abcDEF12345", "--tags", "Beginner"])

    assert Enum.map(tags, & &1.slug) == ["beginner"]
    assert Enum.map(Content.list_video_tags(video.id), & &1.slug) == ["beginner"]
  end

  test "empty tags clear existing tags" do
    video = Urielm.Fixtures.video_fixture(%{slug: "tagged-video"})
    {:ok, old_tag} = Content.find_or_create_tag("Old")
    {:ok, _video_tag} = Content.tag_video(video.id, old_tag.id)

    assert [] = Tags.run(["tagged-video", " , "])
    assert Content.list_video_tags(video.id) == []
  end
end
