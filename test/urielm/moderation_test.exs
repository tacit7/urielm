defmodule Urielm.ModerationTest do
  use Urielm.DataCase

  alias Urielm.Forum
  alias Urielm.Fixtures

  describe "Reporting and Moderation" do
    test "user can report a thread" do
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} = Forum.create_report(reporter.id, "thread", thread.id, %{
        reason: "spam",
        description: "This is spam"
      })

      assert report.reason == "spam"
      assert report.status == "pending"
      assert report.target_type == "thread"
    end

    test "user cannot report the same content twice" do
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, _report} = Forum.create_report(reporter.id, "thread", thread.id, %{reason: "spam"})
      {:error, changeset} = Forum.create_report(reporter.id, "thread", thread.id, %{reason: "spam"})

      assert changeset.errors[:user_id]
    end

    test "user can report a comment" do
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})
      comment = Fixtures.comment_fixture(thread, accused, %{body: "Abusive comment"})

      {:ok, report} = Forum.create_report(reporter.id, "comment", comment.id, %{
        reason: "abuse",
        description: "Abusive content"
      })

      assert report.reason == "abuse"
      assert report.target_type == "comment"
    end

    test "admin can list pending reports" do
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread1 = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})
      thread2 = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      Forum.create_report(reporter.id, "thread", thread1.id, %{reason: "spam"})
      Forum.create_report(reporter.id, "thread", thread2.id, %{reason: "abuse"})

      reports = Forum.list_reports(status: "pending")

      assert length(reports) >= 2
      assert Enum.all?(reports, &(&1.status == "pending"))
    end

    test "admin can review and approve a report" do
      reporter = Fixtures.user_fixture()
      admin = Fixtures.admin_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} = Forum.create_report(reporter.id, "thread", thread.id, %{reason: "spam"})
      assert report.status == "pending"

      {:ok, reviewed} = Forum.review_report(report, admin.id, "reviewed", "Content approved")

      assert reviewed.status == "reviewed"
      assert reviewed.reviewed_by_id == admin.id
      assert reviewed.resolution_notes == "Content approved"
      assert reviewed.resolved_at != nil
    end

    test "admin can resolve a report" do
      reporter = Fixtures.user_fixture()
      admin = Fixtures.admin_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} = Forum.create_report(reporter.id, "thread", thread.id, %{reason: "spam"})

      {:ok, resolved} = Forum.review_report(report, admin.id, "resolved", nil)

      assert resolved.status == "resolved"
    end

    test "admin can dismiss a report" do
      reporter = Fixtures.user_fixture()
      admin = Fixtures.admin_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      {:ok, report} = Forum.create_report(reporter.id, "thread", thread.id, %{reason: "spam"})

      {:ok, dismissed} = Forum.review_report(report, admin.id, "dismissed", nil)

      assert dismissed.status == "dismissed"
    end

    test "admin can count pending reports" do
      reporter = Fixtures.user_fixture()
      accused = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread1 = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})
      thread2 = Fixtures.thread_fixture(%{board_id: board.id, author_id: accused.id})

      Forum.create_report(reporter.id, "thread", thread1.id, %{reason: "spam"})
      Forum.create_report(reporter.id, "thread", thread2.id, %{reason: "abuse"})

      count = Forum.count_pending_reports()

      assert count >= 2
    end
  end

  describe "Notification Settings" do
    test "user can set thread notification level to watching" do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      {:ok, _setting} = Forum.set_notification_level(user.id, thread.id, "watching")

      assert Forum.is_watching?(user.id, thread.id)
      refute Forum.is_tracking?(user.id, thread.id)
      refute Forum.is_muted?(user.id, thread.id)
    end

    test "user can set thread notification level to tracking" do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      {:ok, _setting} = Forum.set_notification_level(user.id, thread.id, "tracking")

      assert Forum.is_tracking?(user.id, thread.id)
      refute Forum.is_watching?(user.id, thread.id)
      refute Forum.is_muted?(user.id, thread.id)
    end

    test "user can mute a thread" do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      {:ok, _setting} = Forum.set_notification_level(user.id, thread.id, "muted")

      assert Forum.is_muted?(user.id, thread.id)
      refute Forum.is_watching?(user.id, thread.id)
      refute Forum.is_tracking?(user.id, thread.id)
    end

    test "default notification level is watching" do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      level = Forum.get_notification_level(user.id, thread.id)

      assert level == "watching"
    end

    test "notification level can be changed multiple times" do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      Forum.set_notification_level(user.id, thread.id, "watching")
      assert Forum.is_watching?(user.id, thread.id)

      Forum.set_notification_level(user.id, thread.id, "muted")
      assert Forum.is_muted?(user.id, thread.id)

      Forum.set_notification_level(user.id, thread.id, "tracking")
      assert Forum.is_tracking?(user.id, thread.id)
    end
  end

  describe "Trust Level Rate Limiting" do
    test "new user (trust level 0) is rate limited to 3 topics per day" do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})

      config = Urielm.TrustLevel.get_config(0)
      assert config.max_new_topics_per_day == 3

      # Create 3 threads
      {:ok, _t1} = Forum.create_thread(board.id, user.id, %{"title" => "T1", "body" => "Body here is long enough"})
      {:ok, _t2} = Forum.create_thread(board.id, user.id, %{"title" => "T2", "body" => "Body here is long enough"})
      {:ok, _t3} = Forum.create_thread(board.id, user.id, %{"title" => "T3", "body" => "Body here is long enough"})

      # 4th should fail
      {:error, :rate_limited} = Forum.create_thread(board.id, user.id, %{"title" => "T4", "body" => "Body here is long enough"})
    end

    test "new user (trust level 0) is rate limited to 1 post per minute" do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      config = Urielm.TrustLevel.get_config(0)
      assert config.max_posts_per_minute == 1

      # Create 1 comment
      {:ok, _c1} = Forum.create_comment(thread.id, user.id, %{"body" => "First comment"})

      # 2nd should fail
      {:error, :rate_limited} = Forum.create_comment(thread.id, user.id, %{"body" => "Second comment"})
    end

    test "admin (trust level 4) has no rate limits" do
      admin = Fixtures.admin_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id})

      config = Urielm.TrustLevel.get_config(4)
      assert config.max_posts_per_minute == -1
      assert config.max_new_topics_per_day == -1

      # Create many threads - should all succeed
      for i <- 1..5 do
        {:ok, _t} = Forum.create_thread(board.id, admin.id, %{"title" => "T#{i}", "body" => "Body here is long enough"})
      end

      # Create many comments - should all succeed
      for i <- 1..5 do
        {:ok, _c} = Forum.create_comment(thread.id, admin.id, %{"body" => "Comment #{i}"})
      end
    end
  end
end
