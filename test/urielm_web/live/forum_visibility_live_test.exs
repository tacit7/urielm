defmodule UrielmWeb.ForumVisibilityLiveTest do
  use UrielmWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Urielm.Fixtures
  alias Urielm.Forum
  alias Urielm.Repo

  setup do
    user = user_fixture()
    board = board_fixture()
    thread = thread_fixture(%{board_id: board.id, author_id: user.id})
    %{user: user, board: board, thread: thread}
  end

  test "hidden board and composer direct routes are unavailable", %{
    conn: conn,
    user: user,
    board: board
  } do
    Repo.update!(Ecto.Changeset.change(board, is_hidden: true))

    assert {:error, {:live_redirect, %{to: "/forum/categories"}}} =
             live(conn, "/forum/b/#{board.slug}")

    assert {:error, {:live_redirect, %{to: "/forum/categories"}}} =
             live(log_in_user(conn, user), "/forum/b/#{board.slug}/new")
  end

  test "a composer opened before the board is hidden cannot publish", %{
    conn: conn,
    user: user,
    board: board
  } do
    {:ok, view, _} = live(log_in_user(conn, user), "/forum/b/#{board.slug}/new")
    Repo.update!(Ecto.Changeset.change(board, is_hidden: true))
    count_before = Repo.aggregate(Urielm.Forum.Thread, :count)

    render_submit(view, "save", %{thread: %{title: "Should not publish", body: "Private content"}})

    assert_redirect(view, "/")
    assert Repo.aggregate(Urielm.Forum.Thread, :count) == count_before
  end

  test "an open board cannot act on threads after its category is hidden", %{
    conn: conn,
    user: user,
    board: board,
    thread: thread
  } do
    {:ok, view, _} = live(log_in_user(conn, user), "/forum/b/#{board.slug}")
    category = Repo.get!(Urielm.Forum.Category, board.category_id)
    Repo.update!(Ecto.Changeset.change(category, is_hidden: true))
    render_click(view, "save_thread", %{thread_id: thread.id})
    assert_redirect(view, "/")
    refute Forum.thread_saved?(user.id, thread.id)
  end

  test "saved topics and notifications exclude newly hidden discussions", %{
    conn: conn,
    user: user,
    board: board,
    thread: thread
  } do
    Forum.save_thread(user.id, thread.id)
    {:ok, notification} = Forum.create_notification(user.id, "comment", thread.id)
    Repo.update!(Ecto.Changeset.change(board, is_hidden: true))
    {:ok, saved, _} = live(log_in_user(conn, user), "/saved")
    assert has_element?(saved, "#saved-threads-empty-state")
    refute has_element?(saved, "a[href='/forum/t/#{thread.id}']")
    {:ok, notifications, _} = live(log_in_user(conn, user), "/notifications")
    refute has_element?(notifications, "#notification-thread-#{notification.id}")
    refute has_element?(notifications, "[data-notification-id='#{notification.id}']")
  end

  test "public profile activity and counts exclude hidden discussions", %{
    conn: conn,
    user: user,
    board: board,
    thread: thread
  } do
    comment_fixture(thread, user)
    Repo.update!(Ecto.Changeset.change(board, is_hidden: true))
    {:ok, view, _} = live(conn, "/u/#{user.username}")
    child = find_live_child(view, "page-user_profile")
    assert has_element?(child, "#profile-threads-empty")
    refute has_element?(child, "a[href='/forum/t/#{thread.id}']")
    stats = Urielm.Accounts.get_user_stats(user.id)
    assert stats.thread_count == 0
    assert stats.comment_count == 0
  end

  test "videos omit discussions belonging to hidden boards", %{
    conn: conn,
    board: board,
    thread: thread
  } do
    video =
      video_fixture(%{
        thread_id: thread.id,
        visibility: "public",
        published_at: DateTime.utc_now()
      })

    Repo.update!(Ecto.Changeset.change(board, is_hidden: true))
    {:ok, view, _} = live(conn, "/videos/#{video.slug}")
    child = find_live_child(view, "page-video")
    assert has_element?(child, "#standard-video-page")
    refute has_element?(child, "#comment-form")
    refute has_element?(child, "[data-name='CommentTree']")
  end

  test "an open video cannot post to a newly hidden discussion", %{
    conn: conn,
    user: user,
    board: board,
    thread: thread
  } do
    video =
      video_fixture(%{
        thread_id: thread.id,
        visibility: "public",
        published_at: DateTime.utc_now()
      })

    {:ok, view, _} = live(log_in_user(conn, user), "/videos/#{video.slug}")
    child = find_live_child(view, "page-video")
    Repo.update!(Ecto.Changeset.change(board, is_hidden: true))
    count_before = Repo.aggregate(Urielm.Forum.Comment, :count)
    render_submit(child, "create_comment", %{body: "Must not publish"})
    assert_redirect(child, "/")
    assert Repo.aggregate(Urielm.Forum.Comment, :count) == count_before
  end
end
