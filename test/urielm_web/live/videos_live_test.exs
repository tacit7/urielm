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
    assert has_element?(view, "#videos-index-header h1", "Videos")
    assert has_element?(view, "#video-toolbar")
    assert has_element?(view, "#video-search-form input[name='q']")
    assert has_element?(view, "#mobile-nav-videos[aria-current='page']")
    assert has_element?(view, "#featured-video-#{featured.id}")
    assert has_element?(view, "#video-card-#{standard.id}")
    assert has_element?(view, "#short-card-#{short.id}")
    refute has_element?(view, "#video-card-#{unpublished.id}")
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

  test "filters the library by singular comma-separated tag slugs" do
    tagged = published_video(%{title: "Tagged workflow"})
    other = published_video(%{title: "Other workflow", published_at: seconds_ago(60)})
    {:ok, tag} = Urielm.Content.find_or_create_tag("AI")
    {:ok, _video_tag} = Urielm.Content.tag_video(tagged.id, tag.id)

    {:ok, view, _html} = live(build_conn(), ~p"/videos?tag=ai")

    assert has_element?(view, "#featured-video-#{tagged.id}")
    refute has_element?(view, "#video-card-#{other.id}")
    refute has_element?(view, "#featured-video-#{other.id}")
    assert has_element?(view, "#video-tag-filter-count", "1")
  end

  test "unknown tag slug returns no results without error" do
    published_video(%{title: "Existing video"})

    {:ok, view, _html} = live(build_conn(), ~p"/videos?tag=missing")

    assert has_element?(view, "#videos-no-results")
  end

  test "format filter links retain sorted tag params" do
    published_video(%{title: "Existing video"})

    {:ok, view, _html} = live(build_conn(), ~p"/videos?q=phoenix&tag=zeta,alpha")

    assert has_element?(
             view,
             "#video-filter-short[href='/videos?q=phoenix&format=short&tag=alpha%2Czeta']"
           )
  end

  test "tag picker drafts selections and applies them with navigation" do
    video = published_video(%{title: "Agent workflow"})
    {:ok, tag} = Urielm.Content.find_or_create_tag("Agents")
    {:ok, _video_tag} = Urielm.Content.tag_video(video.id, tag.id)

    {:ok, view, _html} = live(build_conn(), ~p"/videos?q=workflow&format=standard")
    child = find_live_child(view, "page-videos")

    child |> element("#video-tag-filter-button") |> render_click()
    assert has_element?(child, "#video-tag-picker[role='dialog']")
    assert has_element?(child, "#video-tag-option-agents[aria-pressed='false']")

    child |> element("#video-tag-option-agents") |> render_click()
    assert has_element?(child, "#video-tag-option-agents[aria-pressed='true']")

    child |> element("#apply-video-tag-filters") |> render_click()
    assert_redirect(child, "/videos?q=workflow&format=standard&tag=agents")
  end

  test "clearing draft tag selections removes the tag parameter" do
    video = published_video(%{title: "Agent workflow"})
    {:ok, tag} = Urielm.Content.find_or_create_tag("Agents")
    {:ok, _video_tag} = Urielm.Content.tag_video(video.id, tag.id)

    {:ok, view, _html} = live(build_conn(), ~p"/videos?tag=agents")
    child = find_live_child(view, "page-videos")

    child |> element("#video-tag-filter-button") |> render_click()
    child |> element("#clear-video-tag-filters") |> render_click()
    child |> element("#apply-video-tag-filters") |> render_click()

    assert_redirect(child, "/videos")
  end

  test "renders inert tag badges on featured, standard, and short cards" do
    featured = published_video(%{title: "Featured agents"})
    standard = published_video(%{title: "Agent lesson", published_at: seconds_ago(60)})

    short =
      published_video(%{
        title: "Agent tip",
        format: "short",
        published_at: seconds_ago(120)
      })

    Enum.each([featured, standard, short], fn video ->
      assert {:ok, _video} = Urielm.Content.set_video_tags(video, ["Agents"])
    end)

    {:ok, view, _html} = live(build_conn(), ~p"/videos")

    assert has_element?(view, "#featured-video-tags-#{featured.id}", "Agents")
    assert has_element?(view, "#video-card-tags-#{standard.id}", "Agents")
    assert has_element?(view, "#short-card-tags-#{short.id}", "Agents")
    refute has_element?(view, "#video-results a .badge a")
  end

  test "combines query, format, and tag filters" do
    matching = published_video(%{title: "Agent prompt", format: "short"})
    wrong_format = published_video(%{title: "Agent prompt", published_at: seconds_ago(60)})
    wrong_query = published_video(%{title: "Phoenix tip", format: "short"})

    Enum.each([matching, wrong_format, wrong_query], fn video ->
      assert {:ok, _video} = Urielm.Content.set_video_tags(video, ["Agents"])
    end)

    {:ok, view, _html} = live(build_conn(), ~p"/videos?q=prompt&format=short&tag=agents")

    assert has_element?(view, "#short-card-#{matching.id}")
    refute has_element?(view, "#video-card-#{wrong_format.id}")
    refute has_element?(view, "#short-card-#{wrong_query.id}")
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

    assert has_element?(
             empty_view,
             "#videos-empty-state[data-ui-state='empty']",
             "New videos are on the way"
           )

    published_video(%{title: "A useful video"})

    {:ok, filtered_view, _html} = live(build_conn(), ~p"/videos?q=missing")

    assert has_element?(
             filtered_view,
             "#videos-no-results[data-ui-state='empty']",
             "No videos found"
           )

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
