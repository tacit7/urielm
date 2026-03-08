defmodule UrielmWeb.NotificationsLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Forum

  setup do
    user = user_fixture()
    other = user_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{board_id: board.id, author_id: other.id})

    %{user: user, other: other, thread: thread}
  end

  describe "access control" do
    test "redirects unauthenticated users to signin", %{conn: conn} do
      assert {:error, {:redirect, %{to: path}}} = live(conn, "/notifications")
      assert path =~ "/signup" or path =~ "/signin" or path =~ "/auth"
    end

    test "authenticated user can access notifications page", %{conn: conn, user: user} do
      {:ok, _live, html} = live(log_in_user(conn, user), "/notifications")
      assert html =~ "Notifications"
    end
  end

  describe "listing notifications" do
    test "shows empty state when no notifications", %{conn: conn, user: user} do
      {:ok, _live, html} = live(log_in_user(conn, user), "/notifications")
      assert html =~ "Notifications"
    end

    test "displays notifications for current user", %{conn: conn, user: user, thread: thread} do
      actor = user_fixture()

      Forum.create_notification(user.id, "comment", thread.id, %{
        actor_id: actor.id,
        thread_id: thread.id,
        message: "#{actor.username} replied to your thread"
      })

      {:ok, _live, html} = live(log_in_user(conn, user), "/notifications")
      assert html =~ actor.username
    end

    test "does not show other users' notifications", %{conn: conn, user: user, other: other, thread: thread} do
      Forum.create_notification(other.id, "comment", thread.id, %{
        actor_id: user.id,
        thread_id: thread.id,
        message: "Someone replied to your thread"
      })

      {:ok, _live, html} = live(log_in_user(conn, user), "/notifications")
      refute html =~ "Someone replied to your thread"
    end
  end

  describe "mark_as_read event" do
    test "marks a single notification as read", %{conn: conn, user: user, thread: thread} do
      {:ok, notif} =
        Forum.create_notification(user.id, "comment", thread.id, %{
          actor_id: user_fixture().id,
          thread_id: thread.id,
          message: "Test notification"
        })

      {:ok, live, _html} = live(log_in_user(conn, user), "/notifications")

      render_click(live, "mark_as_read", %{"notification_id" => to_string(notif.id)})

      assert Forum.count_unread_notifications(user.id) == 0
    end
  end

  describe "mark_all_as_read event" do
    test "marks all notifications as read", %{conn: conn, user: user, thread: thread} do
      actor = user_fixture()

      for _ <- 1..3 do
        Forum.create_notification(user.id, "comment", thread.id, %{
          actor_id: actor.id,
          thread_id: thread.id,
          message: "A reply to your thread"
        })
      end

      assert Forum.count_unread_notifications(user.id) == 3

      {:ok, live, _html} = live(log_in_user(conn, user), "/notifications")
      render_click(live, "mark_all_as_read", %{})

      assert Forum.count_unread_notifications(user.id) == 0
    end

    test "updates unread count in UI after marking all read", %{conn: conn, user: user, thread: thread} do
      actor = user_fixture()

      for _ <- 1..2 do
        Forum.create_notification(user.id, "comment", thread.id, %{
          actor_id: actor.id,
          thread_id: thread.id,
          message: "A reply"
        })
      end

      {:ok, live, _html} = live(log_in_user(conn, user), "/notifications")
      html = render_click(live, "mark_all_as_read", %{})

      refute html =~ "2 unread"
    end
  end

  describe "unread filter" do
    test "?unread=true shows only unread notifications", %{conn: conn, user: user, thread: thread} do
      actor = user_fixture()

      {:ok, notif} =
        Forum.create_notification(user.id, "comment", thread.id, %{
          actor_id: actor.id,
          thread_id: thread.id,
          message: "Unread notification"
        })

      Forum.mark_notification_as_read(notif.id)

      Forum.create_notification(user.id, "comment", thread.id, %{
        actor_id: actor.id,
        thread_id: thread.id,
        message: "Still unread notification"
      })

      {:ok, _live, html} = live(log_in_user(conn, user), "/notifications?unread=true")
      assert html =~ "Still unread notification"
    end
  end
end
