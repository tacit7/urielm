defmodule UrielmWeb.PrivacyLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  test "privacy policy is public and exposes the complete policy structure" do
    {:ok, view, _html} = live(build_conn(), ~p"/privacy")

    assert has_element?(view, "#privacy-policy-page")
    assert has_element?(view, "#privacy-policy-title", "Privacy Policy")
    assert has_element?(view, "#privacy-policy-updated", "August 25, 2026")
    assert has_element?(view, "#privacy-table-of-contents")

    for section <- 1..15 do
      assert has_element?(view, "#privacy-section-#{section}")
    end

    assert has_element?(view, "#google-oauth-disclosure")
    assert has_element?(view, "#google-oauth-disclosure", "email")
    assert has_element?(view, "#google-oauth-disclosure", "profile")
    assert has_element?(view, "a[href='mailto:uriel@smpllabs.io']")
  end

  test "homepage footer links to the exact privacy policy URL" do
    {:ok, view, _html} = live(build_conn(), ~p"/")

    assert has_element?(view, "#home-footer-privacy-link[href='/privacy']")
  end
end
