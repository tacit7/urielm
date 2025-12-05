defmodule UrielmWeb.AuthController do
  use UrielmWeb, :controller
  plug Ueberauth

  alias Urielm.Accounts

  @doc """
  OAuth callback - successful authentication
  """
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create_user(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome #{user.name || user.email}!")
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Authentication failed. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  @doc """
  OAuth callback - failed authentication
  """
  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate. Please try again.")
    |> redirect(to: ~p"/")
  end

  @doc """
  Sign out user
  """
  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been signed out.")
    |> redirect(to: ~p"/")
  end
end
