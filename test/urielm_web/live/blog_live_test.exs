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
  end

  test "blog index exposes a stable post collection and cards" do
    post = published_post!()

    {:ok, view, _html} = live(build_conn(), ~p"/blog")

    assert has_element?(view, "#blog-index")
    assert has_element?(view, "#blog-index-header")
    assert has_element?(view, "#blog-posts")
    assert has_element?(view, "#blog-post-#{post.id}")
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
