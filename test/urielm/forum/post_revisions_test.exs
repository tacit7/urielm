defmodule Urielm.Forum.PostRevisionsTest do
  use Urielm.DataCase, async: true

  import Urielm.Fixtures

  alias Urielm.Forum

  setup do
    author = user_fixture()
    admin = admin_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{board_id: board.id, author_id: author.id})
    comment = comment_fixture(thread, author)

    %{author: author, admin: admin, thread: thread, comment: comment}
  end

  describe "edit_thread/3" do
    test "author can edit their thread body", %{author: author, thread: thread} do
      {:ok, updated} = Forum.edit_thread(thread, "Updated body content here.", author)
      assert updated.body == "Updated body content here."
      assert updated.edited_at != nil
    end

    test "admin can edit any thread", %{admin: admin, thread: thread} do
      {:ok, updated} = Forum.edit_thread(thread, "Admin edited this content.", admin)
      assert updated.body == "Admin edited this content."
    end

    test "other user cannot edit thread", %{thread: thread} do
      other = user_fixture()
      assert {:error, :unauthorized} = Forum.edit_thread(thread, "Nope.", other)
    end

    test "edit creates a post revision record", %{author: author, thread: thread} do
      original_body = thread.body
      {:ok, _} = Forum.edit_thread(thread, "New body after edit.", author)

      revisions = Forum.list_revisions("thread", thread.id)
      assert length(revisions) == 1

      [rev] = revisions
      assert rev.body_before == original_body
      assert rev.body_after == "New body after edit."
      assert rev.editor_id == author.id
      assert rev.revision_number == 1
    end

    test "multiple edits increment revision numbers", %{author: author, thread: thread} do
      {:ok, v2} = Forum.edit_thread(thread, "Second version.", author)
      {:ok, _v3} = Forum.edit_thread(v2, "Third version.", author)

      assert Forum.count_revisions("thread", thread.id) == 2

      revisions = Forum.list_revisions("thread", thread.id)
      numbers = Enum.map(revisions, & &1.revision_number)
      assert Enum.sort(numbers) == [1, 2]
    end
  end

  describe "edit_comment/3" do
    test "author can edit their comment body", %{author: author, comment: comment} do
      {:ok, updated} = Forum.edit_comment(comment, "Edited comment text here.", author)
      assert updated.body == "Edited comment text here."
      assert updated.edited_at != nil
    end

    test "admin can edit any comment", %{admin: admin, comment: comment} do
      {:ok, updated} = Forum.edit_comment(comment, "Admin edited.", admin)
      assert updated.body == "Admin edited."
    end

    test "other user cannot edit comment", %{comment: comment} do
      other = user_fixture()
      assert {:error, :unauthorized} = Forum.edit_comment(comment, "Nope.", other)
    end

    test "edit creates a post revision record", %{author: author, comment: comment} do
      original_body = comment.body
      {:ok, _} = Forum.edit_comment(comment, "Revised comment.", author)

      revisions = Forum.list_revisions("comment", comment.id)
      assert length(revisions) == 1

      [rev] = revisions
      assert rev.body_before == original_body
      assert rev.body_after == "Revised comment."
      assert rev.editor_id == author.id
      assert rev.target_type == "comment"
    end
  end

  describe "list_revisions/2" do
    test "returns revisions in descending order by revision number", %{author: author, thread: thread} do
      {:ok, v2} = Forum.edit_thread(thread, "Version two.", author)
      {:ok, _v3} = Forum.edit_thread(v2, "Version three.", author)

      revisions = Forum.list_revisions("thread", thread.id)
      assert length(revisions) == 2
      assert hd(revisions).revision_number == 2
    end

    test "returns empty list for unedited content", %{thread: thread} do
      assert Forum.list_revisions("thread", thread.id) == []
    end

    test "does not mix thread and comment revisions", %{author: author, thread: thread, comment: comment} do
      {:ok, _} = Forum.edit_thread(thread, "Edited thread.", author)
      {:ok, _} = Forum.edit_comment(comment, "Edited comment.", author)

      thread_revs = Forum.list_revisions("thread", thread.id)
      comment_revs = Forum.list_revisions("comment", comment.id)

      assert length(thread_revs) == 1
      assert length(comment_revs) == 1
      assert hd(thread_revs).target_type == "thread"
      assert hd(comment_revs).target_type == "comment"
    end
  end

  describe "count_revisions/2" do
    test "returns 0 for unedited content", %{thread: thread} do
      assert Forum.count_revisions("thread", thread.id) == 0
    end

    test "returns correct count after edits", %{author: author, thread: thread} do
      {:ok, v2} = Forum.edit_thread(thread, "Edit one, first version.", author)
      assert Forum.count_revisions("thread", thread.id) == 1
      {:ok, _} = Forum.edit_thread(v2, "Edit two, second version.", author)
      assert Forum.count_revisions("thread", thread.id) == 2
    end
  end
end
