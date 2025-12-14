defmodule UrielmWeb.ReferencesLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Content

  @page_size 20

  @impl true
  def mount(params, _session, socket) do
    categories = [
      "Analyze Text",
      "Coaching",
      "Content Creation",
      "Creative Arts",
      "Cybersecurity",
      "Entrepreneurs",
      "Gaming",
      "Job Search",
      "Lawyers",
      "Meetings",
      "Product Managers",
      "Prompt Management",
      "Psychology",
      "Real Estate",
      "Software Engineers",
      "Students & School",
      "Visualizations"
    ]

    # Get category from URL params if present
    initial_filter = Map.get(params, "category", "all")
    opts = build_search_opts(initial_filter, 0)
    prompts = Content.search_prompts("", opts)

    {:ok,
     socket
     |> assign(:page_title, "Romanov Prompts")
     |> assign(:search_query, "")
     |> assign(:current_filter, initial_filter)
     |> assign(:categories, categories)
     |> assign(:page, 1)
     |> assign(:has_more, length(prompts) == @page_size)
     |> assign(:selected_prompt, nil)
     |> stream(:prompts, serialize_prompts(prompts), reset: true)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    %{current_filter: filter} = socket.assigns
    opts = build_search_opts(filter, 0)

    prompts = Content.search_prompts(query, opts)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> assign(:has_more, length(prompts) == @page_size)
     |> stream(:prompts, serialize_prompts(prompts), reset: true)}
  end

  @impl true
  def handle_event("filter_changed", %{"category" => category}, socket) do
    %{search_query: query} = socket.assigns
    opts = build_search_opts(category, 0)

    prompts = Content.search_prompts(query, opts)

    {:noreply,
     socket
     |> assign(:current_filter, category)
     |> assign(:page, 1)
     |> assign(:has_more, length(prompts) == @page_size)
     |> stream(:prompts, serialize_prompts(prompts), reset: true)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{current_filter: filter, search_query: query, page: page} = socket.assigns

    offset = page * @page_size
    opts = build_search_opts(filter, offset)

    new_prompts = Content.search_prompts(query, opts)

    {:noreply,
     socket
     |> assign(:page, page + 1)
     |> assign(:has_more, length(new_prompts) == @page_size)
     |> stream(:prompts, serialize_prompts(new_prompts))}
  end

  @impl true
  def handle_event("open_prompt_modal", %{"id" => id}, socket) do
    prompt =
      id
      |> String.to_integer()
      |> Content.get_prompt!()
      |> Urielm.Repo.preload(:tag_records)

    tag_names = Enum.map(prompt.tag_records, & &1.name)

    serialized = %{
      id: prompt.id,
      title: prompt.title,
      url: prompt.url,
      prompt: prompt.prompt,
      category: prompt.category,
      tags: tag_names,
      likes_count: prompt.likes_count,
      saves_count: prompt.saves_count,
      user_liked:
        socket.assigns.current_user &&
          Content.user_liked_prompt?(socket.assigns.current_user.id, prompt.id),
      user_saved:
        socket.assigns.current_user &&
          Content.user_saved_prompt?(socket.assigns.current_user.id, prompt.id)
    }

    {:noreply, assign(socket, :selected_prompt, serialized)}
  end

  @impl true
  def handle_event("close_prompt_modal", _params, socket) do
    {:noreply, assign(socket, :selected_prompt, nil)}
  end

  @impl true
  def handle_event("toggle_like", %{"id" => id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to like prompts")}

      user ->
        prompt_id = String.to_integer(id)

        case Content.toggle_like(user.id, prompt_id) do
          {:ok, _prompt} ->
            # Refresh the prompt data in modal if it's open
            updated_socket =
              if socket.assigns.selected_prompt && socket.assigns.selected_prompt.id == prompt_id do
                prompt =
                  prompt_id
                  |> Content.get_prompt!()
                  |> Urielm.Repo.preload(:tag_records)

                tag_names = Enum.map(prompt.tag_records, & &1.name)

                serialized = %{
                  id: prompt.id,
                  title: prompt.title,
                  url: prompt.url,
                  prompt: prompt.prompt,
                  category: prompt.category,
                  tags: tag_names,
                  likes_count: prompt.likes_count,
                  user_liked: Content.user_liked_prompt?(user.id, prompt.id)
                }

                assign(socket, :selected_prompt, serialized)
              else
                socket
              end

            {:noreply, updated_socket}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to like prompt")}
        end
    end
  end

  @impl true
  def handle_event("toggle_save", %{"id" => id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to save prompts")}

      user ->
        prompt_id = String.to_integer(id)

        case Content.toggle_save(user.id, prompt_id) do
          {:ok, _prompt} ->
            # Refresh the prompt data in modal if it's open
            updated_socket =
              if socket.assigns.selected_prompt && socket.assigns.selected_prompt.id == prompt_id do
                prompt =
                  prompt_id
                  |> Content.get_prompt!()
                  |> Urielm.Repo.preload(:tag_records)

                tag_names = Enum.map(prompt.tag_records, & &1.name)

                serialized = %{
                  id: prompt.id,
                  title: prompt.title,
                  url: prompt.url,
                  prompt: prompt.prompt,
                  category: prompt.category,
                  tags: tag_names,
                  saves_count: prompt.saves_count,
                  user_saved: Content.user_saved_prompt?(user.id, prompt.id)
                }

                assign(socket, :selected_prompt, serialized)
              else
                socket
              end

            {:noreply, updated_socket}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to save prompt")}
        end
    end
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
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="references"
      socket={@socket}
    >
      <div class="min-h-screen bg-base-100 text-base-content">
        <div class="pt-16">
          <.SubNav activeFilter={@current_filter} categories={@categories} socket={@socket} />

          <div class="container mx-auto px-4 py-8">
            <div class="mb-8">
              <h1 class="text-4xl font-bold mb-2 text-base-content">Romanov Prompts</h1>
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

            <div id="prompts" phx-update="stream" class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              <div class="hidden only:block col-span-full text-center py-12 text-base-content/50">
                No prompts found.
              </div>
              <div
                :for={{id, prompt} <- @streams.prompts}
                id={id}
                class="card bg-base-200 border border-base-300 hover:bg-base-300 transition-colors cursor-pointer"
                phx-click="open_prompt_modal"
                phx-value-id={prompt.id}
              >
                <div class="card-body p-4 gap-3">
                  <h2 class="card-title text-base-content text-lg">
                    {prompt.title}
                  </h2>

                  <%= if prompt.tags && prompt.tags != [] do %>
                    <div class="flex flex-wrap gap-1">
                      <%= for tag <- prompt.tags do %>
                        <span class="badge badge-sm badge-secondary">{tag}</span>
                      <% end %>
                    </div>
                  <% end %>

                  <p :if={prompt.prompt} class="text-sm text-base-content/60 line-clamp-3">
                    {prompt.prompt}
                  </p>
                </div>
              </div>
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

      <%= if @selected_prompt do %>
        <dialog class="modal modal-open">
          <div class="modal-box max-w-3xl bg-base-200">
            <form method="dialog">
              <button
                phx-click="close_prompt_modal"
                class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
              >
                ✕
              </button>
            </form>

            <h3 class="font-bold text-2xl text-base-content mb-4">{@selected_prompt.title}</h3>

            <%= if @selected_prompt.tags && @selected_prompt.tags != [] do %>
              <div class="mb-4 flex flex-wrap gap-2">
                <%= for tag <- @selected_prompt.tags do %>
                  <span class="badge badge-secondary">{tag}</span>
                <% end %>
              </div>
            <% end %>

            <%= if @selected_prompt.prompt do %>
              <div class="bg-base-300 rounded-lg p-4 mb-4">
                <.svelte
                  name="MarkdownRenderer"
                  props={%{content: @selected_prompt.prompt}}
                  socket={@socket}
                />
              </div>
              <div class="flex gap-4 items-center">
                <.svelte
                  name="PromptActions"
                  props={
                    %{
                      likesCount: Map.get(@selected_prompt, :likes_count, 0),
                      savesCount: Map.get(@selected_prompt, :saves_count, 0),
                      userLiked: Map.get(@selected_prompt, :user_liked, false),
                      userSaved: Map.get(@selected_prompt, :user_saved, false),
                      promptId: to_string(@selected_prompt.id),
                      detailUrl: ~p"/prompts/#{@selected_prompt.id}",
                      live: @socket
                    }
                  }
                  socket={@socket}
                >
                  <button
                    id="copy-prompt-btn"
                    phx-hook="CopyToClipboard"
                    data-text={@selected_prompt.prompt}
                    class="flex items-center gap-2 text-base-content/70 hover:text-primary transition-colors"
                    title="Copy to clipboard"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2">
                      </path>
                      <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
                    </svg>
                  </button>
                </.svelte>
              </div>
            <% end %>
          </div>
          <form method="dialog" class="modal-backdrop">
            <button phx-click="close_prompt_modal">close</button>
          </form>
        </dialog>
      <% end %>
    </Layouts.app>
    """
  end

  defp serialize_prompts(prompts) do
    prompts = Urielm.Repo.preload(prompts, :tag_records)

    Enum.map(prompts, fn prompt ->
      tag_names = Enum.map(prompt.tag_records, & &1.name)

      %{
        id: prompt.id,
        title: prompt.title,
        url: prompt.url,
        prompt: prompt.prompt,
        category: prompt.category,
        tags: tag_names
      }
    end)
  end
end
