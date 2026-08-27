defmodule UrielmWeb.AuthController do
  use UrielmWeb, :controller
  plug Ueberauth

  alias Urielm.Accounts
  alias Urielm.RateLimiter

  # Rate limits for the email/password auth endpoints, as `{max_requests, window_seconds}`.
  #
  # Every signin/signup attempt costs a full bcrypt round, so unthrottled these
  # endpoints allow both credential stuffing and a cheap CPU DoS. check_handle is
  # an unauthenticated username-enumeration oracle.
  #
  # Each request is keyed on BOTH the client IP and the submitted identifier
  # (email for signin/signup, username for check_handle) and the stricter of the
  # two wins. IP-only is trivially bypassed by a distributed attacker; identifier
  # -only lets one host spray many accounts. Limits are per 60s so a human who
  # fat-fingers a password a few times is never affected, while sustained abuse
  # is capped. Tune here.
  @signin_ip_limit {10, 60}
  @signin_id_limit {5, 60}
  @signup_ip_limit {5, 60}
  @signup_id_limit {3, 60}
  # check_handle is called from the signup form (client-side debounced), so it
  # gets more headroom than the password endpoints.
  @check_handle_ip_limit {30, 60}
  @check_handle_id_limit {15, 60}

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

    case rate_limit(conn, "signup", email, @signup_ip_limit, @signup_id_limit) do
      {:error, :rate_limited} -> too_many_requests(conn)
      :ok -> do_signup(conn, email, password, username, display_name)
    end
  end

  defp do_signup(conn, email, password, username, display_name) do
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
    case rate_limit(conn, "signin", email, @signin_ip_limit, @signin_id_limit) do
      {:error, :rate_limited} -> too_many_requests(conn)
      :ok -> do_signin(conn, email, password)
    end
  end

  defp do_signin(conn, email, password) do
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

  # Rate-limits an attempt on both the client IP and the submitted identifier.
  # Returns `:ok` or `{:error, :rate_limited}`. Honors :rate_limit_bypass in tests.
  defp rate_limit(conn, action, identifier, {ip_max, ip_window}, {id_max, id_window}) do
    ip = client_ip(conn)
    id = identifier |> to_string() |> String.trim() |> String.downcase()

    RateLimiter.check_all([
      {"auth_ip:#{ip}", action, max_requests: ip_max, window_seconds: ip_window},
      {"auth_id:#{id}", action, max_requests: id_max, window_seconds: id_window}
    ])
  end

  # Client IP, used as a rate-limit key.
  #
  # X-Forwarded-For is a client-supplied header, so the LEFTMOST entries are
  # attacker-controlled: anyone can send "X-Forwarded-For: 1.2.3.4" and mint a
  # fresh rate-limit bucket per request. Our reverse proxy appends the peer it
  # actually saw, so the RIGHTMOST entry is the first value the attacker cannot
  # forge. Take that one, dropping any hops the attacker prepended.
  #
  # :trusted_proxy_hops is how many proxies sit in front of the app (default 1).
  # Raise it only if you add another appending proxy; each extra hop discards one
  # more entry from the right.
  defp client_ip(conn) do
    hops = Application.get_env(:urielm, :trusted_proxy_hops, 1)

    forwarded =
      conn
      |> get_req_header("x-forwarded-for")
      |> Enum.flat_map(&String.split(&1, ","))
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case Enum.at(forwarded, -hops) do
      value when is_binary(value) -> value
      nil -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  # 429 for the JSON endpoints. Deliberately generic so it never leaks whether
  # the account/handle exists.
  defp too_many_requests(conn) do
    conn
    |> put_status(:too_many_requests)
    |> json(%{error: "Too many attempts. Please try again later."})
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
    case rate_limit(
           conn,
           "check_handle",
           username,
           @check_handle_ip_limit,
           @check_handle_id_limit
         ) do
      {:error, :rate_limited} -> too_many_requests(conn)
      :ok -> do_check_handle(conn, username)
    end
  end

  defp do_check_handle(conn, username) do
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

  # Tokens are valid for 10 minutes — enough to survive the redirect from signup.
  @post_signup_token_max_age 600

  @doc """
  Signs a short-lived token that authorizes the post-signup redirect for a specific user.
  Called immediately after user record creation.
  """
  def sign_post_signup_token(conn_or_endpoint, user_id) do
    Phoenix.Token.sign(conn_or_endpoint, "post signup", user_id,
      max_age: @post_signup_token_max_age
    )
  end

  @doc """
  Post-signup redirect - verifies a signed token and sets the session.
  The token is minted by sign_post_signup_token/2 immediately after registration.
  """
  def post_signup(conn, %{"token" => token}) do
    case Phoenix.Token.verify(conn, "post signup", token, max_age: @post_signup_token_max_age) do
      {:error, _} ->
        conn |> put_flash(:error, "Session invalid") |> redirect(to: ~p"/")

      {:ok, user_id} ->
        case Accounts.get_user(user_id) do
          nil ->
            conn |> put_flash(:error, "Session invalid") |> redirect(to: ~p"/")

          user ->
            return_to = get_session(conn, :return_to) || "/"

            conn =
              conn
              |> put_session(:user_id, user.id)
              |> delete_session(:return_to)
              |> configure_session(renew: true)

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
