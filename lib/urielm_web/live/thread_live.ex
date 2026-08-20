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
         |> assign(:comment_form, to_form(%{"body" => ""}))
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
             |> assign(:comment_form, to_form(%{"body" => ""}))
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
      <main id="thread-reading-view" class="mx-auto max-w-4xl pb-12">
        <.link
          navigate={~p"/forum/b/#{@thread.board_slug}"}
          class="group mb-5 inline-flex items-center gap-2 text-sm font-medium text-base-content/45 transition-colors hover:text-secondary"
        >
          <.um_icon
            name="arrow_left"
            class="size-4 transition-transform group-hover:-translate-x-0.5"
          />
          {@thread.board_name}
        </.link>

        <article
          id="thread-topic"
          class="rounded-2xl border border-base-300/60 bg-base-200/35 p-5 sm:p-7 lg:p-8"
        >
          <div class="flex flex-wrap items-center gap-2 text-xs font-bold uppercase tracking-[0.12em]">
            <.link
              navigate={~p"/forum/b/#{@thread.board_slug}"}
              class="rounded-full bg-secondary/10 px-3 py-1.5 text-secondary transition-colors hover:bg-secondary/15"
            >
              {@thread.board_name}
            </.link>
            <span :if={@thread.is_pinned} class="badge badge-info badge-sm gap-1">
              <.um_icon name="bookmark" class="size-3" /> Pinned
            </span>
            <span :if={@thread.is_locked} class="badge badge-warning badge-sm gap-1">
              <.um_icon name="lock_closed" class="size-3" /> Locked
            </span>
            <span :if={@thread.solved_comment_id} class="badge badge-success badge-sm gap-1">
              <.um_icon name="check_circle" class="size-3" /> Solved
            </span>
          </div>

          <h1 class="mt-4 max-w-3xl text-3xl font-black leading-tight tracking-[-0.04em] text-base-content sm:text-4xl lg:text-5xl">
            {@thread.title}
          </h1>

          <div class="mt-5 flex items-start justify-between gap-4">
            <div id="thread-author" class="flex items-center gap-3 text-sm text-base-content/45">
              <%= if Map.get(@thread, :author_avatar_url) do %>
                <img
                  src={Map.get(@thread, :author_avatar_url)}
                  alt={Map.get(@thread, :author_username) || "User"}
                  class="size-9 rounded-full object-cover"
                />
              <% else %>
                <div class="flex size-9 shrink-0 items-center justify-center rounded-full bg-accent text-xs font-black text-accent-content">
                  {String.slice(Map.get(@thread, :author_username) || "U", 0..0)
                  |> String.upcase()}
                </div>
              <% end %>
              <div class="leading-5">
                <span class="font-semibold text-base-content/75">
                  {Map.get(@thread, :author_username) || "Unknown"}
                </span>
                <span class="block text-xs">
                  {Calendar.strftime(@thread.created_at, "%B %d, %Y")} · {Map.get(
                    @thread,
                    :view_count,
                    0
                  )} views
                </span>
              </div>
            </div>
          </div>

          <div class="prose prose-base mt-7 max-w-none text-base-content/85 prose-headings:text-base-content prose-a:text-secondary">
            <.svelte
              name="MarkdownRenderer"
              props={%{content: @thread.body}}
              socket={@socket}
              ssr={false}
            />
          </div>

          <div
            id="thread-actions"
            class="mt-7 flex flex-wrap items-center gap-2 border-t border-base-300/50 pt-5"
          >
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
            <span class="mr-auto text-xs text-base-content/40">
              {pluralize(@thread.comment_count, "reply")}
            </span>

            <a
              :if={!@thread.is_locked && @current_user}
              href="#comment-form"
              class="btn btn-sm border-0 bg-secondary/10 text-secondary hover:bg-secondary/20"
            >
              <.um_icon name="reply" class="size-4" />
              <span class="hidden sm:inline">Reply</span>
            </a>

            <%= if @current_user do %>
              <button
                id="thread-save-action"
                class={[
                  "btn btn-sm btn-ghost",
                  @thread_is_saved && "bg-secondary/10 text-secondary"
                ]}
                phx-click="save_thread"
                aria-label={if @thread_is_saved, do: "Remove saved thread", else: "Save thread"}
              >
                <.um_icon
                  name={if @thread_is_saved, do: "bookmark_solid", else: "bookmark"}
                  class="size-4"
                />
                <span class="hidden sm:inline">
                  {if @thread_is_saved, do: "Saved", else: "Save"}
                </span>
              </button>

              <button
                id="thread-subscribe-action"
                class={[
                  "btn btn-sm btn-ghost",
                  @thread_is_subscribed && "bg-secondary/10 text-secondary"
                ]}
                phx-click={if @thread_is_subscribed, do: "unsubscribe", else: "subscribe"}
                aria-label={
                  if @thread_is_subscribed, do: "Stop watching thread", else: "Watch thread"
                }
              >
                <.um_icon
                  name={if @thread_is_subscribed, do: "bell_solid", else: "bell"}
                  class="size-4"
                />
                <span class="hidden sm:inline">
                  {if @thread_is_subscribed, do: "Watching", else: "Watch"}
                </span>
              </button>

              <div class="dropdown dropdown-end">
                <button
                  data-testid="notification-button"
                  class="btn btn-sm btn-ghost btn-square"
                  aria-label="More thread actions"
                >
                  <.um_icon name="ellipsis_horizontal" class="size-5" />
                </button>
                <ul class="dropdown-content menu z-10 mt-2 w-56 rounded-2xl border border-base-300 bg-base-100 p-2 shadow-xl">
                  <li class="menu-title">Notifications</li>
                  <li>
                    <button
                      data-testid="notification-watching"
                      phx-click="set_notification_level"
                      phx-value-level="watching"
                      class={if(@notification_level == "watching", do: "active", else: nil)}
                    >
                      Watching
                    </button>
                  </li>
                  <li>
                    <button
                      data-testid="notification-tracking"
                      phx-click="set_notification_level"
                      phx-value-level="tracking"
                      class={if(@notification_level == "tracking", do: "active", else: nil)}
                    >
                      Tracking
                    </button>
                  </li>
                  <li>
                    <button
                      data-testid="notification-muted"
                      phx-click="set_notification_level"
                      phx-value-level="muted"
                      class={if(@notification_level == "muted", do: "active", else: nil)}
                    >
                      Muted
                    </button>
                  </li>
                  <li>
                    <button
                      data-testid="report-button"
                      class="text-warning"
                      onclick="document.getElementById('report_thread_modal').showModal()"
                    >
                      <.um_icon name="warning" class="size-4" /> Report
                    </button>
                  </li>
                  <li :if={@current_user.is_admin || @current_user.is_moderator}>
                    <button phx-click={if @thread.is_pinned, do: "unpin_thread", else: "pin_thread"}>
                      <.um_icon name="bookmark" class="size-4" />
                      {if @thread.is_pinned, do: "Unpin", else: "Pin"}
                    </button>
                  </li>
                  <li :if={@current_user.is_admin || @current_user.is_moderator}>
                    <button phx-click={if @thread.is_locked, do: "unlock_thread", else: "lock_thread"}>
                      <.um_icon name="lock_closed" class="size-4" />
                      {if @thread.is_locked, do: "Unlock", else: "Lock"}
                    </button>
                  </li>
                  <li :if={@current_user.is_admin || @current_user.id == Map.get(@thread, :author_id)}>
                    <button
                      phx-click="delete_thread"
                      class="text-error"
                      data-confirm="Delete this thread?"
                    >
                      Delete
                    </button>
                  </li>
                </ul>
              </div>
            <% end %>
          </div>
        </article>

        <section class="mt-10" aria-labelledby="join-discussion-title">
          <div class="mb-4 flex items-end justify-between gap-4 px-1">
            <h2 id="join-discussion-title" class="text-xl font-bold tracking-tight text-base-content">
              Join the discussion
            </h2>
            <span class="hidden text-xs text-base-content/35 sm:inline">Markdown supported</span>
          </div>

          <%= cond do %>
            <% @thread.is_locked -> %>
              <div
                id="thread-locked-state"
                class="flex items-start gap-3 rounded-2xl border border-warning/25 bg-warning/8 p-5 text-sm"
              >
                <.um_icon name="lock_closed" class="mt-0.5 size-5 shrink-0 text-warning" />
                <div>
                  <p class="font-semibold text-base-content">This discussion is locked</p>
                  <p class="mt-1 text-base-content/55">Existing replies remain available to read.</p>
                </div>
              </div>
            <% @current_user -> %>
              <.form
                for={@comment_form}
                id="comment-form"
                phx-submit="create_comment"
                class="rounded-2xl border border-base-300/70 bg-base-200/45 p-4 sm:p-5"
              >
                <.input
                  field={@comment_form[:body]}
                  type="textarea"
                  label="Your reply"
                  placeholder="Share a useful answer or ask a follow-up…"
                  required
                  class="textarea min-h-28 w-full resize-y rounded-xl border-base-300 bg-base-100/65 text-base-content placeholder:text-base-content/30 focus:border-secondary focus:outline-none"
                />
                <div class="mt-3 flex items-center justify-between gap-3 border-t border-base-300/50 pt-4">
                  <p class="text-xs text-base-content/40">Be specific, kind, and useful.</p>
                  <button
                    id="comment-submit"
                    type="submit"
                    class="btn btn-sm border-0 bg-secondary text-secondary-content hover:bg-secondary/85"
                    phx-disable-with="Posting…"
                  >
                    Post reply
                  </button>
                </div>
              </.form>
            <% true -> %>
              <div
                id="thread-sign-in-to-reply"
                class="flex flex-col items-start justify-between gap-4 rounded-2xl border border-base-300/60 bg-base-200/35 p-5 sm:flex-row sm:items-center"
              >
                <div>
                  <p class="font-semibold text-base-content">Have something useful to add?</p>
                  <p class="mt-1 text-sm text-base-content/50">
                    Sign in to reply to this discussion.
                  </p>
                </div>
                <.link navigate={~p"/auth/signin"} class="btn btn-sm btn-secondary">
                  Sign in to reply
                </.link>
              </div>
          <% end %>
        </section>

        <section id="thread-replies" class="mt-10" aria-labelledby="thread-replies-title">
          <div class="mb-4 flex items-end justify-between gap-4 px-1">
            <h2 id="thread-replies-title" class="text-xl font-bold tracking-tight text-base-content">
              {pluralize(@thread.comment_count, "reply")}
            </h2>
            <span class="text-xs text-base-content/35">Oldest first</span>
          </div>
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
        </section>
      </main>
      
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
