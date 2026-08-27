defmodule UrielmWeb.Admin.UserDetailLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Urielm.Accounts
  alias Urielm.Fixtures
  alias Urielm.Repo

  describe "access control" do
    test "admin can access /admin/users/:id and sees user info", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, "/admin/users/#{user.id}")

      assert has_element?(view, "#admin-user-detail-page.ui-page-shell")
      assert has_element?(view, "#admin-user-detail-header.ui-page-header")
      assert has_element?(view, "#admin-nav-users[aria-current='page']")
      assert has_element?(view, "#admin-user-overview.ui-card", user.username)
      assert has_element?(view, "#admin-user-overview", user.email)
      assert has_element?(view, "#admin-user-trust-control.ui-card", "TL#{user.trust_level}")
      assert has_element?(view, "#admin-user-role-control.ui-card")
      assert has_element?(view, "#admin-user-suspension-control.ui-card")
      assert has_element?(view, "#admin-user-silence-control.ui-card")
    end

    test "non-admin is redirected to /", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/admin/users/#{admin.id}")
    end

    test "unknown user id redirects to /admin/users", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      conn = log_in_user(conn, admin)

      assert {:error, {:redirect, %{to: "/admin/users"}}} = live(conn, "/admin/users/0")
    end
  end

  describe "user status badges" do
    test "shows Suspended badge when user is suspended", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      {:ok, user} = Accounts.suspend_user(user, admin, reason: "test suspension")
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, "/admin/users/#{user.id}")

      assert html =~ "Suspended"
    end

    test "shows Silenced badge when user is silenced", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      {:ok, user} = Accounts.silence_user(user, admin, reason: "test silence")
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, "/admin/users/#{user.id}")

      assert html =~ "Silenced"
    end
  end

  describe "moderator role" do
    test "grant_mod grants moderator role", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, "/admin/users/#{user.id}")

      view |> element("button[phx-click='grant_mod']") |> render_click()

      updated = Repo.reload(user)
      assert updated.is_moderator == true
    end

    test "revoke_mod revokes moderator role", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      {:ok, user} = Accounts.grant_moderator(user, admin)
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, "/admin/users/#{user.id}")

      view |> element("button[phx-click='revoke_mod']") |> render_click()

      updated = Repo.reload(user)
      assert updated.is_moderator == false
    end
  end

  describe "suspension" do
    test "shows Remove Suspension button when user is already suspended", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      {:ok, user} = Accounts.suspend_user(user, admin, reason: "spam")
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, "/admin/users/#{user.id}")

      assert html =~ "Remove Suspension"
    end

    test "unsuspend removes suspension", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      {:ok, user} = Accounts.suspend_user(user, admin, reason: "spam")
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, "/admin/users/#{user.id}")

      view |> element("button[phx-click='unsuspend']") |> render_click()

      updated = Repo.reload(user)
      assert updated.suspended_at == nil
      assert updated.suspended_reason == nil
    end

    test "suspend action: show form, fill reason, confirm suspends user", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, "/admin/users/#{user.id}")

      view
      |> element("button[phx-click='show_action'][phx-value-action='suspend']")
      |> render_click()

      assert has_element?(view, "#admin-suspend-form")

      view
      |> element("button[phx-click='set_duration'][phx-value-duration='7d']")
      |> render_click()

      view
      |> element("textarea[phx-keyup='set_reason']")
      |> render_keyup(%{"reason" => "Spam"})

      view |> element("button[phx-click='suspend']") |> render_click()

      updated = Repo.reload(user)
      assert updated.suspended_at != nil
      assert updated.suspended_reason == "Spam"
    end

    test "suspend without reason shows error flash", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, "/admin/users/#{user.id}")

      view
      |> element("button[phx-click='show_action'][phx-value-action='suspend']")
      |> render_click()

      html = view |> element("button[phx-click='suspend']") |> render_click()

      assert html =~ "Reason is required"

      updated = Repo.reload(user)
      assert updated.suspended_at == nil
    end
  end

  describe "silencing" do
    test "shows Remove Silence button when user is silenced", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      {:ok, user} = Accounts.silence_user(user, admin, reason: "spam")
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, "/admin/users/#{user.id}")

      assert html =~ "Remove Silence"
    end

    test "unsilence removes silence", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      {:ok, user} = Accounts.silence_user(user, admin, reason: "spam")
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, "/admin/users/#{user.id}")

      view |> element("button[phx-click='unsilence']") |> render_click()

      updated = Repo.reload(user)
      assert updated.silenced_at == nil
      assert updated.silenced_reason == nil
    end
  end

  describe "trust level" do
    test "set_trust_level changes trust level", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, "/admin/users/#{user.id}")

      view
      |> element("button[phx-click='set_trust_level'][phx-value-trust_level='3']")
      |> render_click()

      updated = Repo.reload(user)
      assert updated.trust_level == 3
    end
  end
end
