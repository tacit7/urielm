defmodule UrielmWeb.BlogLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Urielm.Content

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  test "published post renders a complete reading experience" do
    body = Enum.map_join(1..401, " ", fn _ -> "word" end)
    post = published_post!(%{body: body})

    {:ok, view, _html} = live(build_conn(), ~p"/blog/#{post.slug}")

    assert has_element?(view, "#blog-reading-shell")
    assert has_element?(view, "#blog-article-header")
    assert has_element?(view, "#blog-reading-time", "3 min read")
    assert has_element?(view, "#blog-article")
    assert has_element?(view, "#blog-article-footer a[href='/blog']")
    refute has_element?(view, "script[type='application/ld+json']")
  end

  test "blog index exposes a stable post collection and cards" do
    post = published_post!()

    {:ok, view, _html} = live(build_conn(), ~p"/blog")

    assert has_element?(view, "#blog-index")
    assert has_element?(view, "#blog-index-header")
    assert has_element?(view, "#blog-featured-post-#{post.id}")
  end

  test "blog index uses the shared empty state when no posts are published" do
    {:ok, view, _html} = live(build_conn(), ~p"/blog")

    assert has_element?(view, "#blog-empty-state[data-ui-state='empty']")
  end

  test "blog index features the newest post and places older posts in the archive" do
    older_post =
      published_post!(%{
        title: "A durable AI workflow",
        published_at: ~U[2026-08-18 12:00:00Z]
      })

    newest_post =
      published_post!(%{
        title: "Writing effective prompts",
        published_at: ~U[2026-08-20 12:00:00Z]
      })

    {:ok, view, _html} = live(build_conn(), ~p"/blog")

    assert has_element?(view, "#blog-featured-post-#{newest_post.id}")
    assert has_element?(view, "#blog-featured-post-#{newest_post.id}", newest_post.title)
    assert has_element?(view, "#blog-posts")
    assert has_element?(view, "#blog-post-#{older_post.id}", older_post.title)
    refute has_element?(view, "#blog-post-#{newest_post.id}")
  end

  test "blog index omits the archive when only the featured post is published" do
    post = published_post!()

    {:ok, view, _html} = live(build_conn(), ~p"/blog")

    assert has_element?(view, "#blog-featured-post-#{post.id}")
    refute has_element?(view, "#blog-posts")
  end

  defp published_post!(overrides \\ %{}) do
    suffix = System.unique_integer([:positive])

    attrs =
      Map.merge(
        %{
          title: "Effective prompts #{suffix}",
          slug: "effective-prompts-#{suffix}",
          body: "Clear goals and useful context make prompts better.",
          excerpt: "A concise guide to clearer prompts.",
          status: "published",
          published_at: DateTime.utc_now() |> DateTime.truncate(:second)
        },
        overrides
      )

    {:ok, post} = Content.create_post(attrs)
    post
  end
end
