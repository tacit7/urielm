defmodule UrielmWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", UrielmWeb.RoomChannel

  # Phoenix supplies this session only after validating the signed cookie and
  # the socket CSRF token. Never authenticate from browser-visible params.
  @impl true
  def connect(_params, socket, %{session: %{"session_token" => token}}) do
    case Urielm.Accounts.Sessions.user(token) do
      nil ->
        :error

      user ->
        if Urielm.Accounts.User.suspended?(user) || !user.active do
          :error
        else
          {:ok, socket |> assign(:current_user, user) |> assign(:session_token, token)}
        end
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket) do
    Urielm.Accounts.Sessions.topic(socket.assigns.session_token)
  end
end
