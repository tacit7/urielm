defmodule UrielmWeb.ThreadLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, _session, socket) do
    id = params["thread_id"]
    user = socket.assigns.current_user
    is_admin = user && user.is_admin

    # Fetch thread with comments for the thread page
    # Admins can view soft-deleted threads; regular users cannot
    case Forum.get_thread(id, include_comments?: true, allow_removed?: is_admin) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Thread not found")
         |> redirect(to: ~p"/")}

      thread ->
        comment_tree =
          LiveHelpers.build_comment_tree(thread.comments, socket.assigns.current_user)

        # Only track view count when connected (real page view)
        if connected?(socket) do
          Forum.increment_thread_view_count(thread.id)

          # Mark thread as read (only when connected to avoid double DB write)
          if socket.assigns.current_user do
            Forum.mark_thread_read(socket.assigns.current_user.id, thread.id)
          end
        end

        is_saved =
          if socket.assigns.current_user,
            do: Forum.thread_saved?(socket.assigns.current_user.id, thread.id),
            else: false

        is_subscribed =
          if socket.assigns.current_user,
            do: Forum.subscribed?(socket.assigns.current_user.id, thread.id),
            else: false

        notification_level =
          if socket.assigns.current_user,
            do: Forum.get_notification_level(socket.assigns.current_user.id, thread.id),
            else: "watching"

        all_categories = Forum.list_categories_with_boards()

        {:ok,
         socket
         |> assign(:page_title, thread.title)
         |> assign(
           :thread,
           LiveHelpers.serialize_thread_full(thread, socket.assigns.current_user)
         )
         |> assign(:comment_tree, comment_tree)
         |> assign(:thread_is_saved, is_saved)
         |> assign(:thread_is_subscribed, is_subscribed)
         |> assign(:notification_level, notification_level)
         |> assign(:reporting_comment_id, nil)
         |> assign(:all_categories, all_categories)}
    end
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

          {:error, :thread_locked} ->
            {:noreply, put_flash(socket, :error, "This thread is locked")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to post comment")}
        end
    end
  end

  @impl true
  def handle_event(
        "vote",
        %{"target_type" => target_type, "target_id" => target_id, "value" => value},
        socket
      ) do
    LiveHelpers.with_auth(socket, "vote", fn socket, user ->
      value_int =
        case Integer.parse(value) do
          {n, ""} -> n
          _ -> nil
        end

      case value_int do
        nil ->
          {:noreply, put_flash(socket, :error, "Invalid vote value")}

        value_int ->
          # Intentionally uses Forum.cast_vote (upsert: always sets to given value) rather than
          # Engagement.toggle_vote (toggle: removes vote when clicking the same value again).
          # LiveHelpers.handle_vote uses toggle_vote for non-forum views. These are distinct
          # behaviors: forum votes are sticky (cast), other content votes are toggleable.
          case Forum.cast_vote(user.id, target_type, target_id, value_int) do
            {:ok, _vote} ->
              {:noreply, socket |> refresh_thread(user)}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to vote")}
          end
      end
    end)
  end

  @impl true
  def handle_event("delete_thread", _params, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "delete threads", fn socket, user ->
      # Fetch thread metadata only (no comments needed for deletion)
      case Forum.get_thread(thread_data.id, allow_removed?: true) do
        nil ->
          {:noreply,
           socket
           |> put_flash(:error, "Thread not found")
           |> redirect(to: ~p"/forum/categories")}

        thread ->
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
    end)
  end

  @impl true
  def handle_event("mark_solved", %{"comment_id" => comment_id}, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "mark threads as solved", fn socket, user ->
      thread_id = thread_data.id
      # Fetch thread metadata only (no comments needed for mark as solved)
      case Forum.get_thread(thread_id, allow_removed?: true) do
        nil ->
          {:noreply,
           socket
           |> put_flash(:error, "Thread not found")
           |> redirect(to: ~p"/forum/categories")}

        thread ->
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
    end)
  end

  @impl true
  def handle_event("unmark_solved", _params, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "unmark threads as solved", fn socket, user ->
      thread_id = thread_data.id
      # Fetch thread metadata only (no comments needed for unmark solved)
      case Forum.get_thread(thread_id, allow_removed?: true) do
        nil ->
          {:noreply,
           socket
           |> put_flash(:error, "Thread not found")
           |> redirect(to: ~p"/forum/categories")}

        thread ->
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
    end)
  end

  @impl true
  def handle_event("save_thread", _params, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "save threads", fn socket, user ->
      case Forum.toggle_save_thread(user.id, thread_data.id) do
        {:ok, _} ->
          # No need to refetch thread; just update the saved status
          {:noreply,
           assign(socket, :thread_is_saved, Forum.thread_saved?(user.id, thread_data.id))}

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
    LiveHelpers.with_auth(socket, "edit comments", fn socket, user ->
      case Forum.get_comment(comment_id) do
        nil ->
          {:noreply, put_flash(socket, :error, "Comment not found")}

        comment ->
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
    end)
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    LiveHelpers.with_auth(socket, "delete comments", fn socket, user ->
      case Forum.get_comment(comment_id) do
        nil ->
          {:noreply, put_flash(socket, :error, "Comment not found")}

        comment ->
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
    end)
  end

  @impl true
  def handle_event(
        "toggle_like",
        %{"target_type" => _target_type, "target_id" => _target_id},
        socket
      ) do
    LiveHelpers.with_auth(socket, "like", fn socket, _user ->
      # For now, just acknowledge the event. Like functionality can be expanded later.
      # This handler prevents errors when PostActions tries to toggle likes
      {:noreply, socket}
    end)
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
  def handle_event("lock_thread", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    if user && (user.is_admin || user.is_moderator) do
      # Fetch thread metadata only (no comments needed for locking)
      case Forum.get_thread(thread_data.id, allow_removed?: true) do
        nil ->
          {:noreply,
           socket
           |> put_flash(:error, "Thread not found")
           |> redirect(to: ~p"/forum/categories")}

        thread ->
          case Forum.lock_thread(thread, user) do
            {:ok, _} ->
              {:noreply,
               socket
               |> refresh_thread(user)
               |> put_flash(:info, "Thread locked")}

            {:error, :unauthorized} ->
              {:noreply, put_flash(socket, :error, "Admin only")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to lock thread")}
          end
      end
    else
      {:noreply, put_flash(socket, :error, "Admin only")}
    end
  end

  @impl true
  def handle_event("unlock_thread", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    if user && (user.is_admin || user.is_moderator) do
      # Fetch thread metadata only (no comments needed for unlocking)
      case Forum.get_thread(thread_data.id, allow_removed?: true) do
        nil ->
          {:noreply,
           socket
           |> put_flash(:error, "Thread not found")
           |> redirect(to: ~p"/forum/categories")}

        thread ->
          case Forum.unlock_thread(thread, user) do
            {:ok, _} ->
              {:noreply,
               socket
               |> refresh_thread(user)
               |> put_flash(:info, "Thread unlocked")}

            {:error, :unauthorized} ->
              {:noreply, put_flash(socket, :error, "Admin only")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to unlock thread")}
          end
      end
    else
      {:noreply, put_flash(socket, :error, "Admin only")}
    end
  end

  @impl true
  def handle_event("pin_thread", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    if user && (user.is_admin || user.is_moderator) do
      # Fetch thread metadata only (no comments needed for pinning)
      case Forum.get_thread(thread_data.id, allow_removed?: true) do
        nil ->
          {:noreply,
           socket
           |> put_flash(:error, "Thread not found")
           |> redirect(to: ~p"/forum/categories")}

        thread ->
          case Forum.pin_thread(thread, user) do
            {:ok, _} ->
              {:noreply,
               socket
               |> refresh_thread(user)
               |> put_flash(:info, "Thread pinned")}

            {:error, :unauthorized} ->
              {:noreply, put_flash(socket, :error, "Admin only")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to pin thread")}
          end
      end
    else
      {:noreply, put_flash(socket, :error, "Admin only")}
    end
  end

  @impl true
  def handle_event("unpin_thread", _params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    if user && (user.is_admin || user.is_moderator) do
      # Fetch thread metadata only (no comments needed for unpinning)
      case Forum.get_thread(thread_data.id, allow_removed?: true) do
        nil ->
          {:noreply,
           socket
           |> put_flash(:error, "Thread not found")
           |> redirect(to: ~p"/forum/categories")}

        thread ->
          case Forum.unpin_thread(thread, user) do
            {:ok, _} ->
              {:noreply,
               socket
               |> refresh_thread(user)
               |> put_flash(:info, "Thread unpinned")}

            {:error, :unauthorized} ->
              {:noreply, put_flash(socket, :error, "Admin only")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to unpin thread")}
          end
      end
    else
      {:noreply, put_flash(socket, :error, "Admin only")}
    end
  end

  @impl true
  def handle_event("reply_to_comment", %{"comment_id" => _comment_id}, socket) do
    # This just acknowledges the event. The actual reply UI is managed by the CommentTree component
    {:noreply, socket}
  end

  @impl true
  def handle_event("report_thread", %{"reason" => reason, "description" => description}, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "report", fn socket, user ->
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
    end)
  end

  @impl true
  def handle_event("open_report_comment", %{"comment_id" => comment_id}, socket) do
    {:noreply,
     socket
     |> assign(:reporting_comment_id, comment_id)
     |> push_event("open_modal", %{"id" => "report_comment_modal"})}
  end

  @impl true
  def handle_event(
        "report_comment",
        %{"comment_id" => comment_id, "reason" => reason, "description" => description},
        socket
      ) do
    LiveHelpers.with_auth(socket, "report", fn socket, user ->
      case Forum.create_report(user.id, "comment", comment_id, %{
             reason: reason,
             description: description
           }) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:reporting_comment_id, nil)
           |> put_flash(:info, "Report submitted successfully")
           |> push_event("close_modal", %{"id" => "report_comment_modal"})}

        {:error, :unique_constraint} ->
          {:noreply, put_flash(socket, :error, "You've already reported this")}

        {:error, changeset} ->
          # Extract validation errors
          errors = format_errors(changeset)
          {:noreply, put_flash(socket, :error, errors)}
      end
    end)
  end

  @impl true
  def handle_event("set_notification_level", %{"level" => level}, socket) do
    thread_data = socket.assigns.thread

    LiveHelpers.with_auth(socket, "change notification settings", fn socket, user ->
      case Forum.set_notification_level(user.id, thread_data.id, level) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:notification_level, level)
           |> put_flash(:info, "Notification setting updated")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update notification setting")}
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories}
      flash={@flash}
      current_user={@current_user}
      current_board={@thread.board_slug}
    >
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
                  <.link
                    navigate={~p"/forum/b/#{@thread.board_slug}"}
                    class="text-primary hover:underline text-sm"
                  >
                    {@thread.board_name}
                  </.link>
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
                    phx-click={if @thread_is_subscribed, do: "unsubscribe", else: "subscribe"}
                    title={if @thread_is_subscribed, do: "Unsubscribe", else: "Subscribe"}
                  >
                    <.um_icon
                      name={if @thread_is_subscribed, do: "bell_solid", else: "bell"}
                      class="w-4 h-4"
                    />
                  </button>

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

                  <%= if @current_user && (@current_user.is_admin || @current_user.is_moderator) do %>
                    <%= if @thread.is_pinned do %>
                      <button
                        class="btn btn-xs btn-ghost"
                        phx-click="unpin_thread"
                        title="Unpin thread"
                      >
                        <.um_icon name="bookmark_slash" class="w-4 h-4" />
                      </button>
                    <% else %>
                      <button
                        class="btn btn-xs btn-ghost text-info"
                        phx-click="pin_thread"
                        title="Pin thread to top"
                      >
                        <.um_icon name="bookmark" class="w-4 h-4" />
                      </button>
                    <% end %>

                    <%= if @thread.is_locked do %>
                      <button
                        class="btn btn-xs btn-ghost text-warning"
                        phx-click="unlock_thread"
                        title="Unlock thread"
                      >
                        <.um_icon name="lock_open" class="w-4 h-4" />
                      </button>
                    <% else %>
                      <button
                        class="btn btn-xs btn-ghost"
                        phx-click="lock_thread"
                        title="Lock thread"
                      >
                        <.um_icon name="lock_closed" class="w-4 h-4" />
                      </button>
                    <% end %>
                  <% end %>

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
              ssr={false}
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
              ssr={false}
              />
              <span class="text-sm text-base-content/60">
                {pluralize(@thread.comment_count, "comment")}
              </span>
            </div>
          </div>
        </div>

        <div class="mb-8">
          <h2 class="text-2xl font-bold text-base-content mb-4">
            Comments
            <%= if @thread.is_locked do %>
              <span class="badge badge-warning badge-sm ml-2">
                <.um_icon name="lock_closed" class="w-3 h-3 mr-1" /> Locked
              </span>
            <% end %>
          </h2>

          <%= if @thread.is_locked do %>
            <div class="alert alert-warning mb-6">
              <.um_icon name="lock_closed" class="w-5 h-5" />
              <span>This thread is locked. New comments cannot be added.</span>
            </div>
          <% else %>
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
          ssr={false}
          />
        </div>
      </div>
      
    <!-- Report Modal -->
      <.report_modal
        id="report_thread_modal"
        title="Report this thread"
        subtitle="Help us keep the community safe"
        form_event="report_thread"
        form_testid="report-form"
        description_placeholder="Explain why this content violates guidelines (minimum 10 characters)..."
        cancel_class="btn"
        bg_class="bg-base-300"
        data-testid="report-modal"
      />
      
    <!-- Comment Report Modal (Single Reusable) -->
      <.report_modal
        id="report_comment_modal"
        title="Report Comment"
        form_event="report_comment"
        form_id="report-comment-form"
        comment_id={@reporting_comment_id}
        submit_disabled={is_nil(@reporting_comment_id)}
        submit_class="btn btn-warning"
        description_placeholder="Explain why you're reporting this comment..."
        bg_class="bg-base-300"
        data-testid="comment-report-modal"
      />
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  # full thread serialization handled by LiveHelpers.serialize_thread_full/2

  defp maybe_put_parent_id(attrs, parent_id) when parent_id in [nil, ""], do: attrs
  defp maybe_put_parent_id(attrs, parent_id), do: Map.put(attrs, "parent_id", parent_id)

  defp refresh_thread(socket, current_user) do
    thread_id = socket.assigns.thread.id
    is_admin = current_user && current_user.is_admin
    # Fetch thread with comments for refresh (no view count increment)
    case Forum.get_thread(thread_id, include_comments?: true, allow_removed?: is_admin) do
      nil ->
        socket

      thread ->
        comment_tree = LiveHelpers.build_comment_tree(thread.comments, current_user)

        socket
        |> assign(:thread, LiveHelpers.serialize_thread_full(thread, current_user))
        |> assign(:comment_tree, comment_tree)
    end
  end

  # comment tree handled by LiveHelpers.build_comment_tree/2

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
