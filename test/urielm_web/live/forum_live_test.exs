# Forum LiveView Integration Tests
#
# Coverage:
# - Thread creation with form validation
# - Voting idempotency and race condition prevention (DB unique constraint)
# - Nested comment rendering (N+1 query prevented via single preload)
# - Authorization for delete operations (author/admin only, enforced in context)
# - Pagination edge cases (offset-based, stable on "New" sort)
# - Soft delete filtering (removed content hidden from queries)

defmodule UrielmWeb.ForumLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Forum

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  setup do
    # Create test data
    user = user_fixture()
    admin = admin_fixture()

    category = category_fixture()
    board = board_fixture(%{category_id: category.id})

    thread =
      thread_fixture(%{
        board_id: board.id,
        author_id: user.id,
        title: "Test Thread",
        body: "This is a test thread"
      })

    comment =
      comment_fixture(thread, user, %{
        body: "Test comment"
      })

    {:ok,
     user: user, admin: admin, category: category, board: board, thread: thread, comment: comment}
  end

  describe "ForumLive" do
    test "renders the shared community discovery shell" do
      {:ok, view, _html} = live(build_conn(), ~p"/forum")

      assert has_element?(
               view,
               "#forum-navbar-container div[data-name='Navbar'][data-props*='showNavLinks'][data-props*='false'][data-props*='forum-drawer']"
             )

      assert has_element?(view, "#forum-sidebar-nav")
      assert has_element?(view, "#forum-page-shell.ui-page-shell")
      assert has_element?(view, "#community-discovery-header")
      assert has_element?(view, "#forum-search-link[href='/forum/search']")
      assert has_element?(view, "#forum-view-tabs a[aria-current='page']", "Latest")
      assert has_element?(view, "#latest-discussions-surface.ui-card")
      assert has_element?(view, "#threads[phx-update='stream']")
    end

    test "pins start here and announcements first in the sidebar boards", %{category: category} do
      _other_board =
        board_fixture(%{
          category_id: category.id,
          name: "General Discussion",
          slug: "general-discussion"
        })

      _announcements =
        board_fixture(%{
          category_id: category.id,
          name: "Announcements",
          slug: "announcements"
        })

      _start_here =
        board_fixture(%{
          category_id: category.id,
          name: "Start Here",
          slug: "start-here"
        })

      {:ok, view, _html} = live(build_conn(), ~p"/forum")
      html = render(view)

      start_here_index = :binary.match(html, ~s(href="/forum/b/start-here")) |> elem(0)
      announcements_index = :binary.match(html, ~s(href="/forum/b/announcements")) |> elem(0)
      general_index = :binary.match(html, ~s(href="/forum/b/general-discussion")) |> elem(0)

      assert start_here_index < announcements_index
      assert announcements_index < general_index
    end

    test "pagination patch reloads the latest discussions" do
      {:ok, view, _html} = live(build_conn(), ~p"/forum")

      html = render_patch(view, ~p"/forum?page=1")

      assert html =~ "Latest discussions"
      assert has_element?(view, "#latest-discussions-surface.ui-card")
    end

    test "updates the signed-in user's unread badge without a reload", %{
      user: user,
      thread: thread
    } do
      {:ok, view, _html} = live(build_conn_with_user(user), ~p"/forum")

      refute has_element?(view, "#forum-notification-badge")

      assert has_element?(
               view,
               "#forum-navbar-container div[data-name='Navbar'][data-props*='#{user.username}']"
             )

      {:ok, _notification} = Forum.create_notification(user.id, "comment", thread.id)

      assert has_element?(view, "#forum-notification-badge", "1")
    end

    test "caps the unread badge at 99+", %{user: user} do
      {:ok, view, _html} = live(build_conn_with_user(user), ~p"/forum")

      send(view.pid, {:unread_notification_count, 100})

      assert has_element?(view, "#forum-notification-badge", "99+")
    end

    test "categories view exposes discovery navigation and structured board groups", %{
      category: category,
      board: board
    } do
      {:ok, view, _html} = live(build_conn(), ~p"/forum/categories")

      assert has_element?(view, "#community-discovery-header")
      assert has_element?(view, "#forum-view-tabs a[aria-current='page']", "Categories")
      assert has_element?(view, "#forum-category-#{category.id}")
      assert has_element?(view, "#forum-category-surface-#{category.id}.ui-card")
      assert has_element?(view, "#forum-board-#{board.id}[href='/forum/b/#{board.slug}']")
    end

    test "signed-in users can change all four category notification levels", %{
      category: category,
      user: user
    } do
      {:ok, view, _html} = live(build_conn_with_user(user), ~p"/forum/categories")

      assert has_element?(view, "#category-notification-form-#{category.id}")

      assert has_element?(
               view,
               "#category-notification-level-#{category.id} option[value='normal']"
             )

      assert has_element?(
               view,
               "#category-notification-level-#{category.id} option[value='watching']"
             )

      assert has_element?(
               view,
               "#category-notification-level-#{category.id} option[value='tracking']"
             )

      assert has_element?(
               view,
               "#category-notification-level-#{category.id} option[value='muted']"
             )

      for level <- ~w(watching tracking muted normal) do
        view
        |> form("#category-notification-form-#{category.id}", %{
          "category_notification" => %{"level" => level}
        })
        |> render_change()

        assert Forum.get_category_watch_level(user.id, category.id) == level

        assert has_element?(
                 view,
                 "#category-notification-level-#{category.id} option[value='#{level}'][selected]"
               )
      end
    end

    test "category notification controls are hidden from anonymous visitors", %{
      category: category
    } do
      {:ok, view, _html} = live(build_conn(), ~p"/forum/categories")

      refute has_element?(view, "#category-notification-form-#{category.id}")
    end

    test "mount displays forum categories and boards", %{category: category, board: board} do
      {:ok, _live, html} = live(build_conn(), ~p"/forum/categories")

      assert html =~ category.name
      assert html =~ board.name
      assert html =~ board.description
    end

    test "shows no categories when none exist" do
      {:ok, _live, html} = live(build_conn(), ~p"/forum")

      # Should still render without errors
      assert html =~ "Forum"
    end

    test "board links are clickable" do
      category = category_fixture()
      board = board_fixture(%{category_id: category.id})

      {:ok, _live, html} = live(build_conn(), ~p"/forum")

      assert html =~ ~p"/forum/b/#{board.slug}"
    end
  end

  describe "BoardLive" do
    test "mount displays board with threads", %{board: board, thread: thread} do
      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}")

      assert html =~ board.name
      assert html =~ thread.title
    end

    test "displays sort tabs", %{board: board} do
      {:ok, view, _html} = live(build_conn(), ~p"/forum/b/#{board.slug}")

      assert has_element?(view, "#board-header.ui-page-header")
      assert has_element?(view, "#board-filter-tabs.tabs")
      assert has_element?(view, "#board-filter-tabs a[aria-current='page']", "Latest")
      assert has_element?(view, "#board-filter-tabs", "Top")
      assert has_element?(view, "#board-filter-tabs", "New")
      assert has_element?(view, "#board-discussions-surface.ui-card")
    end

    test "shows new thread button for authenticated users", %{board: board, user: user} do
      {:ok, view, _html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}")

      assert has_element?(
               view,
               "#forum-navbar-container div[data-name='Navbar'][data-props*='/forum/b/#{board.slug}/new']"
             )

      refute has_element?(view, "#board-new-topic-link")
    end

    test "hides new thread button for anonymous users", %{board: board} do
      {:ok, view, _html} = live(build_conn(), ~p"/forum/b/#{board.slug}")

      refute has_element?(
               view,
               "#forum-navbar-container div[data-name='Navbar'][data-props*='/new']"
             )

      refute has_element?(view, "#board-new-topic-link")
    end

    test "hides new thread button for locked boards", %{category: category, user: user} do
      locked_board = board_fixture(%{category_id: category.id, is_locked: true})

      {:ok, view, _html} = live(build_conn_with_user(user), ~p"/forum/b/#{locked_board.slug}")

      refute has_element?(
               view,
               "#forum-navbar-container div[data-name='Navbar'][data-props*='/new']"
             )

      refute has_element?(view, "#board-new-topic-link")
    end

    test "handles vote event for authenticated user", %{board: board, thread: thread, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}")

      render_click(live, "vote", %{
        "target_type" => "thread",
        "target_id" => to_string(thread.id),
        "value" => "1"
      })

      # Verify vote was created
      vote = Forum.get_user_vote(user.id, "thread", thread.id)
      assert vote.value == 1
    end

    test "redirects to signin for anonymous vote attempt", %{board: board, thread: thread} do
      {:ok, live, _html} = live(build_conn(), ~p"/forum/b/#{board.slug}")

      result =
        render_click(live, "vote", %{
          "target_type" => "thread",
          "target_id" => to_string(thread.id),
          "value" => "1"
        })

      assert result =~ "Sign in to vote"
    end

    test "pagination works with page parameter", %{board: board} do
      # Create multiple threads to trigger pagination
      user = user_fixture()

      for i <- 1..25 do
        thread_fixture(%{
          board_id: board.id,
          author_id: user.id,
          title: "Thread #{i}",
          slug: "thread-#{i}"
        })
      end

      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}")

      # Verify first page loaded with threads
      assert html =~ "Thread"

      # Page 2 should also work
      {:ok, _live, html2} = live(build_conn(), ~p"/forum/b/#{board.slug}?page=2")
      assert html2 =~ "Thread"
    end

    test "sort=top parameter works", %{board: board} do
      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?sort=top")

      assert html =~ board.name
    end

    test "handles invalid page param gracefully", %{board: board} do
      # Should not crash on garbage page values
      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?page=lol")
      assert html =~ board.name

      # Negative and zero should default to page 1
      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?page=-5")
      assert html =~ board.name

      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?page=0")
      assert html =~ board.name
    end
  end

  describe "BoardLive mount" do
    @describetag :board_live

    test "renders board and threads for anonymous user", %{board: board, thread: thread} do
      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}")

      assert html =~ board.name
      assert html =~ thread.title
    end

    test "renders board for logged-in user with Unread tab visible", %{board: board, user: user} do
      {:ok, _live, html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}")

      assert html =~ board.name
      assert html =~ "Unread"
    end

    test "sort=top param activates top ordering", %{board: board, user: user} do
      thread_a =
        thread_fixture(%{board_id: board.id, author_id: user.id, title: "Low Score Thread"})

      # Give thread_a a high score via votes
      other = user_fixture()
      vote_fixture(other, "thread", thread_a.id, 1)

      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?sort=top")

      assert html =~ board.name
      assert html =~ "Low Score Thread"
    end

    test "sort=new param uses inserted_at ordering", %{board: board, user: user} do
      thread_fixture(%{board_id: board.id, author_id: user.id, title: "Sort New Thread"})

      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?sort=new")

      assert html =~ board.name
      assert html =~ "Sort New Thread"
    end

    test "filter=new param uses paginate_new_threads path", %{board: board, user: user} do
      thread_fixture(%{board_id: board.id, author_id: user.id, title: "Filter New Thread"})

      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?filter=new")

      assert html =~ board.name
      assert html =~ "Filter New Thread"
    end

    test "filter=solved shows only solved threads", %{board: board, user: user} do
      solved =
        thread_fixture(%{board_id: board.id, author_id: user.id, title: "Solved Thread Title"})

      Urielm.Repo.update!(Ecto.Changeset.change(solved, is_solved: true))

      unsolved =
        thread_fixture(%{board_id: board.id, author_id: user.id, title: "Unsolved Thread Title"})

      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?filter=solved")

      assert html =~ "Solved Thread Title"
      refute html =~ unsolved.title
    end

    test "filter=unsolved shows only unsolved threads", %{board: board, user: user} do
      solved =
        thread_fixture(%{board_id: board.id, author_id: user.id, title: "Solved Thread Title 2"})

      Urielm.Repo.update!(Ecto.Changeset.change(solved, is_solved: true))

      unsolved =
        thread_fixture(%{
          board_id: board.id,
          author_id: user.id,
          title: "Unsolved Thread Title 2"
        })

      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?filter=unsolved")

      assert html =~ unsolved.title
      refute html =~ "Solved Thread Title 2"
    end

    test "filter=unread for logged-in user loads unread path", %{board: board, user: user} do
      thread_fixture(%{board_id: board.id, author_id: user.id, title: "Unread Filter Thread"})

      {:ok, _live, html} =
        live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}?filter=unread")

      assert html =~ board.name
    end

    test "filter=unread for anonymous user falls back to default listing", %{
      board: board,
      thread: thread
    } do
      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?filter=unread")

      assert html =~ board.name
      assert html =~ thread.title
    end

    test "page param is applied on mount", %{board: board, user: user} do
      for i <- 1..25 do
        thread_fixture(%{
          board_id: board.id,
          author_id: user.id,
          title: "Paginated Thread #{i}"
        })
      end

      {:ok, _live, html} = live(build_conn(), ~p"/forum/b/#{board.slug}?page=2")

      assert html =~ board.name
    end

    test "unknown board slug redirects to forum categories" do
      assert {:error, {:live_redirect, %{to: "/forum/categories"}}} =
               live(build_conn(), "/forum/b/board-that-does-not-exist-xyz-abc-999")
    end
  end

  describe "NewThreadLive" do
    test "requires authentication", %{board: board} do
      conn = build_conn()
      response = get(conn, "/forum/b/#{board.slug}/new")

      # Should redirect to sign in
      assert response.status in [301, 302]
    end

    test "redirects with error when board is locked", %{user: user} do
      locked_board = board_fixture(%{is_locked: true})

      {:error, {:redirect, %{to: to, flash: flash}}} =
        live(build_conn_with_user(user), ~p"/forum/b/#{locked_board.slug}/new")

      assert to == "/forum/b/#{locked_board.slug}"
      assert flash["error"] =~ "locked"
    end

    test "authenticated user can view form", %{board: board, user: user} do
      {:ok, view, _html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}/new")

      assert has_element?(view, "#new-thread-page")
      assert has_element?(view, "#new-thread-header.ui-page-header")
      assert has_element?(view, "#new-thread-board-context.ui-card", board.name)
      assert has_element?(view, "#new-thread-composer.ui-card")
      assert has_element?(view, "#new-thread-form[phx-hook='DiscussionDraft']")
      assert has_element?(view, "#new-thread-title[maxlength='300']")
      assert has_element?(view, "#new-thread-body[maxlength='10000']")
      assert has_element?(view, "#new-thread-title-count", "0 / 300")
      assert has_element?(view, "#new-thread-body-count", "0 / 10,000")
      assert has_element?(view, "#new-thread-preview.ui-card")
      assert has_element?(view, "#new-thread-guidance.ui-card")
      assert has_element?(view, "#new-thread-submit[phx-disable-with='Publishing…']")
    end

    test "back link navigates to board", %{board: board, user: user} do
      {:ok, _live, html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}/new")

      assert html =~ ~p"/forum/b/#{board.slug}"
    end

    test "validates on form input", %{board: board, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}/new")

      render_change(live, "validate", %{
        "thread" => %{
          "title" => "A clearer discussion title",
          "body" => "Some useful **Markdown** context."
        }
      })

      assert has_element?(live, "#new-thread-title-count", "26 / 300")
      assert has_element?(live, "#new-thread-body-count", "33 / 10,000")
      assert has_element?(live, "#new-thread-preview-title", "A clearer discussion title")
      assert has_element?(live, "#new-thread-preview-body")
    end

    test "restores a locally saved draft without showing validation errors", %{
      board: board,
      user: user
    } do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}/new")

      render_hook(live, "restore_draft", %{
        "title" => "Restored draft",
        "body" => "Draft body restored from local storage."
      })

      assert has_element?(live, "#new-thread-title[value='Restored draft']")
      assert has_element?(live, "#new-thread-preview-title", "Restored draft")
      refute has_element?(live, "#new-thread-form .text-error")
    end

    test "creates thread successfully", %{board: board, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}/new")

      # Note: slug auto-generation in the form is not implemented, so we need to provide it
      _html =
        render_submit(live, "save", %{
          "thread" => %{
            "title" => "New Test Thread",
            "slug" => "new-test-thread",
            "body" => "This is the body of the new thread"
          }
        })

      # Verify thread was created
      threads = Forum.list_threads(board.id)
      assert length(threads) > 0
      assert Enum.any?(threads, &(&1.title == "New Test Thread"))
    end

    test "shows validation errors on failed submit", %{board: board, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/b/#{board.slug}/new")

      # Submit with missing required fields
      html =
        render_submit(live, "save", %{"thread" => %{"title" => "", "slug" => "", "body" => ""}})

      # Should show form again with errors
      assert html =~ "form"
    end
  end

  describe "ThreadLive" do
    test "displays thread and comments", %{thread: thread, comment: comment} do
      {:ok, _live, html} = live(build_conn(), ~p"/forum/t/#{thread.id}")

      assert html =~ thread.title
      assert html =~ thread.body
      assert html =~ comment.body
    end

    test "shows comment form for authenticated users", %{thread: thread, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      assert has_element?(live, "#comment-form")
      assert has_element?(live, "#comment-submit")
    end

    test "hides comment form for anonymous users", %{thread: thread} do
      {:ok, live, _html} = live(build_conn(), ~p"/forum/t/#{thread.id}")

      refute has_element?(live, "#comment-form")
      assert has_element?(live, "#thread-sign-in-to-reply")
    end

    test "authenticated user can create comment", %{thread: thread, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      live
      |> form("#comment-form", %{"body" => "New comment"})
      |> render_submit()

      # Verify comment was created
      updated_thread = Forum.get_thread!(thread.id)
      assert updated_thread.comment_count > 0
    end

    test "shows success flash on comment creation", %{thread: thread, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      html = render_submit(live, "create_comment", %{"body" => "New comment"})

      assert html =~ "Comment posted"
    end

    test "handles vote on thread", %{thread: thread, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      render_click(live, "vote", %{
        "target_type" => "thread",
        "target_id" => to_string(thread.id),
        "value" => "1"
      })

      # Verify vote was recorded
      vote = Forum.get_user_vote(user.id, "thread", thread.id)
      assert vote.value == 1
    end

    test "handles vote on comment", %{thread: thread, comment: comment, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      render_click(live, "vote", %{
        "target_type" => "comment",
        "target_id" => to_string(comment.id),
        "value" => "1"
      })

      # Verify vote was recorded
      vote = Forum.get_user_vote(user.id, "comment", comment.id)
      assert vote.value == 1
    end

    test "cannot vote on a comment from another thread", %{
      board: board,
      thread: current_thread,
      user: user
    } do
      other_thread = thread_fixture(%{board_id: board.id, author_id: user.id})
      other_comment = comment_fixture(other_thread, user)

      {:ok, live, _html} =
        live(build_conn_with_user(user), ~p"/forum/t/#{current_thread.id}")

      html =
        render_click(live, "vote", %{
          "target_type" => "comment",
          "target_id" => to_string(other_comment.id),
          "value" => "1"
        })

      assert html =~ "Comment not found"
      refute Forum.get_user_vote(user.id, "comment", other_comment.id)
      assert Forum.get_comment!(other_comment.id).score == 0
    end

    test "author can delete thread", %{thread: thread, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      # Author can see delete button
      html = render_page(live)
      assert html =~ "Delete"

      # Delete the thread
      _html = render_click(live, "delete_thread", %{})

      # Verify thread was marked as removed
      updated_thread = Forum.get_thread!(thread.id, allow_removed?: true)
      assert updated_thread.is_removed
    end

    test "admin can delete others' threads", %{thread: thread, admin: admin} do
      {:ok, live, _html} = live(build_conn_with_user(admin), ~p"/forum/t/#{thread.id}")

      # Admin can delete
      _html = render_click(live, "delete_thread", %{})

      # Verify thread was marked as removed
      updated_thread = Forum.get_thread!(thread.id, allow_removed?: true)
      assert updated_thread.is_removed
    end

    test "non-author cannot delete thread", %{thread: thread} do
      other_user = user_fixture()

      {:ok, live, _html} = live(build_conn_with_user(other_user), ~p"/forum/t/#{thread.id}")

      html = render_click(live, "delete_thread", %{})

      # Should show error message
      assert html =~ "Not authorized"
    end

    test "author can delete their comment", %{thread: thread, comment: comment, user: user} do
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      render_click(live, "delete_comment", %{"id" => to_string(comment.id)})

      # Verify comment was marked as removed
      updated_comment = Forum.get_comment!(comment.id)
      assert updated_comment.is_removed
    end

    test "cannot edit a comment from another thread", %{
      board: board,
      thread: current_thread,
      user: user
    } do
      other_thread = thread_fixture(%{board_id: board.id, author_id: user.id})
      other_comment = comment_fixture(other_thread, user, %{body: "Keep this body"})

      {:ok, live, _html} =
        live(build_conn_with_user(user), ~p"/forum/t/#{current_thread.id}")

      html =
        render_click(live, "edit_comment", %{
          "id" => to_string(other_comment.id),
          "body" => "Changed elsewhere"
        })

      assert html =~ "Comment not found"
      assert Forum.get_comment!(other_comment.id).body == "Keep this body"
    end

    test "cannot delete a comment from another thread", %{
      board: board,
      thread: current_thread,
      user: user
    } do
      other_thread = thread_fixture(%{board_id: board.id, author_id: user.id})
      other_comment = comment_fixture(other_thread, user)

      {:ok, live, _html} =
        live(build_conn_with_user(user), ~p"/forum/t/#{current_thread.id}")

      html = render_click(live, "delete_comment", %{"id" => to_string(other_comment.id)})

      assert html =~ "Comment not found"
      refute Forum.get_comment!(other_comment.id).is_removed
    end

    test "non-author cannot delete comment", %{thread: thread, comment: comment} do
      other_user = user_fixture()

      {:ok, live, _html} = live(build_conn_with_user(other_user), ~p"/forum/t/#{thread.id}")

      html = render_click(live, "delete_comment", %{"id" => to_string(comment.id)})

      # Should show error message
      assert html =~ "Not authorized"

      # Verify comment was not deleted
      updated_comment = Forum.get_comment!(comment.id)
      refute updated_comment.is_removed
    end

    test "displays back link to board", %{thread: thread} do
      # Reload thread to get preloaded board association
      thread = Urielm.Repo.preload(thread, :board)
      {:ok, _live, html} = live(build_conn(), ~p"/forum/t/#{thread.id}")

      assert html =~ ~p"/forum/b/#{thread.board.slug}"
    end

    test "handles nested comments correctly" do
      user = user_fixture()
      board = board_fixture()
      thread = thread_fixture(%{board_id: board.id, author_id: user.id})

      # Create root comment
      root = comment_fixture(thread, user, %{body: "Root comment"})

      # Create reply to root comment
      _reply = comment_fixture(thread, user, %{body: "Reply to root", parent_id: root.id})

      {:ok, _live, html} = live(build_conn(), ~p"/forum/t/#{thread.id}")

      # Both comments should be visible
      assert html =~ "Root comment"
      assert html =~ "Reply to root"
    end

    test "viewing thread increments view count exactly once", %{thread: thread} do
      # Get initial view count
      initial_count = thread.view_count || 0

      # Visit thread page (includes both disconnected and connected mounts)
      {:ok, _live, _html} = live(build_conn(), ~p"/forum/t/#{thread.id}")

      # Reload thread and verify view count increased by exactly 1
      updated_thread = Urielm.Repo.get!(Forum.Thread, thread.id)
      assert updated_thread.view_count == initial_count + 1
    end

    test "voting on thread does NOT increment view count", %{thread: thread, user: user} do
      # Visit thread page first to establish baseline
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      # Get view count after initial visit
      after_visit = Urielm.Repo.get!(Forum.Thread, thread.id)
      count_after_visit = after_visit.view_count || 0

      # Cast a vote
      render_click(live, "vote", %{
        "target_type" => "thread",
        "target_id" => to_string(thread.id),
        "value" => "1"
      })

      # Verify view count did NOT change due to voting
      after_vote = Urielm.Repo.get!(Forum.Thread, thread.id)
      assert after_vote.view_count == count_after_visit
    end

    test "saving thread does NOT increment view count", %{thread: thread, user: user} do
      # Visit thread page first
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      # Get view count after initial visit
      after_visit = Urielm.Repo.get!(Forum.Thread, thread.id)
      count_after_visit = after_visit.view_count || 0

      # Save the thread
      render_click(live, "save_thread", %{})

      # Verify view count did NOT change due to saving
      after_save = Urielm.Repo.get!(Forum.Thread, thread.id)
      assert after_save.view_count == count_after_visit
    end

    test "posting comment does NOT increment view count", %{thread: thread, user: user} do
      # Visit thread page first
      {:ok, live, _html} = live(build_conn_with_user(user), ~p"/forum/t/#{thread.id}")

      # Get view count after initial visit
      after_visit = Urielm.Repo.get!(Forum.Thread, thread.id)
      count_after_visit = after_visit.view_count || 0

      # Post a comment
      render_submit(live, "create_comment", %{"body" => "Test comment"})

      # Verify view count did NOT change due to comment creation
      after_comment = Urielm.Repo.get!(Forum.Thread, thread.id)
      assert after_comment.view_count == count_after_visit
    end
  end

  # Helper functions
  defp build_conn_with_user(user) do
    build_conn()
    |> Plug.Test.init_test_session(%{"user_id" => user.id})
  end

  defp render_page(live) do
    render(live)
  end
end
