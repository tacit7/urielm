defmodule UrielmWeb.SignupLive do
  use UrielmWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        :form,
        to_form(%{"email" => "", "password" => "", "username" => "", "displayName" => ""})
      )
      |> assign(:error, nil)
      |> assign(:loading, false)
      |> assign(:page_title, "Create account")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div
        id="auth-page"
        class="relative min-h-screen overflow-hidden bg-[radial-gradient(circle_at_18%_20%,color-mix(in_oklab,var(--color-secondary)_10%,transparent),transparent_34%),radial-gradient(circle_at_82%_80%,color-mix(in_oklab,var(--color-primary)_8%,transparent),transparent_32%)] px-5 pb-12 pt-24 sm:px-7 lg:px-8 lg:py-24"
      >
        <div class="mx-auto grid min-h-[calc(100vh-7rem)] w-full max-w-6xl items-center gap-14 lg:grid-cols-[minmax(0,1fr)_minmax(25rem,30rem)] lg:gap-20">
          <section id="auth-story" class="hidden max-w-xl lg:block">
            <p class="ui-eyebrow text-secondary">Build with clarity</p>
            <h1 class="mt-4 text-5xl font-black leading-[1.02] tracking-[-0.05em] text-base-content xl:text-6xl">
              Your next useful idea starts here.
            </h1>
            <p class="mt-6 max-w-lg text-lg leading-relaxed text-base-content/60">
              Join a practical space for learning, sharing prompts, and building thoughtful software with AI.
            </p>

            <div class="mt-9 grid gap-4 text-sm font-medium text-base-content/65">
              <p class="flex items-center gap-3">
                <span class="grid size-8 place-items-center rounded-xl bg-secondary/10 text-secondary">
                  <.um_icon name="hero-bookmark" class="size-4" />
                </span>
                Save and organize prompts worth reusing
              </p>
              <p class="flex items-center gap-3">
                <span class="grid size-8 place-items-center rounded-xl bg-secondary/10 text-secondary">
                  <.um_icon name="hero-academic-cap" class="size-4" />
                </span>
                Follow structured courses at your pace
              </p>
              <p class="flex items-center gap-3">
                <span class="grid size-8 place-items-center rounded-xl bg-secondary/10 text-secondary">
                  <.um_icon name="hero-user-group" class="size-4" />
                </span>
                Learn alongside curious builders
              </p>
            </div>
          </section>

          <section
            id="signup-card"
            class="mx-auto w-full max-w-md rounded-3xl border border-base-300/70 bg-base-200/65 p-6 shadow-2xl shadow-base-300/20 backdrop-blur-xl sm:p-8"
          >
            <header>
              <p class="ui-eyebrow text-secondary lg:hidden">Join the community</p>
              <h2 class="mt-2 text-3xl font-black tracking-[-0.035em] text-base-content lg:mt-0">
                Create your account
              </h2>
              <p class="mt-2 text-sm leading-relaxed text-base-content/55">
                A few details, then you’re ready to start building.
              </p>
            </header>

            <a
              id="google-signup-link"
              href="/auth/google"
              class="btn mt-7 h-12 w-full rounded-xl border-base-300 bg-base-100/55 font-semibold text-base-content shadow-sm transition hover:border-secondary/30 hover:bg-secondary/5"
            >
              <svg class="size-5" viewBox="0 0 24 24" aria-hidden="true">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              Continue with Google
            </a>

            <div class="my-6 flex items-center gap-3 text-[0.68rem] font-bold uppercase tracking-[0.14em] text-base-content/35">
              <span class="h-px flex-1 bg-base-300/70"></span>
              or use email <span class="h-px flex-1 bg-base-300/70"></span>
            </div>

            <.form
              for={@form}
              phx-submit="submit"
              id="signup-form"
              phx-hook="SignupForm"
              aria-busy={@loading}
              class="space-y-4"
            >
              <div phx-update="ignore" id="signup-form-fields" class="space-y-3">
                <div>
                  <.input
                    field={@form[:username]}
                    id="signup-username"
                    type="text"
                    label="Username"
                    required
                    autocomplete="username"
                    minlength="3"
                    maxlength="20"
                    pattern="[a-z0-9_-]+"
                    placeholder="lowercase-username"
                    class="input input-bordered h-12 w-full rounded-xl border-base-300 bg-base-100/45 px-4 text-base-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/15"
                  />
                  <p class="-mt-1 text-xs leading-relaxed text-base-content/40">
                    3–20 lowercase letters, numbers, dashes, or underscores.
                  </p>
                </div>
                <.input
                  field={@form[:displayName]}
                  id="signup-display-name"
                  type="text"
                  label="Display name"
                  required
                  autocomplete="name"
                  maxlength="50"
                  placeholder="Your name"
                  class="input input-bordered h-12 w-full rounded-xl border-base-300 bg-base-100/45 px-4 text-base-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/15"
                />
                <.input
                  field={@form[:email]}
                  id="signup-email"
                  type="email"
                  label="Email address"
                  required
                  autocomplete="email"
                  placeholder="you@example.com"
                  class="input input-bordered h-12 w-full rounded-xl border-base-300 bg-base-100/45 px-4 text-base-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/15"
                />
                <div>
                  <.input
                    field={@form[:password]}
                    id="signup-password"
                    type="password"
                    label="Password"
                    required
                    autocomplete="new-password"
                    minlength="8"
                    placeholder="At least 8 characters"
                    class="input input-bordered h-12 w-full rounded-xl border-base-300 bg-base-100/45 px-4 text-base-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/15"
                  />
                  <p class="-mt-1 text-xs leading-relaxed text-base-content/40">
                    Use at least 8 characters.
                  </p>
                </div>
              </div>

              <%= if @error do %>
                <div
                  id="signup-error"
                  role="alert"
                  class="alert border border-error/20 bg-error/10 text-sm text-error"
                >
                  <.um_icon name="hero-exclamation-circle" class="size-5 shrink-0" />
                  <span>{@error}</span>
                </div>
              <% end %>

              <button
                id="signup-submit"
                type="submit"
                disabled={@loading}
                class="btn btn-primary h-12 w-full rounded-full font-bold shadow-md shadow-primary/15 transition hover:-translate-y-0.5 disabled:translate-y-0"
              >
                <%= if @loading do %>
                  <span class="loading loading-spinner loading-sm"></span> Creating account…
                <% else %>
                  Create account
                <% end %>
              </button>
            </.form>

            <p class="mt-6 text-center text-sm text-base-content/55">
              Already have an account?
              <.link navigate={~p"/signin"} class="font-bold text-primary hover:underline">
                Sign in
              </.link>
            </p>
          </section>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def handle_event("submit", _params, socket) do
    {:noreply, socket |> assign(:loading, true) |> assign(:error, nil)}
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
