defmodule UrielmWeb.ForumLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @board_colors %{
    "start-here"     => "#1B4F8A",
    "announcements"  => "#B03A2E",
    "qa"             => "#1A7A5E",
    "prompting"      => "#5B3A9E",
    "building"       => "#2D6A4F",
    "models-tools"   => "#8B4513",
    "show-and-tell"  => "#962D4A",
    "feedback"       => "#9A6B10",
    "off-topic"      => "#4A5568",
    "ai-development" => "#1A3A7A"
  }

  @impl true
  def mount(_params, _session, socket) do
    categories = Forum.list_categories_with_boards()

    {:ok,
     socket
     |> assign(:page_title, "Community")
     |> assign(:all_categories, categories)
     |> assign(:categories, serialize_categories(categories))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories}
      flash={@flash}
      current_path="/forum/categories"
    >
      <!-- Page header -->
      <div class="mb-8">
        <p class="font-mono text-xs tracking-widest uppercase text-base-content/40 mb-2">
          Community / Forum
        </p>
        <div class="flex items-end justify-between">
          <h1 class="text-4xl font-black tracking-tight text-base-content leading-none">
            Community
          </h1>
          <p class="font-mono text-xs text-base-content/40 pb-1">
            {Enum.sum(Enum.map(@categories, fn c -> length(c.boards) end))} boards
          </p>
        </div>
        <div class="mt-4 h-px bg-base-content/10" />
      </div>

      <!-- Empty state -->
      <div :if={@categories == []} class="flex flex-col items-center justify-center py-32">
        <p class="font-mono font-black text-8xl text-base-content/10 select-none mb-4">00</p>
        <p class="font-mono text-xs tracking-[0.3em] uppercase text-base-content/30">
          No categories yet
        </p>
      </div>

      <!-- Categories -->
      <div :if={@categories != []} class="space-y-8">
        <.category_section :for={category <- @categories} category={category} />
      </div>
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  attr :category, :map, required: true

  defp category_section(assigns) do
    ~H"""
    <section>
      <!-- Category label -->
      <div class="flex items-center gap-3 mb-3">
        <span class="font-mono text-xs tracking-widest uppercase text-base-content/40">
          {@category.name}
        </span>
        <div class="flex-1 h-px bg-base-content/8" />
      </div>

      <!-- Discourse-style board table -->
      <div class="rounded-xl border border-base-300/60 overflow-hidden">
        <!-- Column headers -->
        <div class="hidden md:grid md:grid-cols-[1fr_220px_72px] bg-base-200/60 px-4 py-2 border-b border-base-300/40">
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider">Board</span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider">Latest</span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider text-right">
            Topics
          </span>
        </div>

        <!-- Board rows -->
        <div class="divide-y divide-base-300/40">
          <.board_row :for={board <- @category.boards} board={board} />
        </div>
      </div>
    </section>
    """
  end

  attr :board, :map, required: true

  defp board_row(assigns) do
    hex = Map.get(@board_colors, assigns.board.slug, "#4A5568")

    assigns =
      assign(assigns, :icon_style, "background: linear-gradient(135deg, rgba(255,255,255,0.12) 0%, transparent 55%), #{hex};")

    ~H"""
    <div class="group grid grid-cols-1 md:grid-cols-[1fr_220px_72px] items-center px-4 py-4 hover:bg-base-200/40 transition-colors duration-150 gap-y-2 gap-x-4">
      <!-- Board info -->
      <a href={~p"/forum/b/#{@board.slug}"} class="flex items-center gap-3 min-w-0">
        <div
          class="w-9 h-9 rounded-lg flex-shrink-0 flex items-center justify-center text-white text-sm font-bold select-none"
          style={@icon_style}
        >
          {String.first(@board.name)}
        </div>
        <div class="min-w-0">
          <h3 class="font-semibold text-sm text-base-content group-hover:text-primary transition-colors duration-150 truncate">
            {@board.name}
          </h3>
          <p
            :if={@board.description}
            class="text-xs text-base-content/45 line-clamp-1 leading-relaxed"
          >
            {@board.description}
          </p>
        </div>
      </a>

      <!-- Latest thread -->
      <div class="md:block min-w-0 pl-12 md:pl-0">
        <%= if @board.latest_thread_title do %>
          <a
            href={~p"/forum/t/#{@board.latest_thread_id}"}
            class="block text-xs text-base-content/65 hover:text-primary truncate leading-snug transition-colors"
          >
            {@board.latest_thread_title}
          </a>
          <span class="font-mono text-xs text-base-content/30">
            {LiveHelpers.format_short(@board.last_activity_at)}
          </span>
        <% else %>
          <span class="font-mono text-xs text-base-content/20">—</span>
        <% end %>
      </div>

      <!-- Topic count -->
      <div class="hidden md:flex flex-col items-end justify-center">
        <span class="font-mono text-sm text-base-content/60 tabular-nums">
          {@board.thread_count}
        </span>
      </div>
    </div>
    """
  end

  defp serialize_categories(categories) do
    Enum.map(categories, fn category ->
      %{
        id: to_string(category.id),
        name: category.name,
        slug: category.slug,
        boards: serialize_boards(category.boards)
      }
    end)
  end

  defp serialize_boards(boards) do
    Enum.map(boards, fn board ->
      %{
        id: to_string(board.id),
        name: board.name,
        slug: board.slug,
        description: board.description,
        thread_count: board.thread_count || 0,
        post_count: board.post_count || 0,
        last_activity_at: board.last_activity_at,
        latest_thread_title: board.latest_thread_title,
        latest_thread_id: board.latest_thread_id
      }
    end)
  end
end
