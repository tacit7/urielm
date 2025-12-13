defmodule UrielmWeb.ForumLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias Urielm.Repo

  @impl true
  def mount(_params, _session, socket) do
    categories =
      Forum.list_categories()
      |> Repo.preload(:boards)

    {:ok,
     socket
     |> assign(:page_title, "Forum")
     |> assign(:categories, serialize_categories(categories))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <div class="container mx-auto px-4 py-12">
        <div class="mb-12">
          <h1 class="text-4xl font-bold mb-2 text-base-content">Forum</h1>
          <p class="text-base-content/60">Community discussions and support</p>
        </div>

        <%= for category <- @categories do %>
          <div class="mb-8">
            <h2 class="text-2xl font-bold text-base-content mb-4">
              {category.name}
            </h2>

            <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              <%= for board <- category.boards do %>
                <a
                  href={~p"/forum/b/#{board.slug}"}
                  class="card bg-base-200 border border-base-300 hover:shadow-lg transition-shadow"
                >
                  <div class="card-body">
                    <h3 class="card-title text-base-content text-lg">
                      {board.name}
                    </h3>
                    <p class="text-sm text-base-content/60">
                      {board.description}
                    </p>
                    <div class="flex gap-4 text-xs text-base-content/50 pt-4 border-t border-base-300">
                      <span>Threads: {board.thread_count || 0}</span>
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
      thread_count = length(board.threads || [])

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
