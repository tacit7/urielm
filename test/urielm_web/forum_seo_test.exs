defmodule UrielmWeb.ForumSEOTest do
  use Urielm.DataCase, async: false

  import Urielm.Fixtures

  alias Urielm.Forum
  alias Urielm.Forum.Board
  alias Urielm.Repo
  alias UrielmWeb.SEO

  describe "forum_metadata/3 directories" do
    test "latest page normalizes pagination and keeps unrelated options out of canonical" do
      metadata = SEO.forum_metadata(:latest, nil, page: "3", filter: "unread", sort: "top")

      assert metadata.page_title == "Community - Page 3"
      assert metadata.meta_description =~ "Page 3."
      assert metadata.canonical_url == "https://urielm.dev/forum?page=3"
      assert metadata.robots == nil
      assert metadata.og_url == metadata.canonical_url
      assert metadata.twitter_image == "https://urielm.dev/images/social-card.png"
      assert [%{"@type" => "BreadcrumbList"}] = decode_json_ld(metadata)
    end

    test "page one omits query strings for directory pages" do
      metadata = SEO.forum_metadata(:categories, nil, page: 1, q: "ignored")

      assert metadata.page_title == "Forum Categories"
      assert metadata.canonical_url == "https://urielm.dev/forum/categories"
      assert metadata.robots == nil
    end

    test "search is generic noindex metadata with no canonical" do
      metadata = SEO.forum_metadata(:search, nil, q: "<unsafe>")

      assert metadata.page_title == "Search Forum"
      assert metadata.canonical_url == nil
      assert metadata.robots == "noindex"
      assert metadata.og_url == nil
      assert metadata.json_ld == []
    end
  end

  describe "forum_metadata/3 tags and boards" do
    test "tag metadata path-encodes slugs and includes page number copy" do
      tag = tag_fixture(%{name: "Elixir & AI", slug: "elixir & ai"})

      metadata = SEO.forum_metadata(:tag, tag, page: 2, extra: "ignored")

      assert metadata.page_title == "Elixir & AI Forum Topics - Page 2"

      assert metadata.meta_description ==
               "Read Urielm community discussions tagged Elixir & AI. Page 2."

      assert metadata.canonical_url == "https://urielm.dev/forum/tags/elixir%20%26%20ai?page=2"
      assert metadata.robots == nil
    end

    test "board uses category privacy and marks recognized sort or filter variants noindex" do
      category = category_fixture(%{name: "Help & Practice"})

      board =
        board_fixture(%{category_id: category.id, name: "Q&A", description: "Good answers."})

      metadata = SEO.forum_metadata(:board, board, page: 2, sort: "top", filter: "ignored")

      assert metadata.page_title == "Q&A - Page 2"
      assert metadata.meta_description == "Good answers. Page 2."
      assert metadata.canonical_url =~ "/forum/b/"
      assert metadata.canonical_url =~ "?page=2"
      assert metadata.robots == "noindex"
    end

    test "hidden board or category returns generic noindex metadata" do
      hidden_board = board_fixture(%{is_hidden: true})
      hidden_category = category_fixture(%{is_hidden: true})
      board_in_hidden_category = board_fixture(%{category_id: hidden_category.id})

      for resource <- [hidden_board, board_in_hidden_category] do
        metadata = SEO.forum_metadata(:board, resource)

        assert metadata.page_title == "Urielm"
        assert metadata.canonical_url == nil
        assert metadata.robots == "noindex"
        assert metadata.protected? == true
      end
    end
  end

  describe "forum_metadata/3 threads" do
    test "public thread uses title, sanitized markdown excerpt, default social image, and escaped JSON-LD" do
      board = board_fixture(%{name: "Announcements"})

      thread =
        thread_fixture(%{
          board_id: board.id,
          title: "Launch <Plan>",
          body:
            "Hello **world** &amp; friends.\n\n<script>alert('x')</script><div onclick=\"bad()\">Keep punctuation!</div>"
        })

      metadata = SEO.forum_metadata(:thread, thread)

      assert metadata.page_title == "Launch <Plan>"
      assert metadata.meta_description == "Hello world & friends. Keep punctuation!"
      assert metadata.canonical_url == "https://urielm.dev/forum/t/#{thread.id}"
      assert metadata.robots == nil
      assert metadata.og_image == "https://urielm.dev/images/social-card.png"
      refute metadata.meta_description =~ "alert"
      refute metadata.meta_description =~ "<"
      assert Enum.all?(metadata.json_ld, &(not String.contains?(&1, "<")))

      [%{"@type" => "BreadcrumbList"}] = decode_json_ld(metadata)
    end

    test "page suffixes survive long board titles and descriptions" do
      board =
        board_fixture(%{
          name: String.duplicate("Long Board Name ", 12),
          description: String.duplicate("Long board description with enough words. ", 16)
        })

      metadata = SEO.forum_metadata(:board, board, page: 12)

      assert String.ends_with?(metadata.page_title, " - Page 12")
      assert String.length(metadata.page_title) <= 90
      assert String.ends_with?(metadata.meta_description, " Page 12.")
      assert String.length(metadata.meta_description) <= 180
    end

    test "forum markdown summaries handle GFM markers without leaking raw syntax" do
      thread =
        thread_fixture(%{
          body: """
          ~~old~~ new answer with a table.

          | Key | Value |
          | --- | --- |
          | A | B |
          """
        })

      metadata = SEO.forum_metadata(:thread, thread)

      refute metadata.meta_description =~ "~~"
      refute metadata.meta_description =~ "|"
      assert metadata.meta_description =~ "old"
      assert metadata.meta_description =~ "Key"
    end

    test "removed thread and thread in hidden board return generic noindex metadata" do
      removed_thread = thread_fixture(%{is_removed: true})

      hidden_board_thread = thread_fixture()
      hide_board!(hidden_board_thread.board_id)

      for thread <- [removed_thread, hidden_board_thread] do
        metadata = SEO.forum_metadata(:thread, thread)

        assert metadata.page_title == "Urielm"
        assert metadata.canonical_url == nil
        assert metadata.robots == "noindex"
        assert metadata.json_ld == []
      end
    end
  end

  defp tag_fixture(attrs) do
    {:ok, tag} =
      attrs
      |> Map.put_new(:name, "Tag")
      |> Map.put_new(:slug, "tag-#{System.unique_integer([:positive])}")
      |> Forum.create_tag()

    tag
  end

  defp hide_board!(board_id) do
    Board
    |> Repo.get!(board_id)
    |> Board.changeset(%{is_hidden: true})
    |> Repo.update!()
  end

  defp decode_json_ld(metadata), do: Enum.map(metadata.json_ld, &Jason.decode!/1)
end
