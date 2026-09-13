defmodule UrielmWeb.InitialHTMLRenderingTest do
  use UrielmWeb.ConnCase, async: false

  alias Urielm.Content
  alias Urielm.Fixtures

  describe "public initial HTML" do
    test "blog detail includes crawlable article content", %{conn: conn} do
      post =
        published_post!(%{
          title: "Initial HTML for crawlers",
          slug: "initial-html-for-crawlers",
          body: "Server rendered article body for search engines."
        })

      document = conn |> get(~p"/blog/#{post.slug}") |> document()

      assert_present(document, "#blog-reading-shell")
      assert_present(document, "#blog-article-header")
      assert_present(document, "#blog-article")
      assert_present(document, "#blog-article p")
    end

    test "blog missing slug does not crash the disconnected render", %{conn: conn} do
      document = conn |> get(~p"/blog/not-a-real-post") |> document()

      assert_present(document, "#blog-index")
      assert_present(document, "#blog-empty-state")
      refute_present(document, "#blog-reading-shell")
    end

    test "prompt index cards expose crawlable detail links", %{conn: conn} do
      {:ok, prompt} =
        Content.create_prompt(%{
          title: "Review launch copy",
          category: "Content Creation",
          prompt: "Review this launch copy for clarity and conversion."
        })

      document = conn |> get(~p"/prompts") |> document()

      assert_present(document, "#prompts")
      assert_present(document, "#prompts a[href='/prompts/#{prompt.id}']")
    end

    test "prompt detail includes crawlable prompt body", %{conn: conn} do
      {:ok, prompt} =
        Content.create_prompt(%{
          title: "Plan a careful refactor",
          category: "Software Engineers",
          prompt: "Create a phased refactor plan with risks and validation steps."
        })

      document = conn |> get(~p"/prompts/#{prompt.id}") |> document()

      assert_present(document, "#prompt-detail-page")
      assert_present(document, "#prompt-content-panel")
      assert_present(document, "#prompt-content-fallback")
    end

    test "public video detail includes crawlable overview content", %{conn: conn} do
      video =
        Fixtures.video_fixture(%{
          title: "Make LiveView pages crawlable",
          slug: "make-liveview-pages-crawlable",
          visibility: "public",
          published_at: DateTime.utc_now() |> DateTime.truncate(:second),
          description_md: "A practical overview for rendering useful initial HTML.",
          resources_md: "- [Checklist](https://example.com/checklist)"
        })

      document = conn |> get(~p"/videos/#{video.slug}") |> document()

      assert_present(document, "#standard-video-page")
      assert_present(document, "#video-detail-header")
      assert_present(document, "#video-description-fallback")
      assert_present(document, "#video-resources-card")
    end

    test "restricted video detail does not expose private content in initial HTML", %{conn: conn} do
      video =
        Fixtures.video_fixture(%{
          title: "Subscriber only rendering notes",
          slug: "subscriber-only-rendering-notes",
          visibility: "subscriber",
          published_at: DateTime.utc_now() |> DateTime.truncate(:second),
          description_md: "This gated summary must not be exposed to crawlers."
        })

      html = conn |> get(~p"/videos/#{video.slug}") |> html_response(200)
      document = LazyHTML.from_fragment(html)

      refute_present(document, "#standard-video-page")
      refute html =~ video.title
      refute html =~ "This gated summary must not be exposed"
    end

    test "forum board initial HTML includes crawlable thread links", %{conn: conn} do
      board = Fixtures.board_fixture()

      thread =
        Fixtures.thread_fixture(%{
          board_id: board.id,
          title: "Server render forum cards",
          body: "Forum cards need crawlable links before hydration."
        })

      document = conn |> get(~p"/forum/b/#{board.slug}") |> document()

      assert_present(document, "#threads")
      assert_present(document, "#threads a[href='/forum/t/#{thread.id}']")
    end
  end

  defp document(conn) do
    conn
    |> html_response(200)
    |> LazyHTML.from_fragment()
  end

  defp assert_present(document, selector) do
    refute document |> LazyHTML.query(selector) |> Enum.empty?()
  end

  defp refute_present(document, selector) do
    assert document |> LazyHTML.query(selector) |> Enum.empty?()
  end

  defp published_post!(overrides) do
    attrs =
      Map.merge(
        %{
          title: "Published post",
          slug: "published-post-#{System.unique_integer([:positive])}",
          body: "Published body.",
          excerpt: "Published excerpt.",
          status: "published",
          published_at: DateTime.utc_now() |> DateTime.truncate(:second)
        },
        overrides
      )

    {:ok, post} = Content.create_post(attrs)
    post
  end
end
