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

  @doc """
  OAuth callback - failed authentication
  """
  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate. Please try again.")
    |> redirect(to: ~p"/")
  end

  @doc """
  Sign up with email and password
  """
  def signup(conn, %{"email" => email, "password" => password} = params) do
    user_params = %{
      email: email,
      password: password,
      name: Map.get(params, "name")
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
  Sign out user
  """
  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been signed out.")
    |> redirect(to: ~p"/")
  end
end
