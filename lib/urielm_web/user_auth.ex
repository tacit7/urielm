defmodule UrielmWeb.UserAuth do
  @moduledoc """
  Handles mounting current user into LiveView socket assigns.
  """

  import Phoenix.Component
  import Phoenix.LiveView
  alias Urielm.Accounts

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, load_current_user(session, socket)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = load_current_user(session, socket)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      # Redirect to signup - the return path will be preserved via query param or referer
      {:halt, redirect(socket, to: "/signup")}
    end
  end

  def on_mount(:ensure_admin, _params, session, socket) do
    socket = load_current_user(session, socket)

    cond do
      socket.assigns.current_user && socket.assigns.current_user.is_admin ->
        {:cont, socket}

      socket.assigns.current_user ->
        # Logged in but not admin - redirect home
        {:halt, redirect(socket, to: "/")}

      true ->
        # Not logged in - redirect to signup
        {:halt, redirect(socket, to: "/signup")}
    end
  end

  defp load_current_user(session, socket) do
    case session do
      %{"user_id" => user_id} ->
        assign_new(socket, :current_user, fn -> Accounts.get_user(user_id) end)

      %{} ->
        assign_new(socket, :current_user, fn -> nil end)
    end
  end
end
