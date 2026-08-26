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
      {:ok, view, _html} = live(log_in_user(conn, user), "/notifications")

      assert has_element?(view, "#notifications-page")
      assert has_element?(view, "#notifications-header")
      assert has_element?(view, "#notification-filters")
      assert has_element?(view, "#notification-filter-all[aria-current='page']")
      assert has_element?(view, "#notification-filter-unread")
    end
  end

  describe "global navbar" do
    test "includes the dynamically resolved search icon in Tailwind's generated styles" do
      css = File.read!(Path.expand("../../../assets/css/app.css", __DIR__))

      assert css =~ ~s|@source inline("hero-magnifying-glass")|
    end

    test "signed-in users receive the initial unread count in global navigation", %{
      conn: conn,
      user: user,
      thread: thread
    } do
      {:ok, _notification} = Forum.create_notification(user.id, "comment", thread.id)

      {:ok, view, _html} = live(log_in_user(conn, user), "/")

      assert has_element?(
               view,
               ~s([data-name="Navbar"][data-props*='"unreadNotificationCount":1'])
             )

      assert has_element?(
               view,
               "#mobile-bottom-nav[aria-label='Mobile navigation'][data-navigation='mobile-dock']"
             )

      assert has_element?(view, "#mobile-bottom-nav [data-navigation-item]")
      assert has_element?(view, "#mobile-nav-home[aria-current='page']")
      assert has_element?(view, "#mobile-nav-videos[href='/videos']")
      assert has_element?(view, "#mobile-nav-forum[href='/forum']")
      assert has_element?(view, "#mobile-nav-notifications[href='/notifications']")
      assert has_element?(view, "#mobile-nav-notification-badge", "1")
      assert has_element?(view, "#mobile-nav-profile[href='/u/#{user.username}']")
    end

    test "signed-out users receive public mobile navigation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(
               view,
               ~s([data-name="Navbar"][data-props*='"currentUser":null'])
             )

      assert has_element?(view, "#mobile-nav-sign-in[href='/signin']")
      refute has_element?(view, "#mobile-nav-notifications")
      refute has_element?(view, "#mobile-nav-profile")
    end

    test "forum pages keep the shared mobile dock and forum active state", %{
      conn: conn,
      user: user
    } do
      {:ok, view, _html} = live(log_in_user(conn, user), "/forum")

      assert has_element?(view, "#mobile-bottom-nav")
      assert has_element?(view, "#mobile-nav-forum[aria-current='page']")
    end

    test "new notifications push the unread count across the persistent navbar boundary", %{
      conn: conn,
      user: user,
      thread: thread
    } do
      {:ok, view, _html} = live(log_in_user(conn, user), "/")

      {:ok, _notification} = Forum.create_notification(user.id, "comment", thread.id)

      assert_push_event(view, "unread-notification-count", %{count: 1})
    end
  end

  describe "listing notifications" do
    test "shows empty state when no notifications", %{conn: conn, user: user} do
      {:ok, view, _html} = live(log_in_user(conn, user), "/notifications")

      assert has_element?(view, "#notifications-empty-state")
      assert has_element?(view, "#notifications-empty-state a[href='/forum']")
    end

    test "displays notifications for current user", %{conn: conn, user: user, thread: thread} do
      actor = user_fixture()

      {:ok, notif} =
        Forum.create_notification(user.id, "comment", thread.id, %{
          actor_id: actor.id,
          thread_id: thread.id,
          message: "#{actor.username} replied to your thread"
        })

      {:ok, view, _html} = live(log_in_user(conn, user), "/notifications")

      assert has_element?(view, "[data-notification-id='#{notif.id}']", actor.username)
      assert has_element?(view, "[data-notification-id='#{notif.id}']", thread.title)
      assert has_element?(view, "[data-notification-id='#{notif.id}'] [data-unread-indicator]")
      assert has_element?(view, "[data-day-heading='Today']")
      assert has_element?(view, "#notification-read-#{notif.id}")
      assert has_element?(view, "#notification-thread-#{notif.id}[href='/forum/t/#{thread.id}']")
    end

    test "does not show other users' notifications", %{
      conn: conn,
      user: user,
      other: other,
      thread: thread
    } do
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
      refute has_element?(live, "#notification-read-#{notif.id}")
      refute has_element?(live, "[data-notification-id='#{notif.id}'] [data-unread-indicator]")
    end

    test "cannot mark another user's notification as read", %{
      conn: conn,
      user: user,
      other: other,
      thread: thread
    } do
      {:ok, notif} =
        Forum.create_notification(other.id, "comment", thread.id, %{
          actor_id: user.id,
          thread_id: thread.id,
          message: "Private notification"
        })

      {:ok, live, _html} = live(log_in_user(conn, user), "/notifications")
      render_click(live, "mark_as_read", %{"notification_id" => to_string(notif.id)})

      assert Forum.count_unread_notifications(other.id) == 1
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
      assert has_element?(live, "#notifications-mark-all")
      render_click(live, "mark_all_as_read", %{})

      assert Forum.count_unread_notifications(user.id) == 0
      refute has_element?(live, "#notifications-mark-all")
    end

    test "updates unread count in UI after marking all read", %{
      conn: conn,
      user: user,
      thread: thread
    } do
      actor = user_fixture()

      for _ <- 1..2 do
        Forum.create_notification(user.id, "comment", thread.id, %{
          actor_id: actor.id,
          thread_id: thread.id,
          message: "A reply"
        })
      end

      {:ok, live, _html} = live(log_in_user(conn, user), "/notifications")
      render_click(live, "mark_all_as_read", %{})

      assert has_element?(live, "#notifications-summary", "You're all caught up. Nice work.")
      refute has_element?(live, "#mobile-nav-notification-badge")
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

      {:ok, view, _html} = live(log_in_user(conn, user), "/notifications?unread=true")

      assert has_element?(view, "#notification-filter-unread[aria-current='page']")
      assert has_element?(view, "#notifications", "Still unread notification")
      refute has_element?(view, "[data-notification-id='#{notif.id}']")
    end

    test "shows a dedicated empty state for the unread filter", %{conn: conn, user: user} do
      {:ok, view, _html} = live(log_in_user(conn, user), "/notifications?unread=true")

      assert has_element?(view, "#notifications-empty-unread")
      assert has_element?(view, "#notifications-empty-unread a[href='/notifications']")
    end
  end
end
