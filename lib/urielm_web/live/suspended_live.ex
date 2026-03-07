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

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div class="min-h-screen flex items-center justify-center bg-base-100 px-4">
        <div class="max-w-lg w-full">
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body text-center space-y-6">
              <div class="flex justify-center">
                <div class="w-16 h-16 rounded-full bg-error/20 flex items-center justify-center">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-8 w-8 text-error"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"
                    />
                  </svg>
                </div>
              </div>

              <div>
                <h1 class="text-2xl font-bold text-base-content">
                  Account Suspended
                </h1>
                <p class="mt-2 text-base-content/70">
                  Your account has been suspended and you cannot access the site.
                </p>
              </div>

              <%= if @reason do %>
                <div class="bg-base-300 rounded-lg p-4 text-left">
                  <p class="text-sm font-medium text-base-content/70 mb-1">Reason:</p>
                  <p class="text-base-content">{@reason}</p>
                </div>
              <% end %>

              <%= if @until do %>
                <div class="text-sm text-base-content/70">
                  <p>
                    Your suspension ends on
                    <span class="font-medium text-base-content">
                      {Calendar.strftime(@until, "%B %d, %Y at %I:%M %p")}
                    </span>
                  </p>
                </div>
              <% else %>
                <p :if={@reason} class="text-sm text-base-content/70">
                  This suspension is permanent.
                </p>
              <% end %>

              <div class="divider"></div>

              <div class="text-sm text-base-content/70">
                <p>
                  If you believe this is a mistake, please contact us at
                  <a href="mailto:support@urielm.dev" class="link link-primary">
                    support@urielm.dev
                  </a>
                </p>
              </div>

              <a href="/" class="btn btn-ghost btn-sm">
                Return to Home
              </a>
            </div>
          </div>
        </div>
      </div>
    </Layouts.auth>
    """
  end
end
