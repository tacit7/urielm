defmodule UrielmWeb.UserAuth do
  @moduledoc """
  Handles mounting current user into LiveView socket assigns.
  """

  import Phoenix.LiveView
  import Phoenix.Component
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
end
