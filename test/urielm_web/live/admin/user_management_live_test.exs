defmodule UrielmWeb.Admin.UserManagementLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Urielm.Accounts
  alias Urielm.Fixtures

  describe "access control" do
    test "admin can access /admin/users", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, "/admin/users")
      assert html =~ "User Management"
    end

    test "non-admin is redirected to /", %{conn: conn} do
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, user)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/admin/users")
    end

    test "unauthenticated user is redirected", %{conn: conn} do
      assert {:error, {:redirect, _}} = live(conn, "/admin/users")
    end
  end

  describe "page content" do
    test "page title is 'User Management'", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, "/admin/users")
      assert html =~ "User Management"
    end

    test "shows users in the table", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, "/admin/users")
      assert html =~ user.username
    end

    test "manage link present for each user pointing to /admin/users/:id", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/users")
      assert has_element?(view, "a[href='/admin/users/#{user.id}']")
    end
  end

  describe "search" do
    test "filters users by username", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      alice = Fixtures.user_fixture(%{username: "alicexyz", email: "alicexyz@example.com"})
      bob = Fixtures.user_fixture(%{username: "bobxyz", email: "bobxyz@example.com"})
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/users")

      html =
        view |> element("form[phx-change='search']") |> render_change(%{"search" => "alicexyz"})

      assert html =~ alice.username
      refute html =~ bob.username
    end

    test "filters users by email", %{conn: conn} do
      admin = Fixtures.admin_fixture()

      alice =
        Fixtures.user_fixture(%{username: "aliceemail", email: "unique_alice_email@example.com"})

      bob = Fixtures.user_fixture(%{username: "bobemail", email: "unique_bob_email@example.com"})
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/users")

      html =
        view
        |> element("form[phx-change='search']")
        |> render_change(%{"search" => "unique_alice_email"})

      assert html =~ alice.email
      refute html =~ bob.email
    end
  end

  describe "status filter" do
    test "filter_status 'suspended' shows only suspended users", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      suspended_user = Fixtures.user_fixture()
      active_user = Fixtures.user_fixture()
      {:ok, _} = Accounts.suspend_user(suspended_user, admin, reason: "test")

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/users")

      html =
        view
        |> element("form[phx-change='filter_status']")
        |> render_change(%{"status" => "suspended"})

      assert html =~ suspended_user.username
      refute html =~ active_user.username
    end

    test "filter_status 'active' excludes suspended users", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      suspended_user = Fixtures.user_fixture()
      active_user = Fixtures.user_fixture()
      {:ok, _} = Accounts.suspend_user(suspended_user, admin, reason: "test")

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/users")

      html =
        view
        |> element("form[phx-change='filter_status']")
        |> render_change(%{"status" => "active"})

      assert html =~ active_user.username
      refute html =~ suspended_user.username
    end
  end
end
