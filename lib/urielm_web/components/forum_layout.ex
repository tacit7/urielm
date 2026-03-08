defmodule UrielmWeb.Components.ForumLayout do
  use UrielmWeb, :html

  import UrielmWeb.Layouts, only: [flash_group: 1]

  attr :flash, :map, default: %{}, doc: "the map of flash messages"
  attr :current_user, :map, default: nil, doc: "the current user"
  attr :categories, :list, default: [], doc: "list of forum categories with boards"
  attr :current_path, :string, default: "/forum", doc: "current request path for active state"
  attr :current_board, :string, default: nil, doc: "current board slug for active state"
  slot :inner_block, required: true

  def forum_layout(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="forum-drawer" type="checkbox" class="drawer-toggle" />

      <!-- Main Content -->
      <div class="drawer-content flex flex-col min-h-screen bg-base-100">
        <!-- Mobile navbar with hamburger -->
        <header class="sticky top-0 z-30 flex items-center gap-2 px-4 py-3 bg-base-100 border-b border-base-300 lg:hidden">
          <label
            for="forum-drawer"
            class="btn btn-ghost btn-sm btn-square"
            aria-label="Open sidebar"
            role="button"
            tabindex="0"
          >
            <.um_icon name="bars_3" class="w-5 h-5" />
          </label>
          <a href="/forum" class="font-semibold text-base-content">Forum</a>
        </header>

        <!-- Page content -->
        <main class="flex-1 overflow-y-auto">
          <div class="max-w-5xl mx-auto px-4 sm:px-6 py-6 lg:py-8">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>

      <!-- Sidebar -->
      <aside class="drawer-side z-40">
        <label for="forum-drawer" class="drawer-overlay" aria-label="Close sidebar" role="button" tabindex="-1"></label>
        <nav class="w-64 min-h-screen bg-base-200 border-r border-base-300">
          <div class="p-4">
            <!-- Logo/Home -->
            <a href="/" class="flex items-center gap-2 mb-6 p-2 rounded hover:bg-base-300">
              <div class="w-8 h-8 bg-primary rounded flex items-center justify-center text-primary-content font-bold">
                U
              </div>
              <span class="font-semibold text-base-content">Urielm</span>
            </a>

            <!-- Main Navigation -->
            <div class="space-y-1 mb-8">
              <.nav_link href="/forum" icon="home" label="Home" active={@current_path == "/forum"} />
              <.nav_link href="/forum/latest" icon="topics" label="Latest" active={@current_path == "/forum/latest"} />
              <.nav_link href="/saved" icon="bookmark" label="Saved" active={@current_path == "/saved"} />
              <.nav_link href="/notifications" icon="bell" label="Notifications" active={@current_path == "/notifications"} />
            </div>

            <!-- Categories -->
            <div class="mb-6">
              <h3 class="text-xs font-bold text-base-content/60 uppercase tracking-wider px-2 mb-3">
                Categories
              </h3>
              <div class="space-y-1">
                <%= for category <- @categories do %>
                  <.category_group category={category} current_board={@current_board} />
                <% end %>
              </div>
            </div>

            <!-- More Section -->
            <div class="space-y-1 pt-6 border-t border-base-300">
              <.nav_link href="#" icon="users" label="Users" active={false} />
              <.nav_link href="#" icon="info" label="About" active={false} />
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
          "flex items-center gap-3 px-3 py-2 rounded text-sm transition-colors",
          if(@active,
            do: "bg-primary/10 text-primary font-medium",
            else: "text-base-content/70 hover:text-base-content hover:bg-base-300"
          )
        ]}
      >
        <.um_icon name={@icon} class="w-4 h-4" />
        <span>{@label}</span>
      </a>
    </label>
    """
  end

  @category_colors %{
    "start-here" => "badge-primary",
    "announcements" => "badge-secondary",
    "qa" => "badge-accent",
    "prompting" => "badge-info",
    "building" => "badge-success",
    "models-tools" => "badge-warning",
    "show-and-tell" => "badge-neutral",
    "feedback" => "badge-error",
    "off-topic" => "badge-ghost"
  }

  attr :category, :map, required: true
  attr :current_board, :string, default: nil

  def category_group(assigns) do
    assigns = assign(assigns, :colors, @category_colors)

    ~H"""
    <div class="mb-2">
      <div class="px-3 py-1 text-xs font-semibold text-base-content/50 uppercase tracking-wide">
        {@category.name}
      </div>
      <%= for board <- @category.boards || [] do %>
        <.board_link board={board} active={@current_board == board.slug} colors={@colors} />
      <% end %>
    </div>
    """
  end

  attr :board, :map, required: true
  attr :active, :boolean, default: false
  attr :colors, :map, required: true

  def board_link(assigns) do
    badge_class = Map.get(assigns.colors, assigns.board.slug, "badge-neutral")
    assigns = assign(assigns, :badge_class, badge_class)

    ~H"""
    <label for="forum-drawer" class="cursor-pointer lg:cursor-default">
      <a
        href={~p"/forum/b/#{@board.slug}"}
        class={[
          "flex items-center gap-2 px-3 py-2 rounded text-sm transition-colors",
          if(@active,
            do: "bg-primary/10 text-primary font-medium",
            else: "text-base-content/70 hover:text-base-content hover:bg-base-300"
          )
        ]}
      >
        <span class={"badge badge-xs #{@badge_class}"}></span>
        <span class="truncate">{@board.name}</span>
      </a>
    </label>
    """
  end
end
