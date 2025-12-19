defmodule UrielmWeb.UserAuth do
  @moduledoc """
  Handles mounting current user into LiveView socket assigns.
  """

  import Phoenix.Component
  import Phoenix.LiveView
  alias Urielm.Accounts

  def on_mount(:mount_current_user, _params, session, socket) do
    socket =
      case session do
        %{"user_id" => user_id} ->
          assign_new(socket, :current_user, fn -> Accounts.get_user(user_id) end)

        %{} ->
          assign_new(socket, :current_user, fn -> nil end)
      end

    {:cont, socket}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket =
      case session do
        %{"user_id" => user_id} ->
          assign_new(socket, :current_user, fn -> Accounts.get_user(user_id) end)

        %{} ->
          assign_new(socket, :current_user, fn -> nil end)
      end

    if socket.assigns.current_user do
      {:cont, socket}
    else
      # Redirect to signup - the return path will be preserved via query param or referer
      {:halt, redirect(socket, to: "/signup")}
    end
  end
end
