defmodule UrielmWeb.Admin.ModerationQueueLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Urielm.Fixtures
  alias Urielm.Forum
  alias Urielm.Repo

  describe "moderation queue" do
    test "admin sees pending reports on moderation page", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, _report} =
        Forum.create_report(reporter.id, "thread", thread.id, %{
          reason: "spam",
          description: "This content appears to be spam."
        })

      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, "/admin/moderation")

      # Admin sees the report card
      assert html =~ "data-testid=\"report-card-"
      assert html =~ "Spam"
      assert html =~ reporter.username
    end

    test "admin can approve a report", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} =
        Forum.create_report(reporter.id, "thread", thread.id, %{
          reason: "spam",
          description: "This content appears to be spam."
        })

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/moderation")

      # Verify initial state - report exists
      html = render(view)
      assert html =~ "data-testid=\"report-card-#{report.id}\""

      # Admin clicks approve button using button value selector
      view
      |> element("button[phx-value-report_id='#{report.id}'][phx-click='approve']")
      |> render_click()

      # Verify report disappears from queue
      html = render(view)
      refute html =~ "data-testid=\"report-card-#{report.id}\""

      # Verify report status updated in DB
      updated_report = Repo.get!(Urielm.Forum.Report, report.id)
      assert updated_report.status == "reviewed"
      assert updated_report.reviewed_by_id == admin.id
    end

    test "admin can resolve a report", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} =
        Forum.create_report(reporter.id, "thread", thread.id, %{
          reason: "abuse",
          description: "This content includes clearly abusive language."
        })

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/moderation")

      # Verify report exists initially
      html = render(view)
      assert html =~ "data-testid=\"report-card-#{report.id}\""

      # Admin clicks resolve button for this specific report
      view
      |> element("button[phx-value-report_id='#{report.id}'][phx-click='resolve']")
      |> render_click()

      # Verify report disappears from pending queue
      html = render(view)
      refute html =~ "data-testid=\"report-card-#{report.id}\""

      # Verify report status changed in DB
      updated_report = Repo.get!(Urielm.Forum.Report, report.id)
      assert updated_report.status == "resolved"
      assert updated_report.reviewed_by_id == admin.id
    end

    test "admin can dismiss a report", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} =
        Forum.create_report(reporter.id, "thread", thread.id, %{
          reason: "offensive",
          description: "This content includes clearly offensive language."
        })

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/moderation")

      # Verify report exists initially
      html = render(view)
      assert html =~ "data-testid=\"report-card-#{report.id}\""

      # Admin clicks dismiss button for this specific report
      view
      |> element("button[phx-value-report_id='#{report.id}'][phx-click='dismiss']")
      |> render_click()

      # Verify report removed from queue
      html = render(view)
      refute html =~ "data-testid=\"report-card-#{report.id}\""

      # Verify report dismissed in DB
      updated_report = Repo.get!(Urielm.Forum.Report, report.id)
      assert updated_report.status == "dismissed"
      assert updated_report.reviewed_by_id == admin.id
    end

    test "admin can browse handled report history with reviewer context", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} =
        Forum.create_report(reporter.id, "thread", thread.id, %{
          reason: "abuse",
          description: "This reply targets another member personally."
        })

      {:ok, _report} =
        Forum.review_report(
          report,
          admin.id,
          "resolved",
          "Removed the reply and contacted its author."
        )

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/moderation")

      refute has_element?(view, "#report-card-#{report.id}")

      view
      |> element("#report-filter-all")
      |> render_click()

      assert has_element?(view, "#report-card-#{report.id}[data-status='resolved']")
      assert has_element?(view, "#report-history-#{report.id}", admin.username)
      assert has_element?(view, "#report-history-#{report.id}", "Removed the reply")
      refute has_element?(view, "#report-card-#{report.id} [phx-click='resolve']")
    end

    test "admin can filter report history by status", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})

      resolved_thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})
      dismissed_thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, resolved_report} =
        Forum.create_report(reporter.id, "thread", resolved_thread.id, %{
          reason: "spam",
          description: "This report should appear in resolved results."
        })

      {:ok, dismissed_report} =
        Forum.create_report(reporter.id, "thread", dismissed_thread.id, %{
          reason: "other",
          description: "This report should appear in dismissed results."
        })

      {:ok, _} = Forum.review_report(resolved_report, admin.id, "resolved", "Resolved")
      {:ok, _} = Forum.review_report(dismissed_report, admin.id, "dismissed", "Dismissed")

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/moderation")

      view |> element("#report-filter-resolved") |> render_click()

      assert has_element?(view, "#report-card-#{resolved_report.id}")
      refute has_element?(view, "#report-card-#{dismissed_report.id}")
    end

    test "admin can search reports by reporter and description", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      matching_reporter = Fixtures.user_fixture()
      other_reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      matching_thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})
      other_thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, matching_report} =
        Forum.create_report(matching_reporter.id, "thread", matching_thread.id, %{
          reason: "spam",
          description: "Repeated promotional links appear throughout this discussion."
        })

      {:ok, other_report} =
        Forum.create_report(other_reporter.id, "thread", other_thread.id, %{
          reason: "abuse",
          description: "This reply contains an unnecessary personal attack."
        })

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/moderation")

      view
      |> form("#moderation-report-filters", filters: %{search: matching_reporter.username})
      |> render_change()

      assert has_element?(view, "#report-card-#{matching_report.id}")
      refute has_element?(view, "#report-card-#{other_report.id}")
    end

    test "admin can save context that remains attached to a pending report", %{conn: conn} do
      admin = Fixtures.admin_fixture()
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} =
        Forum.create_report(reporter.id, "thread", thread.id, %{
          reason: "other",
          description: "This report needs additional moderator investigation."
        })

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, "/admin/moderation")

      view
      |> form("#report-note-form-#{report.id}",
        moderation_note: %{notes: "Check the linked context before deciding."}
      )
      |> render_submit()

      updated_report = Repo.get!(Urielm.Forum.Report, report.id)
      assert updated_report.resolution_notes == "Check the linked context before deciding."
      assert has_element?(view, "#report-history-#{report.id}", "Check the linked context")
    end

    test "non-admins cannot access moderation queue", %{conn: conn} do
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, user)

      # Attempt to access moderation page - should redirect
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/admin/moderation")
    end

    test "non-admins cannot access trust-levels admin page", %{conn: conn} do
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, user)

      # Attempt to access trust-levels page - should redirect
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/admin/trust-levels")
    end

    test "anonymous users are redirected to signup from admin pages", %{conn: conn} do
      # Attempt to access admin pages without being logged in
      assert {:error, {:redirect, %{to: "/signup"}}} = live(conn, "/admin/moderation")
      assert {:error, {:redirect, %{to: "/signup"}}} = live(conn, "/admin/trust-levels")
    end
  end
end
