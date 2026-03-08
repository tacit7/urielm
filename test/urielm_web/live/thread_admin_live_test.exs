defmodule UrielmWeb.ThreadAdminLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Forum

  setup do
    author = user_fixture()
    mod = make_moderator(user_fixture())
    admin = admin_fixture()
    regular = user_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{board_id: board.id, author_id: author.id})
    comment = comment_fixture(thread, regular)

    %{
      author: author,
      mod: mod,
      admin: admin,
      regular: regular,
      thread: thread,
      comment: comment
    }
  end

  defp make_moderator(user) do
    user
    |> Ecto.Changeset.change(%{is_moderator: true})
    |> Urielm.Repo.update!()
  end

  describe "lock_thread event" do
    test "moderator can lock a thread", %{conn: conn, mod: mod, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, mod), "/forum/t/#{thread.id}")

      render_click(live, "lock_thread", %{})

      assert Forum.get_thread!(thread.id).is_locked == true
    end

    test "admin can lock a thread", %{conn: conn, admin: admin, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, admin), "/forum/t/#{thread.id}")

      render_click(live, "lock_thread", %{})

      assert Forum.get_thread!(thread.id).is_locked == true
    end

    test "regular user cannot lock a thread", %{conn: conn, regular: regular, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, regular), "/forum/t/#{thread.id}")

      render_click(live, "lock_thread", %{})

      assert Forum.get_thread!(thread.id).is_locked == false
    end

    test "locked thread shows locked indicator", %{conn: conn, mod: mod, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, mod), "/forum/t/#{thread.id}")

      html = render_click(live, "lock_thread", %{})

      assert html =~ "locked" or html =~ "Locked"
    end
  end

  describe "unlock_thread event" do
    test "moderator can unlock a locked thread", %{conn: conn, mod: mod, thread: thread} do
      Forum.lock_thread(thread, mod)

      {:ok, live, _html} = live(log_in_user(conn, mod), "/forum/t/#{thread.id}")

      render_click(live, "unlock_thread", %{})

      assert Forum.get_thread!(thread.id).is_locked == false
    end

    test "regular user cannot unlock a thread", %{conn: conn, mod: mod, regular: regular, thread: thread} do
      Forum.lock_thread(thread, mod)

      {:ok, live, _html} = live(log_in_user(conn, regular), "/forum/t/#{thread.id}")

      render_click(live, "unlock_thread", %{})

      assert Forum.get_thread!(thread.id).is_locked == true
    end
  end

  describe "pin_thread event" do
    test "moderator can pin a thread", %{conn: conn, mod: mod, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, mod), "/forum/t/#{thread.id}")

      render_click(live, "pin_thread", %{})

      assert Forum.get_thread!(thread.id).is_pinned == true
    end

    test "admin can pin a thread", %{conn: conn, admin: admin, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, admin), "/forum/t/#{thread.id}")

      render_click(live, "pin_thread", %{})

      assert Forum.get_thread!(thread.id).is_pinned == true
    end

    test "regular user cannot pin a thread", %{conn: conn, regular: regular, thread: thread} do
      {:ok, live, _html} = live(log_in_user(conn, regular), "/forum/t/#{thread.id}")

      render_click(live, "pin_thread", %{})

      assert Forum.get_thread!(thread.id).is_pinned == false
    end
  end

  describe "unpin_thread event" do
    test "moderator can unpin a thread", %{conn: conn, mod: mod, thread: thread} do
      Forum.pin_thread(thread, mod)

      {:ok, live, _html} = live(log_in_user(conn, mod), "/forum/t/#{thread.id}")

      render_click(live, "unpin_thread", %{})

      assert Forum.get_thread!(thread.id).is_pinned == false
    end
  end

  describe "mark_solved event" do
    test "thread author can mark a comment as the solution", %{conn: conn, author: author, thread: thread, comment: comment} do
      {:ok, live, _html} = live(log_in_user(conn, author), "/forum/t/#{thread.id}")

      render_click(live, "mark_solved", %{"comment_id" => to_string(comment.id)})

      solved = Forum.get_thread!(thread.id)
      assert solved.is_solved == true
      assert solved.solved_comment_id == comment.id
    end

    test "admin can mark any thread as solved", %{conn: conn, admin: admin, thread: thread, comment: comment} do
      {:ok, live, _html} = live(log_in_user(conn, admin), "/forum/t/#{thread.id}")

      render_click(live, "mark_solved", %{"comment_id" => to_string(comment.id)})

      assert Forum.get_thread!(thread.id).is_solved == true
    end

    test "non-author cannot mark thread as solved", %{conn: conn, regular: regular, thread: thread, comment: comment} do
      {:ok, live, _html} = live(log_in_user(conn, regular), "/forum/t/#{thread.id}")

      render_click(live, "mark_solved", %{"comment_id" => to_string(comment.id)})

      assert Forum.get_thread!(thread.id).is_solved == false
    end

    test "solved thread shows solved indicator", %{conn: conn, author: author, thread: thread, comment: comment} do
      {:ok, live, _html} = live(log_in_user(conn, author), "/forum/t/#{thread.id}")

      html = render_click(live, "mark_solved", %{"comment_id" => to_string(comment.id)})

      assert html =~ "solved" or html =~ "Solved"
    end
  end

  describe "unmark_solved event" do
    test "thread author can unmark solved", %{conn: conn, author: author, thread: thread, comment: comment} do
      Forum.mark_as_solved(thread, comment.id, author)

      {:ok, live, _html} = live(log_in_user(conn, author), "/forum/t/#{thread.id}")

      render_click(live, "unmark_solved", %{})

      unsolved = Forum.get_thread!(thread.id)
      assert unsolved.is_solved == false
      assert unsolved.solved_comment_id == nil
    end

    test "non-author cannot unmark solved", %{conn: conn, author: author, regular: regular, thread: thread, comment: comment} do
      Forum.mark_as_solved(thread, comment.id, author)

      {:ok, live, _html} = live(log_in_user(conn, regular), "/forum/t/#{thread.id}")

      render_click(live, "unmark_solved", %{})

      assert Forum.get_thread!(thread.id).is_solved == true
    end
  end

  describe "mod controls visibility" do
    test "moderator sees lock/pin controls", %{conn: conn, mod: mod, thread: thread} do
      {:ok, _live, html} = live(log_in_user(conn, mod), "/forum/t/#{thread.id}")
      assert html =~ "lock_thread" or html =~ "Lock"
      assert html =~ "pin_thread" or html =~ "Pin"
    end

    test "regular user does not see mod controls", %{conn: conn, regular: regular, thread: thread} do
      {:ok, _live, html} = live(log_in_user(conn, regular), "/forum/t/#{thread.id}")
      refute html =~ "lock_thread"
      refute html =~ "pin_thread"
    end

    test "author sees delete control on their thread", %{conn: conn, author: author, thread: thread} do
      {:ok, _live, html} = live(log_in_user(conn, author), "/forum/t/#{thread.id}")
      assert html =~ "delete_thread"
    end
  end
end
