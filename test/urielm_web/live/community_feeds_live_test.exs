defmodule UrielmWeb.CommunityFeedsLiveTest do
  use UrielmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  test "discussions and news have separate feeds and navigation", %{conn: conn} do
    member = thread_fixture()
    news_board = board_fixture(%{slug: "ai-news", name: "AI News"})
    news = thread_fixture(%{board_id: news_board.id})

    {:ok, view, _} = live(conn, "/forum")
    assert has_element?(view, "#threads-#{member.id}")
    refute has_element?(view, "#threads-#{news.id}")

    assert has_element?(
             view,
             "#forum-view-tabs a[href='/forum'][aria-current='page']",
             "Discussions"
           )

    assert has_element?(view, "#forum-view-tabs a[href='/forum/news']", "News")

    {:ok, news_view, _} = live(conn, "/forum/news")
    assert has_element?(news_view, "#threads-#{news.id}")
    refute has_element?(news_view, "#threads-#{member.id}")
    assert has_element?(news_view, "#forum-view-tabs a[href='/forum/news'][aria-current='page']")
    render_patch(news_view, "/forum/news?page=1")
    assert has_element?(news_view, "#threads-#{news.id}")
    refute has_element?(news_view, "#threads-#{member.id}")
  end

  test "news has an honest empty state when there is no news board", %{conn: conn} do
    {:ok, view, _} = live(conn, "/forum/news")
    assert has_element?(view, "#empty-state", "No news yet")
  end

  test "feed filtering happens before pagination and hides removed news" do
    params = %{page_size: 1, order_by: [:updated_at, :id], order_directions: [:desc, :desc]}
    {:ok, {_, baseline}} = Urielm.Forum.paginate_latest_threads(params)
    member = thread_fixture()
    news_board = board_fixture(%{slug: "ai-news"})
    news = thread_fixture(%{board_id: news_board.id})
    thread_fixture(%{board_id: news_board.id, is_removed: true})

    assert {:ok, {[discussion], meta}} =
             Urielm.Forum.paginate_latest_threads(params, feed: :discussions)

    assert discussion.id == member.id
    assert meta.total_count == baseline.total_count + 1

    assert {:ok, {[item], news_meta}} =
             Urielm.Forum.paginate_latest_threads(params, feed: :news)

    assert item.id == news.id
    assert news_meta.total_count == 1
  end
end
