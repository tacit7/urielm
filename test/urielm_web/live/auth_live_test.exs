defmodule UrielmWeb.AuthLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Urielm.Fixtures

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

  describe "secondary account flow" do
    test "email signup uses the shared authentication panel and form controls", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/signup/email")

      assert has_element?(view, "#auth-page.ui-auth-page")
      assert has_element?(view, "#signup-email-card.ui-auth-panel")
      assert has_element?(view, "#signup-email-form")
      assert has_element?(view, "#signup-email-address")
      assert has_element?(view, "#signup-email-password")
      assert has_element?(view, "#signup-email-submit[phx-disable-with='Creating account…']")
      assert has_element?(view, "#signup-options-link[href='/signup']")
    end

    test "email signup keeps form-level errors in the shared feedback component", %{conn: conn} do
      existing_user = user_fixture()
      {:ok, view, _html} = live(conn, ~p"/signup/email")

      view
      |> form("#signup-email-form", %{
        "email" => existing_user.email,
        "password" => "password123"
      })
      |> render_submit()

      assert has_element?(view, "#signup-email-error[role='alert']")
    end

    test "email verification exposes consistent status and actions", %{conn: conn} do
      user = user_fixture() |> set_email_unverified()
      {:ok, view, _html} = live(log_in_user(conn, user), ~p"/signup/verify-email")

      assert has_element?(view, "#verify-email-card.ui-auth-panel")
      assert has_element?(view, "#resend-verification-button")
      assert has_element?(view, "#continue-browsing-link[href='/']")

      view |> element("#resend-verification-button") |> render_click()
      assert has_element?(view, "#resend-verification-button[disabled]")
    end

    test "handle setup uses shared fields and availability feedback", %{conn: conn} do
      {:ok, user} =
        Urielm.Accounts.register_user_email_only(%{
          email: "handle-#{System.unique_integer([:positive])}@example.com",
          password: "password123"
        })

      {:ok, view, _html} = live(log_in_user(conn, user), ~p"/signup/set-handle")

      assert has_element?(view, "#set-handle-card.ui-auth-panel")
      assert has_element?(view, "#set-handle-form")
      assert has_element?(view, "#handle-username")
      assert has_element?(view, "#handle-display-name")
      assert has_element?(view, "#handle-availability[role='status']")
      assert has_element?(view, "#set-handle-submit")
    end

    test "handle setup preserves unavailable-name feedback", %{conn: conn} do
      existing_user = user_fixture()

      {:ok, onboarding_user} =
        Urielm.Accounts.register_user_email_only(%{
          email: "onboarding-#{System.unique_integer([:positive])}@example.com",
          password: "password123"
        })

      {:ok, view, _html} = live(log_in_user(conn, onboarding_user), ~p"/signup/set-handle")

      view
      |> form("#set-handle-form", %{
        "username" => existing_user.username,
        "display_name" => "Onboarding user"
      })
      |> render_change()

      assert has_element?(view, "#handle-availability[role='status']", "already taken")
      assert has_element?(view, "#set-handle-submit[disabled]")
    end

    test "suspension page uses the shared authentication panel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/suspended")

      assert has_element?(view, "#auth-page.ui-auth-page")
      assert has_element?(view, "#suspended-card.ui-auth-panel")
      assert has_element?(view, "#suspended-card a[href='/']")
    end
  end

  defp set_email_unverified(user) do
    user
    |> Ecto.Changeset.change(email_verified: false)
    |> Urielm.Repo.update!()
  end
end
