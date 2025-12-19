defmodule UrielmWeb.AuthController do
  use UrielmWeb, :controller
  plug Ueberauth

  alias Urielm.Accounts

  @doc """
  Initiate OAuth request - handled by Ueberauth plug
  """
  def request(conn, _params) do
    # Ueberauth plug handles this, but we need this function defined
    # This is a fallback that should rarely be called
    conn
  end

  # OAuth callback - successful authentication
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create_user(auth) do
      {:ok, user} ->
        return_to = get_session(conn, :return_to) || "/"

        conn =
          conn
          |> put_flash(:info, "Welcome #{user.name || user.email}!")
          |> put_session(:user_id, user.id)
          |> delete_session(:return_to)
          |> configure_session(renew: true)

        # Check if user needs a handle for this action
        if needs_handle_for_action?(return_to) && is_nil(user.username) do
          conn
          |> put_session(:pending_redirect, return_to)
          |> redirect(to: ~p"/signup/set-handle")
        else
          redirect(conn, to: return_to)
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Authentication failed. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  # OAuth callback - failed authentication
  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate. Please try again.")
    |> redirect(to: ~p"/")
  end

  # Check if the action requires a username/handle
  defp needs_handle_for_action?(path) do
    # Paths that require a handle: posting, commenting, creating threads
    String.contains?(path, "/new") ||
      String.contains?(path, "/post") ||
      String.contains?(path, "/comment")
  end

  @doc """
  Sign up with email and password
  """
  def signup(conn, params) do
    email = Map.get(params, "email")
    password = Map.get(params, "password")
    username = Map.get(params, "username")
    display_name = Map.get(params, "displayName")

    user_params = %{
      email: email,
      password: password,
      username: if(username, do: String.downcase(String.trim(username))),
      display_name: if(display_name, do: String.trim(display_name))
    }

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_status(:ok)
        |> json(%{success: true})

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
        error_message = format_errors(errors)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: error_message})
    end
  end

  @doc """
  Sign in with email and password
  """
  def signin(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_status(:ok)
        |> json(%{success: true})

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {field, messages} ->
      "#{field}: #{Enum.join(messages, ", ")}"
    end)
    |> Enum.join("; ")
  end

  @doc """
  Check if handle (username) is available
  """
  def check_handle(conn, %{"username" => username}) do
    case Accounts.get_user_by_username(String.downcase(String.trim(username))) do
      nil ->
        conn
        |> put_status(:ok)
        |> json(%{available: true})

      _user ->
        conn
        |> put_status(:ok)
        |> json(%{available: false})
    end
  end

  @doc """
  Post-signup redirect - sets session and redirects to verification page or intended destination
  """
  def post_signup(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user(String.to_integer(user_id))
    return_to = get_session(conn, :return_to) || "/"

    conn =
      conn
      |> put_session(:user_id, user.id)
      |> delete_session(:return_to)
      |> configure_session(renew: true)

    # If email not verified, redirect to verification page
    cond do
      !user.email_verified ->
        conn
        |> put_session(:pending_redirect, return_to)
        |> redirect(to: ~p"/signup/verify-email")

      needs_handle_for_action?(return_to) && is_nil(user.username) ->
        conn
        |> put_session(:pending_redirect, return_to)
        |> redirect(to: ~p"/signup/set-handle")

      true ->
        redirect(conn, to: return_to)
    end
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
