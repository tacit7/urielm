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
      fresh_admin =
        Repo.get!(Urielm.Accounts.User, admin.id)
        |> Ecto.Changeset.change(is_admin: true, active: true, suspended_at: nil)
        |> Repo.update!()

      assert Forum.get_thread(thread.id, viewer: fresh_admin).id == thread.id

      fresh_admin
      |> Ecto.Changeset.change(attrs)
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

  test "fixes hidden forum mutations through saved client identifiers" do
    for hidden_parent <- [:board, :category] do
      user = user_fixture()
      category = category_fixture()
      board = board_fixture(%{category_id: category.id})
      thread = thread_fixture(%{board_id: board.id, author_id: user.id})
      comment = comment_fixture(thread, user)
      assert {:ok, _} = Forum.save_thread(user.id, thread.id)
      assert {:ok, _} = Forum.save_comment(user.id, comment.id)
      assert {:ok, _} = Forum.subscribe_to_thread(user.id, thread.id)
      assert {:ok, _} = Forum.cast_vote(user.id, "thread", thread.id, 1)
      parent = if hidden_parent == :board, do: board, else: category
      parent |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()

      assert {:error, :not_found} = Forum.unsave_thread(user.id, thread.id)
      assert {:error, :not_found} = Forum.unsave_comment(user.id, comment.id)
      assert {:error, :not_found} = Forum.unsubscribe_from_thread(user.id, thread.id)
      assert {:error, :not_found} = Forum.save_thread(user.id, thread.id)
      assert {:error, :not_found} = Forum.toggle_save_thread(user.id, thread.id)
      assert {:error, :not_found} = Forum.save_comment(user.id, comment.id)
      assert {:error, :not_found} = Forum.toggle_save_comment(user.id, comment.id)
      assert {:error, :not_found} = Forum.subscribe_to_thread(user.id, thread.id)
      assert {:error, :not_found} = Forum.cast_vote(user.id, "thread", thread.id, 1)
      assert {:error, :not_found} = Forum.cast_vote(user.id, "comment", comment.id, 1)
      assert {:error, :not_found} = Urielm.Engagement.toggle_vote(user.id, "thread", thread.id, 1)
      assert {:error, :not_found} = Urielm.Engagement.cast_vote(user.id, "comment", comment.id, 1)
      assert {:error, :not_found} = Urielm.Engagement.unvote(user.id, "thread", thread.id)
      assert {:error, :not_found} = Forum.edit_thread(thread, "Changed", user)
      assert {:error, :not_found} = Forum.remove_thread(thread, user)
      assert {:error, :not_found} = Forum.mark_as_solved(thread, comment.id, user)
      assert {:error, :not_found} = Forum.unmark_as_solved(thread, user)
      assert {:error, :not_found} = Forum.unvote(user.id, "thread", thread.id)
      assert {:error, :not_found} = Forum.edit_comment(comment, "Changed", user)
      assert {:error, :not_found} = Forum.remove_comment(comment, user)
      assert Repo.get!(Urielm.Forum.Thread, thread.id).score == 1
      assert Repo.get!(Urielm.Forum.Comment, comment.id).body == comment.body
      assert Repo.get_by!(Urielm.Forum.SavedThread, user_id: user.id, thread_id: thread.id)
      assert Repo.get_by!(Urielm.Forum.SavedComment, user_id: user.id, comment_id: comment.id)
      assert Repo.get_by!(Urielm.Forum.Subscription, user_id: user.id, thread_id: thread.id)
      assert Forum.get_user_vote(user.id, "thread", thread.id).value == 1
    end
  end

  test "fixes malformed and missing forum mutation identifiers" do
    user = user_fixture()

    for id <- ["invalid", Ecto.UUID.generate()] do
      assert {:error, :not_found} = Forum.save_thread(user.id, id)
      assert {:error, :not_found} = Forum.save_comment(user.id, id)
      assert {:error, :not_found} = Forum.subscribe_to_thread(user.id, id)
      assert {:error, :not_found} = Forum.toggle_save_thread(user.id, id)
      assert {:error, :not_found} = Forum.toggle_save_comment(user.id, id)
      assert {:error, :not_found} = Forum.cast_vote(user.id, "thread", id, 1)
      assert {:error, :not_found} = Urielm.Engagement.toggle_vote(user.id, "comment", id, 1)
    end
  end

  test "fixes author edits to comments in a newly hidden board" do
    user = user_fixture()
    board = board_fixture()
    thread = thread_fixture(%{board_id: board.id, author_id: user.id})
    comment = comment_fixture(thread, user)
    board |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()
    assert {:error, :not_found} = Forum.edit_comment(comment, "Forbidden edit", user)
  end

  test "fixes engagement voting on a hidden thread" do
    user = user_fixture()
    board = board_fixture()
    thread = thread_fixture(%{board_id: board.id})
    board |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()
    assert {:error, :not_found} = Urielm.Engagement.toggle_vote(user.id, "thread", thread.id, 1)
  end

  test "fixes stale or forged administrators mutating hidden forum content" do
    owner = user_fixture()
    admin = admin_fixture()
    board = board_fixture()
    thread = thread_fixture(%{board_id: board.id, author_id: owner.id})
    comment = comment_fixture(thread, owner)
    board |> Ecto.Changeset.change(is_hidden: true) |> Repo.update!()

    assert {:error, :not_found} = Forum.edit_comment(comment, "Forged", %{owner | is_admin: true})

    for attrs <- [
          %{is_admin: false},
          %{active: false},
          %{suspended_at: DateTime.utc_now() |> DateTime.truncate(:second)}
        ] do
      fresh_admin =
        Repo.get!(Urielm.Accounts.User, admin.id)
        |> Ecto.Changeset.change(is_admin: true, active: true, suspended_at: nil)
        |> Repo.update!()

      assert {:ok, _} = Forum.save_thread(fresh_admin.id, thread.id)
      assert {:ok, _} = Forum.toggle_save_thread(fresh_admin.id, thread.id)
      assert {:ok, _} = Forum.save_comment(fresh_admin.id, comment.id)
      assert {:ok, _} = Forum.toggle_save_comment(fresh_admin.id, comment.id)
      assert {:ok, _} = Forum.subscribe_to_thread(fresh_admin.id, thread.id)
      assert {:ok, _} = Forum.unsubscribe_from_thread(fresh_admin.id, thread.id)
      assert {:ok, _} = Forum.edit_comment(comment, "Admin edit", fresh_admin)
      assert {:ok, _} = Urielm.Engagement.toggle_vote(fresh_admin.id, "thread", thread.id, 1)
      assert {:ok, _} = Urielm.Engagement.unvote(fresh_admin.id, "thread", thread.id)

      fresh_admin |> Ecto.Changeset.change(attrs) |> Repo.update!()
      expected = if Map.has_key?(attrs, :is_admin), do: :not_found, else: :unauthorized
      assert {:error, ^expected} = Forum.save_thread(admin.id, thread.id)
      assert {:error, ^expected} = Forum.subscribe_to_thread(admin.id, thread.id)
      assert {:error, ^expected} = Forum.edit_comment(comment, "Forbidden", admin)
      assert {:error, ^expected} = Forum.remove_comment(comment, admin)
      assert {:error, ^expected} = Urielm.Engagement.toggle_vote(admin.id, "thread", thread.id, 1)
    end

    refute Repo.get!(Urielm.Forum.Comment, comment.id).is_removed
  end

  test "forum vote authorization preserves nonforum voting and posting restrictions" do
    user = user_fixture()
    assert {:ok, _} = Urielm.Engagement.toggle_vote(user.id, "video", Ecto.UUID.generate(), 1)
    thread = thread_fixture()

    user
    |> Ecto.Changeset.change(silenced_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update!()

    assert {:error, :silenced} = Urielm.Engagement.cast_vote(user.id, "thread", thread.id, 1)
    assert {:error, :silenced} = Urielm.Engagement.unvote(user.id, "thread", thread.id)
    assert {:error, :unauthorized} = Forum.edit_thread(thread, "Forbidden", user)
  end

  test "removal stays idempotent while missing actors are denied cleanly" do
    user = user_fixture()
    thread = thread_fixture(%{author_id: user.id})
    comment = comment_fixture(thread, user)
    assert {:error, :unauthorized} = Forum.edit_thread(thread, "Forbidden", nil)
    assert {:error, :unauthorized} = Forum.edit_comment(comment, "Forbidden", nil)
    assert {:error, :unauthorized} = Forum.unmark_as_solved(thread, nil)
    assert {:ok, removed} = Forum.remove_comment(comment, user)
    assert {:ok, _} = Forum.remove_comment(removed, user)
    assert Repo.get!(Urielm.Forum.Thread, thread.id).comment_count == 0
    assert {:ok, removed_thread} = Forum.remove_thread(thread, user)
    assert {:ok, _} = Forum.remove_thread(removed_thread, user)
    assert {:error, :not_found} = Forum.save_thread(user.id, thread.id)
    assert {:error, :not_found} = Forum.cast_vote(user.id, "thread", thread.id, 1)
  end
end
