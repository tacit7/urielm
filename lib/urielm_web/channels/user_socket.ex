defmodule UrielmWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", UrielmWeb.RoomChannel

  @impl true
  def connect(params, socket, _connect_info) do
    # Get user_id from params (passed from LiveView)
    case params["user_id"] do
      user_id when is_binary(user_id) ->
        case Integer.parse(user_id) do
          {id, ""} ->
            case Urielm.Accounts.get_user(id) do
              nil -> :error
              user -> {:ok, assign(socket, :current_user, user)}
            end

          :error ->
            :error
        end

      _ ->
        :error
    end
  end

  @impl true
  def id(socket) do
    "user_socket:#{socket.assigns.current_user.id}"
  end
end
