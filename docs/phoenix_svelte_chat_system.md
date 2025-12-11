# Building a Chat System with Phoenix and Svelte

Phoenix handles your backend and real time layer; Svelte handles the UI without dragging a million dependencies into your bundle. This stack gives you a fast, predictable chat system that does not fight you at scale.

## Architecture

- **Phoenix**
  - HTTP API for auth, rooms, and message history
  - WebSockets via Phoenix Channels
  - Ecto + Postgres for persistence

- **Svelte**
  - SPA or embedded widget
  - Connects to Phoenix Channels
  - Owns UI state, message buffer, room selection

## Data Model

Minimum viable schema:

```
users
rooms
room_memberships
messages
```

`messages` table example:

```
id          bigserial
room_id     references rooms
user_id     references users
body        text
inserted_at utc_datetime
```

## Phoenix Channels

Example channel module:

```elixir
defmodule MyAppWeb.RoomChannel do
  use Phoenix.Channel
  alias MyApp.Chat

  def join("room:" <> room_id, _payload, %{assigns: %{current_user: user}} = socket) do
    if Chat.member?(user.id, room_id) do
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new_message", %{"body" => body}, socket) do
    user_id = socket.assigns.current_user.id
    room_id = socket.assigns.room_id

    case Chat.create_message(%{user_id: user_id, room_id: room_id, body: body}) do
      {:ok, message} ->
        broadcast!(socket, "message_created", %{
          id: message.id,
          body: message.body,
          user_id: message.user_id,
          room_id: message.room_id,
          inserted_at: message.inserted_at
        })
        {:noreply, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end
end
```

## Svelte Integration

Install Phoenix JS client:

```
npm install phoenix
```

Create a wrapper:

```ts
import { Socket } from "phoenix";
const socket = new Socket("/socket", {
  params: () => ({ token: localStorage.getItem("auth_token") })
});
socket.connect();
export function joinRoom(roomId) {
  const channel = socket.channel(`room:${roomId}`, {});
  return new Promise((resolve, reject) => {
    channel.join().receive("ok", () => resolve(channel)).receive("error", reject);
  });
}
```

## Svelte Stores

```ts
import { writable } from "svelte/store";
export const currentRoomId = writable(null);
export const messages = writable([]);
export const isConnected = writable(false);
```

Connection logic:

```ts
let activeChannel = null;
export async function connectToRoom(roomId) {
  if (activeChannel) activeChannel.leave();
  messages.set([]);
  currentRoomId.set(roomId);

  const channel = await joinRoom(roomId);
  activeChannel = channel;

  channel.on("message_created", payload => {
    messages.update(list => [...list, payload]);
  });

  isConnected.set(true);
}
```

## Svelte Chat Component

```svelte
<script>
  import { onMount } from "svelte";
  import { messages, isConnected } from "$lib/chat/store";
  import { connectToRoom, sendMessage } from "$lib/chat/joinRoom";
  let input = "";
  const roomId = "general";
  onMount(() => connectToRoom(roomId));
  function handleSend() {
    if (input.trim()) {
      sendMessage(input.trim());
      input = "";
    }
  }
</script>
```

## Message History

Use a `GET /api/rooms/:id/messages` endpoint for historical messages. Load these before connecting to the channel.

## Optional Enhancements

- Phoenix Presence for online users
- Typing indicators
- Message editing
- Read receipts
- Room-level permissions

## Summary

Phoenix owns business logic and real time events; Svelte owns UI state. This division keeps your system simple, predictable, and fast while staying flexible for future features.
