defmodule UrielmWeb.Plugs.Auth do
  @moduledoc """
  Authentication plugs for fetching and requiring authenticated users.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias Urielm.Accounts

  def init(opts), do: opts

  def call(conn, :fetch_current_user) do
    fetch_current_user(conn)
  end

  def call(conn, :require_authenticated_user) do
    require_authenticated_user(conn)
  end

  def call(conn, :require_admin) do
    require_admin(conn)
  end

  defp fetch_current_user(conn) do
    user_id = get_session(conn, :user_id)

    cond do
      user = user_id && Accounts.get_user(user_id) ->
        assign(conn, :current_user, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end

  defp require_authenticated_user(conn) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be signed in to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  defp require_admin(conn) do
    if conn.assigns[:current_user] && conn.assigns[:current_user].is_admin do
      conn
    else
      conn
      |> put_flash(:error, "You must be an admin to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
