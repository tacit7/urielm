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

  # OAuth callback - failed authentication
  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate. Please try again.")
    |> redirect(to: ~p"/")
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
  Sign out user
  """
  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been signed out.")
    |> redirect(to: ~p"/")
  end
end
