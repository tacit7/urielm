defmodule UrielmWeb.SitemapControllerTest do
  use UrielmWeb.ConnCase, async: false

  import SweetXml
  import Urielm.Fixtures

  alias Urielm.Content
  alias Urielm.Learning
  alias Urielm.Repo

  test "missing HTML paths return 404 outside sitemap routes" do
    conn =
      build_conn()
      |> put_req_header("accept", "text/html")
      |> get("/missing-page")

    assert response(conn, 404)
  end

  test "accepts XML requests for the index and child sitemaps" do
    for path <- ["/sitemap.xml", "/sitemap-pages-1.xml"] do
      conn = build_conn() |> put_req_header("accept", "application/xml") |> get(path)
      assert response_content_type(conn, :xml) =~ "application/xml"
      assert response(conn, 200) |> xml_doc()
    end
  end

  test "serves valid XML with public fixed and canonical content URLs", %{conn: conn} do
    post = published_post!(%{slug: "ai-tools-&-teams"})
    video = video_fixture(%{slug: "public-video", published_at: ~U[2026-08-26 12:00:00Z]})
    prompt = prompt_fixture!(%{title: "XML & SEO prompt"})
    {course, lesson} = course_with_lesson!()
    thread = thread_fixture()

    conn = get(conn, ~p"/sitemap.xml")

    assert response_content_type(conn, :xml) =~ "application/xml"
    assert get_resp_header(conn, "cache-control") == ["public, max-age=3600"]

    urls = content_urls(conn)

    assert "https://urielm.dev/" in urls
    assert "https://urielm.dev/privacy" in urls
    assert "https://urielm.dev/blog/#{URI.encode(post.slug, &URI.char_unreserved?/1)}" in urls
    assert "https://urielm.dev/videos/#{video.slug}" in urls
    assert "https://urielm.dev/prompts/#{prompt.id}" in urls
    assert "https://urielm.dev/courses/#{course.slug}" in urls
    assert "https://urielm.dev/courses/#{course.slug}/lessons/#{lesson.slug}" in urls
    assert "https://urielm.dev/forum/t/#{thread.id}" in urls

    posts = build_conn() |> get("/sitemap-posts-1.xml") |> response(200) |> xml_doc()
    assert xpath(posts, ~x"count(//*[local-name()='lastmod'])"f) >= 1

    assert xpath(posts, ~x"//*[local-name()='lastmod']/text()"ls) ==
             [DateTime.to_iso8601(post.updated_at)]
  end

  test "child sitemap URLs remain within each child sitemap URL scope", %{conn: conn} do
    published_post!(%{slug: "scoped-post"})
    index = conn |> get(~p"/sitemap.xml") |> response(200) |> xml_doc()

    child_sitemap_urls = xpath(index, ~x"//*[local-name()='loc']/text()"ls)

    assert child_sitemap_urls != []

    for child_sitemap_url <- child_sitemap_urls do
      child_uri = URI.parse(child_sitemap_url)
      child_path = child_uri.path
      child_scope = sitemap_url_scope(child_path)

      child_doc =
        build_conn()
        |> get(child_path)
        |> response(200)
        |> xml_doc()

      child_urls = xpath(child_doc, ~x"//*[local-name()='loc']/text()"ls)
      assert child_urls != []

      assert Enum.all?(child_urls, fn child_url ->
               child_url |> URI.parse() |> Map.fetch!(:path) |> String.starts_with?(child_scope)
             end),
             "#{child_sitemap_url} listed URLs outside #{child_scope}: #{inspect(child_urls)}"
    end
  end

  test "excludes draft, scheduled, gated, and hidden content", %{conn: conn} do
    draft = post_fixture!(%{slug: "draft-post", status: "draft", published_at: nil})

    future_post =
      post_fixture!(%{
        slug: "future-post",
        status: "published",
        published_at: DateTime.utc_now() |> DateTime.add(86_400, :second)
      })

    signed_in_video =
      video_fixture(%{
        slug: "signed-in-video",
        visibility: "signed_in",
        published_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    future_video =
      video_fixture(%{
        slug: "future-video",
        visibility: "public",
        published_at: DateTime.utc_now() |> DateTime.add(86_400, :second)
      })

    removed_thread = thread_fixture(%{is_removed: true})
    hidden_board_thread = thread_fixture()
    hide_board!(hidden_board_thread.board_id)

    conn = get(conn, ~p"/sitemap.xml")
    urls = content_urls(conn)

    refute "https://urielm.dev/blog/#{draft.slug}" in urls
    refute "https://urielm.dev/blog/#{future_post.slug}" in urls
    refute "https://urielm.dev/videos/#{signed_in_video.slug}" in urls
    refute "https://urielm.dev/videos/#{future_video.slug}" in urls
    refute "https://urielm.dev/forum/t/#{removed_thread.id}" in urls
    refute "https://urielm.dev/forum/t/#{hidden_board_thread.id}" in urls
    refute "https://urielm.dev/forum/search" in urls
    refute "https://urielm.dev/themes" in urls
    refute "https://urielm.dev/signin" in urls
  end

  test "robots.txt declares the sitemap without blocking resources", %{conn: conn} do
    conn = get(conn, "/robots.txt")

    assert response(conn, 200) =~ "Sitemap: https://urielm.dev/sitemap.xml"
    refute conn.resp_body =~ "Disallow: /assets"
  end

  test "sitemap pagination includes older content without truncation" do
    posts = for index <- 1..3, do: published_post!(%{slug: "paged-post-#{index}"})
    index = Urielm.SEO.Sitemap.index_entries(page_size: 2)
    assert Enum.any?(index, &(&1.loc == "https://urielm.dev/sitemap-posts-2.xml"))

    {:ok, first} = Urielm.SEO.Sitemap.entries("posts", 1, page_size: 2)
    {:ok, second} = Urielm.SEO.Sitemap.entries("posts", 2, page_size: 2)
    assert length(first) == 2
    assert length(second) == 1

    assert Enum.map(first ++ second, & &1.loc) ==
             Enum.map(posts, &"https://urielm.dev/blog/#{&1.slug}")

    assert :not_found = Urielm.SEO.Sitemap.entries("posts", 3, page_size: 2)
  end

  test "invalid sitemap collections and pages return 404", %{conn: conn} do
    for path <- [
          "/sitemap-private-1.xml",
          "/sitemap-posts-0.xml",
          "/sitemap-posts-nope.xml",
          "/sitemap-posts-999999999999999999999999.xml",
          "/sitemap-pages-2.xml"
        ] do
      assert conn |> get(path) |> response(404) == "Not found"
    end
  end

  test "XML escaping preserves URL values" do
    url = "https://urielm.dev/videos?q=AI&format=shorts"
    doc = Urielm.SEO.Sitemap.to_xml([%{loc: url, lastmod: nil}]) |> xml_doc()
    assert xpath(doc, ~x"//*[local-name()='loc']/text()"ls) == [url]
  end

  defp content_urls(conn) do
    conn.resp_body
    |> xml_doc()
    |> xpath(~x"//*[local-name()='loc']/text()"ls)
    |> Enum.flat_map(fn url ->
      build_conn()
      |> get(URI.parse(url).path)
      |> response(200)
      |> xml_doc()
      |> xpath(~x"//*[local-name()='loc']/text()"ls)
    end)
  end

  defp xml_doc(xml), do: xml |> to_charlist() |> :xmerl_scan.string() |> elem(0)

  defp sitemap_url_scope(path) do
    path
    |> Path.dirname()
    |> then(fn
      "/" -> "/"
      dirname -> dirname <> "/"
    end)
  end

  defp published_post!(attrs) do
    attrs
    |> Map.put_new(:status, "published")
    |> Map.put_new(:published_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> post_fixture!()
  end

  defp post_fixture!(attrs) do
    attrs =
      Map.merge(
        %{
          title: "Sitemap post",
          slug: "sitemap-post-#{System.unique_integer([:positive])}",
          body: "A useful article for public readers.",
          status: "published",
          published_at: DateTime.utc_now() |> DateTime.truncate(:second)
        },
        attrs
      )

    {:ok, post} = Content.create_post(attrs)
    post
  end

  defp prompt_fixture!(attrs) do
    attrs =
      Map.merge(
        %{
          title: "Public prompt",
          category: "coding",
          prompt: "Help me structure this implementation."
        },
        attrs
      )

    {:ok, prompt} = Content.create_prompt(attrs)
    prompt
  end

  defp course_with_lesson! do
    suffix = System.unique_integer([:positive])

    {:ok, course} =
      Learning.create_course(%{
        title: "Public course #{suffix}",
        slug: "public-course-#{suffix}"
      })

    {:ok, lesson} =
      Learning.create_lesson(%{
        course_id: course.id,
        title: "Public lesson",
        slug: "public-lesson",
        lesson_number: 1
      })

    {course, lesson}
  end

  defp hide_board!(board_id) do
    Urielm.Forum.Board
    |> Repo.get!(board_id)
    |> Ecto.Changeset.change(%{is_hidden: true})
    |> Repo.update!()
  end
end
