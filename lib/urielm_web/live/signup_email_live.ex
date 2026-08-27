defmodule UrielmWeb.SignupEmailLive do
  use UrielmWeb, :live_view
  alias Urielm.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"email" => "", "password" => ""}))
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
  def handle_event("submit", %{"email" => email, "password" => password}, socket) do
    socket = assign(socket, :loading, true)

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
