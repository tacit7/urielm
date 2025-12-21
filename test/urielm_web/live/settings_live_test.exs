defmodule UrielmWeb.SettingsLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias Urielm.Fixtures

  describe "settings page access control" do
    test "anonymous users are redirected to signup", %{conn: conn} do
      # Attempt to access settings without being logged in
      assert {:error, {:redirect, %{to: "/signup"}}} = live(conn, "/settings")
    end

    test "authenticated users can access settings page", %{conn: conn} do
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, html} = live(conn, "/settings")

      # Verify page loaded with expected content
      assert html =~ "Settings"
      assert has_element?(view, "form")
    end

    test "settings page displays user email information", %{conn: conn} do
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, "/settings")

      # Verify user email is displayed (name may be nil)
      assert html =~ user.email
    end
  end
end
