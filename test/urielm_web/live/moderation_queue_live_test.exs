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
          description: "This is spam"
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
          description: "This is spam"
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
          description: "Abusive content"
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
          description: "Offensive content"
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

    test "non-admins cannot access moderation queue", %{conn: conn} do
      user = Fixtures.user_fixture()
      conn = log_in_user(conn, user)

      # Attempt to access moderation page - should redirect
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/admin/moderation")
    end
  end
end
