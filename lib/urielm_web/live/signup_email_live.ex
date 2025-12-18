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

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4">
        <div class="max-w-md w-full space-y-8">
          <div class="text-center">
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
              Create account
            </h1>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
              Sign up with your email address
            </p>
          </div>

          <.form for={@form} phx-submit="submit" class="space-y-4">
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Email
              </label>
              <input
                type="email"
                name="email"
                id="email"
                value={@form[:email].value}
                required
                class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="you@example.com"
              />
            </div>

            <div>
              <label for="password" class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Password
              </label>
              <input
                type="password"
                name="password"
                id="password"
                value={@form[:password].value}
                required
                minlength="8"
                class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="At least 8 characters"
              />
              <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                Minimum 8 characters
              </p>
            </div>

            <%= if @error do %>
              <div class="p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
                <p class="text-sm text-red-600 dark:text-red-400">{@error}</p>
              </div>
            <% end %>

            <button
              type="submit"
              disabled={@loading}
              class="w-full flex items-center justify-center px-4 py-3 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <%= if @loading do %>
                <svg class="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  >
                  </circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  >
                  </path>
                </svg>
              <% else %>
                Create account
              <% end %>
            </button>
          </.form>

          <div class="text-center space-y-3">
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Already have an account?
              <a href="/signin" class="font-medium text-blue-600 dark:text-blue-400 hover:underline">
                Sign in
              </a>
            </p>

            <p class="text-sm text-gray-600 dark:text-gray-400">
              <a href="/signup" class="font-medium text-blue-600 dark:text-blue-400 hover:underline">
                ← Back to signup options
              </a>
            </p>
          </div>
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
        # Redirect to controller action that sets session and redirects to verification page
        {:noreply, redirect(socket, to: "/auth/post-signup/#{user.id}")}

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
