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

      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4">
        <div class="max-w-md w-full space-y-6">
          <div class="text-center">
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
              Choose your handle
            </h1>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
              Used for your profile URL and mentions
            </p>
          </div>

          <.form for={@form} phx-submit="submit" phx-change="check_availability" class="space-y-4">
            <div>
              <label for="username" class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Username
              </label>
              <div class="mt-1 relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <span class="text-gray-500 dark:text-gray-400 sm:text-sm">@</span>
                </div>
                <input
                  type="text"
                  name="username"
                  id="username"
                  value={@form[:username].value}
                  phx-debounce="500"
                  required
                  pattern="^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$"
                  class="block w-full pl-7 pr-10 py-2 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="yourhandle"
                />
                <%= if @checking do %>
                  <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                    <svg class="animate-spin h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24">
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
                  </div>
                <% end %>
                <%= if @available == true do %>
                  <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                <% end %>
                <%= if @available == false do %>
                  <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                <% end %>
              </div>
              <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                3-20 characters, lowercase, letters/numbers/dashes/underscores
              </p>
              <%= if @available == false do %>
                <p class="mt-1 text-sm text-red-600 dark:text-red-400">
                  This username is already taken
                </p>
              <% end %>
              <%= if @error do %>
                <p class="mt-1 text-sm text-red-600 dark:text-red-400">
                  {@error}
                </p>
              <% end %>
            </div>

            <div>
              <label
                for="display_name"
                class="block text-sm font-medium text-gray-700 dark:text-gray-300"
              >
                Display name <span class="text-gray-500 dark:text-gray-400">(optional)</span>
              </label>
              <input
                type="text"
                name="display_name"
                id="display_name"
                value={@form[:display_name].value}
                maxlength="50"
                class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Your Name"
              />
              <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                Used on posts; you can change it later
              </p>
            </div>

            <button
              type="submit"
              disabled={@available != true}
              class="w-full flex items-center justify-center px-4 py-3 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Continue
            </button>
          </.form>
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

  defp humanize_username(_), do: ""

  defp format_error(changeset) do
    UrielmWeb.LiveHelpers.format_changeset_errors(changeset)
  end
end
