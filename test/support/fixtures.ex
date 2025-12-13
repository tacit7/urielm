defmodule Urielm.Fixtures do
  @moduledoc """
  This module defines test fixtures for creating test data.
  """

  alias Urielm.Repo
  alias Urielm.Accounts.User
  alias Urielm.Forum.{Category, Board, Thread, Comment, Vote}

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "user#{System.unique_integer([:positive])}@example.com",
        username: "user#{System.unique_integer([:positive])}",
        name: "Test User",
        password: "password123"
      })
      |> Urielm.Accounts.register_user()

    user
  end

  def admin_fixture(attrs \\ %{}) do
    {:ok, admin} =
      attrs
      |> Enum.into(%{
        email: "admin#{System.unique_integer([:positive])}@example.com",
        username: "admin#{System.unique_integer([:positive])}",
        name: "Admin User",
        password: "password123"
      })
      |> Urielm.Accounts.register_user()

    admin
    |> Ecto.Changeset.change(%{is_admin: true})
    |> Repo.update!()
  end

  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "Test Category",
        slug: "test-category-#{System.unique_integer([:positive])}"
      })
      |> Urielm.Forum.create_category()

    category
  end

  def board_fixture(attrs \\ %{}) do
    category = category_fixture()

    {:ok, board} =
      attrs
      |> Enum.into(%{
        category_id: category.id,
        name: "Test Board",
        slug: "test-board-#{System.unique_integer([:positive])}",
        description: "A test board"
      })
      |> Urielm.Forum.create_board()

    board
  end

  def thread_fixture(attrs \\ %{}) do
    {board_id, attrs} = Map.pop(attrs, :board_id)
    {author_id, attrs} = Map.pop(attrs, :author_id)

    board_id = board_id || board_fixture().id
    author_id = author_id || user_fixture().id

    thread_attrs = %{
      title: "Test Thread",
      slug: "test-thread-#{System.unique_integer([:positive])}",
      body: "This is a test thread body"
    }

    {:ok, thread} =
      Urielm.Forum.create_thread(board_id, author_id, Map.merge(thread_attrs, attrs))

    thread
  end

  def comment_fixture(thread, author \\ nil, attrs \\ %{}) do
    author = author || user_fixture()

    comment_attrs = %{
      body: "This is a test comment"
    }

    {:ok, comment} =
      Urielm.Forum.create_comment(thread.id, author.id, Map.merge(comment_attrs, attrs))

    comment
  end

  def vote_fixture(user, target_type, target_id, value \\ 1) do
    {:ok, _} = Urielm.Forum.cast_vote(user.id, target_type, target_id, value)
    # Return the created vote
    Repo.get_by(Vote, user_id: user.id, target_type: target_type, target_id: target_id)
  end
end
