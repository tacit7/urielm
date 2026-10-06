defmodule UrielmWeb.ChatLive do
  use UrielmWeb, :live_view
  alias Urielm.Chat

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]

    unless user do
      {:ok, redirect(socket, to: ~p"/")}
    else
      rooms = Chat.list_rooms_for_user(user.id)

      {:ok,
       socket
       |> assign(:rooms, rooms)
       |> assign(:selected_room, nil)
       |> assign(:messages, [])
       |> assign(:room_form, room_form())
       |> assign(:page_title, "Chat")}
    end
  end

  @impl true
  def handle_params(%{"room_id" => room_id}, _url, socket) do
    socket = clear_room(socket)
    user = socket.assigns.current_user

    with true <- is_binary(room_id),
         {id, ""} when id > 0 and id <= 9_223_372_036_854_775_807 <- Integer.parse(room_id),
         room when not is_nil(room) <- Chat.get_room(id) do
      # Subscribe before checking membership so a concurrent removal cannot be missed.
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Urielm.PubSub, Chat.membership_topic(user.id, id))
      end

      socket = assign(socket, :membership_room_id, id)

      case authorized_messages(user.id, id) do
        {:ok, fresh_user, messages} ->
          {:noreply,
           socket
           |> assign(:current_user, fresh_user)
           |> assign(:selected_room, room)
           |> assign(:messages, messages)}

        {:error, :unauthorized} ->
          {:noreply, revoke_room_access(socket)}
      end
    else
      _ -> {:noreply, revoke_room_access(socket)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, clear_room(socket)}
  end

  @impl true
  def handle_info({:room_access_revoked, user_id, room_id}, socket) do
    if socket.assigns.current_user.id == user_id and
         socket.assigns[:membership_room_id] == room_id do
      {:noreply, revoke_room_access(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="chat"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div
        id="chat-page"
        class="grid h-[calc(100dvh-7rem)] min-h-0 grid-rows-[auto_minmax(0,1fr)] overflow-hidden bg-base-100 sm:h-[calc(100dvh-3.5rem)] sm:grid-cols-[16rem_minmax(0,1fr)] sm:grid-rows-1"
      >
        <dialog id="create_room_modal" class="modal">
          <div class="modal-box max-w-lg rounded-lg border border-base-300 p-6 shadow-xl">
            <div class="mb-5 space-y-1">
              <p class="text-xs font-semibold uppercase text-primary">Chat administration</p>
              <h2 class="text-xl font-semibold text-base-content">Create a room</h2>
              <p class="text-sm text-base-content/60">
                Add a focused space for a community conversation.
              </p>
            </div>

            <.form for={@room_form} id="create-room-form" phx-submit="create_room">
              <.input
                field={@room_form[:name]}
                label="Room name"
                placeholder="e.g. general, random, dev"
                autocomplete="off"
                required
              />
              <.input
                field={@room_form[:description]}
                type="textarea"
                label="Description (optional)"
                placeholder="What will people discuss here?"
                rows="3"
              />
              <div class="modal-action">
                <button
                  id="cancel-create-room-button"
                  type="button"
                  class="btn btn-ghost"
                  onclick="create_room_modal.close()"
                >
                  Cancel
                </button>
                <button id="submit-create-room-button" type="submit" class="btn btn-primary">
                  Create room
                </button>
              </div>
            </.form>
          </div>
          <form method="dialog" class="modal-backdrop">
            <button aria-label="Close create room dialog">close</button>
          </form>
        </dialog>

        <aside
          id="chat-room-sidebar"
          aria-label="Chat rooms"
          class="min-w-0 border-b border-base-300 bg-base-200/55 sm:flex sm:min-h-0 sm:flex-col sm:border-r sm:border-b-0"
        >
          <header
            id="chat-header"
            class="flex h-14 items-center justify-between gap-3 border-b border-base-300 px-4"
          >
            <div class="min-w-0">
              <p class="text-xs font-semibold uppercase text-primary">Community</p>
              <h1 class="truncate text-base font-semibold text-base-content">Chat rooms</h1>
            </div>

            <%= if @current_user.is_admin do %>
              <button
                id="create-room-button"
                type="button"
                onclick="create_room_modal.showModal()"
                class="btn btn-primary btn-sm shrink-0"
                aria-label="Create a chat room"
              >
                <.icon name="hero-plus" class="size-4" />
                <span class="hidden sm:inline">New room</span>
              </button>
            <% end %>
          </header>

          <nav
            id="chat-room-list"
            class="flex min-w-0 gap-2 overflow-x-auto p-2 sm:min-h-0 sm:flex-1 sm:flex-col sm:gap-1 sm:overflow-x-hidden sm:overflow-y-auto sm:p-3"
          >
            <%= for room <- @rooms do %>
              <.link
                id={"chat-room-#{room.id}"}
                navigate={~p"/chat?room_id=#{room.id}"}
                class={[
                  "btn btn-sm min-h-10 max-w-52 flex-none justify-start rounded-lg border-0 px-3 font-medium shadow-none transition sm:w-full sm:max-w-none",
                  @selected_room && @selected_room.id == room.id &&
                    "bg-primary/10 text-primary hover:bg-primary/15",
                  (!@selected_room || @selected_room.id != room.id) &&
                    "btn-ghost text-base-content/65 hover:text-base-content"
                ]}
                aria-current={@selected_room && @selected_room.id == room.id && "page"}
              >
                <span aria-hidden="true" class="font-mono text-base-content/40">#</span>
                <span class="truncate">{room.name}</span>
              </.link>
            <% end %>
          </nav>
        </aside>

        <main id="chat-conversation" class="flex min-h-0 min-w-0 flex-col bg-base-100">
          <%= if @selected_room do %>
            <.svelte
              name="ChatWindow"
              class="min-h-0 flex-1"
              props={
                %{
                  room: serialize_room(@selected_room),
                  messages: Enum.map(@messages, &serialize_message/1),
                  userId: to_string(@current_user.id)
                }
              }
              socket={@socket}
              ssr={false}
            />
          <% else %>
            <div class="grid min-h-0 flex-1 place-items-center overflow-y-auto p-6">
              <.empty_state
                id="chat-empty-state"
                title="Choose a room"
                description="Select a room to join the conversation."
                icon="hero-chat-bubble-left-right"
                compact
                class="max-w-sm"
              />
            </div>
          <% end %>
        </main>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event(
        "create_room",
        %{"room" => %{"name" => name, "description" => description}},
        socket
      ) do
    user = socket.assigns[:current_user]

    # Only allow admins to create rooms
    if user.is_admin do
      case Chat.create_room(%{
             name: name,
             description: description,
             created_by_id: user.id
           }) do
        {:ok, room} ->
          Chat.add_member(user.id, room.id)

          {:noreply,
           socket
           |> assign(:rooms, Chat.list_rooms_for_user(user.id))
           |> assign(:room_form, room_form())
           |> push_navigate(to: ~p"/chat?room_id=#{room.id}")}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("send_message", %{"body" => body}, socket) do
    user = socket.assigns.current_user

    case socket.assigns.selected_room do
      nil ->
        {:noreply, socket}

      room ->
        case Chat.create_message(%{body: body, user_id: user.id, room_id: room.id}) do
          {:ok, _message} ->
            case authorized_messages(user.id, room.id) do
              {:ok, fresh_user, messages} ->
                {:noreply,
                 socket
                 |> assign(:current_user, fresh_user)
                 |> assign(:messages, messages)}

              {:error, :unauthorized} ->
                {:noreply, revoke_room_access(socket)}
            end

          {:error, :unauthorized} ->
            {:noreply, revoke_room_access(socket)}

          {:error, :silenced} ->
            {:noreply, put_flash(socket, :error, "You cannot send messages while silenced")}

          {:error, _changeset} ->
            {:noreply, socket}
        end
    end
  end

  defp authorized_messages(user_id, room_id) do
    with {:ok, _user} <- Chat.authorize_access(user_id, room_id) do
      messages = Chat.list_room_messages(room_id)

      # Do not assign history if access changed while the query was running.
      with {:ok, user} <- Chat.authorize_access(user_id, room_id) do
        {:ok, user, messages}
      end
    end
  end

  defp clear_room(socket) do
    if connected?(socket) && socket.assigns[:membership_room_id] do
      Phoenix.PubSub.unsubscribe(
        Urielm.PubSub,
        Chat.membership_topic(socket.assigns.current_user.id, socket.assigns.membership_room_id)
      )
    end

    socket
    |> assign(:membership_room_id, nil)
    |> assign(:selected_room, nil)
    |> assign(:messages, [])
  end

  defp revoke_room_access(socket) do
    socket
    |> clear_room()
    |> assign(:rooms, Chat.list_rooms_for_user(socket.assigns.current_user.id))
    |> put_flash(:error, "Chat room not found")
    |> push_patch(to: ~p"/chat")
  end

  defp serialize_room(room) do
    %{
      id: room.id,
      name: room.name,
      description: room.description
    }
  end

  defp serialize_message(message) do
    %{
      id: message.id,
      body: message.body,
      user_id: message.user_id,
      username: message.user.username,
      inserted_at: message.inserted_at
    }
  end

  defp room_form do
    to_form(%{"name" => "", "description" => ""}, as: :room)
  end
end
