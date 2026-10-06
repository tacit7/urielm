defmodule UrielmWeb.RoomChannel do
  @moduledoc false

  use Phoenix.Channel
  alias Urielm.Chat
  require Logger

  intercept ["message_created", "typing"]

  def join("room:" <> room_id, _payload, socket) do
    session = Urielm.Accounts.Sessions.fetch(socket.assigns[:session_token])

    room_id_int =
      case Integer.parse(room_id) do
        {n, ""} -> n
        _ -> nil
      end

    case room_id_int do
      nil ->
        Logger.error("Invalid room ID: #{inspect(room_id)}")
        {:error, %{reason: "invalid_room_id"}}

      room_id_int ->
        with {user, _record} <- session,
             :ok <-
               Phoenix.PubSub.subscribe(
                 Urielm.PubSub,
                 Chat.membership_topic(user.id, room_id_int)
               ),
             joined = socket |> assign(:room_id, room_id_int) |> assign(:current_user, user),
             {:ok, _current_user} <- authorize_socket(joined, :read),
             messages = load_room_messages(room_id_int),
             {:ok, current_user} <- authorize_socket(joined, :read),
             {session_user, record} <-
               Urielm.Accounts.Sessions.fetch(socket.assigns[:session_token]),
             true <- session_user.id == current_user.id do
          delay = max(DateTime.diff(record.expires_at, DateTime.utc_now(), :millisecond), 0)
          Process.send_after(self(), :session_expired, delay)
          {:ok, %{messages: messages}, assign(joined, :current_user, current_user)}
        else
          _ -> {:error, %{reason: "unauthorized"}}
        end
    end
  rescue
    e ->
      Logger.error("Error joining room: #{inspect(e)}")
      {:error, %{reason: "error"}}
  end

  def handle_in(event, payload, socket) do
    case authorize_socket(socket, :post) do
      {:ok, user} -> handle_authenticated(event, payload, assign(socket, :current_user, user))
      {:error, :silenced} -> {:reply, {:error, %{reason: "silenced"}}, socket}
      {:error, :unauthorized} -> {:stop, :normal, {:error, %{reason: "unauthorized"}}, socket}
    end
  end

  def handle_out(event, payload, socket) when event in ["message_created", "typing"] do
    case authorize_socket(socket, :read) do
      {:ok, user} ->
        push(socket, event, payload)
        {:noreply, assign(socket, :current_user, user)}

      {:error, :unauthorized} ->
        {:stop, :normal, socket}
    end
  end

  def handle_info({:room_access_revoked, user_id, room_id}, socket) do
    if user_id == socket.assigns.current_user.id && room_id == socket.assigns.room_id do
      {:stop, :normal, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:session_expired, socket), do: {:stop, :normal, socket}

  defp authorize_socket(socket, mode) do
    case Urielm.Accounts.Sessions.fetch(socket.assigns[:session_token]) do
      {user, _record} when user.id == socket.assigns.current_user.id ->
        if mode == :post,
          do: Chat.authorize_post(user.id, socket.assigns.room_id),
          else: Chat.authorize_access(user.id, socket.assigns.room_id)

      _ ->
        {:error, :unauthorized}
    end
  end

  defp handle_authenticated("new_message", %{"body" => body}, socket) do
    user = socket.assigns[:current_user]
    room_id = socket.assigns[:room_id]

    Logger.info("Creating message: user=#{user.id}, room=#{room_id}")

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

      {:error, %Ecto.Changeset{} = changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
            Enum.reduce(opts, message, fn {key, value}, text ->
              String.replace(text, "%{#{key}}", to_string(value))
            end)
          end)

        {:reply, {:error, %{errors: errors}}, socket}

      {:error, reason} when reason in [:unauthorized, :silenced] ->
        {:reply, {:error, %{reason: Atom.to_string(reason)}}, socket}
    end
  rescue
    e ->
      Logger.error("Error in handle_in: #{inspect(e)}")
      {:reply, {:error, %{reason: "error"}}, socket}
  end

  defp handle_authenticated("typing", _payload, socket) do
    user = socket.assigns[:current_user]

    broadcast_from!(socket, "typing", %{
      user_id: user.id,
      username: user.username
    })

    {:noreply, socket}
  end

  defp handle_authenticated(_event, _payload, socket) do
    {:reply, {:error, %{reason: "invalid_event"}}, socket}
  end

  defp load_room_messages(room_id_int) do
    Chat.list_room_messages(room_id_int, 50)
    |> Enum.map(fn msg ->
      if Ecto.assoc_loaded?(msg.user), do: msg, else: Urielm.Repo.preload(msg, :user)
    end)
    |> Enum.map(&serialize_message/1)
  end

  defp serialize_message(message) do
    # Ensure user is loaded
    user =
      if is_nil(message.user), do: Urielm.Repo.preload(message, :user).user, else: message.user

    %{
      id: message.id,
      body: message.body,
      user_id: message.user_id,
      username: user.username || "Unknown",
      inserted_at: message.inserted_at
    }
  end
end
