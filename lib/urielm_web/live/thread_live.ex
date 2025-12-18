defmodule UrielmWeb.ThreadLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(%{"thread_id" => id}, _session, socket) do
    thread = Forum.get_thread!(id)
    comment_tree = LiveHelpers.build_comment_tree(thread.comments, socket.assigns.current_user)

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
     |> assign(:thread, LiveHelpers.serialize_thread_full(thread, socket.assigns.current_user))
     |> assign(:comment_tree, comment_tree)
     |> assign(:thread_is_saved, is_saved)
     |> assign(:thread_is_subscribed, is_subscribed)
     |> assign(:notification_level, notification_level)}
  end

  @impl true
  def handle_event("create_comment", %{"body" => body} = params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    cond do
      is_nil(user) ->
        {:noreply, put_flash(socket, :error, "Sign in to comment")}

      is_nil(user.username) ->
        {:noreply,
         socket
         |> put_flash(:info, "Please set a username before commenting")
         |> redirect(to: ~p"/signup/set-handle")}

      true ->
        thread_id = thread_data.id
        parent_id = Map.get(params, "parent_id")

        attrs =
          %{"body" => body}
          |> maybe_put_parent_id(parent_id)

        case Forum.create_comment(thread_id, user.id, attrs) do
          {:ok, _comment} ->
            {:noreply,
             socket
             |> refresh_thread(user)
             |> put_flash(:info, "Comment posted")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to post comment")}
        end
    end
  end

  defp maybe_put_parent_id(attrs, parent_id) when parent_id in [nil, ""], do: attrs
  defp maybe_put_parent_id(attrs, parent_id), do: Map.put(attrs, "parent_id", parent_id)

  @impl true
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
            {:noreply, socket |> refresh_thread(user)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to vote")}
        end
    end
  end

  @impl true
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

  @impl true
  def handle_event("mark_solved", %{"comment_id" => comment_id}, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      user ->
        thread_id = thread_data.id
        thread = Forum.get_thread!(thread_id)

        case Forum.mark_as_solved(thread, comment_id, user) do
          {:ok, _} ->
            {:noreply,
             socket
             |> refresh_thread(user)
             |> put_flash(:info, "Marked as solved")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Only the author can mark as solved")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to mark as solved")}
        end
    end
  end

  @impl true
  def handle_event("unmark_solved", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      user ->
        thread_id = thread_data.id
        thread = Forum.get_thread!(thread_id)

        case Forum.unmark_as_solved(thread, user) do
          {:ok, _} ->
            {:noreply,
             socket
             |> refresh_thread(user)
             |> put_flash(:info, "Unmarked as solved")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Only the author can unmark solved")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to unmark as solved")}
        end
    end
  end

  @impl true
  def handle_event("save_thread", _params, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "save threads", fn socket, user ->
      case Forum.toggle_save_thread(user.id, thread_data.id) do
        {:ok, _} ->
          thread = Forum.get_thread!(thread_data.id)
          {:noreply, assign(socket, :thread_is_saved, Forum.is_thread_saved?(user.id, thread.id))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to save thread")}
      end
    end)
  end

  @impl true
  def handle_event("subscribe", _params, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "subscribe", fn socket, user ->
      case Forum.subscribe_to_thread(user.id, thread_data.id) do
        {:ok, _} ->
          {:noreply, assign(socket, :thread_is_subscribed, true)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to subscribe")}
      end
    end)
  end

  @impl true
  def handle_event("unsubscribe", _params, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "unsubscribe", fn socket, user ->
      case Forum.unsubscribe_from_thread(user.id, thread_data.id) do
        {:ok, _} ->
          {:noreply, assign(socket, :thread_is_subscribed, false)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to unsubscribe")}
      end
    end)
  end

  @impl true
  def handle_event("edit_comment", %{"id" => comment_id, "body" => body}, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      user ->
        comment = Forum.get_comment!(comment_id)

        case Forum.edit_comment(comment, body, user) do
          {:ok, _} ->
            {:noreply,
             socket
             |> refresh_thread(user)
             |> put_flash(:info, "Comment updated")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Not authorized")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update comment")}
        end
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      user ->
        comment = Forum.get_comment!(comment_id)

        case Forum.remove_comment(comment, user) do
          {:ok, _} ->
            {:noreply,
             socket
             |> refresh_thread(user)
             |> put_flash(:info, "Comment deleted")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Not authorized")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to delete comment")}
        end
    end
  end

  @impl true
  def handle_event(
        "toggle_like",
        %{"target_type" => _target_type, "target_id" => _target_id},
        socket
      ) do
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

  @impl true
  def handle_event("save_comment", %{"comment_id" => comment_id}, socket) do
    LiveHelpers.with_auth(socket, "save comments", fn socket, user ->
      case Forum.toggle_save_comment(user.id, comment_id) do
        {:ok, _} ->
          {:noreply,
           socket
           |> refresh_thread(user)
           |> put_flash(:info, "Bookmark toggled")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to toggle bookmark")}
      end
    end)
  end

  @impl true
  def handle_event("reply_to_comment", %{"comment_id" => _comment_id}, socket) do
    # This just acknowledges the event. The actual reply UI is managed by the CommentTree component
    {:noreply, socket}
  end

  @impl true
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

  @impl true
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

  @impl true
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
    <Layouts.app flash={@flash} current_user={@current_user} current_page="" socket={@socket}>
      <div class="min-h-screen bg-base-100">
        <div class="container mx-auto px-4 py-8 max-w-6xl">
          <.link navigate={~p"/forum/b/#{@thread.board_slug}"} class="link link-hover text-sm mb-4">
            ← Back to {@thread.board_name}
          </.link>

          <div class="card bg-base-200 border border-base-300 mb-8">
            <div class="card-body">
              <div class="flex justify-between items-start">
                <div>
                  <h1 class="text-3xl font-bold text-base-content mb-2">{@thread.title}</h1>
                  <div class="flex items-center gap-3 text-sm text-base-content/60">
                    <%= if Map.get(@thread, :author_avatar_url) do %>
                      <img
                        src={Map.get(@thread, :author_avatar_url)}
                        alt={Map.get(@thread, :author_username) || "User"}
                        class="w-6 h-6 rounded-full object-cover"
                      />
                    <% else %>
                      <div class="w-6 h-6 rounded-full bg-base-300 flex items-center justify-center text-xs font-bold">
                        {String.slice(Map.get(@thread, :author_username) || "U", 0..0)
                        |> String.upcase()}
                      </div>
                    <% end %>
                    <span>By {Map.get(@thread, :author_username) || "Unknown"}</span>
                    <span>{Calendar.strftime(@thread.created_at, "%B %d, %Y")}</span>
                  </div>
                </div>

                <div class="flex gap-2 items-start">
                  <%= if @current_user do %>
                    <div class="dropdown dropdown-end">
                      <button
                        data-testid="notification-button"
                        class="btn btn-xs btn-ghost"
                        title="Notification settings"
                      >
                        <.um_icon name="bell" class="w-4 h-4" />
                      </button>
                      <ul class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
                        <li>
                          <a
                            data-testid="notification-watching"
                            phx-click="set_notification_level"
                            phx-value-level="watching"
                            class={(@notification_level == "watching" && "active") || ""}
                          >
                            Watching
                          </a>
                        </li>
                        <li>
                          <a
                            data-testid="notification-tracking"
                            phx-click="set_notification_level"
                            phx-value-level="tracking"
                            class={(@notification_level == "tracking" && "active") || ""}
                          >
                            Tracking
                          </a>
                        </li>
                        <li>
                          <a
                            data-testid="notification-muted"
                            phx-click="set_notification_level"
                            phx-value-level="muted"
                            class={(@notification_level == "muted" && "active") || ""}
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
                      <.um_icon
                        name={if @thread_is_saved, do: "bookmark_solid", else: "bookmark"}
                        class="w-4 h-4"
                      />
                    </button>

                    <button
                      data-testid="report-button"
                      class="btn btn-xs btn-ghost text-warning"
                      onclick="document.getElementById('report_thread_modal').showModal()"
                      title="Report this thread"
                    >
                      <.um_icon name="warning" class="w-4 h-4" />
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

              <div class="p-4 my-4">
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
                      target_type: "thread",
                      target_id: @thread.id,
                      score: @thread.score,
                      user_vote: @thread.user_vote
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
                  current_user_id: (@current_user && @current_user.id) || nil,
                  current_user_is_admin: (@current_user && @current_user.is_admin) || false,
                  thread_author_id: @thread.author_id,
                  solved_comment_id: @thread.solved_comment_id
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
              <button
                class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
                aria-label="Close"
              >
                <.um_icon name="close" class="w-4 h-4" />
              </button>
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
                <p class="text-xs text-base-content/50 mt-1">
                  Minimum 10 characters • Maximum 5000 characters
                </p>
              </div>

              <div class="modal-action">
                <form method="dialog">
                  <button class="btn">Cancel</button>
                </form>
                <button type="submit" data-testid="report-submit" class="btn btn-error">
                  Submit Report
                </button>
              </div>
            </form>
          </div>
          <form method="dialog" class="modal-backdrop">
            <button>close</button>
          </form>
        </dialog>
        
    <!-- Comment Report Modals -->
        <%= for comment <- flatten_comments(@comment_tree) do %>
          <dialog
            id={"report_comment_modal_#{comment.id}"}
            data-testid="comment-report-modal"
            class="modal"
          >
            <div class="modal-box bg-base-300">
              <form method="dialog">
                <button
                  class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
                  aria-label="Close"
                >
                  <.um_icon name="close" class="w-4 h-4" />
                </button>
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
                  <p class="text-xs text-base-content/60 mt-1">
                    Minimum 10 characters • Maximum 5000 characters
                  </p>
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
    </Layouts.app>
    """
  end

  # full thread serialization handled by LiveHelpers.serialize_thread_full/2

  defp refresh_thread(socket, current_user) do
    thread_id = socket.assigns.thread.id
    thread = Forum.get_thread!(thread_id)
    comment_tree = LiveHelpers.build_comment_tree(thread.comments, current_user)

    socket
    |> assign(:thread, LiveHelpers.serialize_thread_full(thread, current_user))
    |> assign(:comment_tree, comment_tree)
  end

  # comment tree handled by LiveHelpers.build_comment_tree/2

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
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
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
