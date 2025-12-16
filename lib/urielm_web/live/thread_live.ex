defmodule UrielmWeb.ThreadLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias Urielm.Repo

  @impl true
  def mount(%{"thread_id" => id}, _session, socket) do
    thread = Forum.get_thread!(id)
    comment_tree = build_comment_tree(thread.comments)

    # Mark thread as read
    if socket.assigns.current_user do
      Forum.mark_thread_read(socket.assigns.current_user.id, thread.id)
    end

    is_saved =
      if socket.assigns.current_user,
        do: Forum.is_thread_saved?(socket.assigns.current_user.id, thread.id),
        else: false

    is_subscribed =
      if socket.assigns.current_user,
        do: Forum.is_subscribed?(socket.assigns.current_user.id, thread.id),
        else: false

    notification_level =
      if socket.assigns.current_user,
        do: Forum.get_notification_level(socket.assigns.current_user.id, thread.id),
        else: "watching"

    {:ok,
     socket
     |> assign(:page_title, thread.title)
     |> assign(:thread, serialize_thread(thread, socket.assigns.current_user))
     |> assign(:comment_tree, comment_tree)
     |> assign(:thread_is_saved, is_saved)
     |> assign(:thread_is_subscribed, is_subscribed)
     |> assign(:notification_level, notification_level)}
  end

  @impl true
  def handle_event("create_comment", %{"body" => body}, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to comment")}

      user ->
        thread_id = thread_data.id

        case Forum.create_comment(thread_id, user.id, %{"body" => body}) do
          {:ok, _comment} ->
            # Reload thread and rebuild comment tree
            thread = Forum.get_thread!(thread_id)
            comment_tree = build_comment_tree(thread.comments)

            {:noreply,
             socket
             |> assign(:comment_tree, comment_tree)
             |> put_flash(:info, "Comment posted")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to post comment")}
        end
    end
  end

  def handle_event(
        "vote",
        %{"target_type" => target_type, "target_id" => target_id, "value" => value},
        socket
      ) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to vote")}

      user ->
        value_int = String.to_integer(value)

        case Forum.cast_vote(user.id, target_type, target_id, value_int) do
          {:ok, _vote} ->
            # Reload thread with updated scores
            thread = Forum.get_thread!(thread_data.id)
            comment_tree = build_comment_tree(thread.comments)

            {:noreply,
             socket
             |> assign(:thread, serialize_thread(thread, user))
             |> assign(:comment_tree, comment_tree)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to vote")}
        end
    end
  end

  def handle_event("delete_thread", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      user ->
        thread = Forum.get_thread!(thread_data.id)

        case Forum.remove_thread(thread, user) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Thread deleted")
             |> redirect(to: ~p"/forum/b/#{thread.board.slug}")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Not authorized")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to delete thread")}
        end
    end
  end

  def handle_event("save_thread", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to save threads")}

      user ->
        case Forum.toggle_save_thread(user.id, thread_data.id) do
          {:ok, _} ->
            thread = Forum.get_thread!(thread_data.id)
            is_saved = Forum.is_thread_saved?(user.id, thread.id)

            {:noreply, assign(socket, :thread_is_saved, is_saved)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to save thread")}
        end
    end
  end

  def handle_event("subscribe", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to subscribe")}

      user ->
        case Forum.subscribe_to_thread(user.id, thread_data.id) do
          {:ok, _} ->
            {:noreply, assign(socket, :thread_is_subscribed, true)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to subscribe")}
        end
    end
  end

  def handle_event("unsubscribe", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, socket}

      user ->
        case Forum.unsubscribe_from_thread(user.id, thread_data.id) do
          {:ok, _} ->
            {:noreply, assign(socket, :thread_is_subscribed, false)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to unsubscribe")}
        end
    end
  end

  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      user ->
        comment = Forum.get_comment!(comment_id)

        case Forum.remove_comment(comment, user) do
          {:ok, _} ->
            # Reload thread and rebuild tree
            thread = Forum.get_thread!(thread_data.id)
            comment_tree = build_comment_tree(thread.comments)

            {:noreply,
             socket
             |> assign(:comment_tree, comment_tree)
             |> put_flash(:info, "Comment deleted")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Not authorized")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to delete comment")}
        end
    end
  end

  def handle_event("toggle_like", %{"target_type" => _target_type, "target_id" => _target_id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to like")}

      _user ->
        # For now, just acknowledge the event. Like functionality can be expanded later.
        # This handler prevents errors when PostActions tries to toggle likes
        {:noreply, socket}
    end
  end

  def handle_event("reply_to_comment", %{"comment_id" => _comment_id}, socket) do
    # This just acknowledges the event. The actual reply UI is managed by the CommentTree component
    {:noreply, socket}
  end

  def handle_event("report_thread", %{"reason" => reason, "description" => description}, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to report")}

      user ->
        case Forum.create_report(user.id, "thread", thread_data.id, %{
               reason: reason,
               description: description
             }) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Report submitted successfully")
             |> push_event("close_modal", %{"id" => "report_thread_modal"})}

          {:error, :unique_constraint} ->
            {:noreply, put_flash(socket, :error, "You've already reported this")}

          {:error, changeset} ->
            # Extract validation errors
            errors = format_errors(changeset)
            {:noreply, put_flash(socket, :error, errors)}
        end
    end
  end

  def handle_event(
        "report_comment",
        %{"comment_id" => comment_id, "reason" => reason, "description" => description},
        socket
      ) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to report")}

      user ->
        case Forum.create_report(user.id, "comment", comment_id, %{
               reason: reason,
               description: description
             }) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Report submitted successfully")
             |> push_event("close_modal", %{"id" => "report_comment_modal_#{comment_id}"})}

          {:error, :unique_constraint} ->
            {:noreply, put_flash(socket, :error, "You've already reported this")}

          {:error, changeset} ->
            # Extract validation errors
            errors = format_errors(changeset)
            {:noreply, put_flash(socket, :error, errors)}
        end
    end
  end

  def handle_event("set_notification_level", %{"level" => level}, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to change notification settings")}

      user ->
        case Forum.set_notification_level(user.id, thread_data.id, level) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(:notification_level, level)
             |> put_flash(:info, "Notification setting updated")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update notification setting")}
        end
    end
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <div class="container mx-auto px-4 py-8 max-w-3xl">
        <.link navigate={~p"/forum/b/#{@thread.board_slug}"} class="link link-hover text-sm mb-4">
          ← Back to {@thread.board_name}
        </.link>

        <div class="card bg-base-200 border border-base-300 mb-8">
          <div class="card-body">
            <div class="flex justify-between items-start">
              <div>
                <h1 class="text-3xl font-bold text-base-content mb-2">{@thread.title}</h1>
                <div class="flex items-center gap-4 text-sm text-base-content/60">
                  <span>By {Map.get(@thread, :author_username) || "Unknown"}</span>
                  <span>{Calendar.strftime(@thread.created_at, "%B %d, %Y")}</span>
                </div>
              </div>

              <div class="flex gap-2 items-start">
                <%= if @current_user do %>
                  <div class="dropdown dropdown-end">
                    <button data-testid="notification-button" class="btn btn-xs btn-ghost" title="Notification settings">
                      🔔
                    </button>
                    <ul class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
                      <li>
                        <a
                          data-testid="notification-watching"
                          phx-click="set_notification_level"
                          phx-value-level="watching"
                          class={@notification_level == "watching" && "active" || ""}
                        >
                          Watching
                        </a>
                      </li>
                      <li>
                        <a
                          data-testid="notification-tracking"
                          phx-click="set_notification_level"
                          phx-value-level="tracking"
                          class={@notification_level == "tracking" && "active" || ""}
                        >
                          Tracking
                        </a>
                      </li>
                      <li>
                        <a
                          data-testid="notification-muted"
                          phx-click="set_notification_level"
                          phx-value-level="muted"
                          class={@notification_level == "muted" && "active" || ""}
                        >
                          Muted
                        </a>
                      </li>
                    </ul>
                  </div>

                  <button
                    class="btn btn-xs btn-ghost"
                    phx-click="save_thread"
                    title="Save this thread"
                  >
                    <%= if @thread_is_saved, do: "★", else: "☆" %>
                  </button>

                  <button
                    data-testid="report-button"
                    class="btn btn-xs btn-ghost text-warning"
                    onclick="document.getElementById('report_thread_modal').showModal()"
                    title="Report this thread"
                  >
                    ⚠️
                  </button>
                <% end %>

                <%= if @current_user && (@current_user.is_admin or @current_user.id == Map.get(@thread, :author_id)) do %>
                  <button
                    phx-click="delete_thread"
                    class="btn btn-xs btn-ghost text-error"
                    data-confirm="Delete this thread?"
                  >
                    Delete
                  </button>
                <% end %>
              </div>
            </div>

            <div class="bg-base-300 rounded-lg p-4 my-4">
              <.svelte
                name="MarkdownRenderer"
                props={%{content: @thread.body}}
                socket={@socket}
              />
            </div>

            <div class="flex items-center gap-4">
              <.svelte
                name="VoteButtons"
                props={
                  %{
                    targetType: "thread",
                    targetId: @thread.id,
                    score: @thread.score,
                    userVote: @thread.user_vote
                  }
                }
                socket={@socket}
              />
              <span class="text-sm text-base-content/60">
                {pluralize(@thread.comment_count, "comment")}
              </span>
            </div>
          </div>
        </div>

        <div class="mb-8">
          <h2 class="text-2xl font-bold text-base-content mb-4">Comments</h2>

          <%= if @current_user do %>
            <div class="card bg-base-200 border border-base-300 mb-6">
              <div class="card-body">
                <form phx-submit="create_comment" class="space-y-4">
                  <textarea
                    name="body"
                    placeholder="Share your thoughts... (Markdown supported)"
                    required
                    class="textarea textarea-bordered w-full min-h-24"
                  >
                  </textarea>
                  <button type="submit" class="btn btn-primary">Post Comment</button>
                </form>
              </div>
            </div>
          <% else %>
            <div class="alert alert-info mb-6">
              <span>
                <.link navigate={~p"/auth/signin"} class="link link-primary">Sign in</.link>
                to comment on this thread
              </span>
            </div>
          <% end %>

          <.svelte
            name="CommentTree"
            props={
              %{
                comments: @comment_tree,
                currentUserId: (@current_user && @current_user.id) || nil,
                currentUserIsAdmin: (@current_user && @current_user.is_admin) || false
              }
            }
            socket={@socket}
          />
        </div>
      </div>

      <!-- Report Modal -->
      <dialog id="report_thread_modal" data-testid="report-modal" class="modal">
        <div class="modal-box bg-base-300">
          <form method="dialog">
            <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
          </form>
          <h3 class="font-bold text-lg">Report this thread</h3>
          <p class="py-4 text-sm text-base-content/60">Help us keep the community safe</p>

          <form phx-submit="report_thread" data-testid="report-form" class="space-y-4">
            <div>
              <label class="label">
                <span class="label-text">Reason</span>
              </label>
              <select
                name="reason"
                required
                data-testid="report-reason"
                class="select select-bordered w-full"
              >
                <option disabled selected>Choose a reason</option>
                <option value="spam">Spam</option>
                <option value="abuse">Abuse</option>
                <option value="offensive">Offensive Content</option>
                <option value="other">Other</option>
              </select>
            </div>

            <div>
              <label class="label">
                <span class="label-text">Description (required)</span>
              </label>
              <textarea
                name="description"
                required
                minlength="10"
                maxlength="5000"
                placeholder="Explain why this content violates guidelines (minimum 10 characters)..."
                data-testid="report-description"
                class="textarea textarea-bordered w-full h-24"
              ></textarea>
              <p class="text-xs text-base-content/50 mt-1">Minimum 10 characters • Maximum 5000 characters</p>
            </div>

            <div class="modal-action">
              <form method="dialog">
                <button class="btn">Cancel</button>
              </form>
              <button type="submit" data-testid="report-submit" class="btn btn-error">Submit Report</button>
            </div>
          </form>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button>close</button>
        </form>
      </dialog>

      <!-- Comment Report Modals -->
      <%= for comment <- flatten_comments(@comment_tree) do %>
        <dialog id={"report_comment_modal_#{comment.id}"} data-testid="comment-report-modal" class="modal">
          <div class="modal-box bg-base-300">
            <form method="dialog">
              <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
            </form>
            <h3 class="font-bold text-lg mb-4">Report Comment</h3>
            <form phx-submit="report_comment" class="space-y-4">
              <input type="hidden" name="comment_id" value={comment.id} />

              <div>
                <label class="label">
                  <span class="label-text">Reason</span>
                </label>
                <select name="reason" class="select select-bordered w-full" required>
                  <option value="">Select a reason</option>
                  <option value="spam">Spam</option>
                  <option value="abuse">Abuse</option>
                  <option value="offensive">Offensive</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <div>
                <label class="label">
                  <span class="label-text">Description (required)</span>
                </label>
                <textarea
                  name="description"
                  placeholder="Explain why you're reporting this comment..."
                  class="textarea textarea-bordered w-full min-h-24"
                  required
                  minlength="10"
                  maxlength="5000"
                ></textarea>
                <p class="text-xs text-base-content/60 mt-1">Minimum 10 characters • Maximum 5000 characters</p>
              </div>

              <div class="modal-action">
                <form method="dialog">
                  <button class="btn btn-ghost">Cancel</button>
                </form>
                <button type="submit" class="btn btn-warning">Submit Report</button>
              </div>
            </form>
          </div>
          <form method="dialog" class="modal-backdrop">
            <button>close</button>
          </form>
        </dialog>
      <% end %>
    </div>
    """
  end

  defp serialize_thread(thread, current_user) do
    %{
      id: to_string(thread.id),
      title: thread.title,
      body: thread.body,
      score: thread.score,
      comment_count: thread.comment_count,
      author_id: thread.author_id,
      author_username: thread.author.username,
      created_at: thread.inserted_at,
      board_name: thread.board.name,
      board_slug: thread.board.slug,
      user_vote: get_user_vote(current_user, "thread", thread.id)
    }
  end

  defp get_user_vote(nil, _target_type, _target_id), do: nil

  defp get_user_vote(user, target_type, target_id) do
    case Forum.get_user_vote(user.id, target_type, target_id) do
      nil -> nil
      vote -> vote.value
    end
  end

  defp build_comment_tree(comments) do
    comments = Repo.preload(comments, :author)
    grouped = Enum.group_by(comments, & &1.parent_id)

    root_comments = grouped[nil] || []

    Enum.map(root_comments, fn comment ->
      build_node(comment, grouped)
    end)
  end

  defp build_node(comment, grouped) do
    children = grouped[comment.id] || []

    %{
      id: to_string(comment.id),
      body: comment.body,
      author: %{
        id: comment.author.id,
        username: comment.author.username
      },
      score: comment.score,
      inserted_at: comment.inserted_at,
      user_vote: nil,
      replies: Enum.map(children, &build_node(&1, grouped))
    }
  end

  defp flatten_comments(tree) when is_list(tree) do
    Enum.flat_map(tree, &flatten_comments/1)
  end

  defp flatten_comments(%{replies: replies} = comment) do
    [comment | flatten_comments(replies)]
  end

  defp flatten_comments(nil), do: []

  defp pluralize(count, singular) do
    if count == 1 do
      "1 #{singular}"
    else
      "#{count} #{singular}s"
    end
  end

  defp format_errors(changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)

    case errors do
      %{description: msgs} when is_list(msgs) ->
        "Description #{Enum.join(msgs, "; ")}"
      _ ->
        "Failed to submit report. Please check your input."
    end
  end
end
