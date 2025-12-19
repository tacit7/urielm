defmodule Urielm.ForumTest do
  use Urielm.DataCase

  import Urielm.Fixtures

  alias Urielm.Forum
  alias Urielm.Forum.{Category, Board, Thread, Comment, Vote}

  describe "categories" do
    test "list_categories/1 returns all non-hidden categories" do
      cat1 = category_fixture(%{name: "Category 1", slug: "cat-1"})
      cat2 = category_fixture(%{name: "Category 2", slug: "cat-2"})
      _hidden = category_fixture(%{name: "Hidden", slug: "hidden", is_hidden: true})

      categories = Forum.list_categories(hidden: false)

      assert length(categories) >= 2
      assert Enum.any?(categories, &(&1.id == cat1.id))
      assert Enum.any?(categories, &(&1.id == cat2.id))
    end

    test "get_category!/1 returns category by id" do
      category = category_fixture()
      fetched = Forum.get_category!(category.id)

      assert fetched.id == category.id
      assert fetched.name == category.name
    end

    test "create_category/1 creates a category" do
      attrs = %{name: "New Category", slug: "new-cat"}
      {:ok, category} = Forum.create_category(attrs)

      assert category.name == "New Category"
      assert category.slug == "new-cat"
      assert category.position == 0
    end
  end

  describe "boards" do
    test "list_boards/2 returns all boards in category" do
      category = category_fixture()
      board1 = board_fixture(%{category_id: category.id, slug: "board-1"})
      board2 = board_fixture(%{category_id: category.id, slug: "board-2"})

      boards = Forum.list_boards(category.id, hidden: false)

      assert length(boards) >= 2
      assert Enum.any?(boards, &(&1.id == board1.id))
      assert Enum.any?(boards, &(&1.id == board2.id))
    end

    test "get_board!/1 returns board by slug" do
      board = board_fixture()
      fetched = Forum.get_board!(board.slug)

      assert fetched.id == board.id
      assert fetched.name == board.name
    end

    test "create_board/1 creates a board" do
      category = category_fixture()
      attrs = %{category_id: category.id, name: "Test Board", slug: "test-board"}
      {:ok, board} = Forum.create_board(attrs)

      assert board.name == "Test Board"
      assert board.category_id == category.id
    end
  end

  describe "threads" do
    test "list_threads/2 returns threads sorted by new by default" do
      board = board_fixture()
      thread1 = thread_fixture(%{board_id: board.id})
      thread2 = thread_fixture(%{board_id: board.id})

      threads = Forum.list_threads(board.id, sort: :new)

      assert length(threads) >= 2
      assert Enum.any?(threads, &(&1.id == thread1.id))
      assert Enum.any?(threads, &(&1.id == thread2.id))
    end

    test "list_threads/2 sorts by score when sort: :top" do
      board = board_fixture()
      thread1 = thread_fixture(%{board_id: board.id})
      thread2 = thread_fixture(%{board_id: board.id})

      # Manually update scores for testing
      Repo.update_all(from(t in Thread, where: t.id == ^thread1.id), set: [score: 10])
      Repo.update_all(from(t in Thread, where: t.id == ^thread2.id), set: [score: 5])

      threads = Forum.list_threads(board.id, sort: :top)

      # Top sorted, so higher score first
      assert Enum.find_index(threads, &(&1.id == thread1.id)) <
               Enum.find_index(threads, &(&1.id == thread2.id))
    end

    test "list_threads/2 excludes removed threads" do
      board = board_fixture()
      thread1 = thread_fixture(%{board_id: board.id})
      thread2 = thread_fixture(%{board_id: board.id})

      admin = admin_fixture()
      Forum.remove_thread(thread2, admin)

      threads = Forum.list_threads(board.id)

      assert Enum.any?(threads, &(&1.id == thread1.id))
      refute Enum.any?(threads, &(&1.id == thread2.id))
    end

    test "get_thread!/1 returns thread with preloaded data" do
      thread = thread_fixture()
      comment = comment_fixture(thread)

      fetched = Forum.get_thread!(thread.id)

      assert fetched.id == thread.id
      assert fetched.author.id == thread.author_id
      assert length(fetched.comments) >= 1
    end

    test "create_thread/3 creates a thread" do
      board = board_fixture()
      author = user_fixture()

      attrs = %{
        "title" => "New Thread",
        "slug" => "new-thread",
        "body" => "Thread body"
      }

      {:ok, thread} = Forum.create_thread(board.id, author.id, attrs)

      assert thread.title == "New Thread"
      assert thread.board_id == board.id
      assert thread.author_id == author.id
      assert thread.score == 0
      assert thread.comment_count == 0
    end
  end

  describe "comments" do
    test "list_comments/2 returns all non-removed comments for thread" do
      thread = thread_fixture()
      comment1 = comment_fixture(thread)
      comment2 = comment_fixture(thread)

      comments = Forum.list_comments(thread.id)

      assert length(comments) >= 2
      assert Enum.any?(comments, &(&1.id == comment1.id))
      assert Enum.any?(comments, &(&1.id == comment2.id))
    end

    test "list_comments/2 excludes removed comments" do
      thread = thread_fixture()
      comment1 = comment_fixture(thread)
      comment2 = comment_fixture(thread)

      admin = admin_fixture()
      Forum.remove_comment(comment2, admin)

      comments = Forum.list_comments(thread.id)

      assert Enum.any?(comments, &(&1.id == comment1.id))
      refute Enum.any?(comments, &(&1.id == comment2.id))
    end

    test "get_comment!/1 returns comment with author" do
      thread = thread_fixture()
      comment = comment_fixture(thread)

      fetched = Forum.get_comment!(comment.id)

      assert fetched.id == comment.id
      assert fetched.author.id == comment.author_id
    end

    test "create_comment/3 creates a comment and increments thread count" do
      thread = thread_fixture()
      author = user_fixture()

      attrs = %{"body" => "Test comment"}
      {:ok, comment} = Forum.create_comment(thread.id, author.id, attrs)

      assert comment.body == "Test comment"
      assert comment.thread_id == thread.id
      assert comment.author_id == author.id

      # Check thread comment_count was updated
      updated_thread = Repo.get!(Thread, thread.id)
      assert updated_thread.comment_count == 1
    end

    test "create_comment/3 with parent_id creates nested comment" do
      thread = thread_fixture()
      parent = comment_fixture(thread)
      author = user_fixture()

      attrs = %{"body" => "Reply", "parent_id" => parent.id}
      {:ok, comment} = Forum.create_comment(thread.id, author.id, attrs)

      assert comment.parent_id == parent.id
    end
  end

  describe "votes" do
    test "cast_vote/4 creates an upvote on thread" do
      thread = thread_fixture()
      user = user_fixture()

      {:ok, {:ok, vote}} = Forum.cast_vote(user.id, "thread", thread.id, 1)

      assert vote.user_id == user.id
      assert vote.target_type == "thread"
      assert vote.target_id == thread.id
      assert vote.value == 1

      # Check score was updated
      updated = Repo.get!(Thread, thread.id)
      assert updated.score == 1
    end

    test "cast_vote/4 creates a downvote on comment" do
      thread = thread_fixture()
      comment = comment_fixture(thread)
      user = user_fixture()

      {:ok, {:ok, vote}} = Forum.cast_vote(user.id, "comment", comment.id, -1)

      assert vote.value == -1

      updated = Repo.get!(Comment, comment.id)
      assert updated.score == -1
    end

    test "cast_vote/4 replaces existing vote and updates score delta" do
      thread = thread_fixture()
      user = user_fixture()

      # Initial upvote
      {:ok, {:ok, _}} = Forum.cast_vote(user.id, "thread", thread.id, 1)
      assert Repo.get!(Thread, thread.id).score == 1

      # Change to downvote
      {:ok, {:ok, updated_vote}} = Forum.cast_vote(user.id, "thread", thread.id, -1)
      assert updated_vote.value == -1

      # Score should be -1 (delta of -2 applied)
      assert Repo.get!(Thread, thread.id).score == -1
    end

    test "cast_vote/4 validates vote value" do
      thread = thread_fixture()
      user = user_fixture()

      {:error, changeset} = Forum.cast_vote(user.id, "thread", thread.id, 0)
      refute changeset.valid?
    end

    test "get_user_vote/3 retrieves user's vote" do
      thread = thread_fixture()
      user = user_fixture()

      {:ok, {:ok, _}} = Forum.cast_vote(user.id, "thread", thread.id, 1)

      vote = Forum.get_user_vote(user.id, "thread", thread.id)

      assert vote.user_id == user.id
      assert vote.value == 1
    end

    test "get_user_vote/3 returns nil if no vote exists" do
      thread = thread_fixture()
      user = user_fixture()

      vote = Forum.get_user_vote(user.id, "thread", thread.id)

      assert is_nil(vote)
    end

    test "unvote/3 removes vote and updates score" do
      thread = thread_fixture()
      user = user_fixture()

      {:ok, {:ok, _}} = Forum.cast_vote(user.id, "thread", thread.id, 1)
      assert Repo.get!(Thread, thread.id).score == 1

      {:ok, _} = Forum.unvote(user.id, "thread", thread.id)

      assert is_nil(Forum.get_user_vote(user.id, "thread", thread.id))
      assert Repo.get!(Thread, thread.id).score == 0
    end

    test "unvote/3 returns {:ok, nil} if no vote exists" do
      thread = thread_fixture()
      user = user_fixture()

      {:ok, nil} = Forum.unvote(user.id, "thread", thread.id)
    end

    test "vote unique constraint prevents duplicate votes per user" do
      thread = thread_fixture()
      user = user_fixture()

      {:ok, {:ok, _}} = Forum.cast_vote(user.id, "thread", thread.id, 1)

      # Attempting another insert with same user, target, type should fail
      # But our implementation updates instead, so this is tested implicitly
      {:ok, {:ok, vote2}} = Forum.cast_vote(user.id, "thread", thread.id, 1)

      # Should be only one vote
      votes =
        Repo.all(
          from(v in Vote,
            where:
              v.user_id == ^user.id and v.target_type == "thread" and v.target_id == ^thread.id
          )
        )

      assert length(votes) == 1
      assert votes |> List.first() |> Map.get(:value) == 1
    end
  end

  describe "moderation" do
    test "remove_thread/2 marks thread as removed and tracks admin" do
      thread = thread_fixture()
      admin = admin_fixture()

      {:ok, updated} = Forum.remove_thread(thread, admin)

      assert updated.is_removed == true
      assert updated.removed_by_id == admin.id
    end

    test "remove_comment/2 marks comment as removed and tracks admin" do
      thread = thread_fixture()
      comment = comment_fixture(thread)
      admin = admin_fixture()

      {:ok, updated} = Forum.remove_comment(comment, admin)

      assert updated.is_removed == true
      assert updated.removed_by_id == admin.id
    end
  end

  describe "pagination" do
    test "list_threads/2 respects limit and offset" do
      board = board_fixture()
      Enum.each(1..5, fn _ -> thread_fixture(%{board_id: board.id}) end)

      page1 = Forum.list_threads(board.id, limit: 2, offset: 0)
      page2 = Forum.list_threads(board.id, limit: 2, offset: 2)

      assert length(page1) == 2
      assert length(page2) == 2
      assert Enum.at(page1, 0).id != Enum.at(page2, 0).id
    end
  end

  describe "search" do
    test "search_threads/2 returns empty list for empty query" do
      board = board_fixture()
      thread_fixture(%{board_id: board.id, title: "Searchable Thread", body: "Content here"})

      results = Forum.search_threads("")

      assert results == []
    end

    test "search_threads/2 finds threads by title" do
      board = board_fixture()

      thread =
        thread_fixture(%{
          board_id: board.id,
          title: "Phoenix LiveView Guide",
          body: "How to use LiveView"
        })

      results = Forum.search_threads("Phoenix")

      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == thread.id))
    end

    test "search_threads/2 finds threads by body" do
      board = board_fixture()

      thread =
        thread_fixture(%{
          board_id: board.id,
          title: "A Question",
          body: "How do I use Ecto queries?"
        })

      results = Forum.search_threads("Ecto")

      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == thread.id))
    end

    test "search_threads/2 prioritizes title matches over body matches" do
      board = board_fixture()

      title_match =
        thread_fixture(%{
          board_id: board.id,
          title: "Elixir Best Practices",
          body: "This is about coding"
        })

      body_match =
        thread_fixture(%{board_id: board.id, title: "A Question", body: "Elixir tips and tricks"})

      results = Forum.search_threads("Elixir")

      assert length(results) >= 2
      # Title match should come before body match due to ts_rank weightings
      assert Enum.find_index(results, &(&1.id == title_match.id)) <=
               Enum.find_index(results, &(&1.id == body_match.id))
    end

    test "search_threads/2 respects board_id filter" do
      board1 = board_fixture()
      board2 = board_fixture()

      thread1 =
        thread_fixture(%{
          board_id: board1.id,
          title: "Phoenix topic",
          body: "Detailed content about Phoenix"
        })

      thread2 =
        thread_fixture(%{
          board_id: board2.id,
          title: "Phoenix framework",
          body: "More detailed content here"
        })

      results = Forum.search_threads("Phoenix", board_id: board1.id)

      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == thread1.id))
      assert !Enum.any?(results, &(&1.id == thread2.id))
    end

    test "search_threads/2 excludes removed threads" do
      board = board_fixture()

      active =
        thread_fixture(%{
          board_id: board.id,
          title: "Active Thread",
          body: "This thread is active"
        })

      removed =
        thread_fixture(%{
          board_id: board.id,
          title: "Removed Thread",
          body: "This thread is removed",
          is_removed: true
        })

      results = Forum.search_threads("Thread")

      assert Enum.any?(results, &(&1.id == active.id))
      assert !Enum.any?(results, &(&1.id == removed.id))
    end

    test "search_threads/2 respects limit and offset" do
      board = board_fixture()

      Enum.each(1..5, fn i ->
        thread_fixture(%{board_id: board.id, title: "Test #{i}", body: "Test content"})
      end)

      page1 = Forum.search_threads("Test", limit: 2, offset: 0)
      page2 = Forum.search_threads("Test", limit: 2, offset: 2)

      assert length(page1) == 2
      assert length(page2) == 2
      assert Enum.at(page1, 0).id != Enum.at(page2, 0).id
    end
  end

  describe "thread links" do
    test "create_thread_link/3 links a thread to a lesson" do
      thread = thread_fixture()

      {:ok, link} = Forum.create_thread_link(thread.id, "lesson", 123)

      assert link.thread_id == thread.id
      assert link.link_type == "lesson"
      assert link.link_id == 123
    end

    test "get_thread_by_link/2 retrieves thread by link" do
      thread = thread_fixture()
      {:ok, _link} = Forum.create_thread_link(thread.id, "lesson", 123)

      result = Forum.get_thread_by_link("lesson", 123)

      assert result.id == thread.id
    end

    test "get_thread_by_link/2 returns nil if link doesn't exist" do
      result = Forum.get_thread_by_link("lesson", 999)

      assert result == nil
    end

    test "list_lesson_threads/2 returns threads linked to lesson" do
      thread1 = thread_fixture()
      thread2 = thread_fixture()
      other = thread_fixture()

      {:ok, _} = Forum.create_thread_link(thread1.id, "lesson", 100)
      {:ok, _} = Forum.create_thread_link(thread2.id, "lesson", 101)
      {:ok, _} = Forum.create_thread_link(other.id, "lesson", 102)

      results = Forum.list_lesson_threads(100)

      assert length(results) == 1
      assert Enum.any?(results, &(&1.id == thread1.id))
      assert !Enum.any?(results, &(&1.id == thread2.id))
      assert !Enum.any?(results, &(&1.id == other.id))
    end

    test "list_lesson_threads/2 excludes removed threads" do
      active = thread_fixture()
      removed = thread_fixture(%{is_removed: true})

      {:ok, _} = Forum.create_thread_link(active.id, "lesson", 100)
      {:ok, _} = Forum.create_thread_link(removed.id, "lesson", 101)

      results = Forum.list_lesson_threads(100)

      assert Enum.any?(results, &(&1.id == active.id))

      results_other = Forum.list_lesson_threads(101)
      assert !Enum.any?(results_other, &(&1.id == removed.id))
    end

    test "create_thread_link/3 enforces unique constraint on link_type and link_id" do
      thread1 = thread_fixture()
      thread2 = thread_fixture()

      {:ok, _} = Forum.create_thread_link(thread1.id, "lesson", 100)
      {:error, changeset} = Forum.create_thread_link(thread2.id, "lesson", 100)

      assert changeset.errors |> Enum.any?(fn {field, _} -> field == :link_type end)
    end
  end

  describe "saved threads" do
    test "save_thread/2 saves a thread for a user" do
      user = user_fixture()
      thread = thread_fixture()

      {:ok, saved} = Forum.save_thread(user.id, thread.id)

      assert saved.user_id == user.id
      assert saved.thread_id == thread.id
    end

    test "unsave_thread/2 removes a saved thread" do
      user = user_fixture()
      thread = thread_fixture()
      {:ok, _} = Forum.save_thread(user.id, thread.id)

      {:ok, _} = Forum.unsave_thread(user.id, thread.id)

      assert !Forum.is_thread_saved?(user.id, thread.id)
    end

    test "unsave_thread/2 returns error if thread not saved" do
      user = user_fixture()
      thread = thread_fixture()

      {:error, :not_found} = Forum.unsave_thread(user.id, thread.id)
    end

    test "is_thread_saved?/2 checks if thread is saved" do
      user = user_fixture()
      thread = thread_fixture()

      assert !Forum.is_thread_saved?(user.id, thread.id)

      {:ok, _} = Forum.save_thread(user.id, thread.id)

      assert Forum.is_thread_saved?(user.id, thread.id)
    end

    test "list_saved_threads/2 returns user's saved threads" do
      user = user_fixture()
      thread1 = thread_fixture()
      thread2 = thread_fixture()
      removed = thread_fixture(%{is_removed: true})

      {:ok, _} = Forum.save_thread(user.id, thread1.id)
      {:ok, _} = Forum.save_thread(user.id, thread2.id)
      {:ok, _} = Forum.save_thread(user.id, removed.id)

      results = Forum.list_saved_threads(user.id)

      assert length(results) == 2
      assert Enum.any?(results, &(&1.id == thread1.id))
      assert Enum.any?(results, &(&1.id == thread2.id))
      assert !Enum.any?(results, &(&1.id == removed.id))
    end

    test "list_saved_threads/2 respects limit and offset" do
      user = user_fixture()

      Enum.each(1..5, fn _ ->
        thread = thread_fixture()
        Forum.save_thread(user.id, thread.id)
      end)

      page1 = Forum.list_saved_threads(user.id, limit: 2, offset: 0)
      page2 = Forum.list_saved_threads(user.id, limit: 2, offset: 2)

      assert length(page1) == 2
      assert length(page2) == 2
      assert Enum.at(page1, 0).id != Enum.at(page2, 0).id
    end

    test "count_saved_threads/1 returns count of saved threads" do
      user = user_fixture()
      thread1 = thread_fixture()
      thread2 = thread_fixture()

      assert Forum.count_saved_threads(user.id) == 0

      {:ok, _} = Forum.save_thread(user.id, thread1.id)
      assert Forum.count_saved_threads(user.id) == 1

      {:ok, _} = Forum.save_thread(user.id, thread2.id)
      assert Forum.count_saved_threads(user.id) == 2
    end

    test "save_thread/2 enforces unique constraint per user" do
      user = user_fixture()
      thread = thread_fixture()

      {:ok, _} = Forum.save_thread(user.id, thread.id)
      {:error, changeset} = Forum.save_thread(user.id, thread.id)

      assert changeset.errors |> Enum.any?(fn {field, _} -> field == :user_id end)
    end
  end

  describe "tags/flair" do
    test "create_tag/1 creates a tag" do
      {:ok, tag} = Forum.create_tag(%{name: "Beginner", slug: "beginner"})

      assert tag.name == "Beginner"
      assert tag.slug == "beginner"
    end

    test "get_tag!/1 retrieves tag by id" do
      {:ok, tag} = Forum.create_tag(%{name: "Advanced", slug: "advanced"})

      retrieved = Forum.get_tag!(tag.id)

      assert retrieved.id == tag.id
      assert retrieved.name == "Advanced"
    end

    test "get_tag_by_slug/1 retrieves tag by slug" do
      {:ok, tag} = Forum.create_tag(%{name: "Question", slug: "question"})

      retrieved = Forum.get_tag_by_slug("question")

      assert retrieved.id == tag.id
    end

    test "list_tags/1 returns all tags" do
      {:ok, tag1} = Forum.create_tag(%{name: "Bug", slug: "bug"})
      {:ok, tag2} = Forum.create_tag(%{name: "Feature", slug: "feature"})

      tags = Forum.list_tags()

      assert length(tags) >= 2
      assert Enum.any?(tags, &(&1.id == tag1.id))
      assert Enum.any?(tags, &(&1.id == tag2.id))
    end

    test "add_tag_to_thread/2 adds tag to thread" do
      {:ok, tag} = Forum.create_tag(%{name: "Help", slug: "help"})
      thread = thread_fixture()

      {:ok, thread_tag} = Forum.add_tag_to_thread(thread.id, tag.id)

      assert thread_tag.thread_id == thread.id
      assert thread_tag.tag_id == tag.id
    end

    test "remove_tag_from_thread/2 removes tag from thread" do
      {:ok, tag} = Forum.create_tag(%{name: "Solved", slug: "solved"})
      thread = thread_fixture()
      {:ok, _} = Forum.add_tag_to_thread(thread.id, tag.id)

      {:ok, _} = Forum.remove_tag_from_thread(thread.id, tag.id)

      tags = Forum.list_thread_tags(thread.id)
      assert !Enum.any?(tags, &(&1.id == tag.id))
    end

    test "list_thread_tags/1 returns tags for a thread" do
      {:ok, tag1} = Forum.create_tag(%{name: "Tag1", slug: "tag1"})
      {:ok, tag2} = Forum.create_tag(%{name: "Tag2", slug: "tag2"})
      thread = thread_fixture()

      {:ok, _} = Forum.add_tag_to_thread(thread.id, tag1.id)
      {:ok, _} = Forum.add_tag_to_thread(thread.id, tag2.id)

      tags = Forum.list_thread_tags(thread.id)

      assert length(tags) == 2
      assert Enum.any?(tags, &(&1.id == tag1.id))
      assert Enum.any?(tags, &(&1.id == tag2.id))
    end

    test "list_threads_by_tag/2 returns threads with tag" do
      {:ok, tag} = Forum.create_tag(%{name: "Popular", slug: "popular"})
      thread1 = thread_fixture()
      thread2 = thread_fixture()
      removed = thread_fixture(%{is_removed: true})

      {:ok, _} = Forum.add_tag_to_thread(thread1.id, tag.id)
      {:ok, _} = Forum.add_tag_to_thread(thread2.id, tag.id)
      {:ok, _} = Forum.add_tag_to_thread(removed.id, tag.id)

      threads = Forum.list_threads_by_tag(tag.id)

      assert length(threads) == 2
      assert Enum.any?(threads, &(&1.id == thread1.id))
      assert Enum.any?(threads, &(&1.id == thread2.id))
      assert !Enum.any?(threads, &(&1.id == removed.id))
    end

    test "add_tag_to_thread/2 enforces unique constraint" do
      {:ok, tag} = Forum.create_tag(%{name: "Unique", slug: "unique"})
      thread = thread_fixture()

      {:ok, _} = Forum.add_tag_to_thread(thread.id, tag.id)
      {:error, changeset} = Forum.add_tag_to_thread(thread.id, tag.id)

      assert changeset.errors |> Enum.any?(fn {field, _} -> field == :thread_id end)
    end
  end

  describe "reporting/moderation" do
    test "create_report/4 creates a report for a thread" do
      user = user_fixture()
      thread = thread_fixture()

      {:ok, report} =
        Forum.create_report(user.id, "thread", thread.id, %{
          reason: "spam",
          description: "This is spam content"
        })

      assert report.user_id == user.id
      assert report.target_type == "thread"
      assert report.target_id == thread.id
      assert report.reason == "spam"
      assert report.status == "pending"
    end

    test "create_report/4 creates a report for a comment" do
      user = user_fixture()
      thread = thread_fixture()
      comment = comment_fixture(thread)

      {:ok, report} =
        Forum.create_report(user.id, "comment", comment.id, %{
          reason: "abuse",
          description: "Abusive language"
        })

      assert report.target_type == "comment"
      assert report.target_id == comment.id
    end

    test "list_reports/1 returns pending reports by default" do
      user = user_fixture()
      thread1 = thread_fixture()
      thread2 = thread_fixture()

      {:ok, report1} =
        Forum.create_report(user.id, "thread", thread1.id, %{
          reason: "spam",
          description: "Spam content"
        })

      {:ok, _report2} =
        Forum.create_report(user.id, "thread", thread2.id, %{
          reason: "abuse",
          description: "Abusive language"
        })

      reports = Forum.list_reports()

      assert length(reports) >= 2
      assert Enum.all?(reports, &(&1.status == "pending"))
    end

    test "list_reports/1 filters by status" do
      user = user_fixture()
      admin = admin_fixture()
      thread1 = thread_fixture()
      thread2 = thread_fixture()

      {:ok, report1} =
        Forum.create_report(user.id, "thread", thread1.id, %{
          reason: "spam",
          description: "Spam content"
        })

      {:ok, _report2} =
        Forum.create_report(user.id, "thread", thread2.id, %{
          reason: "abuse",
          description: "Abusive language"
        })

      # Review one report
      {:ok, _} = Forum.review_report(report1, admin.id, "resolved", "Removed spam")

      pending = Forum.list_reports(status: "pending")
      resolved = Forum.list_reports(status: "resolved")

      assert Enum.all?(pending, &(&1.status == "pending"))
      assert Enum.all?(resolved, &(&1.status == "resolved"))
    end

    test "get_report!/1 retrieves report with preloads" do
      user = user_fixture()
      thread = thread_fixture()

      {:ok, report} =
        Forum.create_report(user.id, "thread", thread.id, %{
          reason: "spam",
          description: "Spam content"
        })

      retrieved = Forum.get_report!(report.id)

      assert retrieved.id == report.id
      assert retrieved.user.id == user.id
    end

    test "review_report/4 updates report status" do
      user = user_fixture()
      admin = admin_fixture()
      thread = thread_fixture()

      {:ok, report} =
        Forum.create_report(user.id, "thread", thread.id, %{
          reason: "spam",
          description: "Spam content"
        })

      {:ok, updated} = Forum.review_report(report, admin.id, "resolved", "Removed spam")

      assert updated.status == "resolved"
      assert updated.reviewed_by_id == admin.id
      assert updated.resolution_notes == "Removed spam"
      assert updated.resolved_at != nil
    end

    test "count_pending_reports/0 counts pending reports" do
      user = user_fixture()
      admin = admin_fixture()
      thread1 = thread_fixture()
      thread2 = thread_fixture()

      assert Forum.count_pending_reports() == 0

      {:ok, report1} =
        Forum.create_report(user.id, "thread", thread1.id, %{
          reason: "spam",
          description: "Spam content"
        })

      assert Forum.count_pending_reports() == 1

      {:ok, _} =
        Forum.create_report(user.id, "thread", thread2.id, %{
          reason: "abuse",
          description: "Abusive language"
        })

      assert Forum.count_pending_reports() == 2

      {:ok, _} = Forum.review_report(report1, admin.id, "resolved")
      assert Forum.count_pending_reports() == 1
    end

    test "list_reports_by_target/2 returns reports for a specific target" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      thread1 = thread_fixture()
      thread2 = thread_fixture()

      {:ok, _} =
        Forum.create_report(user1.id, "thread", thread1.id, %{
          reason: "spam",
          description: "Spam content"
        })

      {:ok, _} =
        Forum.create_report(user2.id, "thread", thread1.id, %{
          reason: "abuse",
          description: "Abusive language"
        })

      {:ok, _} =
        Forum.create_report(user3.id, "thread", thread2.id, %{
          reason: "offensive",
          description: "Offensive content"
        })

      reports = Forum.list_reports_by_target("thread", thread1.id)

      assert length(reports) == 2
      assert Enum.all?(reports, &(&1.target_id == thread1.id))
    end

    test "create_report/4 enforces unique constraint per user" do
      user = user_fixture()
      thread = thread_fixture()

      {:ok, _} =
        Forum.create_report(user.id, "thread", thread.id, %{
          reason: "spam",
          description: "Spam content"
        })

      {:error, changeset} =
        Forum.create_report(user.id, "thread", thread.id, %{
          reason: "abuse",
          description: "Abusive language"
        })

      assert changeset.errors |> Enum.any?(fn {field, _} -> field == :user_id end)
    end
  end

  describe "subscriptions" do
    test "subscribe_to_thread/2 subscribes user to thread" do
      user = user_fixture()
      thread = thread_fixture()

      {:ok, subscription} = Forum.subscribe_to_thread(user.id, thread.id)

      assert subscription.user_id == user.id
      assert subscription.thread_id == thread.id
    end

    test "unsubscribe_from_thread/2 unsubscribes user" do
      user = user_fixture()
      thread = thread_fixture()
      {:ok, _} = Forum.subscribe_to_thread(user.id, thread.id)

      {:ok, _} = Forum.unsubscribe_from_thread(user.id, thread.id)

      assert !Forum.is_subscribed?(user.id, thread.id)
    end

    test "is_subscribed?/2 checks subscription status" do
      user = user_fixture()
      thread = thread_fixture()

      assert !Forum.is_subscribed?(user.id, thread.id)

      {:ok, _} = Forum.subscribe_to_thread(user.id, thread.id)

      assert Forum.is_subscribed?(user.id, thread.id)
    end

    test "list_subscriptions/2 returns user's subscribed threads" do
      user = user_fixture()
      thread1 = thread_fixture()
      thread2 = thread_fixture()
      removed = thread_fixture(%{is_removed: true})

      {:ok, _} = Forum.subscribe_to_thread(user.id, thread1.id)
      {:ok, _} = Forum.subscribe_to_thread(user.id, thread2.id)
      {:ok, _} = Forum.subscribe_to_thread(user.id, removed.id)

      subscriptions = Forum.list_subscriptions(user.id)

      assert length(subscriptions) == 2
      assert Enum.any?(subscriptions, &(&1.id == thread1.id))
      assert Enum.any?(subscriptions, &(&1.id == thread2.id))
      assert !Enum.any?(subscriptions, &(&1.id == removed.id))
    end

    test "count_subscriptions/1 returns subscription count" do
      user = user_fixture()
      thread1 = thread_fixture()
      thread2 = thread_fixture()

      assert Forum.count_subscriptions(user.id) == 0

      {:ok, _} = Forum.subscribe_to_thread(user.id, thread1.id)
      assert Forum.count_subscriptions(user.id) == 1

      {:ok, _} = Forum.subscribe_to_thread(user.id, thread2.id)
      assert Forum.count_subscriptions(user.id) == 2
    end
  end

  describe "notifications" do
    test "create_notification/4 creates a notification" do
      user = user_fixture()
      actor = user_fixture()
      thread = thread_fixture()

      {:ok, notification} =
        Forum.create_notification(user.id, "comment", thread.id, %{
          actor_id: actor.id,
          thread_id: thread.id,
          message: "Someone replied to your comment"
        })

      assert notification.user_id == user.id
      assert notification.subject_type == "comment"
      assert notification.subject_id == thread.id
      assert is_nil(notification.read_at)
    end

    test "list_notifications/2 returns user's notifications" do
      user = user_fixture()
      actor = user_fixture()
      thread = thread_fixture()

      {:ok, notif1} =
        Forum.create_notification(user.id, "comment", thread.id, %{actor_id: actor.id})

      {:ok, notif2} =
        Forum.create_notification(user.id, "reply", thread.id, %{actor_id: actor.id})

      notifications = Forum.list_notifications(user.id)

      assert length(notifications) >= 2
      assert Enum.any?(notifications, &(&1.id == notif1.id))
      assert Enum.any?(notifications, &(&1.id == notif2.id))
    end

    test "list_notifications/2 filters unread only" do
      user = user_fixture()
      actor = user_fixture()
      thread = thread_fixture()

      {:ok, notif1} =
        Forum.create_notification(user.id, "comment", thread.id, %{actor_id: actor.id})

      {:ok, notif2} =
        Forum.create_notification(user.id, "reply", thread.id, %{actor_id: actor.id})

      Forum.mark_notification_as_read(notif1.id)

      unread = Forum.list_notifications(user.id, unread_only: true)

      assert length(unread) >= 1
      assert !Enum.any?(unread, &(&1.id == notif1.id))
      assert Enum.any?(unread, &(&1.id == notif2.id))
    end

    test "mark_notification_as_read/1 marks notification read" do
      user = user_fixture()
      thread = thread_fixture()

      {:ok, notification} = Forum.create_notification(user.id, "comment", thread.id)

      {:ok, updated} = Forum.mark_notification_as_read(notification.id)

      assert updated.read_at != nil
    end

    test "mark_all_notifications_as_read/1 marks all as read" do
      user = user_fixture()
      thread = thread_fixture()

      {:ok, _} = Forum.create_notification(user.id, "comment", thread.id)
      {:ok, _} = Forum.create_notification(user.id, "reply", thread.id)

      {count, _} = Forum.mark_all_notifications_as_read(user.id)

      assert count == 2

      unread = Forum.list_notifications(user.id, unread_only: true)
      assert length(unread) == 0
    end

    test "count_unread_notifications/1 returns unread count" do
      user = user_fixture()
      thread = thread_fixture()

      assert Forum.count_unread_notifications(user.id) == 0

      {:ok, notif1} = Forum.create_notification(user.id, "comment", thread.id)
      assert Forum.count_unread_notifications(user.id) == 1

      {:ok, _notif2} = Forum.create_notification(user.id, "reply", thread.id)
      assert Forum.count_unread_notifications(user.id) == 2

      Forum.mark_notification_as_read(notif1.id)
      assert Forum.count_unread_notifications(user.id) == 1
    end

    test "notify_thread_subscribers/4 notifies all subscribers" do
      subscriber1 = user_fixture()
      subscriber2 = user_fixture()
      actor = user_fixture()
      thread = thread_fixture()

      {:ok, _} = Forum.subscribe_to_thread(subscriber1.id, thread.id)
      {:ok, _} = Forum.subscribe_to_thread(subscriber2.id, thread.id)

      {:ok, count} =
        Forum.notify_thread_subscribers(thread.id, actor.id, "comment", "New comment")

      assert count == 2

      notif1 = Forum.list_notifications(subscriber1.id) |> Enum.at(0)
      notif2 = Forum.list_notifications(subscriber2.id) |> Enum.at(0)

      assert notif1.actor_id == actor.id
      assert notif2.actor_id == actor.id
      assert notif1.message == "New comment"
    end

    test "notify_thread_subscribers/4 excludes actor" do
      subscriber = user_fixture()
      actor = user_fixture()
      thread = thread_fixture()

      {:ok, _} = Forum.subscribe_to_thread(subscriber.id, thread.id)
      {:ok, _} = Forum.subscribe_to_thread(actor.id, thread.id)

      {:ok, count} =
        Forum.notify_thread_subscribers(thread.id, actor.id, "comment", "New comment")

      assert count == 1

      actor_notifications = Forum.list_notifications(actor.id)
      assert length(actor_notifications) == 0
    end
  end
end
