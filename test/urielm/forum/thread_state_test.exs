defmodule Urielm.Forum.ThreadStateTest do
  use Urielm.DataCase, async: true

  import Urielm.Fixtures

  alias Urielm.Forum

  setup do
    user = user_fixture()
    mod = make_moderator(user_fixture())
    admin = admin_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{board_id: board.id, author_id: user.id})

    %{user: user, mod: mod, admin: admin, thread: thread}
  end

  defp make_moderator(user) do
    user
    |> Ecto.Changeset.change(%{is_moderator: true})
    |> Urielm.Repo.update!()
  end

  describe "lock_thread/2" do
    test "moderator can lock a thread", %{mod: mod, thread: thread} do
      {:ok, locked} = Forum.lock_thread(thread, mod)
      assert locked.is_locked == true
    end

    test "admin can lock a thread", %{admin: admin, thread: thread} do
      {:ok, locked} = Forum.lock_thread(thread, admin)
      assert locked.is_locked == true
    end

    test "regular user cannot lock a thread", %{user: user, thread: thread} do
      assert {:error, :unauthorized} = Forum.lock_thread(thread, user)
    end

    test "locked thread rejects new comments", %{mod: mod, thread: thread} do
      {:ok, locked_thread} = Forum.lock_thread(thread, mod)
      commenter = user_fixture()

      assert {:error, :thread_locked} =
               Forum.create_comment(locked_thread.id, commenter.id, %{"body" => "hello world!"})
    end
  end

  describe "unlock_thread/2" do
    test "moderator can unlock a thread", %{mod: mod, thread: thread} do
      {:ok, locked} = Forum.lock_thread(thread, mod)
      {:ok, unlocked} = Forum.unlock_thread(locked, mod)
      assert unlocked.is_locked == false
    end

    test "regular user cannot unlock a thread", %{user: user, mod: mod, thread: thread} do
      {:ok, locked} = Forum.lock_thread(thread, mod)
      assert {:error, :unauthorized} = Forum.unlock_thread(locked, user)
    end
  end

  describe "pin_thread/2" do
    test "moderator can pin a thread", %{mod: mod, thread: thread} do
      {:ok, pinned} = Forum.pin_thread(thread, mod)
      assert pinned.is_pinned == true
      assert pinned.pinned_at != nil
      assert pinned.pinned_by_id == mod.id
    end

    test "admin can pin a thread", %{admin: admin, thread: thread} do
      {:ok, pinned} = Forum.pin_thread(thread, admin)
      assert pinned.is_pinned == true
    end

    test "regular user cannot pin a thread", %{user: user, thread: thread} do
      assert {:error, :unauthorized} = Forum.pin_thread(thread, user)
    end
  end

  describe "unpin_thread/2" do
    test "moderator can unpin a thread", %{mod: mod, thread: thread} do
      {:ok, pinned} = Forum.pin_thread(thread, mod)
      {:ok, unpinned} = Forum.unpin_thread(pinned, mod)
      assert unpinned.is_pinned == false
      assert unpinned.pinned_at == nil
      assert unpinned.pinned_by_id == nil
    end

    test "regular user cannot unpin a thread", %{user: user, mod: mod, thread: thread} do
      {:ok, pinned} = Forum.pin_thread(thread, mod)
      assert {:error, :unauthorized} = Forum.unpin_thread(pinned, user)
    end
  end

  describe "mark_as_solved/3" do
    test "thread author can mark as solved", %{user: user, thread: thread} do
      comment = comment_fixture(thread, user_fixture())

      {:ok, solved} = Forum.mark_as_solved(thread, comment.id, user)
      assert solved.is_solved == true
      assert solved.solved_comment_id == comment.id
      assert solved.solved_at != nil
      assert solved.solved_by_id == user.id
    end

    test "admin can mark any thread as solved", %{admin: admin, thread: thread} do
      comment = comment_fixture(thread, user_fixture())
      {:ok, solved} = Forum.mark_as_solved(thread, comment.id, admin)
      assert solved.is_solved == true
    end

    test "other user cannot mark thread as solved", %{thread: thread} do
      other = user_fixture()
      comment = comment_fixture(thread, other)
      assert {:error, :unauthorized} = Forum.mark_as_solved(thread, comment.id, other)
    end
  end

  describe "unmark_as_solved/2" do
    test "thread author can unmark as solved", %{user: user, thread: thread} do
      comment = comment_fixture(thread, user_fixture())
      {:ok, solved} = Forum.mark_as_solved(thread, comment.id, user)
      {:ok, unsolved} = Forum.unmark_as_solved(solved, user)

      assert unsolved.is_solved == false
      assert unsolved.solved_comment_id == nil
      assert unsolved.solved_at == nil
      assert unsolved.solved_by_id == nil
    end

    test "other user cannot unmark thread", %{user: user, thread: thread} do
      other = user_fixture()
      comment = comment_fixture(thread, other)
      {:ok, solved} = Forum.mark_as_solved(thread, comment.id, user)
      assert {:error, :unauthorized} = Forum.unmark_as_solved(solved, other)
    end
  end

  describe "set_close_timer/3" do
    test "moderator can set close timer", %{mod: mod, thread: thread} do
      {:ok, updated} = Forum.set_close_timer(thread, 3, mod)
      assert updated.close_at != nil
      assert updated.close_timer_set_by_id == mod.id

      diff = DateTime.diff(updated.close_at, DateTime.utc_now(), :second)
      assert diff > 3 * 86400 - 10
      assert diff <= 3 * 86400
    end

    test "regular user cannot set close timer", %{user: user, thread: thread} do
      assert {:error, :unauthorized} = Forum.set_close_timer(thread, 3, user)
    end

    test "days must be a positive integer", %{mod: mod, thread: thread} do
      assert {:error, :unauthorized} = Forum.set_close_timer(thread, 0, mod)
      assert {:error, :unauthorized} = Forum.set_close_timer(thread, -1, mod)
    end
  end

  describe "clear_close_timer/2" do
    test "moderator can clear close timer", %{mod: mod, thread: thread} do
      {:ok, with_timer} = Forum.set_close_timer(thread, 3, mod)
      {:ok, cleared} = Forum.clear_close_timer(with_timer, mod)

      assert cleared.close_at == nil
      assert cleared.close_timer_set_by_id == nil
    end

    test "regular user cannot clear close timer", %{user: user, mod: mod, thread: thread} do
      {:ok, with_timer} = Forum.set_close_timer(thread, 3, mod)
      assert {:error, :unauthorized} = Forum.clear_close_timer(with_timer, user)
    end
  end

  describe "close_expired_threads/0" do
    test "closes threads whose close_at has passed", %{mod: mod, thread: thread} do
      past = DateTime.utc_now() |> DateTime.add(-1, :second)
      Forum.update_thread(thread, %{close_at: past, close_timer_set_by_id: mod.id})

      count = Forum.close_expired_threads()
      assert count >= 1

      closed = Forum.get_thread!(thread.id)
      assert closed.is_locked == true
    end

    test "does not close threads with future close_at", %{mod: mod, thread: thread} do
      {:ok, _} = Forum.set_close_timer(thread, 7, mod)

      Forum.close_expired_threads()

      still_open = Forum.get_thread!(thread.id)
      assert still_open.is_locked == false
    end

    test "does not close already locked threads", %{mod: mod, thread: thread} do
      past = DateTime.utc_now() |> DateTime.add(-1, :second)

      Forum.update_thread(thread, %{
        close_at: past,
        is_locked: true,
        close_timer_set_by_id: mod.id
      })

      count = Forum.close_expired_threads()
      assert count == 0
    end
  end
end
