defmodule UrielmWeb.AdminComponents do
  @moduledoc false

  use Phoenix.Component

  alias Urielm.Accounts.User

  attr :current, :string, required: true, values: ~w(users moderation trust-levels)

  @doc "Shared navigation for admin pages."
  def admin_nav(assigns) do
    ~H"""
    <nav
      id="admin-page-nav"
      class="tabs tabs-border mb-8 w-full flex-nowrap overflow-x-auto"
      aria-label="Admin pages"
    >
      <a
        id="admin-nav-users"
        href="/admin/users"
        aria-current={if(@current == "users", do: "page", else: nil)}
        class={[
          "tab min-h-11 shrink-0 px-4 font-semibold",
          @current == "users" && "tab-active text-primary"
        ]}
      >
        Users
      </a>
      <a
        id="admin-nav-moderation"
        href="/admin/moderation"
        aria-current={if(@current == "moderation", do: "page", else: nil)}
        class={[
          "tab min-h-11 shrink-0 px-4 font-semibold",
          @current == "moderation" && "tab-active text-primary"
        ]}
      >
        Moderation
      </a>
      <a
        id="admin-nav-trust-levels"
        href="/admin/trust-levels"
        aria-current={if(@current == "trust-levels", do: "page", else: nil)}
        class={[
          "tab min-h-11 shrink-0 px-4 font-semibold",
          @current == "trust-levels" && "tab-active text-primary"
        ]}
      >
        Trust levels
      </a>
    </nav>
    """
  end

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
