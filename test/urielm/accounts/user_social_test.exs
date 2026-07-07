defmodule Urielm.Accounts.UserSocialTest do
  use Urielm.DataCase, async: true

  import Urielm.Fixtures

  alias Urielm.Accounts
  alias Urielm.Forum

  setup do
    user_a = user_fixture()
    user_b = user_fixture()

    %{user_a: user_a, user_b: user_b}
  end

  describe "follow_user/2" do
    test "creates a follow relationship", %{user_a: user_a, user_b: user_b} do
      {:ok, follow} = Accounts.follow_user(user_a.id, user_b.id)
      assert follow.follower_id == user_a.id
      assert follow.following_id == user_b.id
    end

    test "prevents duplicate follows", %{user_a: user_a, user_b: user_b} do
      {:ok, _} = Accounts.follow_user(user_a.id, user_b.id)
      {:error, changeset} = Accounts.follow_user(user_a.id, user_b.id)
      assert changeset.errors[:follower_id] || changeset.errors[:following_id]
    end

    test "prevents following yourself", %{user_a: user_a} do
      {:error, changeset} = Accounts.follow_user(user_a.id, user_a.id)
      assert {"cannot follow yourself", _} = changeset.errors[:following_id]
    end
  end

  describe "unfollow_user/2" do
    test "removes a follow relationship", %{user_a: user_a, user_b: user_b} do
      Accounts.follow_user(user_a.id, user_b.id)
      {:ok, _} = Accounts.unfollow_user(user_a.id, user_b.id)
      refute Accounts.following?(user_a.id, user_b.id)
    end

    test "returns error if not following", %{user_a: user_a, user_b: user_b} do
      assert {:error, :not_found} = Accounts.unfollow_user(user_a.id, user_b.id)
    end
  end

  describe "following?/2" do
    test "returns true when following", %{user_a: user_a, user_b: user_b} do
      Accounts.follow_user(user_a.id, user_b.id)
      assert Accounts.following?(user_a.id, user_b.id)
    end

    test "returns false when not following", %{user_a: user_a, user_b: user_b} do
      refute Accounts.following?(user_a.id, user_b.id)
    end

    test "follow is directional", %{user_a: user_a, user_b: user_b} do
      Accounts.follow_user(user_a.id, user_b.id)
      refute Accounts.following?(user_b.id, user_a.id)
    end
  end

  describe "toggle_follow/2" do
    test "follows when not following", %{user_a: user_a, user_b: user_b} do
      {:ok, _} = Accounts.toggle_follow(user_a.id, user_b.id)
      assert Accounts.following?(user_a.id, user_b.id)
    end

    test "unfollows when already following", %{user_a: user_a, user_b: user_b} do
      Accounts.follow_user(user_a.id, user_b.id)
      {:ok, _} = Accounts.toggle_follow(user_a.id, user_b.id)
      refute Accounts.following?(user_a.id, user_b.id)
    end
  end

  describe "count_followers/1" do
    test "counts followers correctly", %{user_b: user_b} do
      follower1 = user_fixture()
      follower2 = user_fixture()
      Accounts.follow_user(follower1.id, user_b.id)
      Accounts.follow_user(follower2.id, user_b.id)

      assert Accounts.count_followers(user_b.id) == 2
    end

    test "returns 0 for users with no followers", %{user_b: user_b} do
      assert Accounts.count_followers(user_b.id) == 0
    end
  end

  describe "count_following/1" do
    test "counts following correctly", %{user_a: user_a} do
      target1 = user_fixture()
      target2 = user_fixture()
      Accounts.follow_user(user_a.id, target1.id)
      Accounts.follow_user(user_a.id, target2.id)

      assert Accounts.count_following(user_a.id) == 2
    end

    test "returns 0 for users following nobody", %{user_a: user_a} do
      assert Accounts.count_following(user_a.id) == 0
    end
  end

  describe "get_user_stats/1" do
    test "returns correct thread, comment, follower, and following counts", %{user_a: user_a} do
      category = category_fixture()
      board = board_fixture(%{category_id: category.id})
      thread = thread_fixture(%{board_id: board.id, author_id: user_a.id})
      comment_fixture(thread, user_a)
      comment_fixture(thread, user_a)

      follower = user_fixture()
      Accounts.follow_user(follower.id, user_a.id)
      Accounts.follow_user(user_a.id, user_fixture().id)

      stats = Accounts.get_user_stats(user_a.id)

      assert stats.thread_count == 1
      assert stats.comment_count == 2
      assert stats.follower_count == 1
      assert stats.following_count == 1
    end

    test "excludes removed threads and comments from counts", %{user_a: user_a} do
      category = category_fixture()
      board = board_fixture(%{category_id: category.id})
      thread = thread_fixture(%{board_id: board.id, author_id: user_a.id})
      comment = comment_fixture(thread, user_a)

      Forum.remove_thread(thread, user_a)
      Forum.remove_comment(comment, user_a)

      stats = Accounts.get_user_stats(user_a.id)
      assert stats.thread_count == 0
      assert stats.comment_count == 0
    end

    test "returns zeros for new user", %{user_a: user_a} do
      stats = Accounts.get_user_stats(user_a.id)

      assert stats.thread_count == 0
      assert stats.comment_count == 0
      assert stats.follower_count == 0
      assert stats.following_count == 0
    end
  end
end
