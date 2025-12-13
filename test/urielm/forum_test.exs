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
end
