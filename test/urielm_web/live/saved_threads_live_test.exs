defmodule UrielmWeb.SavedThreadsLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Forum

  setup do
    user = user_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{board_id: board.id, author_id: user.id})

    %{user: user, board: board, thread: thread}
  end

  describe "access control" do
    test "redirects unauthenticated users", %{conn: conn} do
      assert {:error, {:redirect, _}} = live(conn, "/saved")
    end

    test "authenticated user can access saved threads", %{conn: conn, user: user} do
      {:ok, _live, html} = live(log_in_user(conn, user), "/saved")
      assert html =~ "Saved"
    end
  end

  describe "listing saved threads" do
    test "shows saved threads for current user", %{conn: conn, user: user, thread: thread} do
      Forum.save_thread(user.id, thread.id)

      {:ok, _live, html} = live(log_in_user(conn, user), "/saved")
      assert html =~ thread.title
    end

    test "shows empty state when no saved threads", %{conn: conn, user: user} do
      {:ok, view, _html} = live(log_in_user(conn, user), "/saved")

      assert has_element?(view, "#saved-threads-empty-state[data-ui-state='empty']")
    end

    test "does not show other users' saved threads", %{conn: conn, user: user, thread: thread} do
      other = user_fixture()
      Forum.save_thread(other.id, thread.id)

      {:ok, _live, html} = live(log_in_user(conn, user), "/saved")
      refute html =~ thread.title
    end

    test "shows multiple saved threads", %{conn: conn, user: user, board: board} do
      thread2 =
        thread_fixture(%{
          board_id: board.id,
          author_id: user.id,
          title: "Second Thread",
          slug: "second-thread"
        })

      thread3 =
        thread_fixture(%{
          board_id: board.id,
          author_id: user.id,
          title: "Third Thread",
          slug: "third-thread"
        })

      Forum.save_thread(user.id, thread2.id)
      Forum.save_thread(user.id, thread3.id)

      {:ok, _live, html} = live(log_in_user(conn, user), "/saved")
      assert html =~ "Second Thread"
      assert html =~ "Third Thread"
    end
  end

  describe "unsave_thread event" do
    test "removes thread from saved list", %{conn: conn, user: user, thread: thread} do
      Forum.save_thread(user.id, thread.id)

      {:ok, live, _html} = live(log_in_user(conn, user), "/saved")

      render_click(live, "unsave_thread", %{"thread_id" => to_string(thread.id)})

      refute Forum.thread_saved?(user.id, thread.id)
    end
  end

  describe "subscribe event" do
    test "subscribes user to thread notifications", %{conn: conn, user: user, thread: thread} do
      Forum.save_thread(user.id, thread.id)

      {:ok, live, _html} = live(log_in_user(conn, user), "/saved")

      render_click(live, "subscribe", %{"thread_id" => to_string(thread.id)})

      assert Forum.subscribed?(user.id, thread.id)
    end
  end

  describe "unsubscribe event" do
    test "unsubscribes user from thread notifications", %{conn: conn, user: user, thread: thread} do
      Forum.save_thread(user.id, thread.id)
      Forum.subscribe_to_thread(user.id, thread.id)

      {:ok, live, _html} = live(log_in_user(conn, user), "/saved")

      render_click(live, "unsubscribe", %{"thread_id" => to_string(thread.id)})

      refute Forum.subscribed?(user.id, thread.id)
    end
  end
end
