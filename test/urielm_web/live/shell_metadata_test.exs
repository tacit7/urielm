defmodule UrielmWeb.ShellMetadataTest do
  use UrielmWeb.ConnCase

  import Urielm.Fixtures

  alias Urielm.Accounts.User
  alias Urielm.Content
  alias Urielm.Repo

  test "blog detail renders article metadata and structured data", %{conn: conn} do
    post =
      published_post!(%{
        title: "Safer <prompt> workflows",
        slug: "safer-prompt-workflows",
        excerpt: "A concise guide to safer prompt workflows.",
        hero_image: "/images/code-kata/hero-editor-results.png"
      })

    conn = get(conn, ~p"/blog/#{post.slug}?utm_source=newsletter")
    html = html_response(conn, 200)
    document = LazyHTML.from_fragment(html)

    assert_present(
      document,
      "meta[name='description'][content='A concise guide to safer prompt workflows.']"
    )

    assert_present(document, "link[rel='canonical'][href='https://urielm.dev/blog/#{post.slug}']")
    assert_present(document, "meta[property='og:title'][content='Safer <prompt> workflows']")
    assert_present(document, "meta[property='og:type'][content='article']")
    assert_present(document, "meta[name='twitter:card'][content='summary_large_image']")
    assert_present(document, "script[type='application/ld+json']")
    refute html =~ "</script><script"
  end

  test "video detail renders public video metadata and video structured data", %{conn: conn} do
    video =
      video_fixture(%{
        title: "Build dependable agents",
        slug: "build-dependable-agents",
        description_md: "A practical walkthrough for testing agent workflows.",
        visibility: "public",
        published_at: DateTime.utc_now()
      })

    conn = get(conn, ~p"/videos/#{video.slug}")
    document = conn |> html_response(200) |> LazyHTML.from_fragment()

    assert_present(
      document,
      "meta[name='description'][content='A practical walkthrough for testing agent workflows.']"
    )

    assert_present(
      document,
      "link[rel='canonical'][href='https://urielm.dev/videos/#{video.slug}']"
    )

    assert_present(document, "meta[property='og:type'][content='video.other']")

    assert_present(
      document,
      "meta[property='og:image'][content='https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg']"
    )

    assert_present(
      document,
      "meta[name='twitter:image'][content='https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg']"
    )

    assert_present(document, "script[type='application/ld+json']")
  end

  test "videos canonical keeps real filters and drops tracking params", %{conn: conn} do
    conn = get(conn, "/videos?q=agents&format=short&tag=ai&utm_source=newsletter")
    document = conn |> html_response(200) |> LazyHTML.from_fragment()

    assert_present(
      document,
      "link[rel='canonical'][href='https://urielm.dev/videos?q=agents&format=short&tag=ai']"
    )
  end

  test "protected video metadata does not expose the protected title", %{conn: conn} do
    video =
      video_fixture(%{
        title: "Members only roadmap",
        slug: "members-only-roadmap",
        visibility: "signed_in",
        published_at: DateTime.utc_now()
      })

    conn = get(conn, ~p"/videos/#{video.slug}")
    html = html_response(conn, 200)
    document = LazyHTML.from_fragment(html)

    assert_present(
      document,
      "meta[name='description'][content^='Urielm is a public learning platform']"
    )

    assert_present(document, "link[rel='canonical'][href='https://urielm.dev/']")

    refute_present(document, "meta[property='og:title'][content='Members only roadmap']")
  end

  test "private profile metadata does not expose profile details", %{conn: conn} do
    user =
      user_fixture(%{
        username: "privateuser",
        display_name: "Private User",
        bio: "Protected biography"
      })

    user
    |> User.profile_changeset(%{"private_profile" => "true"})
    |> Repo.update!()

    conn = get(conn, ~p"/u/#{user.username}")
    html = html_response(conn, 200)
    document = LazyHTML.from_fragment(html)

    assert_present(document, "link[rel='canonical'][href='https://urielm.dev/']")

    refute_present(document, "meta[name='description'][content='Protected biography']")
    refute_present(document, "meta[property='og:title'][content='Private User (@privateuser)']")
  end

  test "missing and malformed public detail routes return 404", %{conn: conn} do
    assert conn |> get(~p"/blog/not-published") |> response(404)

    assert conn |> get(~p"/prompts/not-an-id") |> response(404)
  end

  defp published_post!(overrides) do
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

  defp assert_present(document, selector) do
    refute document |> LazyHTML.filter(selector) |> Enum.empty?()
  end

  defp refute_present(document, selector) do
    assert document |> LazyHTML.filter(selector) |> Enum.empty?()
  end
end
