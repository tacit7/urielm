defmodule UrielmWeb.Components.ForumLayout do
  @moduledoc false

  use UrielmWeb, :html
  use LiveSvelte.Components

  import UrielmWeb.Layouts, only: [flash_group: 1]

  attr :flash, :map, default: %{}, doc: "the map of flash messages"
  attr :current_user, :any, default: nil, doc: "the current user"
  attr :categories, :list, default: [], doc: "list of forum categories with boards"
  attr :current_path, :string, default: "/forum", doc: "current request path for active state"
  attr :current_board, :string, default: nil, doc: "current board slug for active state"

  attr :new_topic_path, :string,
    default: nil,
    doc: "path for creating a topic in the current board"

  attr :unread_notification_count, :integer, default: 0
  slot :inner_block, required: true

  def forum_layout(assigns) do
    ~H"""
    <div class="drawer min-h-screen bg-base-100 lg:drawer-open">
      <input id="forum-drawer" type="checkbox" class="drawer-toggle" />

      <%!-- Main content --%>
      <div class="drawer-content flex min-h-screen flex-col bg-base-100">
        <div id="forum-navbar-container" phx-update="ignore">
          <.Navbar
            currentPage="community"
            currentUser={serialize_user(@current_user)}
            unreadNotificationCount={@unread_notification_count}
            showNavLinks={false}
            newTopicPath={if(@current_user, do: @new_topic_path, else: nil)}
            drawerId="forum-drawer"
          />
        </div>

        <%!-- Page content --%>
        <main class="flex-1 overflow-y-auto pt-14 pb-[calc(3.5rem+env(safe-area-inset-bottom))] lg:pb-0">
          <div id="forum-page-shell" class="ui-page-shell max-w-5xl py-7 lg:py-12">
            {render_slot(@inner_block)}
          </div>
        </main>

        <UrielmWeb.Layouts.mobile_bottom_nav
          current_user={@current_user}
          current_page="community"
          unread_notification_count={@unread_notification_count}
        />
      </div>

      <%!-- Sidebar --%>
      <aside class="drawer-side z-40 pt-14">
        <label
          for="forum-drawer"
          class="drawer-overlay"
          aria-label="Close sidebar"
          role="button"
          tabindex="-1"
        ></label>
        <nav
          id="forum-sidebar-nav"
          aria-label="Community navigation"
          class="w-56 min-h-[calc(100vh-3.5rem)] overflow-y-auto border-r border-base-300/60 bg-base-200/80"
        >
          <div class="p-3 lg:sticky lg:top-0">
            <%!-- Main navigation --%>
            <div class="space-y-0.5" aria-label="Forum views">
              <.nav_link
                href="/forum"
                icon="topics"
                label="Latest"
                active={@current_path in ["/forum", "/forum/latest"]}
              />
              <.nav_link
                href="/forum/categories"
                icon="hero-squares-2x2"
                label="Categories"
                active={@current_path == "/forum/categories"}
              />
              <.nav_link
                href="/forum/tags"
                icon="hero-tag"
                label="Tags"
                active={String.starts_with?(@current_path, "/forum/tags")}
              />
              <.nav_link
                href="/saved"
                icon="bookmark"
                label="Saved"
                active={@current_path == "/saved"}
              />
              <.nav_link
                href="/notifications"
                icon="bell"
                label="Notifications"
                active={@current_path == "/notifications"}
                badge_count={@unread_notification_count}
              />
              <.nav_link
                href="/forum/search"
                icon="search"
                label="Search"
                active={@current_path == "/forum/search"}
              />
              <%= unless @current_user do %>
                <.nav_link href="/auth/signin" icon="user_circle" label="Sign in" active={false} />
              <% end %>
            </div>

            <%!-- Boards --%>
            <div
              id="forum-sidebar-boards"
              class="mt-3 space-y-0.5 border-t border-base-300/60 pt-3"
              aria-label="Forum boards"
            >
              <div class="space-y-0.5">
                <.board_link
                  :for={board <- sidebar_boards(@categories)}
                  board={board}
                  active={@current_board == board.slug}
                />
              </div>
            </div>
          </div>
        </nav>
      </aside>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  defp serialize_user(nil), do: nil

  defp serialize_user(%{avatarUrl: _} = user), do: user
  defp serialize_user(%{"avatarUrl" => _} = user), do: user

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

  defp sidebar_boards(categories) do
    categories
    |> Enum.flat_map(&(&1.boards || []))
    |> Enum.with_index()
    |> Enum.sort_by(fn {board, index} -> {sidebar_board_rank(board.slug), index} end)
    |> Enum.map(fn {board, _index} -> board end)
  end

  defp sidebar_board_rank("start-here"), do: 0
  defp sidebar_board_rank("announcements"), do: 1
  defp sidebar_board_rank(_slug), do: 2

  attr :board, :map, required: true
  attr :active, :boolean, default: false

  def board_link(assigns) do
    assigns = assign(assigns, :badge_class, UrielmWeb.ForumColors.badge_class(assigns.board.slug))

    ~H"""
    <label for="forum-drawer" class="cursor-pointer lg:cursor-default">
      <a
        href={~p"/forum/b/#{@board.slug}"}
        class={[
          "flex min-h-8 items-center gap-2 rounded-md px-2.5 py-1.5 text-sm transition duration-150 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
          if(@active,
            do: "bg-secondary/10 text-secondary font-semibold",
            else: "text-base-content/60 hover:text-base-content hover:bg-base-300/60"
          )
        ]}
      >
        <span class={"badge badge-xs #{@badge_class}"}></span>
        <span class="truncate">{@board.name}</span>
      </a>
    </label>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :badge_count, :integer, default: 0

  def nav_link(assigns) do
    ~H"""
    <label for="forum-drawer" class="cursor-pointer lg:cursor-default">
      <a
        href={@href}
        class={[
          "flex min-h-8 items-center gap-2 rounded-md px-2.5 py-1.5 text-sm transition duration-150 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
          if(@active,
            do: "bg-secondary/10 text-secondary font-semibold",
            else: "text-base-content/65 hover:text-base-content hover:bg-base-300/60"
          )
        ]}
      >
        <.um_icon name={@icon} class="size-3.5" />
        <span>{@label}</span>
        <span
          :if={@badge_count > 0}
          id="forum-notification-badge"
          class="badge badge-info badge-xs ml-auto min-w-5 border-0 bg-info/15 px-1 font-bold text-info"
          aria-label={"#{@badge_count} unread notifications"}
        >
          {if(@badge_count > 99, do: "99+", else: @badge_count)}
        </span>
      </a>
    </label>
    """
  end

  attr :active_view, :string, required: true, values: ~w(latest categories tags)
  attr :count_label, :string, default: nil

  def discovery_header(assigns) do
    ~H"""
    <section id="community-discovery-header" class="mb-5 px-1">
      <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <h1 class="text-2xl font-bold leading-tight text-base-content sm:text-3xl">
            Community
          </h1>
          <p class="mt-1 max-w-2xl text-sm text-base-content/55">
            Ask questions, share builds, and follow practical AI discussions.
          </p>
        </div>

        <span
          :if={@count_label}
          class="hidden text-xs font-medium tabular-nums text-base-content/35 lg:block"
        >
          {@count_label}
        </span>
      </div>

      <.link
        id="forum-search-link"
        navigate={~p"/forum/search"}
        class="mt-4 flex min-h-10 max-w-2xl items-center gap-2 rounded-xl border border-base-300/70 bg-base-200/40 px-3 text-sm text-base-content/45 transition duration-150 hover:border-secondary/40 hover:bg-base-200/70 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
      >
        <.um_icon name="search" class="size-4 text-secondary" />
        <span class="flex-1">Search discussions, questions, and projects</span>
        <span class="hidden rounded-md border border-base-300 px-1.5 py-0.5 font-mono text-xs text-base-content/35 sm:inline">
          Explore
        </span>
      </.link>

      <nav
        id="forum-view-tabs"
        aria-label="Community views"
        class="tabs tabs-border mt-5 flex items-center overflow-x-auto border-b border-base-300/50"
      >
        <.view_link href={~p"/forum"} label="Latest" active={@active_view == "latest"} />
        <.view_link
          href={~p"/forum/categories"}
          label="Categories"
          active={@active_view == "categories"}
        />
        <.view_link href={~p"/forum/tags"} label="Tags" active={@active_view == "tags"} />
        <span
          :if={@count_label}
          class="ml-auto shrink-0 text-xs font-medium tabular-nums text-base-content/35 lg:hidden"
        >
          {@count_label}
        </span>
      </nav>
    </section>
    """
  end

  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp view_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      aria-current={if(@active, do: "page", else: nil)}
      class={[
        "tab h-9 shrink-0 px-3 text-sm font-semibold focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
        @active && "tab-active"
      ]}
    >
      {@label}
    </.link>
    """
  end
end
