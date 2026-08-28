defmodule UrielmWeb.TagsLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Urielm.Fixtures
  alias Urielm.Forum

  describe "tag directory" do
    test "renders the tag browse shell and tag rows", %{conn: conn} do
      author = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: author.id})

      {:ok, tag} = Forum.create_tag(%{name: "Question", slug: "question"})
      {:ok, _thread_tag} = Forum.add_tag_to_thread(thread.id, tag.id)

      {:ok, view, _html} = live(conn, "/forum/tags")

      assert has_element?(view, "#forum-tags-page")
      assert has_element?(view, "#community-discovery-header")
      assert has_element?(view, "#forum-tags-surface.ui-card")
      assert has_element?(view, "#forum-view-tabs a[aria-current='page']", "Tags")
      assert has_element?(view, "#forum-sidebar-nav a[href='/forum/tags']")
      assert has_element?(view, "#forum-tag-question")
      assert has_element?(view, "#forum-tag-question .badge", "Tag")
      assert has_element?(view, "#forum-tag-question", "1")
    end
  end

  describe "tag detail" do
    test "renders the tagged thread list", %{conn: conn} do
      author = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: author.id})

      {:ok, tag} = Forum.create_tag(%{name: "Question", slug: "question"})
      {:ok, _thread_tag} = Forum.add_tag_to_thread(thread.id, tag.id)

      {:ok, view, _html} = live(conn, "/forum/tags/question")

      assert has_element?(view, "#forum-tag-page")
      assert has_element?(view, "#forum-tag-header")
      assert has_element?(view, "#forum-tag-summary")
      assert has_element?(view, "#forum-tag-thread-count", "1")
      assert has_element?(view, "#forum-tag-management-note")
      refute has_element?(view, "#forum-tag-breadcrumbs")
      assert has_element?(view, "#tag-threads[phx-update='stream']")
      assert has_element?(view, "#tag-threads [data-thread-id='#{thread.id}']")
    end
  end
end
