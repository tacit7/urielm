defmodule UrielmWeb.ForumLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers
  alias UrielmWeb.ForumColors

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
      current_user={@current_user}
      unread_notification_count={@unread_notification_count}
      current_path="/forum/categories"
    >
      <UrielmWeb.Components.ForumLayout.discovery_header
        active_view="categories"
        count_label={"#{Enum.sum(Enum.map(@categories, fn c -> length(c.boards) end))} boards"}
      />

      <.empty_state
        :if={@categories == []}
        id="forum-categories-empty-state"
        title="No categories yet"
        description="Community spaces will appear here as soon as they are available."
        icon="hero-chat-bubble-left-right"
        compact
      >
        <:action>
          <.link navigate={~p"/forum"} class="btn btn-ghost btn-sm rounded-full text-primary">
            View latest discussions <.um_icon name="hero-arrow-right" class="size-4" />
          </.link>
        </:action>
      </.empty_state>
      <%!-- Categories --%>
      <div :if={@categories != []} id="forum-categories" class="space-y-8">
        <.category_section :for={category <- @categories} category={category} />
      </div>
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  attr :category, :map, required: true

  defp category_section(assigns) do
    ~H"""
    <section id={"forum-category-#{@category.id}"}>
      <%!-- Category label --%>
      <div class="mb-3 flex items-center justify-between gap-3 px-1">
        <h2 class="ui-eyebrow text-base-content/55">
          {@category.name}
        </h2>
        <span class="text-xs text-base-content/30">{length(@category.boards)} boards</span>
      </div>

      <%!-- Board table --%>
      <div id={"forum-category-surface-#{@category.id}"} class="ui-card ui-card-compact h-auto">
        <%!-- Column headers --%>
        <div class="hidden border-b border-base-300/40 bg-base-200/60 px-4 py-2 md:grid md:grid-cols-[1fr_220px_72px]">
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider">Board</span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider">Latest</span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider text-right">
            Topics
          </span>
        </div>

        <%!-- Board rows --%>
        <div class="divide-y divide-base-300/40">
          <.board_row :for={board <- @category.boards} board={board} />
        </div>
      </div>
    </section>
    """
  end

  attr :board, :map, required: true

  defp board_row(assigns) do
    hex = ForumColors.icon_color(assigns.board.slug)

    assigns =
      assign(
        assigns,
        :icon_style,
        "background: linear-gradient(135deg, rgba(255,255,255,0.12) 0%, transparent 55%), #{hex};"
      )

    ~H"""
    <a
      id={"forum-board-#{@board.id}"}
      href={~p"/forum/b/#{@board.slug}"}
      class="group grid grid-cols-1 items-center gap-x-4 gap-y-2 px-4 py-4 transition-colors duration-150 hover:bg-base-200/55 focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-primary md:grid-cols-[1fr_220px_72px]"
    >
      <%!-- Board info --%>
      <div class="flex min-w-0 items-center gap-3">
        <div
          class="w-9 h-9 rounded-lg flex-shrink-0 flex items-center justify-center text-white text-sm font-bold select-none"
          style={@icon_style}
        >
          {String.first(@board.name)}
        </div>
        <div class="min-w-0">
          <h3 class="font-semibold text-sm text-base-content group-hover:text-secondary transition-colors duration-150 truncate">
            {@board.name}
          </h3>
          <p
            :if={@board.description}
            class="text-xs text-base-content/45 line-clamp-1 leading-relaxed"
          >
            {@board.description}
          </p>
        </div>
      </div>

      <%!-- Latest thread --%>
      <div class="min-w-0 pl-12 md:block md:pl-0">
        <%= if @board.latest_thread_title do %>
          <span class="block text-xs text-base-content/65 group-hover:text-secondary truncate leading-snug transition-colors">
            {@board.latest_thread_title}
          </span>
          <span class="font-mono text-xs text-base-content/30">
            {LiveHelpers.format_short(@board.last_activity_at)}
          </span>
        <% else %>
          <span class="font-mono text-xs text-base-content/20">—</span>
        <% end %>
      </div>

      <%!-- Topic count --%>
      <div class="flex flex-col items-end justify-center">
        <span class="font-mono text-sm text-base-content/60 tabular-nums">
          {@board.thread_count}
        </span>
      </div>
    </a>
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
