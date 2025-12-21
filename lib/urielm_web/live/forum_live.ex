defmodule UrielmWeb.ForumLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum

  @impl true
  def mount(_params, _session, socket) do
    categories = Forum.list_categories_with_boards()

    {:ok,
     socket
     |> assign(:page_title, "Forum")
     |> assign(:all_categories, categories)
     |> assign(:categories, serialize_categories(categories))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout categories={@all_categories}>
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content mb-2">Categories</h1>
          <p class="text-base-content/60">Browse all discussion categories</p>
        </div>
        
    <!-- Categories List -->
        <%= for category <- @categories do %>
          <div class="mb-10">
            <!-- Category Title -->
            <div class="mb-4 px-1">
              <h2 class="text-lg font-semibold text-base-content">{category.name}</h2>
            </div>
            
    <!-- Boards Table -->
            <div class="border border-base-300 rounded-lg overflow-hidden bg-base-200/20">
              <%= for {board, index} <- Enum.with_index(category.boards) do %>
                <a
                  href={~p"/forum/b/#{board.slug}"}
                  class={[
                    "flex items-center justify-between px-5 py-4 hover:bg-base-200/50 transition-colors",
                    if(index > 0, do: "border-t border-base-300")
                  ]}
                >
                  <!-- Board Info -->
                  <div class="flex-1 min-w-0">
                    <h3 class="text-base font-semibold text-base-content hover:text-primary transition-colors">
                      {board.name}
                    </h3>
                    <p class="text-sm text-base-content/60 mt-1">
                      {board.description}
                    </p>
                  </div>
                  
    <!-- Stats -->
                  <div class="flex items-center gap-8 ml-4 text-right flex-shrink-0">
                    <div class="flex flex-col items-end">
                      <span class="text-sm font-semibold text-base-content">
                        {board.thread_count || 0}
                      </span>
                      <span class="text-xs text-base-content/50">
                        {if board.thread_count == 1, do: "Topic", else: "Topics"}
                      </span>
                    </div>
                  </div>
                </a>
              <% end %>
            </div>
          </div>
        <% end %>

        <%= if length(@categories) == 0 do %>
          <div class="text-center py-12 text-base-content/50">
            <p>No forum categories available yet.</p>
          </div>
        <% end %>
    </UrielmWeb.Components.ForumLayout.forum_layout>
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
      # Get thread count, handling unloaded association
      thread_count =
        case board.threads do
          %Ecto.Association.NotLoaded{} -> 0
          threads when is_list(threads) -> length(threads)
          _ -> 0
        end

      %{
        id: to_string(board.id),
        name: board.name,
        slug: board.slug,
        description: board.description,
        thread_count: thread_count
      }
    end)
  end
end
