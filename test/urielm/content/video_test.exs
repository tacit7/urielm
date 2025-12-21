defmodule Urielm.Content.VideoTest do
  use Urielm.DataCase
  import Urielm.Fixtures
  import Ecto.Query

  alias Urielm.Content
  alias Urielm.Content.Video
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

    test "can_view_video?/2 blocks anonymous users from signed_in videos", %{signed_in_video: video} do
      assert Content.can_view_video?(nil, video) == false
    end

    test "can_view_video?/2 allows signed-in users to view signed_in videos", %{signed_in_video: video} do
      user = user_fixture()
      assert Content.can_view_video?(user, video) == true
    end

    test "can_view_video?/2 blocks non-subscribers from subscriber videos", %{subscriber_video: video} do
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

      Process.sleep(1100)  # Sleep > 1 second to ensure timestamp changes
      {:ok, _completion2} = Content.mark_video_complete(user, video)

      # Should not create duplicate - verify only one completion exists
      assert Content.completed_video?(user, video) == true

      # Verify no duplicate by counting
      count = Repo.aggregate(
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
