defmodule UrielmWeb.SessionAuth do
  @moduledoc false
  import Plug.Conn
  alias Urielm.Accounts.Sessions

  def log_in(conn, user) do
    Sessions.revoke(get_session(conn, :session_token))
    token = Sessions.create(user)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:session_token, token)
    |> put_session(:live_socket_id, Sessions.topic(token))
    # Kept for display/backwards-compatible consumers; never used to authenticate.
    |> put_session(:user_id, user.id)
  end

  def log_out(conn) do
    Sessions.revoke(get_session(conn, :session_token))
    conn |> clear_session() |> configure_session(drop: true)
  end
end
