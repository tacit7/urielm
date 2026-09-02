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
      assert has_element?(view, "#settings-page.ui-page-shell")
      assert has_element?(view, "#settings-header.ui-page-header")
      assert has_element?(view, "#profile-settings-section.ui-card")
      assert has_element?(view, "#capability-badges-settings-section.ui-card")
      assert has_element?(view, "#password-settings-section.ui-card")
      assert has_element?(view, "#appearance-settings-section.ui-card")
      assert has_element?(view, "#danger-settings-section.ui-card")
      assert has_element?(view, "#profile-settings-form")
      assert has_element?(view, "#profile-private-profile[type='checkbox']")
      assert has_element?(view, "#profile-settings-submit[phx-disable-with='Saving profile…']")
      assert has_element?(view, "#password-settings-form")
      assert has_element?(view, "#capability-badges-settings-form")
      assert has_element?(view, "#capability-agent-badge-enabled[type='checkbox']")
      assert has_element?(view, "#capability-chips-enabled[type='checkbox']")
      assert has_element?(view, "#capability-skills-text")
      assert has_element?(view, "#capability-tools-text")
      assert has_element?(view, "#capability-badges-preview")
      assert has_element?(view, "#capability-badges-settings-submit")

      assert has_element?(
               view,
               "#password-settings-submit[phx-disable-with='Changing password…']"
             )

      refute has_element?(view, "button", "Change Photo")
      assert has_element?(view, "[role='group'][aria-label='Color mode']")

      assert has_element?(
               view,
               "#settings-theme-day[data-theme-choice='tokyo-day'][aria-pressed]"
             )

      assert has_element?(
               view,
               "#settings-theme-night[data-theme-choice='tokyo-night'][aria-pressed]"
             )

      assert has_element?(view, "#delete-account-open[aria-haspopup='dialog']")

      assert has_element?(
               view,
               "#delete_account_modal[aria-labelledby='delete-account-title'][aria-describedby='delete-account-description']"
             )

      assert has_element?(view, "#delete-account-title")
      assert has_element?(view, "#delete-account-description")
      assert has_element?(view, "#delete-account-cancel")
      assert has_element?(view, "#delete-account-confirm")
    end

    test "authenticated users can make their profile private", %{conn: conn} do
      user = Fixtures.user_fixture()

      {:ok, view, _html} = live(log_in_user(conn, user), "/settings")

      view
      |> form("#profile-settings-form", %{
        "user" => %{
          "display_name" => user.display_name,
          "private_profile" => "true"
        }
      })
      |> render_submit()

      assert Urielm.Accounts.get_user(user.id).private_profile
    end

    test "authenticated users can set forum capability badge preferences", %{conn: conn} do
      user = Fixtures.user_fixture()

      {:ok, view, _html} = live(log_in_user(conn, user), "/settings")

      view
      |> form("#capability-badges-settings-form", %{
        "capability_badges" => %{
          "agent_badge_enabled" => "true",
          "capability_chips_enabled" => "false",
          "agent_name" => "Claude",
          "model_name" => "Sonnet 4.5",
          "provider" => "Anthropic",
          "skills_text" => "Writing skill\nDocs search\nWriting skill",
          "tools_text" => "Browser, Git\nTerminal"
        }
      })
      |> render_submit()

      settings = Urielm.Accounts.get_user(user.id).capability_badge_settings

      assert settings["agent_badge_enabled"] == true
      assert settings["capability_chips_enabled"] == false
      assert settings["agent_name"] == "Claude"
      assert settings["model_name"] == "Sonnet 4.5"
      assert settings["provider"] == "Anthropic"

      assert settings["visible_capabilities"] == [
               %{"kind" => "skill", "name" => "Writing skill"},
               %{"kind" => "skill", "name" => "Docs search"},
               %{"kind" => "tool", "name" => "Browser"},
               %{"kind" => "tool", "name" => "Git"},
               %{"kind" => "tool", "name" => "Terminal"}
             ]
    end

    test "settings page displays user email information", %{conn: conn} do
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, "/settings")

      # Verify user email is displayed (name may be nil)
      assert html =~ user.email
    end
  end

  describe "profile overview" do
    test "uses the shared page hierarchy and points to existing settings", %{conn: conn} do
      user = Fixtures.user_fixture()

      {:ok, view, _html} = live(log_in_user(conn, user), "/profile")

      assert has_element?(view, "#profile-page.ui-page-shell")
      assert has_element?(view, "#profile-header.ui-page-header")
      assert has_element?(view, "#profile-overview-empty-state[data-ui-state='empty']")
      assert has_element?(view, "#profile-overview-empty-state a[href='/settings']")
    end
  end
end
