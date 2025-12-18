defmodule UrielmWeb.NotificationsLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @page_size 30

  @impl true
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:ok, redirect(socket, to: ~p"/auth/signin")}

      user ->
        notifications =
          Forum.list_notifications(user.id, limit: @page_size, offset: 0, unread_only: false)

        {:ok,
         socket
         |> assign(:page_title, "Notifications")
         |> assign(:page, 0)
         |> assign(:has_more, length(notifications) == @page_size)
         |> assign(:unread_count, Forum.count_unread_notifications(user.id))
         |> stream(:notifications, serialize_notifications(notifications))}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    %{current_user: user} = socket.assigns
    unread_only = Map.get(params, "unread", "false") == "true"

    notifications =
      if unread_only do
        Forum.list_notifications(user.id, limit: @page_size, offset: 0, unread_only: true)
      else
        Forum.list_notifications(user.id, limit: @page_size, offset: 0, unread_only: false)
      end

    {:noreply,
     socket
     |> assign(:unread_only, unread_only)
     |> assign(:page, 0)
     |> assign(:has_more, length(notifications) == @page_size)
     |> stream(:notifications, serialize_notifications(notifications), reset: true)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{current_user: user, page: page, has_more: has_more, unread_only: unread_only} =
      socket.assigns

    if not has_more do
      {:noreply, socket}
    else
      offset = (page + 1) * @page_size

      notifications =
        Forum.list_notifications(user.id,
          limit: @page_size,
          offset: offset,
          unread_only: unread_only
        )

      {:noreply,
       socket
       |> assign(:page, page + 1)
       |> assign(:has_more, length(notifications) == @page_size)
       |> stream(:notifications, serialize_notifications(notifications))}
    end
  end

  @impl true
  def handle_event("mark_as_read", %{"notification_id" => notif_id}, socket) do
    %{current_user: user} = socket.assigns

    case Forum.mark_notification_as_read(notif_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:unread_count, Forum.count_unread_notifications(user.id))
         |> stream_delete(:notifications, notif_id)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to mark as read")}
    end
  end

  @impl true
  def handle_event("mark_all_as_read", _params, socket) do
    %{current_user: user} = socket.assigns

    case Forum.mark_all_notifications_as_read(user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:unread_count, 0)
         |> put_flash(:info, "All notifications marked as read")
         |> push_patch(to: ~p"/notifications")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to mark notifications as read")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="" socket={@socket}>
      <div class="min-h-screen bg-base-100">
        <div class="container mx-auto px-4 py-8 max-w-3xl">
          <div class="mb-8">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-4xl font-bold text-base-content mb-2">Notifications</h1>
                <%= if @unread_count > 0 do %>
                  <p class="text-base-content/60">
                    You have <span class="font-semibold">{@unread_count}</span>
                    unread notification{if @unread_count != 1, do: "s"}
                  </p>
                <% else %>
                  <p class="text-base-content/60">All caught up!</p>
                <% end %>
              </div>

              <%= if @unread_count > 0 do %>
                <button
                  phx-click="mark_all_as_read"
                  class="btn btn-sm btn-ghost"
                >
                  Mark all as read
                </button>
              <% end %>
            </div>

            <div class="flex gap-2 mt-4">
              <.link
                patch={~p"/notifications"}
                class={[
                  "px-4 py-2 rounded text-sm font-medium transition-colors",
                  if(!@unread_only,
                    do: "bg-primary text-primary-content",
                    else: "bg-base-200 text-base-content hover:bg-base-300"
                  )
                ]}
              >
                All
              </.link>
              <.link
                patch={~p"/notifications?unread=true"}
                class={[
                  "px-4 py-2 rounded text-sm font-medium transition-colors",
                  if(@unread_only,
                    do: "bg-primary text-primary-content",
                    else: "bg-base-200 text-base-content hover:bg-base-300"
                  )
                ]}
              >
                Unread
              </.link>
            </div>
          </div>

          <div id="notifications" phx-update="stream" class="space-y-4">
            <div id="empty-state" class="hidden only:block text-center py-12 text-base-content/50">
              <%= if @unread_only do %>
                <p>No unread notifications. Check back later!</p>
              <% else %>
                <p>You're all caught up on notifications!</p>
              <% end %>
            </div>

            <div :for={{id, notif} <- @streams.notifications} id={id}>
              <div class={[
                "card border",
                if(notif.read_at,
                  do: "bg-base-200 border-base-300",
                  else: "bg-primary/5 border-primary/20"
                )
              ]}>
                <div class="card-body">
                  <div class="flex items-start justify-between">
                    <div class="flex-1">
                      <p class="text-sm font-medium text-base-content/60">
                        {get_notification_label(notif.subject_type)}
                      </p>
                      <p class="text-base text-base-content">
                        {notif.message}
                      </p>
                      <p class="text-xs text-base-content/40 mt-2">
                        {LiveHelpers.format_relative(notif.inserted_at)}
                      </p>
                    </div>

                    <%= if notif.read_at do %>
                      <div class="badge badge-ghost">Read</div>
                    <% else %>
                      <button
                        phx-click="mark_as_read"
                        phx-value-notification_id={notif.id}
                        class="btn btn-xs btn-primary"
                      >
                        Mark read
                      </button>
                    <% end %>
                  </div>

                  <%= if notif.thread_id do %>
                    <.link
                      navigate={~p"/forum/t/#{notif.thread_id}"}
                      class="link link-primary text-sm mt-2"
                    >
                      View thread →
                    </.link>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <%= if @has_more do %>
            <div
              id="infinite-scroll-marker"
              phx-hook="InfiniteScroll"
              class="h-20 flex items-center justify-center mt-8"
            >
              <div class="text-base-content/40 text-sm">Loading more...</div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp serialize_notifications(notifications) do
    Enum.map(notifications, fn notif ->
      %{
        id: to_string(notif.id),
        subject_type: notif.subject_type,
        subject_id: to_string(notif.subject_id),
        message: notif.message,
        read_at: notif.read_at,
        thread_id: notif.thread_id && to_string(notif.thread_id),
        actor:
          notif.actor &&
            %{
              id: notif.actor.id,
              username: notif.actor.username
            },
        inserted_at: notif.inserted_at
      }
    end)
  end

  defp get_notification_label(subject_type) do
    case subject_type do
      "comment" -> "New comment"
      "reply" -> "Reply to your comment"
      "thread_update" -> "Thread updated"
      _ -> "Notification"
    end
  end

  # relative time formatting moved to LiveHelpers
end
