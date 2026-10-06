defmodule UrielmWeb.SessionAuth do
  @moduledoc false
  import Plug.Conn
  alias Urielm.Accounts.Sessions

  def init(opts), do: opts

  def call(%{method: "GET", request_path: "/signup/email"} = conn, _opts) do
    if Urielm.Accounts.email_signup_enabled?() && !get_session(conn, :signup_binding) do
      put_session(
        conn,
        :signup_binding,
        :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
      )
    else
      conn
    end
  end

  def call(conn, _opts), do: conn

  def log_in(conn, user) do
    Sessions.revoke(get_session(conn, :session_token))
    token = Sessions.create(user)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:session_token, token)
    |> put_session(:live_socket_id, Sessions.topic(token))
  end

  def log_out(conn) do
    Sessions.revoke(get_session(conn, :session_token))
    conn |> clear_session() |> configure_session(drop: true)
  end
end
