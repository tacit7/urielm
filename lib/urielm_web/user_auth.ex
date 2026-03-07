defmodule UrielmWeb.UserAuth do
  @moduledoc """
  Handles mounting current user into LiveView socket assigns.
  """

  import Phoenix.Component
  import Phoenix.LiveView
  alias Urielm.Accounts
  alias Urielm.Accounts.User

  def on_mount(:mount_current_user, _params, session, socket) do
    socket = load_current_user(session, socket)

    # Check if user is suspended and redirect to suspended page
    if socket.assigns.current_user && User.suspended?(socket.assigns.current_user) do
      {:halt, redirect_to_suspended(socket, socket.assigns.current_user)}
    else
      {:cont, socket}
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = load_current_user(session, socket)

    cond do
      socket.assigns.current_user && User.suspended?(socket.assigns.current_user) ->
        {:halt, redirect_to_suspended(socket, socket.assigns.current_user)}

      socket.assigns.current_user ->
        {:cont, socket}

      true ->
        # Redirect to signup - the return path will be preserved via query param or referer
        {:halt, redirect(socket, to: "/signup")}
    end
  end

  def on_mount(:ensure_admin, _params, session, socket) do
    socket = load_current_user(session, socket)

    cond do
      socket.assigns.current_user && User.suspended?(socket.assigns.current_user) ->
        {:halt, redirect_to_suspended(socket, socket.assigns.current_user)}

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

  defp redirect_to_suspended(socket, user) do
    socket
    |> put_flash(:suspension_reason, user.suspended_reason)
    |> put_flash(:suspension_until, user.suspended_until)
    |> redirect(to: "/suspended")
  end
end
