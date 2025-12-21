defmodule UrielmWeb.LiveHelpers do
  @moduledoc """
  Shared helpers for LiveViews to reduce duplication across views.

  Includes serialization helpers for Thread cards and utilities like
  user vote lookup.
  """

  alias Urielm.Forum
  alias Urielm.Repo

  @doc """
  Serialize a forum thread into the map shape expected by ThreadCard.svelte.
  Expects the thread author to be preloaded.
  """
  def serialize_thread_card(thread, current_user) do
    # Ensure thread has an ID before serializing
    if is_nil(thread.id) do
      raise ArgumentError, "Cannot serialize thread without an ID: #{inspect(thread)}"
    end

    thread_id_string = to_string(thread.id)

    if thread_id_string == "" do
      raise ArgumentError, "Thread ID serialized to empty string: #{inspect(thread.id)}"
    end

    is_saved = current_user && Forum.is_thread_saved?(current_user.id, thread.id)
    is_subscribed = current_user && Forum.is_subscribed?(current_user.id, thread.id)
    is_unread = current_user && Forum.is_thread_unread?(current_user.id, thread.id)

    %{
      id: thread_id_string,
      title: thread.title,
      body: String.slice(thread.body, 0, 150),
      score: thread.score,
      comment_count: thread.comment_count,
      view_count: thread.view_count || 0,
      is_solved: thread.is_solved || false,
      is_locked: thread.is_locked || false,
      is_pinned: thread.is_pinned || false,
      author: %{
        id: thread.author.id,
        username: thread.author.username
      },
      created_at: thread.inserted_at,
      user_vote: get_user_vote(current_user, "thread", thread.id),
      is_saved: is_saved || false,
      is_subscribed: is_subscribed || false,
      is_unread: is_unread || false
    }
  end

  @doc """
  Return the current user's vote value for a given target or nil.
  """
  def get_user_vote(nil, _target_type, _target_id), do: nil

  def get_user_vote(user, target_type, target_id) do
    case Forum.get_user_vote(user.id, target_type, target_id) do
      nil -> nil
      vote -> vote.value
    end
  end

  @doc """
  Preload authors and serialize a list of threads into ThreadCard maps.
  """
  def serialize_thread_list(threads, current_user) do
    threads = Repo.preload(threads, :author)
    Enum.map(threads, &serialize_thread_card(&1, current_user))
  end

  @doc """
  Serialize a full thread payload for the Thread page.
  Extends the ThreadCard shape with author and board details and full body.
  Requires thread.author and thread.board to be preloaded.
  """
  def serialize_thread_full(thread, current_user) do
    base = serialize_thread_card(thread, current_user)

    Map.merge(base, %{
      body: thread.body,
      author_id: thread.author_id,
      author_username: thread.author.username,
      author_avatar_url: thread.author.avatar_url,
      board_name: thread.board.name,
      board_slug: thread.board.slug,
      solved_comment_id: thread.solved_comment_id && to_string(thread.solved_comment_id),
      is_locked: thread.is_locked || false,
      is_pinned: thread.is_pinned || false
    })
  end

  @doc """
  Build a nested comment tree with votes for the current user.
  Accepts a flat list of Comment structs (author must be loadable).
  """
  def build_comment_tree(comments, current_user) do
    comments = Repo.preload(comments, :author)
    grouped = Enum.group_by(comments, & &1.parent_id)
    root_comments = grouped[nil] || []
    Enum.map(root_comments, &build_comment_node(&1, grouped, current_user))
  end

  defp build_comment_node(comment, grouped, current_user) do
    children = grouped[comment.id] || []
    is_saved = current_user && Forum.is_comment_saved?(current_user.id, comment.id)

    %{
      id: to_string(comment.id),
      body: comment.body,
      author: %{
        id: comment.author.id,
        username: comment.author.username,
        avatar_url: comment.author.avatar_url
      },
      score: comment.score,
      inserted_at: comment.inserted_at,
      edited_at: comment.edited_at,
      user_vote: get_user_vote(current_user, "comment", comment.id),
      is_saved: is_saved || false,
      replies: Enum.map(children, &build_comment_node(&1, grouped, current_user))
    }
  end

  @doc """
  Fetch latest thread metadata, serialize, and stream_insert into the given stream.
  Returns the updated socket.

  This does NOT load comments and does NOT increment view count.
  """
  def update_thread_in_stream(socket, stream_name, thread_id, current_user) do
    # Fetch thread without comments (author and board already preloaded)
    thread = Forum.get_thread!(thread_id)
    serialized = serialize_thread_card(thread, current_user)
    Phoenix.LiveView.stream_insert(socket, stream_name, serialized)
  end

  @doc """
  Format a DateTime as a human readable relative string (long form).
  Examples: "just now", "3 minutes ago", "2 hours ago", "5 days ago", or "October 12, 2025".
  """
  def format_relative(%DateTime{} = datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 604_800 -> "#{div(diff, 86400)} days ago"
      true -> Calendar.strftime(datetime, "%B %d, %Y")
    end
  end

  @doc """
  Format a DateTime as a concise relative string.
  Examples: "now", "3m ago", "2h ago", or "Oct 12, 2025".
  """
  def format_short(%DateTime{} = datetime) do
    now = DateTime.utc_now()
    seconds_ago = DateTime.diff(now, datetime, :second)

    cond do
      seconds_ago < 60 -> "now"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
      seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
      true -> Calendar.strftime(datetime, "%b %d, %Y")
    end
  end

  @doc """
  Serialize a comment for list displays (e.g., user profile).
  Requires comment.author and comment.thread to be preloaded.
  """
  def serialize_comment(comment, current_user) do
    %{
      id: to_string(comment.id),
      body: comment.body,
      score: comment.score,
      author: %{
        id: comment.author.id,
        username: comment.author.username
      },
      created_at: comment.inserted_at,
      thread_id: to_string(comment.thread_id),
      thread_title: comment.thread.title,
      user_vote: get_user_vote(current_user, "comment", comment.id),
      edited_at: comment.edited_at
    }
  end

  @doc """
  Execute a function only if the user is authenticated.

  Checks if current_user exists in socket assigns. If not, returns an error flash.
  If authenticated, calls the provided function with socket and user.

  ## Examples

      def handle_event("save", params, socket) do
        with_auth(socket, "save items", fn socket, user ->
          case MyContext.save_item(user.id, params) do
            {:ok, _} -> {:noreply, assign(socket, :saved, true)}
            {:error, _} -> {:noreply, put_flash(socket, :error, "Failed")}
          end
        end)
      end

  """
  def with_auth(socket, action_name, fun) when is_function(fun, 2) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, Phoenix.LiveView.put_flash(socket, :error, "Sign in to #{action_name}")}

      user ->
        fun.(socket, user)
    end
  end

  @doc """
  Format changeset errors into a human-readable string.

  Takes an Ecto.Changeset and returns a formatted error message string
  combining all field errors.

  ## Examples

      iex> changeset = User.changeset(%User{}, %{email: "invalid"})
      iex> format_changeset_errors(changeset)
      "Email: is invalid"

  """
  def format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      "#{Phoenix.Naming.humanize(field)}: #{Enum.join(errors, ", ")}"
    end)
    |> Enum.join("; ")
  end
end
