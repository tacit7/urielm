defmodule UrielmWeb.VerifyEmailLive do
  use UrielmWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    pending_redirect = Map.get(session, "pending_redirect")

    if user && user.email_verified do
      return_to = pending_redirect || "/"
      {:ok, push_navigate(socket, to: return_to)}
    else
      {:ok, assign(socket, resend_cooldown: false, pending_redirect: pending_redirect)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4">
        <div class="max-w-md w-full space-y-6 text-center">
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-full w-16 h-16 flex items-center justify-center mx-auto">
            <svg
              class="w-8 h-8 text-blue-600 dark:text-blue-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
              />
            </svg>
          </div>

          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
              Check your email
            </h1>
            <p class="mt-2 text-gray-600 dark:text-gray-400">
              We sent a verification link to
            </p>
            <p class="font-medium text-gray-900 dark:text-white">
              {@current_user.email}
            </p>
          </div>

          <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
            <p class="text-sm text-yellow-800 dark:text-yellow-200">
              You can browse the site, but you'll need to verify your email before posting or commenting.
            </p>
          </div>

          <div class="space-y-3">
            <button
              phx-click="resend"
              disabled={@resend_cooldown}
              class="w-full px-4 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <%= if @resend_cooldown do %>
                Email sent! Wait 60s to resend
              <% else %>
                Resend verification email
              <% end %>
            </button>

            <a
              href={@pending_redirect || "/"}
              class="block w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              Continue browsing
            </a>
          </div>
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
