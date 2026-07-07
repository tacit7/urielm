defmodule Urielm.Forum.SavedCommentsTest do
  use Urielm.DataCase, async: true

  import Urielm.Fixtures

  alias Urielm.Forum

  setup do
    user = user_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{board_id: board.id, author_id: user.id})
    comment = comment_fixture(thread, user)

    %{user: user, thread: thread, comment: comment}
  end

  describe "save_comment/2" do
    test "saves a comment for a user", %{user: user, comment: comment} do
      {:ok, saved} = Forum.save_comment(user.id, comment.id)
      assert saved.user_id == user.id
      assert saved.comment_id == comment.id
    end

    test "enforces unique constraint per user per comment", %{user: user, comment: comment} do
      {:ok, _} = Forum.save_comment(user.id, comment.id)
      {:error, changeset} = Forum.save_comment(user.id, comment.id)
      assert changeset.errors[:user_id] || changeset.errors[:comment_id]
    end

    test "different users can save the same comment", %{comment: comment} do
      user2 = user_fixture()
      user3 = user_fixture()

      assert {:ok, _} = Forum.save_comment(user2.id, comment.id)
      assert {:ok, _} = Forum.save_comment(user3.id, comment.id)
    end
  end

  describe "unsave_comment/2" do
    test "removes a saved comment", %{user: user, comment: comment} do
      {:ok, _} = Forum.save_comment(user.id, comment.id)
      {:ok, _} = Forum.unsave_comment(user.id, comment.id)

      refute Forum.comment_saved?(user.id, comment.id)
    end

    test "returns error if comment not saved", %{user: user, comment: comment} do
      assert {:error, :not_found} = Forum.unsave_comment(user.id, comment.id)
    end
  end

  describe "comment_saved?/2" do
    test "returns true when comment is saved", %{user: user, comment: comment} do
      Forum.save_comment(user.id, comment.id)
      assert Forum.comment_saved?(user.id, comment.id)
    end

    test "returns false when comment is not saved", %{user: user, comment: comment} do
      refute Forum.comment_saved?(user.id, comment.id)
    end
  end

  describe "toggle_save_comment/2" do
    test "saves when not saved", %{user: user, comment: comment} do
      {:ok, _} = Forum.toggle_save_comment(user.id, comment.id)
      assert Forum.comment_saved?(user.id, comment.id)
    end

    test "unsaves when already saved", %{user: user, comment: comment} do
      Forum.save_comment(user.id, comment.id)
      {:ok, _} = Forum.toggle_save_comment(user.id, comment.id)
      refute Forum.comment_saved?(user.id, comment.id)
    end
  end

  describe "list_saved_comments/2" do
    test "returns user's saved comments", %{user: user, thread: thread} do
      comment1 = comment_fixture(thread, user)
      comment2 = comment_fixture(thread, user)
      Forum.save_comment(user.id, comment1.id)
      Forum.save_comment(user.id, comment2.id)

      saved = Forum.list_saved_comments(user.id)
      saved_ids = Enum.map(saved, & &1.id)

      assert comment1.id in saved_ids
      assert comment2.id in saved_ids
    end

    test "excludes removed comments", %{user: user, thread: thread} do
      comment = comment_fixture(thread, user)
      Forum.save_comment(user.id, comment.id)
      Forum.remove_comment(comment, user)

      saved = Forum.list_saved_comments(user.id)
      refute Enum.any?(saved, &(&1.id == comment.id))
    end

    test "does not return other users' saved comments", %{user: user, thread: thread} do
      other = user_fixture()
      comment = comment_fixture(thread, other)
      Forum.save_comment(other.id, comment.id)

      saved = Forum.list_saved_comments(user.id)
      refute Enum.any?(saved, &(&1.id == comment.id))
    end

    test "respects limit and offset", %{user: user, thread: thread} do
      for _ <- 1..5, do: Forum.save_comment(user.id, comment_fixture(thread, user).id)

      page1 = Forum.list_saved_comments(user.id, limit: 3, offset: 0)
      page2 = Forum.list_saved_comments(user.id, limit: 3, offset: 3)

      assert length(page1) == 3
      assert length(page2) == 2
    end
  end

  describe "count_saved_comments/1" do
    test "returns count of saved comments", %{user: user, thread: thread} do
      assert Forum.count_saved_comments(user.id) == 0

      for _ <- 1..3, do: Forum.save_comment(user.id, comment_fixture(thread, user).id)

      assert Forum.count_saved_comments(user.id) == 3
    end
  end
end
