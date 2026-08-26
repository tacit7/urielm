defmodule UrielmWeb.ThreadLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Urielm.Fixtures
  alias Urielm.Forum
  alias Urielm.Repo

  describe "discussion reading experience" do
    setup do
      author = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: author.id})

      %{author: author, board: board, thread: thread}
    end

    test "renders focused topic and reply landmarks", %{
      conn: conn,
      author: author,
      thread: thread
    } do
      conn = log_in_user(conn, author)
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      assert has_element?(view, "#thread-reading-view")
      assert has_element?(view, "#thread-topic")
      assert has_element?(view, "#thread-author")
      assert has_element?(view, "#thread-actions")
      assert has_element?(view, "#thread-replies")
      assert has_element?(view, "#comment-form")
      assert has_element?(view, "#comment-form textarea[name='body']")
    end

    test "shows a clear sign-in state instead of the reply form", %{conn: conn, thread: thread} do
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      refute has_element?(view, "#comment-form")
      assert has_element?(view, "#thread-sign-in-to-reply a[href='/signin']")
    end

    test "locked topics replace the composer with a status panel", %{
      conn: conn,
      author: author,
      board: board
    } do
      thread =
        Fixtures.thread_fixture(%{
          board_id: board.id,
          author_id: author.id,
          is_locked: true
        })

      conn = log_in_user(conn, author)
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      refute has_element?(view, "#comment-form")
      assert has_element?(view, "#thread-locked-state")
    end
  end

  describe "thread reporting" do
    test "user can report a thread successfully", %{conn: conn} do
      reporter = Fixtures.user_fixture()
      author = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: author.id})

      conn = log_in_user(conn, reporter)
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      # User clicks report button
      assert view |> has_element?("[data-testid='report-button']")

      # User submits report form
      view
      |> form("[data-testid='report-form']", %{
        "reason" => "spam",
        "description" => "This thread is spam"
      })
      |> render_submit()

      # Verify report was created in DB
      report = Repo.get_by(Urielm.Forum.Report, target_type: "thread", target_id: thread.id)
      assert report != nil
      assert report.reason == "spam"
      assert report.description == "This thread is spam"
      assert report.user_id == reporter.id
      assert report.status == "pending"
    end

    test "anonymous users cannot report", %{conn: conn} do
      author = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: author.id})

      # Don't log in
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      # Report button should not be visible
      refute has_element?(view, "[data-testid='report-button']")
    end
  end

  describe "notification preferences" do
    test "user can change notification level to tracking", %{conn: conn} do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      # User clicks notification tracking option
      view
      |> element("[data-testid='notification-tracking']")
      |> render_click()

      # Verify UI shows tracking selected
      html = render(view)
      assert html =~ "Tracking"

      # Verify DB updated
      level = Forum.get_notification_level(user.id, thread.id)
      assert level == "tracking"
    end

    test "user can change notification level to muted", %{conn: conn} do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      # User clicks notification muted option
      view
      |> element("[data-testid='notification-muted']")
      |> render_click()

      # Verify UI reflects change
      html = render(view)
      assert html =~ "Muted"

      # Verify DB reflects change
      level = Forum.get_notification_level(user.id, thread.id)
      assert level == "muted"
    end

    test "default notification level is watching", %{conn: conn} do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, "/forum/t/#{thread.id}")

      # Default should show watching
      assert html =~ "Watching"

      # Verify DB default
      level = Forum.get_notification_level(user.id, thread.id)
      assert level == "watching"
    end
  end

  describe "comment reporting" do
    test "renders only one comment report modal regardless of comment count", %{conn: conn} do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: user.id})

      # Create multiple comments
      _comment1 = Fixtures.comment_fixture(thread, user)
      _comment2 = Fixtures.comment_fixture(thread, user)
      _comment3 = Fixtures.comment_fixture(thread, user)

      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, "/forum/t/#{thread.id}")

      # Should have exactly one comment report modal
      assert has_element?(view, "[data-testid='comment-report-modal']")

      # Verify there's only one by checking that the ID appears exactly once
      modal_count = html |> String.split("id=\"report_comment_modal\"") |> length() |> Kernel.-(1)
      assert modal_count == 1, "Expected 1 comment report modal, found #{modal_count}"
    end

    test "user can report a comment successfully", %{conn: conn} do
      reporter = Fixtures.user_fixture()
      author = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: author.id})
      comment = Fixtures.comment_fixture(thread, author)

      conn = log_in_user(conn, reporter)
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      # Trigger open_report_comment event
      view
      |> render_click("open_report_comment", %{"comment_id" => to_string(comment.id)})

      # Submit the report form
      view
      |> form("#report-comment-form", %{
        "reason" => "spam",
        "description" => "This comment is spam and violates guidelines"
      })
      |> render_submit()

      # Verify report was created in DB
      report =
        Repo.get_by(Urielm.Forum.Report, target_type: "comment", target_id: comment.id)

      assert report != nil
      assert report.reason == "spam"
      assert report.description == "This comment is spam and violates guidelines"
      assert report.user_id == reporter.id
      assert report.status == "pending"
    end

    test "cannot report a comment from another thread", %{conn: conn} do
      reporter = Fixtures.user_fixture()
      author = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      current_thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: author.id})
      other_thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: author.id})
      other_comment = Fixtures.comment_fixture(other_thread, author)

      conn = log_in_user(conn, reporter)
      {:ok, view, _html} = live(conn, "/forum/t/#{current_thread.id}")

      html =
        render_hook(view, "report_comment", %{
          "comment_id" => to_string(other_comment.id),
          "reason" => "spam",
          "description" => "This comment belongs to a different thread"
        })

      refute Repo.get_by(Urielm.Forum.Report,
               user_id: reporter.id,
               target_type: "comment",
               target_id: other_comment.id
             )

      assert html =~ "Comment not found"
    end

    test "comment report modal submit button is disabled when no comment selected", %{
      conn: conn
    } do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: user.id})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/forum/t/#{thread.id}")

      # Modal should exist but submit button should be disabled (reporting_comment_id is nil)
      html = render(view)
      assert html =~ "id=\"report_comment_modal\""
      assert html =~ "disabled"
    end
  end
end
