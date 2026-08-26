defmodule UrielmWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use UrielmWeb, :html
  use LiveSvelte.Components

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash} current_user={@current_user} current_page="home">
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_user, :map, default: nil, doc: "the current user"
  attr :current_page, :string, default: "home", doc: "the current page identifier"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :socket, :any, default: nil, doc: "LiveView socket (for LiveSvelte components)"
  attr :unread_notification_count, :integer, default: 0
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 font-sans text-base-content antialiased">
      <div id="navbar-container" phx-update="ignore">
        <.Navbar
          socket={@socket}
          currentPage={@current_page || "home"}
          currentUser={serialize_user(@current_user)}
          unreadNotificationCount={@unread_notification_count}
        />
      </div>

      <main class="pt-16 pb-[calc(3.5rem+env(safe-area-inset-bottom))] lg:pb-0">
        {if assigns[:inner_content], do: @inner_content, else: render_slot(@inner_block)}
      </main>

      <.mobile_bottom_nav
        current_user={@current_user}
        current_page={@current_page}
        unread_notification_count={@unread_notification_count}
      />

      <.flash_group flash={@flash} />
    </div>
    """
  end

  attr :current_user, :any, default: nil
  attr :current_page, :string, default: "home"
  attr :unread_notification_count, :integer, default: 0

  def mobile_bottom_nav(assigns) do
    assigns = assign(assigns, :profile_path, profile_path(assigns.current_user))

    ~H"""
    <nav
      id="mobile-bottom-nav"
      aria-label="Mobile navigation"
      class="dock dock-sm z-40 border-base-300/70 bg-base-100/90 shadow-[0_-10px_30px_color-mix(in_oklab,var(--color-base-300)_18%,transparent)] backdrop-blur-xl transition-transform duration-200 lg:hidden"
    >
      <.mobile_nav_link
        id="mobile-nav-home"
        href="/"
        icon="home"
        label="Home"
        active={@current_page == "home"}
      />
      <.mobile_nav_link
        id="mobile-nav-videos"
        href="/videos"
        icon="play"
        label="Videos"
        active={@current_page == "videos"}
      />
      <.mobile_nav_link
        id="mobile-nav-forum"
        href="/forum"
        icon="topics"
        label="Forum"
        active={@current_page == "community"}
      />

      <%= if @current_user do %>
        <.mobile_nav_link
          id="mobile-nav-notifications"
          href="/notifications"
          icon="bell"
          label="Alerts"
          active={@current_page == "notifications"}
          badge_count={@unread_notification_count}
          badge_id="mobile-nav-notification-badge"
        />
        <.mobile_nav_link
          id="mobile-nav-profile"
          href={@profile_path}
          icon="user_circle"
          label="Profile"
          active={@current_page == "profile"}
        />
      <% else %>
        <.mobile_nav_link
          id="mobile-nav-sign-in"
          href="/signin"
          icon="user_circle"
          label="Sign in"
          active={false}
        />
      <% end %>
    </nav>
    """
  end

  attr :id, :string, required: true
  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :badge_count, :integer, default: 0
  attr :badge_id, :string, default: nil

  defp mobile_nav_link(assigns) do
    ~H"""
    <a
      id={@id}
      href={@href}
      data-phx-link="redirect"
      data-phx-link-state="push"
      aria-current={if(@active, do: "page", else: nil)}
      class={[
        "group min-w-0 rounded-xl text-base-content/55 transition duration-150 hover:bg-info/5 hover:text-base-content focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-info",
        @active && "dock-active bg-info/10 text-info"
      ]}
    >
      <span class="relative">
        <.um_icon name={@icon} class="size-5 transition-transform group-active:scale-90" />
        <span
          :if={@badge_count > 0}
          id={@badge_id}
          class="badge badge-info badge-xs absolute -right-3 -top-2 min-w-4.5 border-2 border-base-100 px-1 text-[0.55rem] font-black text-info-content"
          aria-label={"#{@badge_count} unread notifications"}
        >
          {if(@badge_count > 99, do: "99+", else: @badge_count)}
        </span>
      </span>
      <span class="dock-label truncate font-bold">{@label}</span>
    </a>
    """
  end

  @doc """
  Renders a minimal auth layout without navbar.

  Used for signup, signin, and other auth pages.

  ## Examples

      <Layouts.auth flash={@flash}>
        <h1>Sign Up</h1>
      </Layouts.auth>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def auth(assigns) do
    ~H"""
    <div id="auth-shell" class="min-h-screen bg-base-100 font-sans text-base-content antialiased">
      <header
        id="auth-header"
        class="absolute inset-x-0 top-0 z-20 mx-auto flex h-18 w-full max-w-7xl items-center justify-between px-5 sm:px-7 lg:px-8"
      >
        <.link
          navigate={~p"/"}
          class="rounded-xl px-2 py-2 text-lg font-black tracking-[-0.04em] text-base-content transition hover:bg-base-200/70 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary sm:text-xl"
        >
          UrielM<span class="text-base-content/40">.dev</span>
        </.link>
        <.theme_toggle />
      </header>

      <main>
        {render_slot(@inner_block)}
      </main>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.um_icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.um_icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="join border border-base-300 bg-base-200 rounded-full p-1">
      <button
        class="btn btn-ghost btn-xs btn-circle join-item [[data-theme=tokyo-day]_&]:bg-primary [[data-theme=tokyo-day]_&]:text-primary-content"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="tokyo-day"
        aria-label="Use Tokyo Day"
      >
        <.um_icon name="sun" variant="micro" class="size-4" />
      </button>

      <button
        class="btn btn-ghost btn-xs btn-circle join-item [[data-theme=tokyo-night]_&]:bg-primary [[data-theme=tokyo-night]_&]:text-primary-content"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="tokyo-night"
        aria-label="Use Tokyo Night"
      >
        <.um_icon name="moon" variant="micro" class="size-4" />
      </button>
    </div>
    """
  end

  defp serialize_user(nil), do: nil

  # If already serialized (check for avatarUrl in camelCase - only serialized maps have this)
  defp serialize_user(%{avatarUrl: _} = user), do: user
  defp serialize_user(%{"avatarUrl" => _} = user), do: user

  # If it's a User struct (has avatar_url with underscore), serialize it
  defp serialize_user(user) do
    %{
      id: to_string(user.id),
      name: user.name,
      email: user.email,
      username: user.username,
      avatarUrl: user.avatar_url,
      isAdmin: user.is_admin || false
    }
  end

  defp profile_path(%{username: username}) when is_binary(username) and username != "",
    do: "/u/#{username}"

  defp profile_path(_user), do: "/profile"
end
