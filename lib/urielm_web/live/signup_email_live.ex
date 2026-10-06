defmodule UrielmWeb.SignupEmailLive do
  use UrielmWeb, :live_view
  alias Urielm.Accounts

  @impl true
  def mount(_params, _session, socket) do
    if Accounts.email_signup_enabled?() do
      mount_enabled(socket)
    else
      {:ok, redirect(socket, to: ~p"/signup")}
    end
  end

  defp mount_enabled(socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"email" => "", "password" => ""}))
      |> assign(:registration_ip, registration_ip(socket))
      |> assign(:error, nil)
      |> assign(:loading, false)
      |> assign(:page_title, "Create account with email")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div id="auth-page" class="ui-auth-page">
        <div class="ui-auth-frame">
          <section id="signup-email-card" class="ui-auth-panel">
            <header>
              <p class="ui-eyebrow text-secondary">Email signup</p>
              <h1 class="mt-2 text-3xl font-black text-base-content">Create your account</h1>
              <p class="mt-2 text-sm leading-relaxed text-base-content/55">
                Use your email address and a secure password to get started.
              </p>
            </header>

            <.form for={@form} phx-submit="submit" id="signup-email-form" class="mt-7 space-y-4">
              <.input
                field={@form[:email]}
                id="signup-email-address"
                type="email"
                label="Email address"
                required
                autocomplete="email"
                placeholder="you@example.com"
              />

              <.input
                field={@form[:password]}
                id="signup-email-password"
                type="password"
                label="Password"
                required
                autocomplete="new-password"
                minlength="8"
                help="Use at least 8 characters."
                placeholder="At least 8 characters"
              />

              <%= if @error do %>
                <.form_feedback id="signup-email-error" kind={:error} title="Account not created">
                  {@error}
                </.form_feedback>
              <% end %>

              <.button
                id="signup-email-submit"
                type="submit"
                disabled={@loading}
                loading_label="Creating account…"
                class="btn btn-primary h-12 w-full rounded-full font-bold"
              >
                Create account
              </.button>
            </.form>

            <div class="mt-6 space-y-3 text-center text-sm text-base-content/55">
              <p>
                Already have an account?
                <.link navigate={~p"/signin"} class="font-bold text-primary hover:underline">
                  Sign in
                </.link>
              </p>

              <.link
                id="signup-options-link"
                navigate={~p"/signup"}
                class="inline-flex items-center gap-1.5 font-semibold text-base-content/60 hover:text-primary"
              >
                <.um_icon name="hero-arrow-left" class="size-4" /> Signup options
              </.link>
            </div>
          </section>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def handle_event("submit", params, socket) do
    if Accounts.email_signup_enabled?() do
      submit_enabled(params, socket)
    else
      {:noreply, redirect(socket, to: ~p"/signup")}
    end
  end

  defp submit_enabled(%{"email" => email, "password" => password}, socket) do
    socket = assign(socket, :loading, true)

    case UrielmWeb.RegistrationLimiter.check(socket.assigns.registration_ip, email) do
      :ok ->
        register(socket, email, password)

      {:error, :rate_limited} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error, "Too many attempts. Please try again later.")}
    end
  end

  defp registration_ip(socket) do
    peer = get_connect_info(socket, :peer_data)
    headers = get_connect_info(socket, :x_headers) || []
    UrielmWeb.RegistrationLimiter.client_ip(peer.address, headers)
  end

  defp register(socket, email, password) do
    case Accounts.register_user_email_only(%{email: email, password: password}) do
      {:ok, user} ->
        token = UrielmWeb.AuthController.sign_post_signup_token(socket, user.id)
        {:noreply, redirect(socket, to: "/auth/post-signup/#{token}")}

      {:error, changeset} ->
        error_message = format_error(changeset)

        socket =
          socket
          |> assign(:error, error_message)
          |> assign(:loading, false)

        {:noreply, socket}
    end
  end

  defp format_error(changeset) do
    UrielmWeb.LiveHelpers.format_changeset_errors(changeset)
  end
end
