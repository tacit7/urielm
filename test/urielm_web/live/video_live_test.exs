defmodule UrielmWeb.VideoLiveTest do
  use UrielmWeb.ConnCase
  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Content

  describe "VideoLive" do
    setup do
      public_video = video_fixture(%{
        visibility: "public",
        published_at: DateTime.utc_now()
      })

      signed_in_video = video_fixture(%{
        visibility: "signed_in",
        published_at: DateTime.utc_now()
      })

      subscriber_video = video_fixture(%{
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
      assert html =~ "YouTubeEmbed"
    end

    test "public video shows description section", %{conn: conn, public_video: video} do
      {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")

      assert html =~ "Description"
      assert html =~ "Test Description"
    end

    test "signed_in video redirects anonymous user", %{conn: conn, signed_in_video: video} do
      {:ok, _view, _html} = live(conn, ~p"/videos/#{video.slug}")
      assert_redirected(conn, ~p"/signin")
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

      {:ok, _view, _html} = live(conn, ~p"/videos/#{video.slug}")
      assert_redirected(conn, ~p"/")
    end

    test "subscriber video renders for subscriber", %{subscriber_video: video} do
      user = user_fixture()
      future_date = DateTime.add(DateTime.utc_now(), 30, :day)
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

      {:ok, _view, _html} = live(conn, ~p"/videos/#{video.slug}")
      assert_redirected(conn, ~p"/")
    end

    test "unpublished video renders for admin", %{} do
      video = video_fixture(%{published_at: nil})
      admin = admin_fixture()
      conn = log_in_user(build_conn(), admin)

      {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")
      assert html =~ video.title
    end

    test "nonexistent video returns 404", %{conn: conn} do
      {:ok, _view, _html} = live(conn, ~p"/videos/nonexistent-slug")
      assert_redirected(conn, ~p"/")
    end

    test "video with thread shows comments section", %{conn: conn} do
      user = user_fixture()
      board = board_fixture()
      thread = thread_fixture(%{board_id: board.id, author_id: user.id, kind: "video"})
      video = video_fixture(%{
        published_at: DateTime.utc_now(),
        thread_id: thread.id
      })

      {:ok, _view, html} = live(conn, ~p"/videos/#{video.slug}")

      assert html =~ "Comments"
      assert html =~ "CommentTree"
    end

    test "authenticated user can post comment", %{} do
      user = user_fixture()
      board = board_fixture()
      thread = thread_fixture(%{board_id: board.id, author_id: user.id, kind: "video"})
      video = video_fixture(%{
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

  defp log_in_user(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session(:user_id, user.id)
  end
end
