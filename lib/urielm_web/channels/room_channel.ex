defmodule UrielmWeb.RoomChannel do
  use Phoenix.Channel
  alias Urielm.Chat
  require Logger

  def join("room:" <> room_id, _payload, socket) do
    user = socket.assigns[:current_user]
    room_id_int = String.to_integer(room_id)

    if user && Chat.is_member?(user.id, room_id_int) do
      # Load recent messages with users preloaded
      messages =
        Chat.list_room_messages(room_id_int, 50)
        |> Enum.map(fn msg ->
          # Ensure user is loaded
          if Ecto.assoc_loaded?(msg.user) do
            msg
          else
            Urielm.Repo.preload(msg, :user)
          end
        end)
        |> Enum.map(&serialize_message/1)

      {:ok,
       %{messages: messages},
       assign(socket, :room_id, room_id_int)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  rescue
    e ->
      Logger.error("Error joining room: #{inspect(e)}")
      {:error, %{reason: "error"}}
  end

  def handle_in("new_message", %{"body" => body}, socket) do
    user = socket.assigns[:current_user]
    room_id = socket.assigns[:room_id]

    Logger.info("Creating message: user=#{user.id}, room=#{room_id}, body=#{body}")

    case Chat.create_message(%{
      body: body,
      user_id: user.id,
      room_id: room_id
    }) do
      {:ok, message} ->
        Logger.info("Message created: #{message.id}")
        message = Urielm.Repo.preload(message, :user)
        serialized = serialize_message(message)
        broadcast!(socket, "message_created", serialized)
        {:noreply, socket}

      {:error, changeset} ->
        Logger.error("Error creating message: #{inspect(changeset)}")
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  rescue
    e ->
      Logger.error("Error in handle_in: #{inspect(e)}")
      {:reply, {:error, %{reason: "error"}}, socket}
  end

  def handle_in("typing", _payload, socket) do
    user = socket.assigns[:current_user]

    broadcast_from!(socket, "typing", %{
      user_id: user.id,
      username: user.username
    })

    {:noreply, socket}
  end

  defp serialize_message(message) do
    # Ensure user is loaded
    user = if is_nil(message.user), do: Urielm.Repo.preload(message, :user).user, else: message.user

    %{
      id: message.id,
      body: message.body,
      user_id: message.user_id,
      username: user.username || "Unknown",
      inserted_at: message.inserted_at
    }
  end
end
