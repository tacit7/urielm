defmodule UrielmWeb.ReferencesLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Content

  @page_size 20

  @impl true
  def mount(params, _session, socket) do
    categories =
      Content.list_categories()
      |> Enum.reject(&(&1 in ["instagram", "prompts", "youtube"]))

    # Get category from URL params if present
    initial_filter = Map.get(params, "category", "all")
    opts = build_search_opts(initial_filter, 0)
    prompts = Content.search_prompts("", opts)

    socket =
      socket
      |> assign(:search_query, "")
      |> assign(:current_filter, initial_filter)
      |> assign(:categories, categories)
      |> assign(:prompts, serialize_prompts(prompts))
      |> assign(:page, 1)
      |> assign(:has_more, length(prompts) == @page_size)

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    %{current_filter: filter} = socket.assigns
    opts = build_search_opts(filter, 0)

    prompts = Content.search_prompts(query, opts)

    socket =
      socket
      |> assign(:search_query, query)
      |> assign(:prompts, serialize_prompts(prompts))
      |> assign(:page, 1)
      |> assign(:has_more, length(prompts) == @page_size)

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_changed", %{"category" => category}, socket) do
    %{search_query: query} = socket.assigns
    opts = build_search_opts(category, 0)

    prompts = Content.search_prompts(query, opts)

    socket =
      socket
      |> assign(:current_filter, category)
      |> assign(:prompts, serialize_prompts(prompts))
      |> assign(:page, 1)
      |> assign(:has_more, length(prompts) == @page_size)

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{
      current_filter: filter,
      search_query: query,
      page: page,
      prompts: current_prompts
    } = socket.assigns

    offset = page * @page_size
    opts = build_search_opts(filter, offset)

    new_prompts = Content.search_prompts(query, opts)

    socket =
      socket
      |> assign(:prompts, current_prompts ++ serialize_prompts(new_prompts))
      |> assign(:page, page + 1)
      |> assign(:has_more, length(new_prompts) == @page_size)

    {:noreply, socket}
  end

  defp build_search_opts(category, offset) do
    opts = %{limit: @page_size, offset: offset}

    if category == "all" do
      opts
    else
      Map.put(opts, :category, category)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content">
      <.Navbar currentPage="references" socket={@socket} />

      <div class="pt-16">
        <.SubNav activeFilter={@current_filter} categories={@categories} socket={@socket} />

        <div class="container mx-auto px-4 py-8">
          <div class="mb-8">
            <h1 class="text-4xl font-bold mb-2 text-base-content">Prompts</h1>
            <p class="text-base-content/60">
              Curated collection of AI prompts and templates
            </p>
          </div>

          <div class="mb-6">
            <form phx-change="search" phx-submit="search" class="w-full">
              <.input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Search prompts, e.g. &quot;tiktok hooks&quot;, &quot;email subject line&quot;"
                class="input input-bordered w-full"
                phx-debounce="300"
              />
            </form>
          </div>

          <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <%= if @prompts == [] do %>
              <div class="col-span-full text-center py-12 text-base-content/50">
                <%= if @search_query != "" do %>
                  No prompts found for "{@search_query}". Try different keywords or browse by category.
                <% else %>
                  No prompts found. Add some to get started!
                <% end %>
              </div>
            <% else %>
              <%= for prompt <- @prompts do %>
                <div class="card bg-base-200 border border-base-300 hover:bg-base-300 transition-colors">
                  <div class="card-body p-4 gap-3">
                    <div class="flex items-start justify-between gap-2">
                      <h2 class="card-title text-base-content text-lg">
                        {prompt.title}
                      </h2>
                      <span class="badge badge-primary capitalize font-medium">
                        {prompt.category}
                      </span>
                    </div>

                    <%= if prompt.description do %>
                      <p class="text-sm text-base-content/60 line-clamp-2">
                        {prompt.description}
                      </p>
                    <% end %>

                    <%= if prompt.tags && length(prompt.tags) > 0 do %>
                      <div class="flex flex-wrap gap-1">
                        <%= for tag <- prompt.tags do %>
                          <span class="badge badge-ghost text-xs">
                            {tag}
                          </span>
                        <% end %>
                      </div>
                    <% end %>

                    <div class="card-actions justify-start pt-1">
                      <a
                        href={prompt.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="inline-flex items-center gap-1.5 btn btn-primary btn-sm"
                      >
                        View Prompt
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                          />
                        </svg>
                      </a>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>

          <%= if @has_more do %>
            <div
              id="infinite-scroll-marker"
              phx-hook="InfiniteScroll"
              class="h-20 flex items-center justify-center"
            >
              <div class="text-base-content/40 text-sm">Loading more...</div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp serialize_prompts(prompts) do
    Enum.map(prompts, fn prompt ->
      %{
        id: prompt.id,
        title: prompt.title,
        url: prompt.url,
        description: prompt.description,
        category: prompt.category,
        tags: prompt.tags || []
      }
    end)
  end
end
