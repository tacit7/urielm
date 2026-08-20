defmodule UrielmWeb.Components.ForumLayout do
  @moduledoc false

  use UrielmWeb, :html

  import UrielmWeb.Layouts, only: [flash_group: 1]

  attr :flash, :map, default: %{}, doc: "the map of flash messages"
  attr :current_user, :any, default: nil, doc: "the current user"
  attr :categories, :list, default: [], doc: "list of forum categories with boards"
  attr :current_path, :string, default: "/forum", doc: "current request path for active state"
  attr :current_board, :string, default: nil, doc: "current board slug for active state"
  slot :inner_block, required: true

  def forum_layout(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open bg-base-100">
      <input id="forum-drawer" type="checkbox" class="drawer-toggle" />
      
    <!-- Main Content -->
      <div class="drawer-content flex flex-col min-h-screen bg-base-100">
        <!-- Mobile navbar with hamburger -->
        <header
          id="forum-mobile-header"
          class="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-base-300/60 bg-base-100/90 px-4 backdrop-blur-xl lg:hidden"
        >
          <label
            for="forum-drawer"
            class="btn btn-ghost btn-sm btn-square rounded-xl"
            aria-label="Open sidebar"
            role="button"
            tabindex="0"
          >
            <.um_icon name="bars_3" class="w-5 h-5" />
          </label>
          <.link navigate={~p"/forum"} class="font-bold tracking-tight text-base-content">
            Community
          </.link>
          <.link
            navigate={~p"/forum/search"}
            class="btn btn-ghost btn-sm btn-square ml-auto rounded-xl"
            aria-label="Search the community"
          >
            <.um_icon name="search" class="size-5" />
          </.link>
        </header>
        
    <!-- Page content -->
        <main class="flex-1 overflow-y-auto">
          <div class="max-w-5xl mx-auto px-4 sm:px-6 py-7 lg:py-12">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
      
    <!-- Sidebar -->
      <aside class="drawer-side z-40">
        <label
          for="forum-drawer"
          class="drawer-overlay"
          aria-label="Close sidebar"
          role="button"
          tabindex="-1"
        >
        </label>
        <nav
          id="forum-sidebar-nav"
          aria-label="Community navigation"
          class="w-64 min-h-screen border-r border-base-300/60 bg-base-200/80"
        >
          <div class="p-4 lg:sticky lg:top-0">
            <!-- Logo/Home -->
            <.link
              navigate={~p"/"}
              class="group mb-7 flex items-center gap-3 rounded-xl p-2 transition-colors hover:bg-base-300/60"
            >
              <div class="flex size-9 items-center justify-center rounded-xl bg-secondary text-secondary-content font-black shadow-sm transition-transform group-hover:-translate-y-0.5">
                U
              </div>
              <span class="font-bold tracking-tight text-base-content">Urielm</span>
            </.link>
            
    <!-- Main Navigation -->
            <div class="space-y-1 mb-8" aria-label="Forum views">
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
              />
            </div>
            
    <!-- Categories -->
            <div class="mb-6">
              <h3 class="text-[0.65rem] font-bold text-base-content/45 uppercase tracking-[0.16em] px-3 mb-3">
                Explore
              </h3>
              <div class="space-y-1">
                <%= for category <- @categories do %>
                  <.category_group category={category} current_board={@current_board} />
                <% end %>
              </div>
            </div>
            
    <!-- More Section -->
            <div class="space-y-1 pt-5 border-t border-base-300/60">
              <.nav_link
                href="/forum/search"
                icon="search"
                label="Search"
                active={@current_path == "/forum/search"}
              />
              <%= if @current_user do %>
                <.nav_link
                  href={"/u/#{@current_user.username}"}
                  icon="user_circle"
                  label={@current_user.username}
                  active={false}
                />
              <% else %>
                <.nav_link href="/auth/signin" icon="user_circle" label="Sign in" active={false} />
              <% end %>
            </div>
          </div>
        </nav>
      </aside>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  def nav_link(assigns) do
    ~H"""
    <label for="forum-drawer" class="cursor-pointer lg:cursor-default">
      <a
        href={@href}
        class={[
          "flex min-h-10 items-center gap-3 rounded-xl px-3 py-2 text-sm transition duration-150 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
          if(@active,
            do: "bg-secondary/10 text-secondary font-semibold",
            else: "text-base-content/65 hover:text-base-content hover:bg-base-300/60"
          )
        ]}
      >
        <.um_icon name={@icon} class="w-4 h-4" />
        <span>{@label}</span>
      </a>
    </label>
    """
  end

  attr :category, :map, required: true
  attr :current_board, :string, default: nil

  def category_group(assigns) do
    ~H"""
    <div class="mb-2">
      <div class="px-3 py-1 text-[0.65rem] font-semibold text-base-content/40 uppercase tracking-wide">
        {@category.name}
      </div>
      <%= for board <- @category.boards || [] do %>
        <.board_link board={board} active={@current_board == board.slug} />
      <% end %>
    </div>
    """
  end

  attr :board, :map, required: true
  attr :active, :boolean, default: false

  def board_link(assigns) do
    assigns = assign(assigns, :badge_class, UrielmWeb.ForumColors.badge_class(assigns.board.slug))

    ~H"""
    <label for="forum-drawer" class="cursor-pointer lg:cursor-default">
      <a
        href={~p"/forum/b/#{@board.slug}"}
        class={[
          "flex min-h-9 items-center gap-2 rounded-xl px-3 py-2 text-sm transition duration-150 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
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

  attr :active_view, :string, required: true, values: ~w(latest categories)
  attr :count_label, :string, default: nil

  def discovery_header(assigns) do
    ~H"""
    <section id="community-discovery-header" class="mb-8 lg:mb-10">
      <p class="mb-3 text-xs font-bold uppercase tracking-[0.18em] text-accent">
        Learn · build · share
      </p>
      <h1 class="text-4xl font-black leading-none tracking-[-0.045em] text-base-content sm:text-5xl">
        Find your next idea.
      </h1>
      <p class="mt-4 max-w-2xl text-sm leading-7 text-base-content/60 sm:text-base">
        Ask a thoughtful question, share what you are building, or learn alongside people turning
        AI ideas into useful work.
      </p>

      <.link
        id="forum-search-link"
        navigate={~p"/forum/search"}
        class="group mt-6 flex min-h-13 max-w-2xl items-center gap-3 rounded-2xl border border-base-300/80 bg-base-200/55 px-4 text-sm text-base-content/45 transition duration-150 hover:border-secondary/45 hover:bg-base-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
      >
        <.um_icon name="search" class="size-5 text-secondary" />
        <span class="flex-1">Search discussions, questions, and projects</span>
        <span class="hidden rounded-md border border-base-300 px-2 py-0.5 font-mono text-[0.65rem] text-base-content/35 sm:inline">
          Explore
        </span>
      </.link>

      <nav
        id="forum-view-tabs"
        aria-label="Community views"
        class="mt-8 flex items-center gap-1 overflow-x-auto border-b border-base-300/60 pb-3"
      >
        <.view_link href={~p"/forum"} label="Latest" active={@active_view == "latest"} />
        <.view_link
          href={~p"/forum/categories"}
          label="Categories"
          active={@active_view == "categories"}
        />
        <span :if={@count_label} class="ml-auto shrink-0 text-xs text-base-content/35">
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
        "shrink-0 rounded-xl px-3 py-2 text-sm font-semibold transition duration-150 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
        if(@active,
          do: "bg-secondary/10 text-secondary",
          else: "text-base-content/45 hover:bg-base-200 hover:text-base-content"
        )
      ]}
    >
      {@label}
    </.link>
    """
  end
end
