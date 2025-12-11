defmodule UrielmWeb.ChatLive do
  use UrielmWeb, :live_view
  alias Urielm.Chat

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]

    unless user do
      {:ok, redirect(socket, to: ~p"/")}
    else
      rooms = Chat.list_rooms()

      {:ok,
       socket
       |> assign(:rooms, rooms)
       |> assign(:selected_room, nil)
       |> assign(:messages, [])
       |> assign(:show_create_modal, false)
       |> assign(:room_form, %{"name" => "", "description" => ""})
       |> assign(:page_title, "Chat")}
    end
  end

  @impl true
  def handle_params(%{"room_id" => room_id}, _url, socket) do
    case Integer.parse(room_id) do
      {id, ""} ->
        room = Chat.get_room!(id)
        user = socket.assigns[:current_user]

        if Chat.is_member?(user.id, id) do
          messages = Chat.list_room_messages(id)

          {:noreply,
           socket
           |> assign(:selected_room, room)
           |> assign(:messages, messages)}
        else
          # Auto-join if not a member
          Chat.add_member(user.id, id)

          messages = Chat.list_room_messages(id)

          {:noreply,
           socket
           |> assign(:selected_room, room)
           |> assign(:messages, messages)}
        end

      :error ->
        {:noreply, socket}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-4rem)] bg-base-200">
      <!-- Create Room Modal -->
      <div class={["modal", @show_create_modal && "modal-open"]}>
        <div class="modal-box">
          <h3 class="font-bold text-lg text-base-content">Create New Room</h3>
          <form phx-submit="create_room" class="py-4">
            <div class="form-control w-full">
              <label class="label">
                <span class="label-text text-base-content">Room Name</span>
              </label>
              <input
                type="text"
                name="name"
                placeholder="e.g., general, random, dev"
                class="input input-bordered w-full bg-base-100 border-base-300 text-base-content placeholder-base-content/50"
                required
              />
            </div>
            <div class="form-control w-full">
              <label class="label">
                <span class="label-text text-base-content">Description (optional)</span>
              </label>
              <textarea
                name="description"
                placeholder="Optional room description"
                class="textarea textarea-bordered w-full bg-base-100 border-base-300 text-base-content placeholder-base-content/50"
                rows="3"
              ></textarea>
            </div>
            <div class="modal-action">
              <button
                type="button"
                phx-click="toggle_create_modal"
                class="btn btn-ghost"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="btn btn-primary"
              >
                Create
              </button>
            </div>
          </form>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button phx-click="toggle_create_modal">close</button>
        </form>
      </div>

      <!-- Sidebar with rooms -->
      <div class="w-64 bg-base-100 shadow-lg overflow-y-auto border-r border-base-300">
        <div class="p-4 border-b border-base-300">
          <h1 class="text-2xl font-bold text-base-content">Chat</h1>
        </div>

        <div class="p-4">
          <button
            phx-click="toggle_create_modal"
            class="w-full btn btn-primary btn-sm"
          >
            + New Room
          </button>
        </div>

        <nav class="space-y-1 p-3">
          <%= for room <- @rooms do %>
            <a
              href={~p"/chat?room_id=#{room.id}"}
              class={[
                "block px-4 py-2 rounded-lg transition border-l-4 border-transparent",
                @selected_room && @selected_room.id == room.id && "bg-primary/10 text-primary border-l-primary font-semibold",
                @selected_room && @selected_room.id != room.id && "text-base-content hover:bg-base-200/50"
              ]}
            >
              # <%= room.name %>
            </a>
          <% end %>
        </nav>
      </div>

      <!-- Main chat area -->
      <div class="flex-1 flex flex-col bg-base-100 h-full">
        <%= if @selected_room do %>
          <.svelte
            name="ChatWindow"
            class="h-full"
            props={%{
              room: serialize_room(@selected_room),
              messages: Enum.map(@messages, &serialize_message/1),
              userId: to_string(@current_user.id)
            }}
            socket={@socket}
          />
        <% else %>
          <div class="flex-1 flex items-center justify-center text-base-content/50">
            <p>Select a room to start chatting</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_create_modal", _params, socket) do
    {:noreply, assign(socket, :show_create_modal, !socket.assigns[:show_create_modal])}
  end

  def handle_event("create_room", %{"name" => name, "description" => description}, socket) do
    user = socket.assigns[:current_user]

    case Chat.create_room(%{
      name: name,
      description: description,
      created_by_id: user.id
    }) do
      {:ok, room} ->
        Chat.add_member(user.id, room.id)

        {:noreply,
         socket
         |> assign(:rooms, Chat.list_rooms())
         |> assign(:show_create_modal, false)
         |> assign(:room_form, %{"name" => "", "description" => ""})
         |> push_navigate(to: ~p"/chat?room_id=#{room.id}")}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"body" => body}, socket) do
    user = socket.assigns[:current_user]
    room = socket.assigns[:selected_room]

    case Chat.create_message(%{
      body: body,
      user_id: user.id,
      room_id: room.id
    }) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> assign(:messages, Chat.list_room_messages(room.id))}

      {:error, _changeset} ->
        {:noreply, socket}
    end
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
end
