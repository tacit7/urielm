defmodule UrielmWeb.VideoLiveTest do
  use UrielmWeb.ConnCase
  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  describe "VideoLive" do
    setup do
      public_video =
        video_fixture(%{
          visibility: "public",
          published_at: DateTime.utc_now(),
          author_name: "Uriel Maldonado",
          author_url: "https://urielm.dev",
          author_bio_md: "Building practical tools with AI.",
          resources_md: "- [Starter prompt](https://example.com/prompt)"
        })

      signed_in_video =
        video_fixture(%{
          visibility: "signed_in",
          published_at: DateTime.utc_now()
        })

      subscriber_video =
        video_fixture(%{
          visibility: "subscriber",
          published_at: DateTime.utc_now()
        })

      %{
        public_video: public_video,
        signed_in_video: signed_in_video,
        subscriber_video: subscriber_video
      }
    end

    test "public video renders for anonymous user", %{conn: conn, public_video: video} do
      {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")

      assert html =~ video.title
      assert html =~ "YouTubePlayer"
    end

    test "public video shows description section", %{conn: conn, public_video: video} do
      {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")

      assert html =~ "Description"
      assert html =~ "Test description"
    end

    test "standard video uses the theater-first detail layout", %{
      conn: conn,
      public_video: video
    } do
      {:ok, view, _html} = live(conn, ~p"/videos/#{video.slug}")

      assert has_element?(view, "#standard-video-page")
      assert has_element?(view, "#video-back-link[href='/videos']")
      assert has_element?(view, "#video-player-shell")
      assert has_element?(view, "#video-detail-header")
      assert has_element?(view, "#video-share-button[data-text]")
      assert has_element?(view, "#video-detail-tabs[aria-label='Video details']")
      assert has_element?(view, "#video-tab-description[aria-current='page']")
      assert has_element?(view, "#video-creator-card")
      assert has_element?(view, "#video-resources-card")
      refute has_element?(view, "#standard-video-page .dock")
    end

    test "authenticated viewer gets the completion control", %{public_video: video} do
      user = user_fixture()
      conn = log_in_user(build_conn(), user)

      {:ok, view, _html} = live(conn, ~p"/videos/#{video.slug}")

      assert has_element?(view, "#video-completion-control")
    end

    test "shows the next accessible standard video", %{conn: conn, public_video: video} do
      next_video =
        video_fixture(%{
          title: "Test prompts before trusting them",
          visibility: "public",
          format: "standard",
          published_at: DateTime.utc_now() |> DateTime.add(60, :second)
        })

      video_fixture(%{
        visibility: "signed_in",
        format: "standard",
        published_at: DateTime.utc_now() |> DateTime.add(120, :second)
      })

      {:ok, view, _html} = live(conn, ~p"/videos/#{video.slug}")

      assert has_element?(view, "#video-next-card-#{next_video.id}")
    end

    test "signed_in video redirects anonymous user", %{conn: conn, signed_in_video: video} do
      assert {:error, {:redirect, %{to: "/signin"}}} = live(conn, ~p"/videos/#{video.slug}")
    end

    test "signed_in video renders for authenticated user", %{signed_in_video: video} do
      user = user_fixture()
      conn = log_in_user(build_conn(), user)

      {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")
      assert html =~ video.title
    end

    test "subscriber video blocks non-subscriber", %{subscriber_video: video} do
      user = user_fixture()
      conn = log_in_user(build_conn(), user)

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/videos/#{video.slug}")
    end

    test "subscriber video renders for subscriber", %{subscriber_video: video} do
      user = user_fixture()
      future_date = DateTime.add(DateTime.utc_now(), 30, :day) |> DateTime.truncate(:second)
      subscription_fixture(user, %{status: "active", current_period_end: future_date})

      conn = log_in_user(build_conn(), user)

      {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")
      assert html =~ video.title
    end

    test "admin can view all videos regardless of visibility", %{
      public_video: pub,
      signed_in_video: signed,
      subscriber_video: sub
    } do
      admin = admin_fixture()
      conn = log_in_user(build_conn(), admin)

      for video <- [pub, signed, sub] do
        {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")
        assert html =~ video.title
      end
    end

    test "unpublished video blocks non-admin users", %{conn: conn} do
      video = video_fixture(%{published_at: nil})

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/videos/#{video.slug}")
    end

    test "unpublished video renders for admin", %{} do
      video = video_fixture(%{published_at: nil})
      admin = admin_fixture()
      conn = log_in_user(build_conn(), admin)

      {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")
      assert html =~ video.title
    end

    test "nonexistent video returns 404", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/videos/nonexistent-slug")
    end

    test "video with thread shows comments section", %{conn: conn} do
      user = user_fixture()
      board = board_fixture()
      thread = thread_fixture(%{board_id: board.id, author_id: user.id, kind: "video"})

      video =
        video_fixture(%{
          published_at: DateTime.utc_now(),
          thread_id: thread.id
        })

      {:ok, view, _html} = live(conn, ~p"/videos/#{video.slug}")
      child = find_live_child(view, "page-video")

      assert has_element?(view, "#video-tab-comments", "Comments")

      child
      |> element("#video-tab-comments")
      |> render_click()

      assert has_element?(child, "#video-comments-section")
      assert render(child) =~ "CommentTree"
    end

    @tag :skip
    test "authenticated user can post comment", %{} do
      # TODO: This test is skipped because VideoLive is now a child of ShellLive.
      # Events go to ShellLive parent, not VideoLive child.
      # Need to either test through ShellLive or test comment posting at integration level.

      user = user_fixture()
      board = board_fixture()
      thread = thread_fixture(%{board_id: board.id, author_id: user.id, kind: "video"})

      video =
        video_fixture(%{
          published_at: DateTime.utc_now(),
          thread_id: thread.id
        })

      conn = log_in_user(build_conn(), user)
      {:ok, view, _html} = live(conn, ~p"/videos/#{video.slug}")

      view
      |> form("form[phx-submit='create_comment']", %{body: "Test comment"})
      |> render_submit()

      assert render(view) =~ "Test comment"
    end
  end
end
