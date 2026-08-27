defmodule UrielmWeb.UiQuickWinsTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  describe "homepage hero" do
    test "presents one primary learning action and a practical prompt artifact" do
      {:ok, view, _html} = live(build_conn(), ~p"/")

      assert has_element?(view, "#home-hero")
      assert has_element?(view, "#hero-primary-cta[href='/courses']")
      assert has_element?(view, "#prompt-improvement-example")
      assert has_element?(view, "#prompt-variant-before[aria-selected='true']")
      assert has_element?(view, "#prompt-before-pane")
      refute has_element?(view, "#featured-learning-card")
    end

    test "switches the prompt artifact to the improved example" do
      {:ok, view, _html} = live(build_conn(), ~p"/")
      home_view = find_live_child(view, "page-home")

      home_view
      |> element("#prompt-variant-improved")
      |> render_click()

      assert has_element?(home_view, "#prompt-variant-improved[aria-selected='true']")
      assert has_element?(home_view, "#prompt-improved-pane", "developers new to AI tools")

      assert has_element?(
               home_view,
               "#prompt-improvement-example",
               "Illustrative learning example"
             )

      refute has_element?(home_view, "#prompt-before-pane")
    end

    test "offers outcome-led routes immediately after the hero" do
      {:ok, view, _html} = live(build_conn(), ~p"/")

      assert has_element?(view, "#learning-outcomes")
      assert has_element?(view, "#outcome-learn[href='/courses']")
      assert has_element?(view, "#outcome-prompt[href='/prompts']")
      assert has_element?(view, "#outcome-workflow[href='/blog']")
      assert has_element?(view, "#outcome-video[href='/videos']")
    end
  end

  describe "public OAuth verification homepage" do
    test "is accessible without a user session and clearly describes the app" do
      conn = get(build_conn(), ~p"/")
      assert conn.status == 200

      {:ok, view, _html} = live(build_conn(), ~p"/")

      assert has_element?(view, "#app-purpose")
      assert has_element?(view, "#app-purpose", "public learning platform")
      assert has_element?(view, "#app-purpose", "tutorials")
      assert has_element?(view, "#app-purpose", "prompts")
      assert has_element?(view, "#app-purpose", "community")
    end

    test "keeps the Google profile disclosure out of the homepage browsing flow" do
      {:ok, view, _html} = live(build_conn(), ~p"/")

      refute has_element?(view, "#google-signin-purpose")
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

  describe "homepage Shorts" do
    test "keeps sparse desktop Shorts rails compact" do
      video_fixture(%{
        title: "A Short with enough copy to exercise the portrait layout",
        format: "short",
        published_at: ~U[2026-08-24 12:00:00Z]
      })

      {:ok, view, _html} = live(build_conn(), ~p"/")

      assert has_element?(
               view,
               "#home-shorts-rail[class*='lg:auto-cols-[13rem]']"
             )
    end

    test "renders persistent media affordances and real video metadata" do
      short =
        video_fixture(%{
          title: "Turn a rough idea into a useful prompt",
          slug: "useful-prompt-short",
          format: "short",
          author_name: "Uriel Maldonado",
          published_at: ~U[2026-08-24 12:00:00Z]
        })

      assert {:ok, short} = Urielm.Content.set_video_tags(short, ["Prompts", "Writing"])

      {:ok, view, _html} = live(build_conn(), ~p"/")

      assert has_element?(view, "#home-shorts-rail.ui-media-rail")

      assert has_element?(
               view,
               "#home-short-card-#{short.id}[href='/videos/useful-prompt-short']"
             )

      assert has_element?(
               view,
               "#home-short-card-#{short.id} img[src='https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg']"
             )

      assert has_element?(view, "#home-short-play-#{short.id}")
      assert has_element?(view, "#home-short-card-tags-#{short.id}", "Prompts")
      assert has_element?(view, "#home-short-card-meta-#{short.id}", "Uriel Maldonado")
      assert has_element?(view, "#home-short-card-meta-#{short.id}", "Aug 24")
    end

    test "uses the TikTok thumbnail endpoint for a TikTok Short" do
      short =
        video_fixture(%{
          title: "A TikTok workflow tip",
          slug: "tiktok-workflow-tip",
          format: "short",
          youtube_url: nil,
          tiktok_url: "https://www.tiktok.com/@urielm/video/1234567890",
          published_at: ~U[2026-08-23 12:00:00Z]
        })

      {:ok, view, _html} = live(build_conn(), ~p"/")

      assert has_element?(
               view,
               "#home-short-card-#{short.id} img[src='/video-thumbnails/#{short.id}']"
             )

      refute has_element?(view, "#home-short-fallback-#{short.id}")
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
      assert has_element?(view, "#prompts-empty-state[data-ui-state='empty']")
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
