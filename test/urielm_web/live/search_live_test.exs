defmodule UrielmWeb.SearchLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Forum

  setup do
    user = user_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})

    thread =
      thread_fixture(%{
        board_id: board.id,
        author_id: user.id,
        title: "How to bake sourdough bread",
        body: "A comprehensive guide to sourdough fermentation and baking techniques."
      })

    %{user: user, board: board, thread: thread}
  end

  describe "mount" do
    test "loads empty state without query", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/forum/search")
      assert html =~ "Search"
    end

    test "loads results with ?q= param", %{conn: conn, thread: thread} do
      {:ok, _live, html} = live(conn, "/forum/search?q=sourdough")
      assert html =~ thread.title
    end

    test "shows no results for unmatched query", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/forum/search?q=zzznomatch999xyz")
      refute html =~ "sourdough"
    end
  end

  describe "search event" do
    test "pushes patch with query param", %{conn: conn} do
      {:ok, live, _html} = live(conn, "/forum/search")

      render_click(live, "search", %{"query" => "sourdough"})

      html = render(live)
      assert html =~ "sourdough"
    end

    test "empty search clears results", %{conn: conn} do
      {:ok, live, _html} = live(conn, "/forum/search?q=sourdough")

      render_click(live, "search", %{"query" => ""})

      html = render(live)
      refute html =~ "sourdough"
    end
  end

  describe "save_thread from search" do
    test "authenticated user can save a thread from results", %{conn: conn, user: user, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, user), "/forum/search?q=sourdough")

      render_click(live, "save_thread", %{"thread_id" => to_string(thread.id)})

      assert Forum.is_thread_saved?(user.id, thread.id)
    end
  end

  describe "subscribe from search" do
    test "authenticated user can subscribe to a thread from results", %{conn: conn, user: user, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, user), "/forum/search?q=sourdough")

      render_click(live, "subscribe", %{"thread_id" => to_string(thread.id)})

      assert Forum.is_subscribed?(user.id, thread.id)
    end
  end

  describe "pagination" do
    test "page param is respected", %{conn: conn, board: board, user: user} do
      for i <- 1..25 do
        thread_fixture(%{
          board_id: board.id,
          author_id: user.id,
          title: "Search result #{i}",
          body: "Body about searchable content number #{i} in the forum.",
          slug: "search-result-#{i}"
        })
      end

      {:ok, _live, html1} = live(conn, "/forum/search?q=searchable&page=1")
      {:ok, _live, html2} = live(conn, "/forum/search?q=searchable&page=2")

      assert html1 =~ "Search"
      assert html2 =~ "Search"
    end
  end

  describe "anonymous user" do
    test "can search without being logged in", %{conn: conn, thread: thread} do
      {:ok, _live, html} = live(conn, "/forum/search?q=sourdough")
      assert html =~ thread.title
    end
  end
end
