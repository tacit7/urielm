defmodule UrielmWeb.AdminComponents do
  @moduledoc false

  use Phoenix.Component

  alias Urielm.Accounts.User

  @doc "Badge showing a user's role (Admin / Mod / User)."
  def role_badge(assigns) do
    cond do
      assigns.user.is_admin ->
        ~H[<span class="badge badge-sm badge-error">Admin</span>]

      assigns.user.is_moderator ->
        ~H[<span class="badge badge-sm badge-warning">Mod</span>]

      true ->
        ~H[<span class="badge badge-sm badge-ghost">User</span>]
    end
  end

  @doc "Badge showing a user's moderation status (Suspended / Silenced / Active)."
  def status_badge(assigns) do
    cond do
      User.suspended?(assigns.user) ->
        ~H[<span class="badge badge-sm badge-error">Suspended</span>]

      User.silenced?(assigns.user) ->
        ~H[<span class="badge badge-sm badge-warning">Silenced</span>]

      true ->
        ~H[<span class="badge badge-sm badge-success">Active</span>]
    end
  end
end
