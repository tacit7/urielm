defmodule UrielmWeb.ThreadLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.CommentHandlers
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
        serialized_thread = LiveHelpers.serialize_thread_full(thread, socket.assigns.current_user)

        {:ok,
         socket
         |> assign(:page_title, thread.title)
         |> assign(:thread, serialized_thread)
         |> assign(
           :thread_capability_disclosure,
           thread_capability_disclosure(serialized_thread)
         )
         |> assign(:related_threads, Forum.list_related_threads(thread, limit: 5))
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
        parent_id = Map.get(params, "parent_id")

        case CommentHandlers.create(thread_data, body, parent_id, user) do
          {:ok, _comment} ->
            {:noreply,
             socket
             |> refresh_thread(user)
             |> assign(:comment_form, to_form(%{"body" => ""}))
             |> put_flash(:info, "Comment posted")}

          {:error, :thread_locked} ->
            {:noreply, put_flash(socket, :error, "This thread is locked")}

          {:error, :silenced} ->
            {:noreply,
             put_flash(socket, :error, "Your account is silenced and cannot post comments")}

          {:error, :email_unverified} ->
            {:noreply,
             socket
             |> put_flash(:error, "Verify your email before commenting")
             |> redirect(to: ~p"/signup/verify-email")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to post comment")}
        end
    end
  end

  @impl true
  def handle_event("create_composer_reply", %{"body" => body} = params, socket) do
    %{current_user: user, thread: thread_data} = socket.assigns

    cond do
      is_nil(user) ->
        {:reply, %{ok: false}, put_flash(socket, :error, "Sign in to comment")}

      is_nil(user.username) ->
        {:reply, %{ok: false},
         socket
         |> put_flash(:info, "Please set a username before commenting")
         |> redirect(to: ~p"/signup/set-handle")}

      true ->
        parent_id = Map.get(params, "parent_id")

        case CommentHandlers.create(thread_data, body, parent_id, user) do
          {:ok, _comment} ->
            {:reply, %{ok: true},
             socket
             |> refresh_thread(user)
             |> put_flash(:info, "Comment posted")}

          {:error, :thread_locked} ->
            {:reply, %{ok: false}, put_flash(socket, :error, "This thread is locked")}

          {:error, :email_unverified} ->
            {:reply, %{ok: false},
             socket
             |> put_flash(:error, "Verify your email before commenting")
             |> redirect(to: ~p"/signup/verify-email")}

          {:error, :silenced} ->
            {:reply, %{ok: false},
             put_flash(socket, :error, "Your account is silenced and cannot post comments")}

          {:error, _} ->
            {:reply, %{ok: false}, put_flash(socket, :error, "Failed to post comment")}
        end
    end
  end

  @impl true
  def handle_event(
        "vote",
        %{"target_type" => "comment", "target_id" => target_id, "value" => value},
        socket
      ) do
    LiveHelpers.with_auth(socket, "vote", fn socket, user ->
      case CommentHandlers.vote(socket.assigns.thread, target_id, value, user, :cast) do
        {:ok, _} ->
          {:noreply, refresh_thread(socket, user)}

        {:error, :not_found} ->
          {:noreply, put_flash(socket, :error, "Comment not found")}

        {:error, :invalid_vote} ->
          {:noreply, put_flash(socket, :error, "Invalid vote value")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to vote")}
      end
    end)
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
      case CommentHandlers.edit(socket.assigns.thread, comment_id, body, user) do
        {:error, :not_found} ->
          {:noreply, put_flash(socket, :error, "Comment not found")}

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
    end)
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    LiveHelpers.with_auth(socket, "delete comments", fn socket, user ->
      case CommentHandlers.delete(socket.assigns.thread, comment_id, user) do
        {:error, :not_found} ->
          {:noreply, put_flash(socket, :error, "Comment not found")}

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
      case CommentHandlers.report(
             socket.assigns.thread,
             comment_id,
             %{
               reason: reason,
               description: description
             },
             user
           ) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:reporting_comment_id, nil)
           |> put_flash(:info, "Report submitted successfully")
           |> push_event("close_modal", %{"id" => "report_comment_modal"})}

        {:error, :unique_constraint} ->
          {:noreply, put_flash(socket, :error, "You've already reported this")}

        {:error, :not_found} ->
          {:noreply, put_flash(socket, :error, "Comment not found")}

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
      unread_notification_count={@unread_notification_count}
      current_board={@thread.board_slug}
    >
      <main id="thread-reading-view" class="mx-auto max-w-3xl pb-12">
        <.link
          navigate={~p"/forum/b/#{@thread.board_slug}"}
          class="btn btn-ghost btn-sm -ml-2 mb-3 h-9 min-h-9 gap-2 rounded-full px-3 text-base-content/55 hover:text-secondary"
        >
          <.um_icon
            name="arrow_left"
            class="size-4 transition-transform group-hover:-translate-x-0.5"
          />
          {@thread.board_name}
        </.link>

        <article
          id="thread-topic"
          class="rounded-xl border border-base-300/70 bg-base-200/35 p-4"
        >
          <div class="flex flex-wrap items-center gap-2 text-xs font-semibold">
            <span :if={@thread.is_pinned} class="badge badge-info badge-xs h-5 min-h-5 gap-1">
              <.um_icon name="bookmark" class="size-3" /> Pinned
            </span>
            <span :if={@thread.is_locked} class="badge badge-warning badge-xs h-5 min-h-5 gap-1">
              <.um_icon name="lock_closed" class="size-3" /> Locked
            </span>
            <span
              :if={@thread.solved_comment_id}
              class="badge badge-success badge-xs h-5 min-h-5 gap-1"
            >
              <.um_icon name="check_circle" class="size-3" /> Solved
            </span>
            <span
              :if={@thread_capability_disclosure.agent_badge_enabled}
              id="thread-agent-assisted-badge"
              class="badge h-5 min-h-5 gap-1 border-primary/25 bg-primary/10 px-2 text-xs font-bold text-primary"
            >
              <.um_icon name="hero-sparkles" class="size-3" /> Agent-assisted
            </span>
          </div>

          <h1 class="mt-3 max-w-3xl text-2xl font-bold leading-tight text-base-content sm:text-3xl">
            {@thread.title}
          </h1>

          <div class="mt-4 flex flex-wrap items-center justify-between gap-3 border-b border-base-300/50 pb-3">
            <div
              id="thread-author"
              class="flex min-w-0 items-center gap-2.5 text-sm text-base-content/45"
            >
              <%= if Map.get(@thread, :author_avatar_url) do %>
                <img
                  src={Map.get(@thread, :author_avatar_url)}
                  alt={Map.get(@thread, :author_username) || "User"}
                  class="size-8 rounded-full object-cover"
                />
              <% else %>
                <div class="flex size-8 shrink-0 items-center justify-center rounded-full bg-accent text-xs font-black text-accent-content">
                  {String.slice(Map.get(@thread, :author_username) || "U", 0..0)
                  |> String.upcase()}
                </div>
              <% end %>
              <div class="min-w-0 leading-5">
                <div class="flex flex-wrap items-center gap-1.5">
                  <span class="font-semibold text-base-content/75">
                    {Map.get(@thread, :author_username) || "Unknown"}
                  </span>
                  <.capability_agent_badge
                    :if={@thread_capability_disclosure.agent_badge_enabled}
                    agent={@thread_capability_disclosure.agent}
                  />
                </div>
                <span class="block truncate text-xs">
                  {Calendar.strftime(@thread.created_at, "%b %d, %Y")}
                </span>
              </div>
            </div>

            <div id="thread-stats" class="flex items-center gap-1.5 text-xs text-base-content/45">
              <span class="inline-flex items-center gap-1 rounded-full bg-base-100/45 px-2 py-1 font-mono tabular-nums">
                <.um_icon name="hero-eye" class="size-3.5" />
                {Map.get(@thread, :view_count, 0)}
              </span>
              <span class="inline-flex items-center gap-1 rounded-full bg-base-100/45 px-2 py-1 font-mono tabular-nums">
                <.um_icon name="reply" class="size-3.5" />
                {@thread.comment_count}
              </span>
            </div>
          </div>

          <div
            :if={Map.get(@thread, :tag_records, []) != []}
            id="thread-tags"
            aria-label="Thread tags"
            class="mt-4 flex flex-wrap gap-1.5"
          >
            <.link
              :for={tag <- Map.get(@thread, :tag_records, [])}
              id={"thread-tag-#{tag.slug}"}
              navigate={~p"/forum/tags/#{tag.slug}"}
              class="badge badge-outline badge-secondary h-6 min-h-6 gap-1.5 px-2 text-xs font-semibold normal-case transition-colors hover:bg-secondary/10"
            >
              <.um_icon name="hero-tag" class="size-3" />
              {tag.name}
            </.link>
          </div>

          <div
            id="thread-body"
            class="prose prose-base mt-4 max-w-none text-base-content/85 prose-headings:text-base-content prose-a:text-secondary"
          >
            {UrielmWeb.Markdown.to_html!(@thread.body)}
          </div>

          <div
            :if={@thread_capability_disclosure.capability_chips_enabled}
            id="thread-capability-disclosure"
            class="mt-4 flex flex-col gap-3 border-t border-base-300/50 pt-3 sm:flex-row sm:items-start sm:justify-between"
          >
            <div>
              <div
                id="thread-capability-chips"
                class="flex flex-wrap gap-1.5"
                aria-label="Capabilities used for this post"
              >
                <.capability_chip
                  :for={capability <- @thread_capability_disclosure.visible_capabilities}
                  capability={capability}
                />
                <span
                  :if={@thread_capability_disclosure.hidden_count > 0}
                  id="thread-capability-more-count"
                  class="badge h-6 min-h-6 border-warning/25 bg-warning/10 px-2 text-xs font-semibold text-warning"
                >
                  +{@thread_capability_disclosure.hidden_count}
                </span>
              </div>
              <p class="mt-2 text-xs leading-5 text-base-content/45">
                Shown from the post's runtime snapshot, not the author's current settings.
              </p>
            </div>

            <details id="thread-capability-details" class="group relative w-full sm:w-auto">
              <summary class="btn btn-ghost btn-xs min-h-8 w-full list-none rounded-full border border-base-300/70 bg-base-100/45 px-3 text-base-content/60 transition hover:border-primary/40 hover:bg-primary/10 hover:text-primary sm:w-auto [&::-webkit-details-marker]:hidden">
                <.um_icon name="hero-information-circle" class="size-3.5" /> Capability details
                <.um_icon
                  name="hero-chevron-down"
                  class="size-3.5 transition-transform group-open:rotate-180"
                />
              </summary>
              <div class="absolute right-0 z-20 mt-2 w-full min-w-72 rounded-xl border border-base-300 bg-base-100 p-4 text-sm shadow-xl sm:w-80">
                <h3 class="text-sm font-black text-base-content">Used by this post</h3>
                <p class="mt-1 text-xs leading-5 text-base-content/55">
                  Runtime usage is stored as a snapshot so older discussions stay readable when
                  models, skills, or tools are renamed.
                </p>

                <dl class="mt-3 space-y-3">
                  <div>
                    <dt class="text-xs font-bold text-base-content/45">Assistant</dt>
                    <dd class="mt-1 text-xs text-base-content/80">
                      {@thread_capability_disclosure.agent.name} · {@thread_capability_disclosure.agent.model}
                    </dd>
                  </div>
                  <div>
                    <dt class="text-xs font-bold text-base-content/45">Skills</dt>
                    <dd class="mt-1 flex flex-wrap gap-1.5">
                      <.capability_chip
                        :for={capability <- @thread_capability_disclosure.skills}
                        capability={capability}
                      />
                    </dd>
                  </div>
                  <div>
                    <dt class="text-xs font-bold text-base-content/45">Tools</dt>
                    <dd class="mt-1 flex flex-wrap gap-1.5">
                      <.capability_chip
                        :for={capability <- @thread_capability_disclosure.tools}
                        capability={capability}
                      />
                    </dd>
                  </div>
                </dl>
              </div>
            </details>
          </div>

          <div
            id="thread-actions"
            class="mt-4 flex flex-wrap items-center gap-2 border-t border-base-300/50 pt-3"
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
            <span class="mr-auto" />

            <a
              :if={!@thread.is_locked && @current_user}
              href="#comment-form"
              class="btn btn-secondary btn-sm h-9 min-h-9 rounded-full px-4"
            >
              <.um_icon name="reply" class="size-4" />
              <span class="hidden sm:inline">Reply</span>
            </a>

            <%= if @current_user do %>
              <button
                id="thread-save-action"
                class={[
                  "btn btn-sm btn-ghost h-9 min-h-9 rounded-full px-3",
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
                  "btn btn-sm btn-ghost h-9 min-h-9 rounded-full px-3",
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
                  class="btn btn-sm btn-ghost btn-circle h-9 min-h-9 w-9"
                  aria-label="More thread actions"
                >
                  <.um_icon name="ellipsis_horizontal" class="size-5" />
                </button>
                <ul class="dropdown-content menu z-10 mt-2 w-56 rounded-lg border border-base-300 bg-base-100 p-2 shadow-xl">
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

        <section class="mt-8" aria-labelledby="join-discussion-title">
          <div class="mb-4 flex items-end justify-between gap-4 px-1">
            <h2 id="join-discussion-title" class="text-xl font-bold text-base-content">
              Join the discussion
            </h2>
            <span class="hidden text-xs text-base-content/35 sm:inline">Markdown supported</span>
          </div>

          <%= cond do %>
            <% @thread.is_locked -> %>
              <div
                id="thread-locked-state"
                class="alert alert-warning items-start text-sm"
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
                class="rounded-xl border border-base-300/70 bg-base-200/35 p-3 sm:p-4"
              >
                <.input
                  field={@comment_form[:body]}
                  type="textarea"
                  label="Your reply"
                  placeholder="Share a useful answer or ask a follow-up…"
                  required
                  class="textarea min-h-28 w-full resize-y rounded-lg border-base-300 bg-base-100/65 text-base-content placeholder:text-base-content/30 focus:border-secondary focus:outline-none"
                />
                <div class="mt-3 flex items-center justify-between gap-3 border-t border-base-300/50 pt-3">
                  <p class="text-xs text-base-content/40">Be specific, kind, and useful.</p>
                  <button
                    id="comment-submit"
                    type="submit"
                    class="btn btn-secondary btn-sm"
                    phx-disable-with="Posting…"
                  >
                    Post reply
                  </button>
                </div>
              </.form>
            <% true -> %>
              <div
                id="thread-sign-in-to-reply"
                class="flex h-auto flex-col items-start justify-between gap-3 rounded-xl border border-base-300/70 bg-base-200/35 p-4 sm:flex-row sm:items-center"
              >
                <div>
                  <p class="font-semibold text-base-content">Have something useful to add?</p>
                  <p class="mt-1 text-sm text-base-content/50">
                    Sign in to reply to this discussion.
                  </p>
                </div>
                <.link navigate={~p"/signin"} class="btn btn-sm btn-secondary">
                  Sign in to reply
                </.link>
              </div>
          <% end %>
        </section>

        <section id="thread-replies" class="mt-8" aria-labelledby="thread-replies-title">
          <div class="mb-3 flex items-end justify-between gap-4 px-1">
            <h2 id="thread-replies-title" class="text-lg font-bold text-base-content">
              {pluralize(@thread.comment_count, "reply")}
            </h2>
            <span class="text-xs text-base-content/35">Oldest first</span>
          </div>
          <div
            id="thread-replies-surface"
            class="rounded-xl border border-base-300/70 bg-base-200/25 p-2 sm:p-3"
          >
            <.svelte
              name="CommentTree"
              props={
                %{
                  comments: @comment_tree,
                  current_user_id: (@current_user && @current_user.id) || nil,
                  current_user_is_admin: (@current_user && @current_user.is_admin) || false,
                  thread_author_id: @thread.author_id,
                  solved_comment_id: @thread.solved_comment_id,
                  reply_draft_key:
                    if(@current_user,
                      do: "forum:thread-reply:#{@thread.id}:#{@current_user.id}",
                      else: nil
                    ),
                  reply_upload_url:
                    if(@current_user, do: ~p"/forum/t/#{@thread.id}/uploads", else: nil)
                }
              }
              socket={@socket}
              ssr={false}
            />
          </div>
        </section>

        <section
          :if={@related_threads != []}
          id="related-threads"
          class="mt-8"
          aria-labelledby="related-threads-title"
        >
          <div class="mb-2 flex items-center justify-between gap-4 px-1">
            <h2 id="related-threads-title" class="text-base font-bold text-base-content">
              More from {@thread.board_name}
            </h2>
            <.link
              id="related-threads-board-link"
              navigate={~p"/forum/b/#{@thread.board_slug}"}
              class="btn btn-ghost btn-xs h-8 min-h-8 rounded-full px-3 text-base-content/50 hover:text-secondary"
            >
              View all
            </.link>
          </div>

          <div class="divide-y divide-base-300/55 border-y border-base-300/55">
            <.link
              :for={related_thread <- @related_threads}
              id={"related-thread-#{related_thread.id}"}
              navigate={~p"/forum/t/#{related_thread.id}"}
              class="group grid grid-cols-1 gap-1 px-1 py-2.5 transition-colors hover:bg-base-200/45 sm:grid-cols-[minmax(0,1fr)_64px_64px_88px] sm:items-center sm:px-3"
            >
              <div class="min-w-0">
                <div class="flex min-w-0 items-center gap-1.5">
                  <span class="truncate text-sm font-semibold text-base-content transition-colors group-hover:text-secondary">
                    {related_thread.title}
                  </span>
                  <span
                    :if={related_thread.is_solved}
                    class="badge badge-success badge-xs h-4 min-h-4 shrink-0 px-1.5 text-xs"
                  >
                    solved
                  </span>
                  <span
                    :if={related_thread.is_locked}
                    class="badge badge-warning badge-xs h-4 min-h-4 shrink-0 px-1.5 text-xs"
                  >
                    locked
                  </span>
                </div>
                <div class="mt-1 flex items-center gap-3 text-[0.72rem] font-medium text-base-content/40 sm:hidden">
                  <span>{pluralize(related_thread.comment_count, "reply")}</span>
                  <span>{LiveHelpers.format_short(related_thread.updated_at)}</span>
                </div>
              </div>

              <div class="hidden text-center sm:block">
                <span class="font-mono text-xs text-base-content/60 tabular-nums">
                  {related_thread.comment_count}
                </span>
              </div>
              <div class="hidden text-center sm:block">
                <span class="font-mono text-xs text-base-content/50 tabular-nums">
                  {related_thread.view_count}
                </span>
              </div>
              <div class="hidden text-right sm:block">
                <span class="font-mono text-xs text-base-content/45 tabular-nums">
                  {LiveHelpers.format_short(related_thread.updated_at)}
                </span>
              </div>
            </.link>
          </div>
        </section>
      </main>

      <%!-- Report modal --%>
      <.report_modal
        id="report_thread_modal"
        title="Report this thread"
        subtitle="Help us keep the community safe"
        form_event="report_thread"
        form_testid="report-form"
        description_placeholder="Explain why this content violates guidelines (at least 5 words)..."
        cancel_class="btn"
        bg_class="bg-base-300"
        data-testid="report-modal"
      />

      <%!-- Reusable comment report modal --%>
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

  defp refresh_thread(socket, current_user) do
    thread_id = socket.assigns.thread.id
    is_admin = current_user && current_user.is_admin
    # Fetch thread with comments for refresh (no view count increment)
    case Forum.get_thread(thread_id, include_comments?: true, allow_removed?: is_admin) do
      nil ->
        socket

      thread ->
        comment_tree = LiveHelpers.build_comment_tree(thread.comments, current_user)
        serialized_thread = LiveHelpers.serialize_thread_full(thread, current_user)

        socket
        |> assign(:thread, serialized_thread)
        |> assign(:thread_capability_disclosure, thread_capability_disclosure(serialized_thread))
        |> assign(:comment_tree, comment_tree)
    end
  end

  # comment tree handled by LiveHelpers.build_comment_tree/2

  defp thread_capability_disclosure(thread) do
    settings = Map.get(thread, :author_capability_badge_settings, %{})

    capabilities =
      settings
      |> Map.get("visible_capabilities", [])
      |> Enum.map(&normalize_capability/1)
      |> Enum.reject(&is_nil/1)

    skills = Enum.filter(capabilities, &(&1.kind == :skill))
    tools = Enum.filter(capabilities, &(&1.kind == :tool))

    visible_capabilities = Enum.take(capabilities, 3)

    %{
      agent: %{
        name: Map.get(settings, "agent_name", "Codex"),
        model: Map.get(settings, "model_name", "GPT-5"),
        provider: Map.get(settings, "provider", "OpenAI")
      },
      agent_badge_enabled: Map.get(settings, "agent_badge_enabled", true),
      capability_chips_enabled: Map.get(settings, "capability_chips_enabled", true),
      skills: skills,
      tools: tools,
      visible_capabilities: visible_capabilities,
      hidden_count: length(capabilities) - length(visible_capabilities)
    }
  end

  defp normalize_capability(%{"kind" => kind, "name" => name}) when is_binary(name) do
    %{kind: normalize_capability_kind(kind), name: name}
  end

  defp normalize_capability(_capability), do: nil

  defp normalize_capability_kind("skill"), do: :skill
  defp normalize_capability_kind("tool"), do: :tool
  defp normalize_capability_kind(_kind), do: :capability

  attr :agent, :map, required: true

  defp capability_agent_badge(assigns) do
    ~H"""
    <span
      id="thread-author-agent-badge"
      class="inline-flex min-h-5 items-center gap-1 rounded-full border border-primary/25 bg-primary/10 px-2 text-[0.68rem] font-black leading-none text-primary"
      title={"#{@agent.provider} #{@agent.model}"}
    >
      <span class="size-1.5 rounded-full bg-current"></span>
      {@agent.name} · {@agent.model}
    </span>
    """
  end

  attr :capability, :map, required: true

  defp capability_chip(assigns) do
    assigns =
      assign(
        assigns,
        :chip_class,
        case assigns.capability.kind do
          :skill -> "border-primary/25 bg-primary/10 text-primary"
          :tool -> "border-accent/25 bg-accent/10 text-accent"
          _ -> "border-base-300 bg-base-200 text-base-content/60"
        end
      )

    ~H"""
    <span class={"badge h-6 min-h-6 gap-1 border px-2 text-xs font-semibold #{@chip_class}"}>
      <span class="size-1.5 rounded-full bg-current"></span>
      {@capability.name}
    </span>
    """
  end

  defp pluralize(count, singular) do
    if count == 1 do
      "1 #{singular}"
    else
      "#{count} #{plural_form(singular)}"
    end
  end

  defp plural_form("reply"), do: "replies"
  defp plural_form(singular), do: "#{singular}s"

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
