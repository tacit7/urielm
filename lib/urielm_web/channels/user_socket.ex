defmodule UrielmWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", UrielmWeb.RoomChannel

  # Tokens are valid for 10 minutes — enough for page load + initial connect.
  @max_age 600

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, user_id} ->
        case Urielm.Accounts.get_user(user_id) do
          nil -> :error
          user -> {:ok, assign(socket, :current_user, user)}
        end

      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket) do
    "user_socket:#{socket.assigns.current_user.id}"
  end
end
