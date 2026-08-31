defmodule UrielmWeb.VerifyEmailLive do
  use UrielmWeb, :live_view
  alias UrielmWeb.Redirects

  @impl true
  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    pending_redirect = Redirects.safe_return_path(Map.get(session, "pending_redirect"))

    if user && user.email_verified do
      return_to = pending_redirect || "/"
      {:ok, push_navigate(socket, to: return_to)}
    else
      {:ok,
       assign(socket,
         resend_cooldown: false,
         pending_redirect: pending_redirect,
         page_title: "Verify your email"
       )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div id="auth-page" class="ui-auth-page">
        <div class="ui-auth-frame">
          <section id="verify-email-card" class="ui-auth-panel text-center">
            <div class="mx-auto grid size-14 place-items-center rounded-2xl bg-primary/10 text-primary">
              <.um_icon name="hero-envelope" class="size-7" />
            </div>

            <header class="mt-6">
              <p class="ui-eyebrow">One more step</p>
              <h1 class="mt-2 text-3xl font-black text-base-content">Check your email</h1>
              <p class="mt-3 text-sm leading-relaxed text-base-content/55">
                We sent a verification link to
                <strong class="block break-all font-bold text-base-content">
                  {@current_user.email}
                </strong>
              </p>
            </header>

            <div class="alert alert-warning mt-6 text-left text-sm">
              <.um_icon name="hero-information-circle" class="size-5 shrink-0" />
              <span>
                You can browse now, but posting and commenting require a verified email.
              </span>
            </div>

            <div class="mt-6 space-y-3">
              <.button
                id="resend-verification-button"
                type="button"
                phx-click="resend"
                disabled={@resend_cooldown}
                class="btn btn-primary h-12 w-full rounded-full font-bold"
              >
                {if @resend_cooldown,
                  do: "Email sent. Try again in 60 seconds",
                  else: "Resend verification email"}
              </.button>

              <.link
                id="continue-browsing-link"
                navigate={@pending_redirect || "/"}
                class="btn btn-ghost h-11 w-full rounded-xl"
              >
                Continue browsing
              </.link>
            </div>
          </section>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def handle_event("resend", _params, socket) do
    # TODO: Implement email sending logic
    # For now, just show cooldown

    Process.send_after(self(), :reset_cooldown, 60_000)

    socket =
      socket
      |> assign(:resend_cooldown, true)
      |> put_flash(:info, "Verification email sent!")

    {:noreply, socket}
  end

  @impl true
  def handle_info(:reset_cooldown, socket) do
    {:noreply, assign(socket, :resend_cooldown, false)}
  end
end
