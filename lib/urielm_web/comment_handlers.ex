defmodule UrielmWeb.CommentHandlers do
  @moduledoc """
  Shared, thread-scoped comment mutations for LiveView surfaces.

  Page-specific authentication, flashes, and refresh behavior remain in the
  calling LiveView. This module owns the invariant that a comment mutation can
  only target a comment belonging to the active discussion thread.
  """

  alias Urielm.{Engagement, Forum}

  def create(%{id: thread_id}, body, parent_id, user) do
    attrs = %{"body" => body}
    attrs = if parent_id in [nil, ""], do: attrs, else: Map.put(attrs, "parent_id", parent_id)

    Forum.create_comment(thread_id, user.id, attrs)
  end

  def create(_thread, _body, _parent_id, _user), do: {:error, :not_found}

  def edit(thread, comment_id, body, user) do
    with {:ok, comment} <- fetch_for_thread(thread, comment_id) do
      Forum.edit_comment(comment, body, user)
    end
  end

  def delete(thread, comment_id, user) do
    with {:ok, comment} <- fetch_for_thread(thread, comment_id) do
      Forum.remove_comment(comment, user)
    end
  end

  def report(thread, comment_id, attrs, user) do
    with {:ok, comment} <- fetch_for_thread(thread, comment_id) do
      Forum.create_report(user.id, "comment", comment.id, attrs)
    end
  end

  def vote(thread, comment_id, value, user, strategy) when strategy in [:cast, :toggle] do
    with {:ok, _comment} <- fetch_for_thread(thread, comment_id),
         {:ok, value} <- parse_vote(value) do
      case strategy do
        :cast -> Forum.cast_vote(user.id, "comment", comment_id, value)
        :toggle -> Engagement.toggle_vote(user.id, "comment", comment_id, value)
      end
    end
  end

  def fetch_for_thread(%{id: thread_id}, comment_id) do
    case Forum.get_comment(comment_id) do
      nil ->
        {:error, :not_found}

      comment ->
        if to_string(comment.thread_id) == to_string(thread_id) do
          {:ok, comment}
        else
          {:error, :not_found}
        end
    end
  end

  def fetch_for_thread(_thread, _comment_id), do: {:error, :not_found}

  defp parse_vote(value) when is_integer(value) and value in [-1, 1], do: {:ok, value}

  defp parse_vote(value) when is_binary(value) do
    case Integer.parse(value) do
      {value, ""} when value in [-1, 1] -> {:ok, value}
      _ -> {:error, :invalid_vote}
    end
  end

  defp parse_vote(_value), do: {:error, :invalid_vote}
end
