defmodule UrielmWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", UrielmWeb.RoomChannel

  # Tokens are valid for 10 minutes — enough for page load + initial connect.
  @max_age 600

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, session_token} ->
        case Urielm.Accounts.Sessions.user(session_token) do
          nil ->
            :error

          user ->
            {:ok, socket |> assign(:current_user, user) |> assign(:session_token, session_token)}
        end

      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket) do
    Urielm.Accounts.Sessions.topic(socket.assigns.session_token)
  end
end
