defmodule UrielmWeb.UiQuickWinsTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  describe "homepage hero" do
    test "presents one primary learning action and a featured learning surface" do
      {:ok, view, _html} = live(build_conn(), ~p"/")

      assert has_element?(view, "#home-hero")
      assert has_element?(view, "#hero-primary-cta[href='/courses']")
      assert has_element?(view, "#featured-learning-card")
    end
  end

  describe "shared content system" do
    test "uses consistent section hierarchy across homepage content" do
      {:ok, view, _html} = live(build_conn(), ~p"/")

      assert has_element?(view, "#home-courses.ui-section")
      assert has_element?(view, "#home-courses .ui-section-header")
      assert has_element?(view, "#home-articles.ui-section")
      assert has_element?(view, "#home-prompts.ui-section")
    end

    test "defines reusable static and interactive card surfaces" do
      css = File.read!(Path.expand("../../../assets/css/app.css", __DIR__))

      assert css =~ ".ui-card {"
      assert css =~ ".ui-card-interactive {"
      assert css =~ ".ui-card-compact {"
      assert css =~ "prefers-reduced-motion: reduce"
    end
  end

  describe "prompt discovery" do
    test "groups search, full category selection, and quick filters" do
      {:ok, view, _html} = live(build_conn(), ~p"/prompts")

      assert has_element?(view, "#prompts-page-header")
      assert has_element?(view, "#prompt-toolbar")
      assert has_element?(view, "#prompt-search-form input[name='query']")
      assert has_element?(view, "#prompt-category-filter select[name='category']")
      assert has_element?(view, "#prompt-quick-filters button[phx-click='filter_changed']")
    end

    test "quick filters update the active category in place" do
      {:ok, view, _html} = live(build_conn(), ~p"/prompts")
      prompts_view = find_live_child(view, "page-prompts")

      prompts_view
      |> element("#prompt-quick-filters button[phx-value-category='Software Engineers']")
      |> render_click()

      assert has_element?(
               prompts_view,
               "#prompt-quick-filters button.btn-primary[phx-value-category='Software Engineers']"
             )
    end
  end
end
