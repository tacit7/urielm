defmodule UrielmWeb.AuthLiveTest do
  use UrielmWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "sign in" do
    test "renders the polished authentication shell and form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/signin")

      assert has_element?(view, "#auth-header")
      assert has_element?(view, "#auth-page")
      assert has_element?(view, "#auth-story")
      assert has_element?(view, "#signin-card")
      assert has_element?(view, "#google-signin-link[href='/auth/google']")
      assert has_element?(view, "#google-oauth-disclosure", "name")
      assert has_element?(view, "#google-oauth-disclosure", "email")
      assert has_element?(view, "#google-oauth-disclosure", "profile image")
      assert has_element?(view, "#google-oauth-disclosure a[href='/privacy']", "Privacy Policy")
      assert has_element?(view, "#google-oauth-disclosure a[href='/terms']", "Terms of Use")
      assert has_element?(view, "#signin-form")
      assert has_element?(view, "#signin-email")
      assert has_element?(view, "#signin-password")
      assert has_element?(view, "#signin-submit[phx-disable-with='Signing in…']")
    end

    test "shows error and loading states", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/signin")

      render_hook(view, "signin_error", %{"error" => "Check your email and password."})
      assert has_element?(view, "#signin-error[role='alert']", "Check your email and password.")

      view
      |> form("#signin-form", %{"email" => "person@example.com", "password" => "secret123"})
      |> render_submit()

      assert has_element?(view, "#signin-submit[disabled]", "Sign in")
    end
  end

  describe "sign up" do
    test "renders the complete account creation form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/signup")

      assert has_element?(view, "#auth-header")
      assert has_element?(view, "#signup-card")
      assert has_element?(view, "#google-signup-link[href='/auth/google']")
      assert has_element?(view, "#signup-form")
      assert has_element?(view, "#signup-username")
      assert has_element?(view, "#signup-display-name")
      assert has_element?(view, "#signup-email")
      assert has_element?(view, "#signup-password")
      assert has_element?(view, "#signup-submit[phx-disable-with='Creating account…']")
    end

    test "shows error and loading states", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/signup")

      render_hook(view, "signup_error", %{"error" => "That username is already taken."})
      assert has_element?(view, "#signup-error[role='alert']", "That username is already taken.")

      view
      |> form("#signup-form", %{
        "username" => "builder",
        "displayName" => "Builder",
        "email" => "builder@example.com",
        "password" => "secret123"
      })
      |> render_submit()

      assert has_element?(view, "#signup-submit[disabled]", "Create account")
    end
  end
end
