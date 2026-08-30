defmodule UrielmWeb.NotificationsLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:ok, redirect(socket, to: ~p"/auth/signin")}

      _user ->
        {:ok,
         socket
         |> assign(:page_title, "Notifications")
         |> assign(:page, 0)
         |> assign(:unread_only, false)
         |> assign(:has_more, false)
         |> assign(:unread_count, 0)
         |> assign(:last_day_group, nil)
         |> stream(:notifications, [])}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    %{current_user: user} = socket.assigns
    unread_only = Map.get(params, "unread", "false") == "true"

    notifications = list_notifications(user.id, unread_only, LiveHelpers.page_size(), 0)
    {serialized, last_day_group} = serialize_notifications(notifications)

    {:noreply,
     socket
     |> assign(:unread_only, unread_only)
     |> assign(:page, 0)
     |> assign(:has_more, length(notifications) == LiveHelpers.page_size())
     |> assign(:unread_count, Forum.count_unread_notifications(user.id))
     |> assign(:last_day_group, last_day_group)
     |> stream(:notifications, serialized, reset: true)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{
      current_user: user,
      page: page,
      has_more: has_more,
      unread_only: unread_only,
      last_day_group: last_day_group
    } =
      socket.assigns

    if not has_more do
      {:noreply, socket}
    else
      offset = (page + 1) * LiveHelpers.page_size()

      notifications = list_notifications(user.id, unread_only, LiveHelpers.page_size(), offset)
      {serialized, next_last_day_group} = serialize_notifications(notifications, last_day_group)

      {:noreply,
       socket
       |> assign(:page, page + 1)
       |> assign(:has_more, length(notifications) == LiveHelpers.page_size())
       |> assign(:last_day_group, next_last_day_group)
       |> stream(:notifications, serialized)}
    end
  end

  @impl true
  def handle_event("mark_as_read", %{"notification_id" => notif_id}, socket) do
    %{current_user: user} = socket.assigns

    case Forum.mark_notification_as_read(user.id, notif_id) do
      {:ok, _updated_notif} ->
        {:noreply, refresh_notifications(socket)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to mark as read")}
    end
  end

  @impl true
  def handle_event("mark_all_as_read", _params, socket) do
    %{current_user: user} = socket.assigns

    case Forum.mark_all_notifications_as_read(user.id) do
      {_count, nil} ->
        {:noreply,
         socket
         |> assign(:unread_count, 0)
         |> assign(:unread_notification_count, 0)
         |> put_flash(:info, "All notifications marked as read")
         |> push_patch(to: ~p"/notifications")}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to mark notifications as read")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="notifications"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div
        id="notifications-page"
        class="ui-page-shell max-w-4xl"
      >
        <header
          id="notifications-header"
          class="mb-4 flex flex-col gap-3 px-1 sm:flex-row sm:items-end sm:justify-between"
        >
          <div>
            <h1 class="text-2xl font-bold leading-tight text-base-content sm:text-3xl">
              Notifications
            </h1>
            <p
              id="notifications-summary"
              class="mt-1 text-sm text-base-content/50"
            >
              <%= if @unread_count > 0 do %>
                {@unread_count} {if @unread_count == 1, do: "update is", else: "updates are"} waiting for you.
              <% else %>
                You're all caught up. Nice work.
              <% end %>
            </p>
          </div>

          <button
            :if={@unread_count > 0}
            id="notifications-mark-all"
            phx-click="mark_all_as_read"
            phx-disable-with="Marking read…"
            class="btn btn-outline btn-sm h-9 min-h-9 w-full rounded-full border-base-300 px-3 sm:w-auto"
          >
            <.um_icon name="hero-check-circle" class="size-4" /> Mark all read
          </button>
        </header>

        <nav
          id="notification-filters"
          class="tabs tabs-border flex items-center border-b border-base-300/50"
          aria-label="Notification filters"
        >
          <.link
            id="notification-filter-all"
            patch={~p"/notifications"}
            aria-current={if(!@unread_only, do: "page", else: nil)}
            class={[
              "tab min-h-11 px-3 text-sm font-semibold",
              if(!@unread_only,
                do: "tab-active text-primary",
                else: "text-base-content/50 hover:text-base-content"
              )
            ]}
          >
            All
          </.link>
          <.link
            id="notification-filter-unread"
            patch={~p"/notifications?unread=true"}
            aria-current={if(@unread_only, do: "page", else: nil)}
            class={[
              "tab min-h-11 px-3 text-sm font-semibold",
              if(@unread_only,
                do: "tab-active text-primary",
                else: "text-base-content/50 hover:text-base-content"
              )
            ]}
          >
            Unread
          </.link>
          <span class="ml-auto pb-1 text-xs font-medium tabular-nums text-base-content/40">
            {@unread_count} unread
          </span>
        </nav>

        <div
          id="notifications"
          phx-update="stream"
          class="mt-4 divide-y divide-base-300/45 border-y border-base-300/55"
        >
          <div
            id={if(@unread_only, do: "notifications-empty-unread", else: "notifications-empty-state")}
            data-ui-state="empty"
            class="hidden only:block"
          >
            <.empty_state
              id={
                if(@unread_only,
                  do: "notifications-empty-unread-content",
                  else: "notifications-empty-content"
                )
              }
              title={if(@unread_only, do: "Nothing unread", else: "No notifications yet")}
              description={
                if(@unread_only,
                  do:
                    "You've seen every update. New replies and discussion activity will appear here.",
                  else: "Replies and updates from discussions you follow will show up here."
                )
              }
              icon={if(@unread_only, do: "hero-check-circle", else: "hero-bell")}
              compact
            >
              <:action>
                <.link
                  navigate={if(@unread_only, do: ~p"/notifications", else: ~p"/forum")}
                  class="btn btn-primary btn-sm rounded-full"
                >
                  {if(@unread_only, do: "View all notifications", else: "Explore discussions")}
                  <.um_icon name="hero-arrow-right" class="size-4" />
                </.link>
              </:action>
            </.empty_state>
          </div>

          <div
            :for={{id, notif} <- @streams.notifications}
            id={id}
            data-notification-id={notif.id}
          >
            <h2
              :if={notif.show_day_heading}
              data-day-heading={notif.day_label}
              class="px-2 py-2 text-xs font-bold uppercase tracking-widest text-base-content/40"
            >
              {notif.day_label}
            </h2>

            <article class={[
              "group grid grid-cols-[2.25rem_minmax(0,1fr)_auto] gap-3 px-2 py-3 transition duration-150 sm:grid-cols-[2.5rem_minmax(0,1fr)_auto] sm:px-3",
              if(notif.read_at,
                do: "bg-base-100/10 hover:bg-base-200/45",
                else: "bg-secondary/6 hover:bg-secondary/10"
              )
            ]}>
              <div class="relative">
                <%= if notif.actor && notif.actor.avatar_url do %>
                  <img
                    src={notif.actor.avatar_url}
                    alt={notif.actor.username || "Community member"}
                    class="size-9 rounded-full object-cover sm:size-10"
                  />
                <% else %>
                  <div class="flex size-9 items-center justify-center rounded-full bg-accent/15 text-xs font-black uppercase text-accent sm:size-10">
                    {actor_initial(notif.actor)}
                  </div>
                <% end %>
                <span class="absolute -bottom-0.5 -right-0.5 flex size-4 items-center justify-center rounded-full border border-base-100 bg-base-300 text-base-content/65">
                  <.um_icon name={notification_icon(notif.subject_type)} class="size-3" />
                </span>
              </div>

              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs">
                  <span class="font-bold text-accent">
                    {notification_label(notif.subject_type)}
                  </span>
                  <span class="text-base-content/35">•</span>
                  <time class="text-base-content/40" datetime={DateTime.to_iso8601(notif.inserted_at)}>
                    {LiveHelpers.format_relative(notif.inserted_at)}
                  </time>
                </div>
                <p class="mt-1 break-words text-sm leading-6 text-base-content/80">
                  {notif.message || fallback_message(notif)}
                </p>
                <p :if={notif.thread_title} class="mt-1 truncate text-sm text-base-content/40">
                  {notif.thread_title}
                </p>
                <.link
                  :if={notif.thread_id}
                  id={"notification-thread-#{notif.id}"}
                  navigate={~p"/forum/t/#{notif.thread_id}"}
                  phx-click="mark_as_read"
                  phx-value-notification_id={notif.id}
                  class="mt-2 inline-flex items-center gap-1.5 text-sm font-bold text-secondary transition-colors hover:text-secondary/75"
                >
                  View discussion <.um_icon name="hero-arrow-right" class="size-4" />
                </.link>
              </div>

              <div class="col-start-3 row-start-1 flex justify-end">
                <%= if notif.read_at do %>
                  <span class="badge badge-ghost badge-sm border-base-300/60 text-base-content/40">
                    Read
                  </span>
                <% else %>
                  <div class="flex items-center gap-2">
                    <span
                      data-unread-indicator
                      class="size-2 rounded-full bg-secondary shadow-[0_0_12px_color-mix(in_oklab,var(--color-secondary)_65%,transparent)]"
                      aria-label="Unread"
                    ></span>
                    <button
                      id={"notification-read-#{notif.id}"}
                      type="button"
                      phx-click="mark_as_read"
                      phx-value-notification_id={notif.id}
                      class="btn btn-ghost btn-square min-h-9 min-w-9 rounded-lg text-base-content/55 hover:text-base-content"
                      aria-label="Mark as read"
                      title="Mark as read"
                    >
                      <.um_icon name="hero-check" class="size-4" />
                    </button>
                  </div>
                <% end %>
              </div>
            </article>
          </div>
        </div>

        <div
          :if={@has_more}
          id="infinite-scroll-marker"
          phx-hook="InfiniteScroll"
          class="mt-7 flex h-16 items-center justify-center gap-2 text-sm text-base-content/40"
        >
          <span class="loading loading-spinner loading-sm text-secondary"></span> Loading more
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp list_notifications(user_id, unread_only, limit, offset) do
    Forum.list_notifications(user_id,
      limit: limit,
      offset: offset,
      unread_only: unread_only
    )
  end

  defp refresh_notifications(socket) do
    %{current_user: user, unread_only: unread_only, page: page} = socket.assigns
    limit = (page + 1) * LiveHelpers.page_size()
    notifications = list_notifications(user.id, unread_only, limit, 0)
    {serialized, last_day_group} = serialize_notifications(notifications)

    unread_count = Forum.count_unread_notifications(user.id)

    socket
    |> assign(:unread_count, unread_count)
    |> assign(:unread_notification_count, unread_count)
    |> assign(:has_more, length(notifications) == limit)
    |> assign(:last_day_group, last_day_group)
    |> stream(:notifications, serialized, reset: true)
  end

  defp serialize_notifications(notifications, previous_day_group \\ nil) do
    {serialized, last_day_group} =
      Enum.map_reduce(notifications, previous_day_group, fn notif, prior_group ->
        day_group = notification_day_group(notif.inserted_at)
        {serialize_notification(notif, day_group != prior_group, day_group), day_group}
      end)

    {serialized, last_day_group}
  end

  defp serialize_notification(notif, show_day_heading, day_group) do
    %{
      id: to_string(notif.id),
      subject_type: notif.subject_type,
      subject_id: to_string(notif.subject_id),
      message: notif.message,
      read_at: notif.read_at,
      thread_id: notif.thread_id && to_string(notif.thread_id),
      thread_title: notif.thread && notif.thread.title,
      actor:
        notif.actor &&
          %{
            id: notif.actor.id,
            username: notif.actor.username,
            avatar_url: notif.actor.avatar_url
          },
      inserted_at: notif.inserted_at,
      show_day_heading: show_day_heading,
      day_label: notification_day_label(day_group)
    }
  end

  defp notification_day_group(inserted_at) do
    date = DateTime.to_date(inserted_at)
    today = Date.utc_today()

    cond do
      date == today -> :today
      date == Date.add(today, -1) -> :yesterday
      true -> :earlier
    end
  end

  defp notification_day_label(:today), do: "Today"
  defp notification_day_label(:yesterday), do: "Yesterday"
  defp notification_day_label(:earlier), do: "Earlier"

  defp notification_label(subject_type) do
    case subject_type do
      "comment" -> "New comment"
      "reply" -> "Reply"
      "thread_update" -> "Thread updated"
      "mention" -> "Mention"
      _ -> "Notification"
    end
  end

  defp notification_icon("comment"), do: "reply"
  defp notification_icon("reply"), do: "reply"
  defp notification_icon("thread_update"), do: "bell"
  defp notification_icon("mention"), do: "bell"
  defp notification_icon(_subject_type), do: "bell"

  defp actor_initial(%{username: username}) when is_binary(username) and username != "" do
    username |> String.first() |> String.upcase()
  end

  defp actor_initial(_actor), do: "U"

  defp fallback_message(%{actor: %{username: username}, subject_type: "reply"}),
    do: "#{username} replied to your comment."

  defp fallback_message(%{actor: %{username: username}, subject_type: "comment"}),
    do: "#{username} commented on a discussion you follow."

  defp fallback_message(%{actor: %{username: username}, subject_type: "mention"}),
    do: "#{username} mentioned you in a discussion."

  defp fallback_message(%{subject_type: "thread_update"}),
    do: "A discussion you follow was updated."

  defp fallback_message(_notif), do: "There's new activity in the community."

  # relative time formatting moved to LiveHelpers
end
