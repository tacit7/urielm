defmodule UrielmWeb.SuspendedLive do
  use UrielmWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Get suspension info from flash (set during redirect)
    reason = Phoenix.Flash.get(socket.assigns.flash, :suspension_reason)
    until = Phoenix.Flash.get(socket.assigns.flash, :suspension_until)

    socket =
      socket
      |> assign(:reason, reason)
      |> assign(:until, until)
      |> assign(:page_title, "Account suspended")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div id="auth-page" class="ui-auth-page">
        <div class="ui-auth-frame">
          <section id="suspended-card" class="ui-auth-panel text-center">
            <div class="mx-auto grid size-14 place-items-center rounded-2xl bg-error/10 text-error">
              <.um_icon name="hero-no-symbol" class="size-7" />
            </div>

            <header class="mt-6">
              <p class="ui-eyebrow text-error">Access restricted</p>
              <h1 class="mt-2 text-3xl font-black text-base-content">Account suspended</h1>
              <p class="mt-2 text-sm leading-relaxed text-base-content/55">
                Your account is currently unable to access the site.
              </p>
            </header>

            <div
              :if={@reason}
              class="mt-6 rounded-xl border border-base-300 bg-base-100/45 p-4 text-left"
            >
              <p class="text-xs font-bold uppercase text-base-content/45">Reason</p>
              <p class="mt-1 text-sm leading-relaxed text-base-content">{@reason}</p>
            </div>

            <p :if={@until} class="mt-5 text-sm leading-relaxed text-base-content/60">
              Your suspension ends on <strong class="font-bold text-base-content">
                {Calendar.strftime(@until, "%B %d, %Y at %I:%M %p")}
              </strong>.
            </p>
            <p :if={!@until && @reason} class="mt-5 text-sm text-base-content/60">
              This suspension is permanent.
            </p>

            <div class="divider my-6"></div>

            <p class="text-sm leading-relaxed text-base-content/60">
              If you believe this is a mistake, contact <a
                href="mailto:support@urielm.dev"
                class="link link-primary font-semibold"
              >
                support@urielm.dev
              </a>.
            </p>

            <.link navigate={~p"/"} class="btn btn-ghost mt-5 w-full rounded-xl">
              Return home
            </.link>
          </section>
        </div>
      </div>
    </Layouts.auth>
    """
  end
end
