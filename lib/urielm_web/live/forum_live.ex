defmodule UrielmWeb.ForumLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum

  @board_colors %{
    "start-here" => "bg-primary",
    "announcements" => "bg-secondary",
    "qa" => "bg-accent",
    "prompting" => "bg-info",
    "building" => "bg-success",
    "models-tools" => "bg-warning",
    "show-and-tell" => "bg-neutral",
    "feedback" => "bg-error",
    "off-topic" => "bg-base-content/20",
    "ai-development" => "bg-primary"
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
      current_path="/forum"
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
    assigns =
      assign(assigns, :color, Map.get(@board_colors, assigns.board.slug, "bg-base-content/15"))

    ~H"""
    <div class="group grid grid-cols-1 md:grid-cols-[1fr_220px_72px] items-center px-4 py-4 hover:bg-base-200/40 transition-colors duration-150 gap-y-2 gap-x-4">
      <!-- Board info -->
      <a href={~p"/forum/b/#{@board.slug}"} class="flex items-center gap-3 min-w-0">
        <div class={[
          "w-9 h-9 rounded-lg flex-shrink-0 flex items-center justify-center text-white text-sm font-bold select-none",
          @color
        ]}>
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
            {relative_time(@board.last_activity_at)}
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

  defp relative_time(nil), do: "—"

  defp relative_time(%NaiveDateTime{} = naive),
    do: relative_time(DateTime.from_naive!(naive, "Etc/UTC"))

  defp relative_time(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m"
      diff < 86400 -> "#{div(diff, 3600)}h"
      diff < 604_800 -> "#{div(diff, 86400)}d"
      diff < 2_592_000 -> "#{div(diff, 604_800)}w"
      true -> "#{div(diff, 2_592_000)}mo"
    end
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
