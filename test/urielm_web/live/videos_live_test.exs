defmodule UrielmWeb.VideosLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  test "renders published videos and shorts without a marketing header" do
    featured =
      published_video(%{
        title: "Build your first useful AI workflow",
        author_name: "Uriel Maldonado"
      })

    standard =
      published_video(%{
        title: "Writing dependable prompts",
        published_at: seconds_ago(60)
      })

    short =
      published_video(%{
        title: "Give your prompt one clear job",
        format: "short",
        published_at: seconds_ago(120)
      })

    unpublished = video_fixture(%{title: "Draft recording", published_at: nil})

    {:ok, view, _html} = live(build_conn(), ~p"/videos")

    assert has_element?(view, "#videos-index")
    assert has_element?(view, "#video-toolbar")
    assert has_element?(view, "#video-search-form input[name='q']")
    assert has_element?(view, "#mobile-nav-videos[aria-current='page']")
    assert has_element?(view, "#featured-video-#{featured.id}")
    assert has_element?(view, "#video-card-#{standard.id}")
    assert has_element?(view, "#short-card-#{short.id}")
    refute has_element?(view, "#video-card-#{unpublished.id}")
    refute has_element?(view, "#videos-index-header")
  end

  test "filters the library by search query" do
    matching = published_video(%{title: "Prompt engineering essentials"})
    other = published_video(%{title: "Build a Phoenix dashboard", published_at: seconds_ago(60)})

    {:ok, view, _html} = live(build_conn(), ~p"/videos?q=prompt")

    assert has_element?(view, "#video-search-form input[name='q'][value='prompt']")
    assert has_element?(view, "#featured-video-#{matching.id}")
    refute has_element?(view, "#video-card-#{other.id}")
    refute has_element?(view, "#featured-video-#{other.id}")
  end

  test "filters the library to shorts" do
    standard = published_video(%{title: "A complete walkthrough"})
    short = published_video(%{title: "One minute tip", format: "short"})

    {:ok, view, _html} = live(build_conn(), ~p"/videos?format=short")

    assert has_element?(view, "#video-filter-short[aria-current='page']")
    assert has_element?(view, "#short-card-#{short.id}")
    refute has_element?(view, "#featured-video-#{standard.id}")
    refute has_element?(view, "#video-card-#{standard.id}")
  end

  test "filters the library by tag slugs" do
    tagged = published_video(%{title: "Tagged workflow"})
    other = published_video(%{title: "Other workflow", published_at: seconds_ago(60)})
    {:ok, tag} = Urielm.Content.find_or_create_tag("AI")
    {:ok, _video_tag} = Urielm.Content.tag_video(tagged.id, tag.id)

    {:ok, view, _html} = live(build_conn(), ~p"/videos?tags=ai")

    assert has_element?(view, "#featured-video-#{tagged.id}")
    refute has_element?(view, "#video-card-#{other.id}")
    refute has_element?(view, "#featured-video-#{other.id}")
  end

  test "renders tag picker, selected tags, and card tag badges" do
    tagged = published_video(%{title: "Tagged workflow"})
    standard = published_video(%{title: "Standard tag card", published_at: seconds_ago(60)})

    short =
      published_video(%{title: "Short tag card", format: "short", published_at: seconds_ago(120)})

    {:ok, ai_tag} = Urielm.Content.find_or_create_tag("AI")
    {:ok, tutorial_tag} = Urielm.Content.find_or_create_tag("Tutorial")
    {:ok, _video_tag} = Urielm.Content.tag_video(tagged.id, ai_tag.id)
    {:ok, _video_tag} = Urielm.Content.tag_video(standard.id, tutorial_tag.id)
    {:ok, _video_tag} = Urielm.Content.tag_video(short.id, tutorial_tag.id)

    {:ok, view, _html} = live(build_conn(), ~p"/videos?tags=ai")

    assert has_element?(view, "#video-tag-picker")
    assert has_element?(view, "#video-tag-filter-tutorial[href='/videos?tags=ai%2Ctutorial']")
    assert has_element?(view, "#selected-video-tag-ai[href='/videos']")
    assert has_element?(view, "#featured-video-#{tagged.id}-tag-ai", "AI")

    {:ok, unfiltered_view, _html} = live(build_conn(), ~p"/videos")

    assert has_element?(unfiltered_view, "#video-card-#{standard.id}-tag-tutorial", "Tutorial")
    assert has_element?(unfiltered_view, "#short-card-#{short.id}-tag-tutorial", "Tutorial")
  end

  test "unknown tag slug returns no results without error" do
    published_video(%{title: "Existing video"})

    {:ok, view, _html} = live(build_conn(), ~p"/videos?tags=missing")

    assert has_element?(view, "#videos-no-results")
  end

  test "format filter links retain sorted tag params" do
    published_video(%{title: "Existing video"})

    {:ok, view, _html} = live(build_conn(), ~p"/videos?q=phoenix&tags=zeta,alpha")

    assert has_element?(
             view,
             "#video-filter-short[href='/videos?q=phoenix&format=short&tags=alpha%2Czeta']"
           )
  end

  test "labels gated published videos without hiding them" do
    signed_in = published_video(%{visibility: "signed_in"})

    subscriber =
      published_video(%{
        visibility: "subscriber",
        published_at: seconds_ago(60)
      })

    {:ok, view, _html} = live(build_conn(), ~p"/videos")

    assert has_element?(view, "#video-access-#{signed_in.id}[data-access='signed_in']", "Sign in")

    assert has_element?(
             view,
             "#video-access-#{subscriber.id}[data-access='subscriber']",
             "Subscriber"
           )
  end

  test "distinguishes an empty library from a search with no matches" do
    {:ok, empty_view, _html} = live(build_conn(), ~p"/videos")

    assert has_element?(empty_view, "#videos-empty-state", "New videos are on the way")

    published_video(%{title: "A useful video"})

    {:ok, filtered_view, _html} = live(build_conn(), ~p"/videos?q=missing")

    assert has_element?(filtered_view, "#videos-no-results", "No videos found")
    assert has_element?(filtered_view, "#clear-video-filters[href='/videos']")
  end

  defp published_video(attrs) do
    attrs
    |> Map.put_new(:published_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> video_fixture()
  end

  defp seconds_ago(seconds) do
    DateTime.utc_now()
    |> DateTime.add(-seconds, :second)
    |> DateTime.truncate(:second)
  end
end
