defmodule Urielm.Content.VideoTest do
  use Urielm.DataCase
  import Urielm.Fixtures
  import Ecto.Query

  alias Urielm.Content
  alias Urielm.Content.Tag
  alias Urielm.Content.Video
  alias Urielm.Content.VideoTag
  alias Urielm.Repo

  describe "videos" do
    @valid_attrs %{
      title: "Test Video",
      slug: "test-video",
      youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      description_md: "# Test Description",
      visibility: "public"
    }

    @invalid_attrs %{title: nil, slug: nil, youtube_url: nil}

    test "create_video/1 with valid data creates a video" do
      assert {:ok, %Video{} = video} = Content.create_video(@valid_attrs)
      assert video.title == "Test Video"
      assert video.slug == "test-video"
      assert video.visibility == "public"
    end

    test "create_video/2 atomically creates a video with normalized tags" do
      assert {:ok, %Video{} = video} =
               Content.create_video(@valid_attrs, tag_names: ["AI Workflows", "ai workflows"])

      assert Enum.map(video.tag_records, & &1.slug) == ["ai-workflows"]

      invalid_attrs = %{@valid_attrs | slug: "invalid-tags"}
      assert {:error, :blank_tag} = Content.create_video(invalid_attrs, tag_names: ["!!!"])
      assert Repo.get_by(Video, slug: "invalid-tags") == nil
    end

    test "create_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_video(@invalid_attrs)
    end

    test "create_video/1 validates slug format" do
      invalid_slug = %{@valid_attrs | slug: "Bad Slug!"}
      assert {:error, changeset} = Content.create_video(invalid_slug)

      assert "must contain only lowercase letters, numbers, and hyphens" in errors_on(changeset).slug
    end

    test "create_video/1 validates youtube_url is valid URL" do
      invalid_url = %{@valid_attrs | youtube_url: "not-a-url"}
      assert {:error, changeset} = Content.create_video(invalid_url)
      assert "must be a valid URL" in errors_on(changeset).youtube_url
    end

    test "create_video/1 validates visibility inclusion" do
      invalid_visibility = %{@valid_attrs | visibility: "premium"}
      assert {:error, changeset} = Content.create_video(invalid_visibility)
      assert "is invalid" in errors_on(changeset).visibility
    end

    test "create_video/1 enforces unique slug" do
      {:ok, _video1} = Content.create_video(@valid_attrs)
      assert {:error, changeset} = Content.create_video(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).slug
    end

    test "get_video_by_slug!/1 returns the video with given slug" do
      {:ok, video} = Content.create_video(@valid_attrs)
      assert fetched = Content.get_video_by_slug!("test-video")
      assert fetched.id == video.id
    end

    test "get_video_by_slug!/1 raises when video not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Content.get_video_by_slug!("nonexistent")
      end
    end

    test "list_published_videos/0 returns only published videos" do
      published_attrs = Map.put(@valid_attrs, :published_at, DateTime.utc_now())
      unpublished_attrs = Map.merge(@valid_attrs, %{slug: "unpublished", published_at: nil})

      {:ok, published} = Content.create_video(published_attrs)
      {:ok, _unpublished} = Content.create_video(unpublished_attrs)

      videos = Content.list_published_videos()
      assert length(videos) == 1
      assert hd(videos).id == published.id
    end

    test "list_published_videos/1 filters by tag ids and treats empty tag ids as unfiltered" do
      {:ok, tag} = Content.find_or_create_tag("AI")
      tagged = video_fixture(%{published_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      other = video_fixture(%{published_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      {:ok, _video_tag} = Content.tag_video(tagged.id, tag.id)

      filtered = Content.list_published_videos(tag_ids: [tag.id])
      unfiltered = Content.list_published_videos(tag_ids: [])

      assert Enum.map(filtered, & &1.id) == [tagged.id]
      assert Enum.any?(unfiltered, &(&1.id == tagged.id))
      assert Enum.any?(unfiltered, &(&1.id == other.id))
    end

    test "list_published_videos/1 combines query, format, and tag filters and preloads tags" do
      {:ok, ai} = Content.find_or_create_tag("AI Workflows")

      matching =
        video_fixture(%{
          title: "Reliable automations",
          format: "standard",
          published_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      wrong_format =
        video_fixture(%{
          title: "Reliable short",
          format: "short",
          published_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, _} = Content.tag_video(matching.id, ai.id)
      {:ok, _} = Content.tag_video(wrong_format.id, ai.id)

      [result] =
        Content.list_published_videos(query: "automation", format: "standard", tag_ids: [ai.id])

      assert result.id == matching.id
      assert Ecto.assoc_loaded?(result.tag_records)
      assert Enum.map(result.tag_records, & &1.slug) == ["ai-workflows"]
    end

    test "list_published_videos/1 searches associated tag names" do
      video =
        video_fixture(%{
          title: "A practical walkthrough",
          published_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, tag} = Content.find_or_create_tag("Agent Systems")
      {:ok, _} = Content.tag_video(video.id, tag.id)

      assert Enum.map(Content.list_published_videos(query: "agent systems"), & &1.id) == [
               video.id
             ]
    end

    test "video_published?/1 returns true for published videos" do
      attrs = Map.put(@valid_attrs, :published_at, DateTime.utc_now())
      {:ok, video} = Content.create_video(attrs)
      assert Content.video_published?(video) == true
    end

    test "video_published?/1 returns false for unpublished videos" do
      attrs = Map.put(@valid_attrs, :published_at, nil)
      {:ok, video} = Content.create_video(attrs)
      assert Content.video_published?(video) == false
    end
  end

  describe "video tags" do
    test "find_or_create_tag/1 normalizes and reuses tag slugs" do
      assert {:ok, %Tag{} = tag} = Content.find_or_create_tag("AI")
      assert tag.slug == "ai"
      assert {:ok, same_tag} = Content.find_or_create_tag("A.I.")

      assert same_tag.id == tag.id
      assert Repo.aggregate(Tag, :count) == 1
    end

    test "tag_video/2 attaches tags and list_video_tags/1 returns ordered names" do
      video = video_fixture()
      {:ok, zed} = Content.find_or_create_tag("Zed")
      {:ok, alpha} = Content.find_or_create_tag("Alpha")

      assert {:ok, %VideoTag{}} = Content.tag_video(video.id, zed.id)
      assert {:ok, %VideoTag{}} = Content.tag_video(video.id, alpha.id)

      assert Enum.map(Content.list_video_tags(video.id), & &1.name) == ["Alpha", "Zed"]
    end

    test "untag_video/2 removes a tag or returns not_found" do
      video = video_fixture()
      {:ok, tag} = Content.find_or_create_tag("AI")
      {:ok, _video_tag} = Content.tag_video(video.id, tag.id)

      assert {:ok, %VideoTag{}} = Content.untag_video(video.id, tag.id)
      assert Content.list_video_tags(video.id) == []
      assert Content.untag_video(video.id, tag.id) == {:error, :not_found}
    end

    test "video tag changeset validates required fields and constraints" do
      changeset = VideoTag.changeset(%VideoTag{}, %{})
      assert "can't be blank" in errors_on(changeset).video_id
      assert "can't be blank" in errors_on(changeset).tag_id

      assert {:error, fk_changeset} =
               %VideoTag{}
               |> VideoTag.changeset(%{
                 video_id: Ecto.UUID.generate(),
                 tag_id: -1
               })
               |> Repo.insert()

      assert "does not exist" in errors_on(fk_changeset).video_id
    end

    test "tag_video/2 surfaces duplicate video tag as a changeset error" do
      video = video_fixture()
      {:ok, tag} = Content.find_or_create_tag("AI")
      assert {:ok, _video_tag} = Content.tag_video(video.id, tag.id)

      assert {:error, changeset} = Content.tag_video(video.id, tag.id)
      assert "has already been taken" in errors_on(changeset).video_id
    end

    test "set_video_tags/2 replaces tags, deduplicates normalized names, and can clear them" do
      video = video_fixture()
      {:ok, old_tag} = Content.find_or_create_tag("Old")
      {:ok, _} = Content.tag_video(video.id, old_tag.id)

      assert {:ok, tagged_video} =
               Content.set_video_tags(video, ["AI Workflows", "ai workflows", "Agents"])

      assert Ecto.assoc_loaded?(tagged_video.tag_records)
      assert Enum.map(tagged_video.tag_records, & &1.slug) == ["agents", "ai-workflows"]

      assert {:ok, cleared_video} = Content.set_video_tags(video, [])
      assert cleared_video.tag_records == []
    end

    test "list_content_tags/0 returns only tags used by published videos" do
      published = video_fixture(%{published_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      unpublished = video_fixture(%{published_at: nil})
      {:ok, visible} = Content.find_or_create_tag("Visible")
      {:ok, draft_only} = Content.find_or_create_tag("Draft only")
      {:ok, unused} = Content.find_or_create_tag("Unused")
      {:ok, _} = Content.tag_video(published.id, visible.id)
      {:ok, _} = Content.tag_video(unpublished.id, draft_only.id)

      assert Enum.map(Content.list_content_tags(), & &1.id) == [visible.id]
      refute unused.id in Enum.map(Content.list_content_tags(), & &1.id)
    end

    test "tag records expose the reverse videos association" do
      video = video_fixture()
      {:ok, tag} = Content.find_or_create_tag("AI")
      {:ok, _} = Content.tag_video(video.id, tag.id)

      tag = Repo.preload(tag, :videos)
      assert Enum.map(tag.videos, & &1.id) == [video.id]
    end

    test "video lookup functions return loaded tags" do
      video = video_fixture()
      {:ok, tag} = Content.find_or_create_tag("AI")
      {:ok, _} = Content.tag_video(video.id, tag.id)

      assert [%Tag{id: tag_id}] = Content.get_video(video.id).tag_records
      assert tag_id == tag.id
      assert Ecto.assoc_loaded?(Content.get_video_by_slug!(video.slug).tag_records)
      assert Ecto.assoc_loaded?(Content.get_video_by_short_id(video.short_id).tag_records)
    end
  end

  describe "video authorization" do
    setup do
      public_video = video_fixture(%{visibility: "public"})
      signed_in_video = video_fixture(%{visibility: "signed_in"})
      subscriber_video = video_fixture(%{visibility: "subscriber"})

      %{
        public_video: public_video,
        signed_in_video: signed_in_video,
        subscriber_video: subscriber_video
      }
    end

    test "can_view_video?/2 allows anyone to view public videos", %{public_video: video} do
      user = user_fixture()
      assert Content.can_view_video?(nil, video) == true
      assert Content.can_view_video?(user, video) == true
    end

    test "can_view_video?/2 blocks anonymous users from signed_in videos", %{
      signed_in_video: video
    } do
      assert Content.can_view_video?(nil, video) == false
    end

    test "can_view_video?/2 allows signed-in users to view signed_in videos", %{
      signed_in_video: video
    } do
      user = user_fixture()
      assert Content.can_view_video?(user, video) == true
    end

    test "can_view_video?/2 blocks non-subscribers from subscriber videos", %{
      subscriber_video: video
    } do
      user = user_fixture()
      assert Content.can_view_video?(user, video) == false
    end

    test "can_view_video?/2 allows admins to view all videos", %{
      public_video: pub,
      signed_in_video: signed,
      subscriber_video: sub
    } do
      admin = admin_fixture()
      assert Content.can_view_video?(admin, pub) == true
      assert Content.can_view_video?(admin, signed) == true
      assert Content.can_view_video?(admin, sub) == true
    end
  end

  describe "video completion tracking" do
    setup do
      user = user_fixture()
      video = video_fixture()
      %{video: video, user: user}
    end

    test "completed_video?/2 returns false for uncompleted video", %{video: video, user: user} do
      assert Content.completed_video?(user, video) == false
    end

    test "mark_video_complete/2 creates completion record", %{video: video, user: user} do
      assert {:ok, completion} = Content.mark_video_complete(user, video)
      assert completion.user_id == user.id
      assert completion.video_id == video.id
      assert completion.completed_at != nil
    end

    test "completed_video?/2 returns true after marking complete", %{video: video, user: user} do
      {:ok, _} = Content.mark_video_complete(user, video)
      assert Content.completed_video?(user, video) == true
    end

    test "mark_video_complete/2 upserts on duplicate", %{video: video, user: user} do
      {:ok, _completion1} = Content.mark_video_complete(user, video)

      # Sleep > 1 second to ensure timestamp changes
      Process.sleep(1100)
      {:ok, _completion2} = Content.mark_video_complete(user, video)

      # Should not create duplicate - verify only one completion exists
      assert Content.completed_video?(user, video) == true

      # Verify no duplicate by counting
      count =
        Repo.aggregate(
          from(vc in Urielm.Content.VideoCompletion,
            where: vc.user_id == ^user.id and vc.video_id == ^video.id
          ),
          :count
        )

      assert count == 1
    end

    test "unmark_video_complete/2 removes completion", %{video: video, user: user} do
      {:ok, _} = Content.mark_video_complete(user, video)
      assert Content.completed_video?(user, video) == true

      {:ok, count} = Content.unmark_video_complete(user, video)
      assert count == 1
      assert Content.completed_video?(user, video) == false
    end

    test "completed_video?/2 returns false for nil user", %{video: video} do
      assert Content.completed_video?(nil, video) == false
    end
  end
end
