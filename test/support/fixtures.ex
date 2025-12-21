defmodule Urielm.Fixtures do
  @moduledoc """
  This module defines test fixtures for creating test data.
  """

  alias Urielm.Repo
  alias Urielm.Forum.Vote

  def user_fixture(attrs \\ %{}) do
    unique_suffix = random_string()

    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "user#{unique_suffix}@example.com",
        username: "user#{unique_suffix}",
        display_name: "Test User #{unique_suffix}",
        password: "password123"
      })
      |> Urielm.Accounts.register_user()

    user
    |> Ecto.Changeset.change(%{trust_level: 0})
    |> Repo.update!()
  end

  def admin_fixture(attrs \\ %{}) do
    unique_suffix = random_string()

    {:ok, admin} =
      attrs
      |> Enum.into(%{
        email: "admin#{unique_suffix}@example.com",
        username: "admin#{unique_suffix}",
        display_name: "Admin User #{unique_suffix}",
        password: "password123"
      })
      |> Urielm.Accounts.register_user()

    admin
    |> Ecto.Changeset.change(%{is_admin: true, trust_level: 4})
    |> Repo.update!()
  end

  def category_fixture(attrs \\ %{}) do
    unique_suffix = random_string()

    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "Test Category",
        slug: "test-category-#{unique_suffix}"
      })
      |> Urielm.Forum.create_category()

    category
  end

  def board_fixture(attrs \\ %{}) do
    {category_id, attrs} = Map.pop(attrs, :category_id)
    category_id = category_id || category_fixture().id
    unique_suffix = random_string()

    {:ok, board} =
      attrs
      |> Enum.into(%{
        category_id: category_id,
        name: "Test Board",
        slug: "test-board-#{unique_suffix}",
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
    unique_suffix = random_string()

    thread_attrs = %{
      "title" => "Test Thread",
      "slug" => "test-thread-#{unique_suffix}",
      "body" => "This is a test thread body"
    }

    # Normalize attrs to string keys and merge
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)

    {:ok, thread} =
      Urielm.Forum.create_thread(board_id, author_id, Map.merge(thread_attrs, attrs))

    thread
  end

  def comment_fixture(thread, author \\ nil, attrs \\ %{}) do
    author = author || user_fixture()

    comment_attrs = %{
      "body" => "This is a test comment"
    }

    # Normalize attrs to string keys and merge
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)

    {:ok, comment} =
      Urielm.Forum.create_comment(thread.id, author.id, Map.merge(comment_attrs, attrs))

    comment
  end

  def vote_fixture(user, target_type, target_id, value \\ 1) do
    {:ok, _} = Urielm.Forum.cast_vote(user.id, target_type, target_id, value)
    # Return the created vote
    Repo.get_by(Vote, user_id: user.id, target_type: target_type, target_id: target_id)
  end

  def video_fixture(attrs \\ %{}) do
    unique_suffix = random_string()

    {:ok, video} =
      attrs
      |> Enum.into(%{
        title: "Test Video #{unique_suffix}",
        slug: "test-video-#{unique_suffix}",
        youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        visibility: "public",
        description_md: "Test description"
      })
      |> Urielm.Content.create_video()

    video
  end

  def subscription_fixture(user, attrs \\ %{}) do
    Repo.insert!(%Urielm.Billing.Subscription{
      user_id: user.id,
      status: attrs[:status] || "active",
      current_period_end: attrs[:current_period_end]
    })
  end

  # Generate cryptographically random string for guaranteed uniqueness
  defp random_string(length \\ 12) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode16(case: :lower)
    |> String.slice(0, length)
  end
end
