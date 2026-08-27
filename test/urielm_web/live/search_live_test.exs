defmodule UrielmWeb.SearchLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Forum
  alias Urielm.Forum.Thread
  alias Urielm.Repo

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
      {:ok, view, _html} = live(conn, "/forum/search")

      assert has_element?(view, "#forum-search-page")
      assert has_element?(view, "#forum-search-header.ui-page-header")
      assert has_element?(view, "#forum-search-surface.ui-card")
      assert has_element?(view, "#forum-search-form")
      assert has_element?(view, "#forum-search-query")
      assert has_element?(view, "#forum-search-submit[phx-disable-with='Searching…']")
      assert has_element?(view, "#forum-search-advanced-row")
      assert has_element?(view, "#forum-search-author")
      assert has_element?(view, "#forum-search-category")
      assert has_element?(view, "#forum-search-from-date")
      assert has_element?(view, "#forum-search-to-date")
      assert has_element?(view, "#search-start-state[data-ui-state='empty']")
    end

    test "loads results with ?q= param", %{conn: conn, thread: thread} do
      {:ok, view, _html} = live(conn, "/forum/search?q=sourdough")

      assert has_element?(view, result_selector(thread))
    end

    test "shows no results for unmatched query", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/forum/search?q=zzznomatch999xyz")

      assert has_element?(view, "#search-empty-state[data-ui-state='empty']")
    end
  end

  describe "advanced search" do
    test "filters by author, category, and date range", %{conn: conn, board: board} do
      target_author =
        user_fixture(%{username: "target-filter-user", display_name: "Target Filter User"})

      other_author =
        user_fixture(%{username: "other-filter-user", display_name: "Other Filter User"})

      other_category = category_fixture(%{name: "Other Category"})
      other_board = board_fixture(%{category_id: other_category.id})

      target_thread =
        thread_fixture(%{
          board_id: board.id,
          author_id: target_author.id,
          title: "Phoenix Search Target",
          body: "A searchable thread for advanced forum search coverage."
        })

      author_distractor =
        thread_fixture(%{
          board_id: board.id,
          author_id: other_author.id,
          title: "Phoenix Search Distractor",
          body: "A searchable thread from a different author."
        })

      category_distractor =
        thread_fixture(%{
          board_id: other_board.id,
          author_id: target_author.id,
          title: "Phoenix Search Category Distractor",
          body: "A searchable thread in the wrong category."
        })

      old_distractor =
        thread_fixture(%{
          board_id: board.id,
          author_id: target_author.id,
          title: "Phoenix Search Old Distractor",
          body: "A searchable thread outside the selected date range."
        })

      old_date = DateTime.utc_now() |> DateTime.add(-30, :day) |> DateTime.truncate(:second)

      Repo.update_all(
        from(t in Thread, where: t.id == ^old_distractor.id),
        set: [inserted_at: old_date, updated_at: old_date]
      )

      from_date = Date.utc_today() |> Date.add(-7) |> Date.to_iso8601()
      to_date = Date.utc_today() |> Date.to_iso8601()

      {:ok, view, _html} = live(conn, "/forum/search")

      render_submit(
        form(view, "#forum-search-form", %{
          "query" => "Phoenix",
          "author" => "target-filter",
          "category_id" => to_string(board.category_id),
          "from_date" => from_date,
          "to_date" => to_date
        })
      )

      assert has_element?(view, result_selector(target_thread))
      refute has_element?(view, result_selector(author_distractor))
      refute has_element?(view, result_selector(category_distractor))
      refute has_element?(view, result_selector(old_distractor))
    end
  end

  describe "save_thread from search" do
    test "authenticated user can save a thread from results", %{
      conn: conn,
      user: user,
      thread: thread
    } do
      {:ok, live, _html} = live(log_in_user(conn, user), "/forum/search?q=sourdough")

      render_click(live, "save_thread", %{"thread_id" => to_string(thread.id)})

      assert Forum.thread_saved?(user.id, thread.id)
    end
  end

  describe "subscribe from search" do
    test "authenticated user can subscribe to a thread from results", %{
      conn: conn,
      user: user,
      thread: thread
    } do
      {:ok, live, _html} = live(log_in_user(conn, user), "/forum/search?q=sourdough")

      render_click(live, "subscribe", %{"thread_id" => to_string(thread.id)})

      assert Forum.subscribed?(user.id, thread.id)
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
      {:ok, view, _html} = live(conn, "/forum/search?q=sourdough")
      assert has_element?(view, result_selector(thread))
    end
  end

  defp result_selector(thread), do: "div[id='results-#{thread.id}']"
end
