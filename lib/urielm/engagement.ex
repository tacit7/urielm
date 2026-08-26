defmodule Urielm.Engagement do
  @moduledoc """
  Unified engagement system for votes and discussions across all content types.

  ## Votes
  Site-wide thumbs up/down (-1/+1) for threads, comments, videos, lessons, prompts, posts.
  Toggle logic: none+up=>+1, +1+up=>remove, -1+up=>switch to +1 (mirror for down).

  ## Discussions
  Maps any content to a forum thread for comments. Lazy creation when first
  comment is posted or comments UI is opened.
  """

  import Ecto.Query
  alias Urielm.Repo
  alias Urielm.Engagement.{Vote, Discussion}
  alias Urielm.Forum
  alias Urielm.Forum.{Thread, Comment}

  # =============================================================================
  # Voting
  # =============================================================================

  @doc """
  Toggle a vote on a target. Implements predictable toggle logic:
  - none + vote => create with value
  - same + vote => remove
  - opposite + vote => switch to value
  """
  def toggle_vote(user_id, target_type, target_id, value)
      when is_integer(value) and value in [-1, 1] do
    Repo.transaction(fn ->
      existing = get_vote(user_id, target_type, target_id)

      {result, score_delta} =
        case {existing, value} do
          # No existing vote: create new
          {nil, v} ->
            {create_vote(user_id, target_type, target_id, v), v}

          # Same value: remove vote
          {%Vote{value: ^value}, _} ->
            {delete_vote(existing), -value}

          # Different value: switch
          {%Vote{value: old_value} = vote, v} ->
            {update_vote(vote, v), v - old_value}
        end

      apply_score_delta(target_type, target_id, score_delta)
      result
    end)
  end

  def toggle_vote(_user_id, _target_type, _target_id, _value) do
    {:error, :invalid_value}
  end

  @doc """
  Cast a vote (upsert behavior - always sets to the given value).
  Use toggle_vote/4 for the predictable toggle pattern.
  """
  def cast_vote(user_id, target_type, target_id, value)
      when is_integer(value) and value in [-1, 1] do
    Repo.transaction(fn ->
      existing = get_vote(user_id, target_type, target_id)

      delta =
        case {existing, value} do
          {nil, v} -> v
          {%Vote{value: old_v}, new_v} -> new_v - old_v
        end

      result =
        case existing do
          nil -> create_vote(user_id, target_type, target_id, value)
          vote -> update_vote(vote, value)
        end

      apply_score_delta(target_type, target_id, delta)
      result
    end)
  end

  def cast_vote(_user_id, _target_type, _target_id, _value) do
    {:error, Vote.changeset(%Vote{}, %{value: 0})}
  end

  @doc """
  Remove a vote from a target.
  """
  def unvote(user_id, target_type, target_id) do
    case get_vote(user_id, target_type, target_id) do
      nil ->
        {:ok, nil}

      vote ->
        Repo.transaction(fn ->
          apply_score_delta(target_type, target_id, -vote.value)
          Repo.delete!(vote)
        end)
    end
  end

  @doc """
  Get a user's vote on a target.
  """
  def get_vote(user_id, target_type, target_id) do
    Repo.get_by(Vote, user_id: user_id, target_type: target_type, target_id: target_id)
  end

  @doc """
  Bulk fetch votes for multiple targets. Returns map of target_id => vote_value.
  """
  def bulk_get_votes(_user_id, _target_type, []), do: %{}

  def bulk_get_votes(user_id, target_type, target_ids) do
    from(v in Vote,
      where:
        v.user_id == ^user_id and v.target_type == ^target_type and v.target_id in ^target_ids,
      select: {v.target_id, v.value}
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Get vote counts for a target. Returns {upvotes, downvotes, score}.
  """
  def get_vote_counts(target_type, target_id) do
    query =
      from(v in Vote,
        where: v.target_type == ^target_type and v.target_id == ^target_id,
        select: %{
          upvotes: sum(fragment("CASE WHEN value = 1 THEN 1 ELSE 0 END")),
          downvotes: sum(fragment("CASE WHEN value = -1 THEN 1 ELSE 0 END")),
          score: sum(v.value)
        }
      )

    case Repo.one(query) do
      nil -> {0, 0, 0}
      %{upvotes: up, downvotes: down, score: score} -> {up || 0, down || 0, score || 0}
    end
  end

  # Private vote helpers

  defp create_vote(user_id, target_type, target_id, value) do
    %Vote{}
    |> Vote.changeset(%{
      user_id: user_id,
      target_type: target_type,
      target_id: target_id,
      value: value
    })
    |> Repo.insert!()
  end

  defp update_vote(vote, value) do
    vote
    |> Vote.changeset(%{value: value})
    |> Repo.update!()
  end

  defp delete_vote(vote) do
    Repo.delete!(vote)
    nil
  end

  defp apply_score_delta("thread", target_id, delta) do
    from(t in Thread, where: t.id == ^target_id)
    |> Repo.update_all(inc: [score: delta])
  end

  defp apply_score_delta("comment", target_id, delta) do
    from(c in Comment, where: c.id == ^target_id)
    |> Repo.update_all(inc: [score: delta])
  end

  defp apply_score_delta(_target_type, _target_id, _delta) do
    # Other content types don't have score fields (yet)
    :ok
  end

  # =============================================================================
  # Discussions (Content → Thread mapping)
  # =============================================================================

  @doc """
  Get or create a discussion thread for a content item.
  Lazy creation: creates thread when first accessed.

  Options:
  - :board_id - board to create thread in (required for creation)
  - :title - thread title (defaults to content title)
  - :author_id - thread author (defaults to system user)
  """
  def get_or_create_discussion(target_type, target_id, opts \\ []) do
    case get_discussion(target_type, target_id) do
      %Discussion{} = discussion ->
        {:ok, Repo.preload(discussion, :thread)}

      nil ->
        create_discussion(target_type, target_id, opts)
    end
  end

  @doc """
  Get existing discussion for a content item.
  """
  def get_discussion(target_type, target_id) do
    Repo.get_by(Discussion, target_type: target_type, target_id: target_id)
  end

  @doc """
  Get discussion by thread ID.
  """
  def get_discussion_by_thread(thread_id) do
    Repo.get_by(Discussion, thread_id: thread_id)
  end

  @doc """
  Create a new discussion thread for content.
  """
  def create_discussion(target_type, target_id, opts) do
    board_id = Keyword.fetch!(opts, :board_id)
    title = Keyword.get(opts, :title, "Discussion")
    author_id = Keyword.fetch!(opts, :author_id)

    Repo.transaction(fn ->
      # Create hidden thread for comments
      {:ok, thread} =
        Forum.create_thread(board_id, author_id, %{
          title: title,
          body: "Comments for #{target_type} #{target_id}",
          kind: "discussion"
        })

      # Create mapping
      %Discussion{}
      |> Discussion.changeset(%{
        target_type: target_type,
        target_id: target_id,
        thread_id: thread.id
      })
      |> Repo.insert!()
      |> Repo.preload(:thread)
    end)
  end

  @doc """
  Check if a content item has a discussion thread.
  """
  def has_discussion?(target_type, target_id) do
    from(d in Discussion,
      where: d.target_type == ^target_type and d.target_id == ^target_id
    )
    |> Repo.exists?()
  end

  @doc """
  Bulk check which content items have discussions.
  Returns MapSet of target_ids that have discussions.
  """
  def bulk_has_discussions(_target_type, []), do: MapSet.new()

  def bulk_has_discussions(target_type, target_ids) do
    from(d in Discussion,
      where: d.target_type == ^target_type and d.target_id in ^target_ids,
      select: d.target_id
    )
    |> Repo.all()
    |> MapSet.new()
  end
end
