defmodule UrielmWeb.SignupLive do
  use UrielmWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"email" => "", "password" => "", "username" => "", "displayName" => ""}))
      |> assign(:error, nil)
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div class="min-h-screen flex items-center justify-center bg-base-100 px-4">
        <div class="max-w-md w-full space-y-8">
          <div class="text-center">
            <h1 class="text-3xl font-bold text-base-content">
              Create account
            </h1>
            <p class="mt-2 text-sm text-base-content/70">
              Join to unlock all features
            </p>
          </div>

          <div class="space-y-4">
            <a
              href="/auth/google"
              class="w-full flex items-center justify-center gap-3 px-4 py-3 border border-base-300 rounded-lg shadow-sm text-sm font-medium text-base-content bg-base-200 hover:bg-base-300 transition-colors"
            >
              <svg class="w-5 h-5" viewBox="0 0 24 24">
                <path
                  fill="currentColor"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="currentColor"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="currentColor"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="currentColor"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              Continue with Google
            </a>

            <div class="divider text-xs text-base-content/50">or</div>

            <.form
              for={@form}
              phx-submit="submit"
              id="signup-form"
              phx-hook="SignupForm"
              class="space-y-4"
            >
              <div phx-update="ignore" id="signup-form-fields">
                <div class="space-y-4">
                  <div>
                    <label for="username" class="block text-sm font-medium text-base-content/70">
                      Username
                    </label>
                    <input
                      type="text"
                      name="username"
                      id="username"
                      required
                      class="mt-1 block w-full px-3 py-2 input input-bordered bg-base-200"
                      placeholder="lowercase-username"
                      autocomplete="off"
                    />
                    <p class="mt-1 text-xs text-base-content/50">
                      3-20 characters, lowercase letters, numbers, dashes or underscores
                    </p>
                  </div>

                  <div>
                    <label for="displayName" class="block text-sm font-medium text-base-content/70">
                      Display Name
                    </label>
                    <input
                      type="text"
                      name="displayName"
                      id="displayName"
                      required
                      class="mt-1 block w-full px-3 py-2 input input-bordered bg-base-200"
                      placeholder="Your Name"
                      maxlength="50"
                    />
                  </div>

                  <div>
                    <label for="email" class="block text-sm font-medium text-base-content/70">
                      Email
                    </label>
                    <input
                      type="email"
                      name="email"
                      id="email"
                      required
                      class="mt-1 block w-full px-3 py-2 input input-bordered bg-base-200"
                      placeholder="you@example.com"
                    />
                  </div>

                  <div>
                    <label for="password" class="block text-sm font-medium text-base-content/70">
                      Password
                    </label>
                    <input
                      type="password"
                      name="password"
                      id="password"
                      required
                      minlength="8"
                      class="mt-1 block w-full px-3 py-2 input input-bordered bg-base-200"
                      placeholder="At least 8 characters"
                    />
                  </div>
                </div>
              </div>

              <%= if @error do %>
                <div class="alert alert-error text-sm">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                  <span>{@error}</span>
                </div>
              <% end %>

              <button
                type="submit"
                disabled={@loading}
                class="w-full btn btn-primary"
              >
                <%= if @loading do %>
                  <span class="loading loading-spinner loading-sm"></span>
                  Creating account...
                <% else %>
                  Create account
                <% end %>
              </button>
            </.form>
          </div>

          <p class="text-center text-sm text-base-content/60">
            Already have an account?
            <a href="/signin" class="font-medium text-primary hover:underline">
              Sign in
            </a>
          </p>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def handle_event("submit", _params, socket) do
    # Form submission is handled by SignupForm hook
    {:noreply, assign(socket, :loading, true)}
  end

  @impl true
  def handle_event("signup_error", %{"error" => error}, socket) do
    socket =
      socket
      |> assign(:error, error)
      |> assign(:loading, false)

    {:noreply, socket}
  end
end
