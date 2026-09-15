defmodule UrielmWeb.ForumMetadataTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias Urielm.{Fixtures, Forum, Repo}

  test "forum directories emit canonical descriptions and social previews" do
    for path <- ["/forum", "/forum/categories", "/forum/tags"] do
      document = document(path <> "?utm_source=review")
      assert value(document, "link[rel=canonical]", "href") == "https://urielm.dev" <> path
      assert String.length(value(document, "meta[name=description]", "content")) > 20
      assert value(document, "meta[property='og:url']", "content") == "https://urielm.dev" <> path
      assert value(document, "meta[property='og:image']", "content") =~ "https://"
      assert value(document, "meta[name='twitter:card']", "content") == "summary_large_image"
      assert page_payload(document)["canonical_url"] == "https://urielm.dev" <> path
    end
  end

  test "latest board and tag pagination preserve distinct canonical pages" do
    board = Fixtures.board_fixture()
    {:ok, tag} = Forum.create_tag(%{name: "SEO testing", slug: "seo-testing"})

    for path <- ["/forum", "/forum/b/#{board.slug}", "/forum/tags/#{tag.slug}"] do
      first = document(path <> "?page=1&utm_source=review")
      second = document(path <> "?page=2&utm_source=review")
      assert value(first, "link[rel=canonical]", "href") == "https://urielm.dev" <> path

      assert value(second, "link[rel=canonical]", "href") ==
               "https://urielm.dev" <> path <> "?page=2"

      refute text(first, "title") == text(second, "title")

      refute value(first, "meta[name=description]", "content") ==
               value(second, "meta[name=description]", "content")
    end
  end

  test "public thread metadata describes its content without HTML or Markdown artifacts" do
    thread =
      Fixtures.thread_fixture(%{
        title: "State-of-the-art workflows",
        body: "**Useful** notes for state-of-the-art tools. <script>alert(1)</script>"
      })

    page = document("/forum/t/#{thread.id}?utm_source=review")

    assert text(page, "title") =~ thread.title
    assert value(page, "link[rel=canonical]", "href") == "https://urielm.dev/forum/t/#{thread.id}"
    description = value(page, "meta[name=description]", "content")
    assert description =~ "state-of-the-art"
    refute description =~ "**"
    refute description =~ "<script>"
    refute description =~ "alert(1)"
    assert value(page, "meta[property='og:title']", "content") =~ thread.title

    for json <- LazyHTML.query(page, "script[type='application/ld+json']") do
      assert json |> LazyHTML.text() |> Jason.decode!() |> is_map()
    end
  end

  test "search and personalized board filters carry noindex metadata" do
    board = Fixtures.board_fixture()

    for path <- [
          "/forum/search?query=private-query",
          "/forum/b/#{board.slug}?filter=unread",
          "/forum/b/#{board.slug}?sort=top"
        ] do
      page = document(path)
      assert value(page, "meta[name=robots]", "content") =~ "noindex"
      assert page_payload(page)["robots"] =~ "noindex"
    end
  end

  test "hidden boards and their threads do not expose topic metadata" do
    board = Fixtures.board_fixture(%{name: "Hidden board title"})
    thread = Fixtures.thread_fixture(%{board_id: board.id, title: "Hidden thread title"})
    board |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()

    for path <- ["/forum/b/#{board.slug}", "/forum/t/#{thread.id}"] do
      page = document(path)
      assert value(page, "meta[name=robots]", "content") =~ "noindex"
      assert LazyHTML.query(page, "link[rel=canonical]") |> Enum.empty?()
      refute text(page, "title") =~ "Hidden"
      refute value(page, "meta[property='og:title']", "content") =~ "Hidden"
    end
  end

  test "live pagination refreshes the metadata payload", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum")
    render_patch(view, "/forum?page=2&utm_source=review")
    payload = view |> render() |> LazyHTML.from_fragment() |> page_payload()
    assert payload["canonical_url"] == "https://urielm.dev/forum?page=2"
    assert payload["page_title"] =~ "2"

    render_patch(view, "/forum")
    payload = view |> render() |> LazyHTML.from_fragment() |> page_payload()
    assert payload["canonical_url"] == "https://urielm.dev/forum"
    assert is_nil(payload["robots"])
  end

  test "hidden categories and admin-visible removed threads retain generic metadata" do
    category = Fixtures.category_fixture()
    board = Fixtures.board_fixture(%{category_id: category.id})
    hidden_thread = Fixtures.thread_fixture(%{board_id: board.id, title: "Hidden category topic"})
    category |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()

    hidden_page = document("/forum/t/#{hidden_thread.id}")
    assert value(hidden_page, "meta[name=robots]", "content") =~ "noindex"
    refute text(hidden_page, "title") =~ hidden_thread.title

    removed_thread = Fixtures.thread_fixture(%{title: "Removed topic", is_removed: true})
    admin = Fixtures.admin_fixture()

    removed_page =
      build_conn()
      |> log_in_user(admin)
      |> get("/forum/t/#{removed_thread.id}")
      |> html_response(200)
      |> LazyHTML.from_document()

    assert value(removed_page, "meta[name=robots]", "content") =~ "noindex"
    refute text(removed_page, "title") =~ removed_thread.title
    assert is_nil(page_payload(removed_page)["canonical_url"])
  end

  defp document(path),
    do: build_conn() |> get(path) |> html_response(200) |> LazyHTML.from_document()

  defp text(document, selector), do: document |> LazyHTML.query(selector) |> LazyHTML.text()

  defp value(document, selector, attribute) do
    [value] = document |> LazyHTML.query(selector) |> LazyHTML.attribute(attribute)
    value
  end

  defp page_payload(document), do: document |> value("#page-seo", "data-seo") |> Jason.decode!()
end
