defmodule UrielmWeb.TermsLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  test "terms of use are public and expose the complete agreement structure" do
    {:ok, view, _html} = live(build_conn(), ~p"/terms")

    assert has_element?(view, "#terms-page")
    assert has_element?(view, "#terms-title", "Terms of Use")
    assert has_element?(view, "#terms-updated", "August 25, 2026")
    assert has_element?(view, "#terms-table-of-contents")

    for section <- 1..19 do
      assert has_element?(view, "#terms-section-#{section}")
    end

    assert has_element?(view, "#terms-governing-law", "Texas")
    assert has_element?(view, "a[href='/privacy']", "Privacy Policy")
    assert has_element?(view, "a[href='mailto:uriel@smpllabs.io']")
  end

  test "homepage footer links to the exact terms URL" do
    {:ok, view, _html} = live(build_conn(), ~p"/")

    assert has_element?(view, "#home-footer-terms-link[href='/terms']")
  end
end
