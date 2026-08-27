defmodule UrielmWeb.SetHandleLive do
  use UrielmWeb, :live_view
  alias Urielm.Accounts

  @impl true
  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    pending_redirect = Map.get(session, "pending_redirect")

    # If user already has a username, redirect to pending page or home
    if user.username do
      return_to = pending_redirect || "/"
      {:ok, push_navigate(socket, to: return_to)}
    else
      suggested_handle = generate_suggested_handle(user.email)
      suggested_display_name = user.name || humanize_username(suggested_handle)

      # Check if suggested handle is available
      available =
        if String.match?(suggested_handle, ~r/^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$/) do
          case Accounts.get_user_by_username(suggested_handle) do
            nil -> true
            _user -> false
          end
        else
          nil
        end

      socket =
        socket
        |> assign(
          :form,
          to_form(%{"username" => suggested_handle, "display_name" => suggested_display_name})
        )
        |> assign(:checking, false)
        |> assign(:available, available)
        |> assign(:error, nil)
        |> assign(:pending_redirect, pending_redirect)
        |> assign(:page_title, "Choose your handle")

      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div id="auth-page" class="ui-auth-page">
        <div class="ui-auth-frame">
          <section id="set-handle-card" class="ui-auth-panel">
            <header class="text-center">
              <div class="mx-auto grid size-14 place-items-center rounded-2xl bg-primary/10 text-primary">
                <.um_icon name="hero-at-symbol" class="size-7" />
              </div>
              <p class="ui-eyebrow mt-5">Your public identity</p>
              <h1 class="mt-2 text-3xl font-black text-base-content">Choose your handle</h1>
              <p class="mt-2 text-sm leading-relaxed text-base-content/55">
                Your handle appears in your profile URL and mentions.
              </p>
            </header>

            <.form
              for={@form}
              id="set-handle-form"
              phx-submit="submit"
              phx-change="check_availability"
              class="mt-7 space-y-4"
            >
              <div>
                <.input
                  field={@form[:username]}
                  id="handle-username"
                  type="text"
                  label="Username"
                  phx-debounce="500"
                  required
                  autocomplete="username"
                  pattern="^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$"
                  help="Use 3–20 lowercase letters, numbers, dashes, or underscores."
                  placeholder="yourhandle"
                />

                <p
                  :if={@checking}
                  id="handle-availability"
                  role="status"
                  class="mt-1.5 flex items-center gap-2 text-sm text-base-content/55"
                >
                  <.um_icon name="hero-arrow-path" class="size-4 animate-spin" />
                  Checking availability
                </p>
                <p
                  :if={!@checking && @available == true}
                  id="handle-availability"
                  role="status"
                  class="mt-1.5 flex items-center gap-2 text-sm font-semibold text-success"
                >
                  <.um_icon name="hero-check-circle" class="size-4" /> This username is available
                </p>
                <p
                  :if={!@checking && @available == false && is_nil(@error)}
                  id="handle-availability"
                  role="status"
                  class="mt-1.5 flex items-center gap-2 text-sm font-semibold text-error"
                >
                  <.um_icon name="hero-x-circle" class="size-4" /> This username is already taken
                </p>
              </div>

              <.input
                field={@form[:display_name]}
                id="handle-display-name"
                type="text"
                label="Display name (optional)"
                autocomplete="name"
                maxlength="50"
                help="Used on posts; you can change it later."
                placeholder="Your name"
              />

              <%= if @error do %>
                <.form_feedback id="set-handle-error" kind={:error} title="Handle not available">
                  {@error}
                </.form_feedback>
              <% end %>

              <.button
                id="set-handle-submit"
                type="submit"
                disabled={@available != true}
                class="btn btn-primary h-12 w-full rounded-full font-bold"
              >
                Continue
              </.button>
            </.form>
          </section>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def handle_event("check_availability", %{"username" => username}, socket) do
    username = String.downcase(String.trim(username))

    socket = assign(socket, :checking, true)

    # Validate format first
    if String.match?(username, ~r/^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$/) do
      case Accounts.get_user_by_username(username) do
        nil ->
          {:noreply, assign(socket, checking: false, available: true, error: nil)}

        _user ->
          {:noreply, assign(socket, checking: false, available: false, error: nil)}
      end
    else
      {:noreply, assign(socket, checking: false, available: nil, error: "Invalid format")}
    end
  end

  @impl true
  def handle_event("submit", %{"username" => username, "display_name" => display_name}, socket) do
    user = socket.assigns.current_user
    username = String.downcase(String.trim(username))
    display_name = String.trim(display_name)

    # If display_name is blank, set it to username
    final_display_name = if display_name == "", do: username, else: display_name

    case Accounts.update_user(user, %{username: username, display_name: final_display_name}) do
      {:ok, _updated_user} ->
        # Get the pending redirect or default to home
        return_to = socket.assigns.pending_redirect || "/"
        {:noreply, push_navigate(socket, to: return_to)}

      {:error, changeset} ->
        error_message = format_error(changeset)
        {:noreply, assign(socket, error: error_message, available: false)}
    end
  end

  defp generate_suggested_handle(email) when is_binary(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_-]/, "")
    |> String.slice(0, 20)
  end

  defp generate_suggested_handle(_), do: ""

  defp humanize_username(username) when is_binary(username) do
    username
    |> String.replace(~r/[_-]/, " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp format_error(changeset) do
    UrielmWeb.LiveHelpers.format_changeset_errors(changeset)
  end
end
