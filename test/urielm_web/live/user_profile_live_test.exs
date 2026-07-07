defmodule UrielmWeb.UserProfileLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Accounts

  setup do
    owner = user_fixture()
    visitor = user_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{board_id: board.id, author_id: owner.id})

    %{owner: owner, visitor: visitor, thread: thread}
  end

  # ShellLive uses live_render with id "page-user_profile" for the child LiveView.
  defp profile_child(live), do: find_live_child(live, "page-user_profile")

  describe "viewing a profile" do
    test "anonymous user can view public profile", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(conn, "/u/#{owner.username}")
      html = render(profile_child(live))
      assert html =~ owner.display_name
      assert html =~ owner.username
    end

    test "shows thread count in stats", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(conn, "/u/#{owner.username}")
      html = render(profile_child(live))
      assert html =~ "1"
    end

    test "shows follower and following counts", %{conn: conn, owner: owner, visitor: visitor} do
      Accounts.follow_user(visitor.id, owner.id)

      {:ok, live, _html} = live(conn, "/u/#{owner.username}")
      html = render(profile_child(live))
      assert html =~ "1"
    end

    test "redirects to home for non-existent username", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/u/no_such_user_xyz123")
    end
  end

  describe "viewing own profile" do
    test "shows username on own profile", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(log_in_user(conn, owner), "/u/#{owner.username}")
      html = render(profile_child(live))
      assert html =~ owner.username
    end
  end

  describe "follow/unfollow" do
    test "follow button is not shown on own profile", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(log_in_user(conn, owner), "/u/#{owner.username}")
      html = render(profile_child(live))
      refute html =~ "toggle_follow"
    end

    test "visitor can follow a user", %{conn: conn, visitor: visitor, owner: owner} do
      {:ok, live, _html} = live(log_in_user(conn, visitor), "/u/#{owner.username}")

      render_click(profile_child(live), "toggle_follow", %{})

      assert Accounts.following?(visitor.id, owner.id)
    end

    test "visitor can unfollow a user they already follow", %{
      conn: conn,
      visitor: visitor,
      owner: owner
    } do
      Accounts.follow_user(visitor.id, owner.id)

      {:ok, live, _html} = live(log_in_user(conn, visitor), "/u/#{owner.username}")

      render_click(profile_child(live), "toggle_follow", %{})

      refute Accounts.following?(visitor.id, owner.id)
    end

    test "anonymous user cannot follow", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(conn, "/u/#{owner.username}")

      render_click(profile_child(live), "toggle_follow", %{})

      assert Accounts.count_followers(owner.id) == 0
    end
  end

  describe "tab switching" do
    test "threads tab shows user's threads", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(conn, "/u/#{owner.username}")
      child = profile_child(live)

      html = render_click(child, "switch_tab", %{"tab" => "threads"})
      assert html =~ owner.display_name
    end

    test "comments tab switches view", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(conn, "/u/#{owner.username}")
      child = profile_child(live)

      html = render_click(child, "switch_tab", %{"tab" => "comments"})
      assert html =~ owner.display_name
    end
  end

  describe "admin moderation actions" do
    test "admin sees suspend option on other user's profile", %{conn: conn, owner: owner} do
      admin = admin_fixture()
      {:ok, live, _html} = live(log_in_user(conn, admin), "/u/#{owner.username}")
      html = render(profile_child(live))
      assert html =~ "suspend" or html =~ "Suspend"
    end

    test "regular user does not see suspend option", %{conn: conn, visitor: visitor, owner: owner} do
      {:ok, live, _html} = live(log_in_user(conn, visitor), "/u/#{owner.username}")
      html = render(profile_child(live))
      refute html =~ "show_suspend_modal"
    end
  end

  describe "mount tab params" do
    test "defaults to threads tab when no tab param", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(conn, "/u/#{owner.username}")
      html = render(profile_child(live))
      assert html =~ "phx-value-tab=\"threads\""
      assert html =~ "phx-value-tab=\"comments\""
    end

    test "mounts with threads tab active when ?tab=threads", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(conn, "/u/#{owner.username}?tab=threads")
      html = render(profile_child(live))
      assert html =~ owner.username
      assert html =~ "Threads"
    end

    test "mounts with comments tab active when ?tab=comments", %{conn: conn, owner: owner} do
      {:ok, live, _html} = live(conn, "/u/#{owner.username}?tab=comments")
      html = render(profile_child(live))
      assert html =~ owner.username
      assert html =~ "Comments"
    end

    test "mounts with saved tab when ?tab=saved and user is logged in", %{
      conn: conn,
      owner: owner
    } do
      {:ok, live, _html} = live(log_in_user(conn, owner), "/u/#{owner.username}?tab=saved")
      html = render(profile_child(live))
      assert html =~ owner.username
    end

    test "unknown username redirects to home regardless of tab param", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/u/no_such_user_abc999?tab=threads")
    end
  end
end
