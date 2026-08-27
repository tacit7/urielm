defmodule Urielm.Forum.SecurityTest do
  use Urielm.DataCase

  import Urielm.Fixtures

  alias Urielm.Accounts
  alias Urielm.Forum

  describe "create_thread/3 mass assignment (SEC-1)" do
    test "ignores client-supplied moderation fields" do
      board = board_fixture()
      author = user_fixture()

      {:ok, thread} =
        Forum.create_thread(board.id, author.id, %{
          "title" => "A perfectly legit title",
          "slug" => "a-perfectly-legit-title",
          "body" => "This is a legitimate thread body that is long enough.",
          "is_pinned" => true,
          "is_locked" => true,
          "is_removed" => true,
          "is_solved" => true,
          "pinned_by_id" => author.id,
          "solved_by_id" => author.id
        })

      refute thread.is_pinned
      refute thread.is_locked
      refute thread.is_removed
      refute thread.is_solved
      assert is_nil(thread.pinned_by_id)
      assert is_nil(thread.solved_by_id)
    end

    test "Thread.create_changeset does not cast moderation fields" do
      changeset =
        Urielm.Forum.Thread.create_changeset(%Urielm.Forum.Thread{}, %{
          "board_id" => Ecto.UUID.generate(),
          "author_id" => 1,
          "title" => "Title here",
          "slug" => "title-here",
          "body" => "Body content long enough to pass validation.",
          "is_pinned" => true,
          "pinned_by_id" => 2
        })

      refute Map.has_key?(changeset.changes, :is_pinned)
      refute Map.has_key?(changeset.changes, :pinned_by_id)
    end
  end

  describe "silencing enforcement in the Forum context (SEC-2)" do
    test "silenced user cannot create a thread" do
      board = board_fixture()
      admin = admin_fixture()
      user = user_fixture()

      {:ok, user} = Accounts.silence_user(user, admin, reason: "spam")

      assert {:error, :silenced} =
               Forum.create_thread(board.id, user.id, %{
                 "title" => "Trying to post while silenced",
                 "slug" => "trying-to-post-while-silenced",
                 "body" => "This body is long enough to pass validation."
               })
    end

    test "silenced user cannot create a comment" do
      thread = thread_fixture()
      admin = admin_fixture()
      user = user_fixture()

      {:ok, user} = Accounts.silence_user(user, admin, reason: "spam")

      assert {:error, :silenced} =
               Forum.create_comment(thread.id, user.id, %{"body" => "silenced comment attempt"})
    end

    test "non-silenced user can still create a thread and comment" do
      board = board_fixture()
      user = user_fixture()

      assert {:ok, thread} =
               Forum.create_thread(board.id, user.id, %{
                 "title" => "A normal thread title",
                 "slug" => "a-normal-thread-title",
                 "body" => "This body is long enough to pass validation."
               })

      assert {:ok, _comment} =
               Forum.create_comment(thread.id, user.id, %{"body" => "a normal comment"})
    end
  end

  describe "mark_as_solved/3 comment binding (SEC-3)" do
    test "rejects a comment that belongs to another thread" do
      thread = thread_fixture()
      other_thread = thread_fixture()
      author = Accounts.get_user(thread.author_id)
      foreign_comment = comment_fixture(other_thread)

      assert {:error, :invalid_comment} =
               Forum.mark_as_solved(thread, foreign_comment.id, author)

      reloaded = Forum.get_thread!(thread.id)
      refute reloaded.is_solved
      assert is_nil(reloaded.solved_comment_id)
    end

    test "accepts a comment that belongs to the thread" do
      thread = thread_fixture()
      author = Accounts.get_user(thread.author_id)
      comment = comment_fixture(thread)

      assert {:ok, solved} = Forum.mark_as_solved(thread, comment.id, author)
      assert solved.is_solved
      assert solved.solved_comment_id == comment.id
    end
  end
end
