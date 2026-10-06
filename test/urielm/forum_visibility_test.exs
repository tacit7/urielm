defmodule Urielm.ForumVisibilityTest do
  use Urielm.DataCase
  import Urielm.Fixtures
  alias Urielm.{Forum, Repo}

  test "fixes populated hidden boards and categories leaking through public reads" do
    for hidden_parent <- [:board, :category] do
      user = user_fixture()
      category = category_fixture()
      board = board_fixture(%{category_id: category.id})
      thread = thread_fixture(%{board_id: board.id, author_id: user.id})
      comment = comment_fixture(thread, user)
      visible = thread_fixture(%{author_id: user.id})
      Forum.save_thread(user.id, thread.id)
      Forum.save_comment(user.id, comment.id)
      Forum.subscribe_to_thread(user.id, thread.id)

      Forum.create_notification(user.id, "comment", comment.id, %{
        thread_id: thread.id,
        message: thread.title
      })

      {:ok, tag} = Forum.create_tag(%{name: "Tag", slug: "tag-#{board.id}"})
      Forum.add_tag_to_thread(thread.id, tag.id)

      {:ok, legacy} =
        Forum.create_notification(user.id, "mention", comment.id, %{message: "Hidden excerpt"})

      parent = if hidden_parent == :board, do: board, else: category
      parent |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()

      assert_raise Ecto.NoResultsError, fn -> Forum.get_thread!(thread.id) end
      assert_raise Ecto.NoResultsError, fn -> Forum.get_board!(board.slug) end
      assert Forum.get_thread(thread.id, viewer: user, allow_removed?: true) == nil
      assert Forum.list_boards(category.id) == []
      assert Forum.list_related_threads(thread) == []
      assert Forum.search_threads("", board_id: board.id) == []
      assert Forum.list_threads_by_tag(tag.id) == []
      assert Forum.count_threads_by_tag(tag.id) == 0
      assert Forum.list_thread_tags(thread.id) == []
      assert Enum.find(Forum.list_tags_with_counts(), &(&1.id == tag.id)).thread_count == 0
      assert {:error, :not_found} = Forum.mark_notification_as_read(user.id, legacy.id)
      assert Forum.get_board(board.slug) == nil
      assert Forum.get_thread(thread.id) == nil
      assert Forum.get_comment(comment.id) == nil
      assert Forum.list_comments(thread.id) == []
      assert Forum.list_threads(board.id) == []
      assert Forum.list_latest_threads(board.id) == []
      assert Forum.list_new_threads(user.id, board.id) == []
      assert Forum.list_unread_threads(user.id, board.id) == []
      assert Forum.list_saved_threads(user.id) == []
      assert Forum.list_saved_comments(user.id) == []
      assert Forum.list_subscriptions(user.id) == []
      assert Forum.list_notifications(user.id) == []
      assert Forum.count_saved_threads(user.id) == 0
      assert Forum.count_saved_comments(user.id) == 0
      assert Forum.count_subscriptions(user.id) == 0
      assert Forum.count_unread_notifications(user.id) == 0
      assert Enum.map(Forum.list_threads_by_author(user.id), & &1.id) == [visible.id]
      assert Forum.count_threads_by_author(user.id) == 1
      assert Forum.count_comments_by_author(user.id) == 0
      assert Forum.list_comments_by_author(user.id) == []
      assert {:ok, {[], _}} = Forum.paginate_search_threads("", %{}, board_id: board.id)
      assert {:ok, {[], _}} = Forum.paginate_threads_by_tag(tag.id)
      assert {:ok, {[], _}} = Forum.paginate_new_threads(board.id)
      assert {:ok, {[], _}} = Forum.paginate_unread_threads(user.id, board.id)
      assert {:ok, {[public_thread], author_meta}} = Forum.paginate_threads_by_author(user.id)
      assert public_thread.id == visible.id
      assert author_meta.total_count == 1
      assert {:ok, {[], meta}} = Forum.paginate_threads(board.id)
      assert meta.total_count == 0
      assert {:ok, {[], _}} = Forum.paginate_saved_threads(user.id)
      assert {:ok, {[], _}} = Forum.paginate_comments_by_author(user.id)
      refute MapSet.member?(Forum.bulk_unread_thread_ids(user.id, [thread.id]), thread.id)
    end
  end

  test "fixes hidden direct reads requiring an explicit current persisted administrator" do
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{board_id: board.id})
    comment = comment_fixture(thread)
    admin = admin_fixture()
    board |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()

    assert Forum.get_thread(thread.id, viewer: admin, include_comments?: true).comments
           |> Enum.map(& &1.id) == [comment.id]

    assert Forum.get_board(board.slug, viewer: admin).id == board.id
    assert Forum.get_comment(comment.id, viewer: admin).id == comment.id
    assert Forum.get_thread(thread.id) == nil

    for attrs <- [
          %{is_admin: false},
          %{active: false},
          %{suspended_at: DateTime.utc_now() |> DateTime.truncate(:second)}
        ] do
      admin
      |> Ecto.Changeset.change(
        Map.merge(%{is_admin: true, active: true, suspended_at: nil}, attrs)
      )
      |> Repo.update!()

      assert Forum.get_thread(thread.id, viewer: admin) == nil
      assert Forum.get_board(board.slug, viewer: admin) == nil
      assert Forum.get_comment(comment.id, viewer: admin) == nil
    end
  end

  test "fixes revision body and count exposure after forum category is hidden" do
    user = user_fixture()
    category = category_fixture()
    board = board_fixture(%{category_id: category.id})
    thread = thread_fixture(%{author_id: user.id, board_id: board.id})
    comment = comment_fixture(thread, user)
    assert {:ok, _} = Forum.edit_thread(thread, "Hidden thread revision", user)
    assert {:ok, _} = Forum.edit_comment(comment, "Hidden comment revision", user)
    category |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()
    assert Forum.list_revisions("thread", thread.id) == []
    assert Forum.list_revisions("comment", comment.id) == []
    assert Forum.count_revisions("thread", thread.id) == 0
    assert Forum.count_revisions("comment", comment.id) == 0
  end
end
