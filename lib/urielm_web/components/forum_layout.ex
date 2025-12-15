defmodule UrielmWeb.Components.ForumLayout do
  use Phoenix.Component

  def forum_layout(assigns) do
    ~H"""
    <div class="flex h-screen bg-base-100">
      <!-- Left Sidebar -->
      <div class="w-56 border-r border-base-300 bg-base-200 overflow-y-auto">
        <div class="p-4">
          <!-- Logo/Home -->
          <a href="/" class="flex items-center gap-2 mb-6 p-2 rounded hover:bg-base-300">
            <div class="w-8 h-8 bg-primary rounded flex items-center justify-center text-primary-content font-bold">
              U
            </div>
            <span class="font-semibold text-base-content">Urielm</span>
          </a>
          
    <!-- Main Navigation -->
          <nav class="space-y-1 mb-8">
            <.nav_link href="/forum" icon="🏠" label="Home" />
            <.nav_link href="/forum" icon="💬" label="Topics" />
            <.nav_link href="/saved" icon="🔖" label="Saved" />
            <.nav_link href="/notifications" icon="🔔" label="Notifications" />
          </nav>
          
    <!-- Categories -->
          <div class="mb-6">
            <h3 class="text-xs font-bold text-base-content/60 uppercase tracking-wider px-2 mb-3">
              Categories
            </h3>
            <div class="space-y-1">
              <%= for category <- @categories do %>
                <.category_link category={category} />
              <% end %>
            </div>
          </div>
          
    <!-- More Section -->
          <nav class="space-y-1 pt-6 border-t border-base-300">
            <.nav_link href="#" icon="👥" label="Users" />
            <.nav_link href="#" icon="🏅" label="Badges" />
            <.nav_link href="#" icon="📋" label="About" />
            <.nav_link href="#" icon="⋯" label="More" />
          </nav>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="flex-1 overflow-y-auto">
        <div class="max-w-5xl mx-auto px-6 py-8">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  def nav_link(assigns) do
    ~H"""
    <a
      href={@href}
      class="flex items-center gap-3 px-3 py-2 rounded text-sm text-base-content/70 hover:text-base-content hover:bg-base-300 transition-colors"
    >
      <span class="text-lg">{@icon}</span>
      <span>{@label}</span>
    </a>
    """
  end

  def category_link(assigns) do
    ~H"""
    <a
      href="#"
      class="flex items-center gap-2 px-3 py-2 rounded text-sm text-base-content/60 hover:text-base-content hover:bg-base-300 transition-colors"
    >
      <div
        class="w-3 h-3 rounded-full"
        style={"background-color: var(--color-#{String.downcase(@category.slug)})"}
      >
      </div>
      <span>{@category.name}</span>
    </a>
    """
  end
end
