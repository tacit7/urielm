defmodule UrielmWeb.PromptsLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Content
  alias Urielm.Engagement
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, session, socket) do
    # Handle both direct mount and child mount via live_render
    child_params =
      case params do
        :not_mounted_at_router -> session["child_params"] || %{}
        params -> params
      end

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
    initial_filter = Map.get(child_params, "category", "all")
    opts = build_search_opts(initial_filter, 0)
    prompts = Content.search_prompts("", opts)

    {:ok,
     socket
     |> assign(:page_title, "Prompts")
     |> assign(:search_query, "")
     |> assign(:current_filter, initial_filter)
     |> assign(:categories, categories)
     |> assign(:page, 1)
     |> assign(:has_more, length(prompts) == LiveHelpers.page_size())
     |> assign(:selected_prompt, nil)
     |> assign(:drawer_upvotes, 0)
     |> assign(:drawer_downvotes, 0)
     |> assign(:drawer_user_vote, nil)
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
     |> assign(:has_more, length(prompts) == LiveHelpers.page_size())
     |> stream(:prompts, serialize_prompts(prompts), reset: true)}
  end

  @impl true
  def handle_event("filter_changed", %{"category" => category}, socket) do
    handle_filter_change(category, socket)
  end

  @impl true
  def handle_event("tab_change", %{"key" => key}, socket) do
    handle_filter_change(key, socket)
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{current_filter: filter, search_query: query, page: page} = socket.assigns

    offset = page * LiveHelpers.page_size()
    opts = build_search_opts(filter, offset)

    new_prompts = Content.search_prompts(query, opts)

    {:noreply,
     socket
     |> assign(:page, page + 1)
     |> assign(:has_more, length(new_prompts) == LiveHelpers.page_size())
     |> stream(:prompts, serialize_prompts(new_prompts))}
  end

  @impl true
  def handle_event("open_prompt_modal", %{"id" => id}, socket) do
    %{current_user: user} = socket.assigns

    prompt_id =
      case Integer.parse(id) do
        {n, ""} -> n
        _ -> nil
      end

    case prompt_id do
      nil ->
        {:noreply, put_flash(socket, :error, "Invalid prompt")}

      prompt_id ->
        case Content.get_prompt(prompt_id) do
          nil ->
            {:noreply, put_flash(socket, :error, "Prompt not found")}

          prompt ->
            tag_names = Enum.map(prompt.tag_records, & &1.name)

            target_id = to_string(prompt.id)
            {upvotes, downvotes, _score} = Engagement.get_vote_counts("prompt", target_id)
            user_vote = if user, do: Engagement.get_vote(user.id, "prompt", target_id), else: nil

            serialized = %{
              id: prompt.id,
              title: prompt.title,
              url: prompt.url,
              prompt: prompt.prompt,
              category: prompt.category,
              tags: tag_names,
              saves_count: prompt.saves_count,
              user_saved: user && Content.user_saved_prompt?(user.id, prompt.id)
            }

            {:noreply,
             socket
             |> assign(:selected_prompt, serialized)
             |> assign(:drawer_upvotes, upvotes)
             |> assign(:drawer_downvotes, downvotes)
             |> assign(:drawer_user_vote, user_vote && user_vote.value)}
        end
    end
  end

  @impl true
  def handle_event("close_prompt_modal", _params, socket) do
    {:noreply, assign(socket, :selected_prompt, nil)}
  end

  @impl true
  def handle_event(
        "vote",
        %{"target_type" => "prompt", "target_id" => id, "value" => value},
        socket
      ) do
    LiveHelpers.with_auth(socket, "vote", fn socket, user ->
      case Integer.parse(value) do
        {n, ""} -> do_drawer_vote(user, id, n, socket)
        _ -> {:noreply, put_flash(socket, :error, "Invalid vote value")}
      end
    end)
  end

  @impl true
  def handle_event("toggle_save", %{"id" => id}, socket) do
    LiveHelpers.with_auth(socket, "save prompts", fn socket, user ->
      case Integer.parse(id) do
        {n, ""} -> do_toggle_save(n, user, socket)
        _ -> {:noreply, put_flash(socket, :error, "Invalid prompt")}
      end
    end)
  end

  defp do_drawer_vote(user, id, value_int, socket) do
    case Engagement.toggle_vote(user.id, "prompt", id, value_int) do
      {:ok, _} ->
        {upvotes, downvotes, _score} = Engagement.get_vote_counts("prompt", id)
        user_vote = Engagement.get_vote(user.id, "prompt", id)

        {:noreply,
         socket
         |> assign(:drawer_upvotes, upvotes)
         |> assign(:drawer_downvotes, downvotes)
         |> assign(:drawer_user_vote, user_vote && user_vote.value)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to vote")}
    end
  end

  defp do_toggle_save(prompt_id, user, socket) do
    case Content.toggle_save(user.id, prompt_id) do
      {:ok, _prompt} ->
        updated_socket =
          if socket.assigns.selected_prompt &&
               socket.assigns.selected_prompt.id == prompt_id do
            case Content.get_prompt(prompt_id) do
              nil -> socket
              prompt -> assign(socket, :selected_prompt, serialize_prompt(prompt, user))
            end
          else
            socket
          end

        {:noreply, updated_socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save prompt")}
    end
  end

  defp handle_filter_change(category, socket) do
    {:noreply, apply_filter(category, socket)}
  end

  defp apply_filter(category, socket) do
    %{search_query: query} = socket.assigns
    opts = build_search_opts(category, 0)
    prompts = Content.search_prompts(query, opts)

    socket
    |> assign(:current_filter, category)
    |> assign(:page, 1)
    |> assign(:has_more, length(prompts) == LiveHelpers.page_size())
    |> stream(:prompts, serialize_prompts(prompts), reset: true)
  end

  defp build_search_opts(category, offset) do
    opts = %{limit: LiveHelpers.page_size(), offset: offset}

    if category == "all" do
      opts
    else
      Map.put(opts, :category, category)
    end
  end

  defp quick_filter_items do
    [
      %{key: "all", label: "All"},
      %{key: "Software Engineers", label: "Developers"},
      %{key: "Content Creation", label: "Content"},
      %{key: "Students & School", label: "Students"},
      %{key: "Entrepreneurs", label: "Business"}
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["drawer drawer-end", @selected_prompt && "drawer-open"]}>
      <input
        id="prompt-drawer-toggle"
        type="checkbox"
        class="drawer-toggle"
        checked={@selected_prompt != nil}
      />

      <div class="drawer-content min-h-screen bg-base-100 text-base-content">
        <div class="mx-auto w-full max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
          <div id="prompts-page-header" class="mb-8 max-w-2xl">
            <p class="mb-3 text-xs font-bold uppercase tracking-[0.18em] text-primary">
              Prompt library
            </p>
            <h1 class="text-4xl font-black tracking-[-0.035em] text-base-content sm:text-5xl">
              Prompts that help you ship.
            </h1>
            <p class="mt-3 text-base leading-relaxed text-base-content/55 sm:text-lg">
              Curated, reusable templates for building, writing, learning, and getting better work from AI.
            </p>
          </div>

          <div
            id="prompt-toolbar"
            class="mb-5 grid gap-3 rounded-2xl border border-base-300/70 bg-base-200/40 p-3 md:grid-cols-[minmax(0,1fr)_18rem]"
          >
            <form
              id="prompt-search-form"
              phx-change="search"
              phx-submit="search"
              class="w-full"
            >
              <div class="relative">
                <.um_icon
                  name="search"
                  class="pointer-events-none absolute left-3 top-1/2 z-10 size-5 -translate-y-1/2 text-base-content/35"
                />
                <.input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder="Search prompts…"
                  aria-label="Search prompts"
                  class="input input-bordered w-full bg-base-100 pl-10"
                  phx-debounce="300"
                />
              </div>
            </form>

            <form id="prompt-category-filter" phx-change="filter_changed" class="w-full">
              <.input
                type="select"
                name="category"
                value={@current_filter}
                options={[{"All categories", "all"} | Enum.map(@categories, &{&1, &1})]}
                aria-label="Filter prompts by category"
                class="select select-bordered w-full bg-base-100"
              />
            </form>
          </div>

          <div id="prompt-quick-filters" class="mb-7 flex gap-2 overflow-x-auto pb-1">
            <button
              :for={item <- quick_filter_items()}
              type="button"
              phx-click="filter_changed"
              phx-value-category={item.key}
              class={[
                "btn btn-sm flex-shrink-0 rounded-full px-4 transition duration-200",
                if(@current_filter == item.key,
                  do: "btn-primary",
                  else:
                    "btn-ghost border border-base-300/70 bg-base-100 text-base-content/65 hover:border-primary/35 hover:text-base-content"
                )
              ]}
            >
              {item.label}
            </button>
          </div>

          <div id="prompts" phx-update="stream" class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <div
              id="empty-state"
              class="hidden only:block col-span-full rounded-2xl border border-dashed border-base-300 py-16 text-center text-base-content/50"
            >
              <.um_icon name="search" class="mx-auto mb-3 size-8 text-base-content/25" />
              <p class="font-semibold text-base-content/70">No prompts found</p>
              <p class="mt-1 text-sm">Try a broader search or another category.</p>
            </div>
            <div
              :for={{id, prompt} <- @streams.prompts}
              id={id}
              class="card group cursor-pointer border border-base-300/70 bg-base-100 transition duration-200 hover:-translate-y-0.5 hover:border-primary/35 hover:shadow-lg hover:shadow-base-300/10"
              phx-click="open_prompt_modal"
              phx-value-id={prompt.id}
            >
              <div class="card-body gap-3 p-5">
                <p class="text-[0.68rem] font-bold uppercase tracking-[0.14em] text-primary/80">
                  {prompt.category || "Prompt"}
                </p>
                <h2 class="card-title text-lg leading-snug text-base-content transition-colors group-hover:text-primary">
                  {prompt.title}
                </h2>

                <%= if prompt.tags && prompt.tags != [] do %>
                  <div class="flex flex-wrap gap-1">
                    <%= for tag <- prompt.tags do %>
                      <span class="badge badge-sm border-base-300 bg-base-200 text-base-content/60">
                        {tag}
                      </span>
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

      <div class="drawer-side z-50">
        <label
          for="prompt-drawer-toggle"
          aria-label="close sidebar"
          class="drawer-overlay"
          phx-click="close_prompt_modal"
        >
        </label>

        <div class="bg-base-200 min-h-full w-full max-w-2xl">
          <%= if @selected_prompt do %>
            <div class="sticky top-0 bg-base-200 border-b border-base-300 p-4 flex items-center justify-between z-10">
              <div class="flex-1 min-w-0 pr-4">
                <h3 class="font-bold text-xl text-base-content truncate">
                  {@selected_prompt.title}
                </h3>
                <.link
                  navigate={~p"/prompts/#{@selected_prompt.id}"}
                  class="text-sm link link-primary"
                >
                  View full page →
                </.link>
              </div>
              <button
                phx-click="close_prompt_modal"
                class="btn btn-sm btn-circle btn-ghost"
                aria-label="Close drawer"
              >
                <.um_icon name="close" class="w-5 h-5" />
              </button>
            </div>

            <div class="p-6">
              <%= if @selected_prompt.tags && @selected_prompt.tags != [] do %>
                <div class="mb-4 flex flex-wrap gap-2">
                  <%= for tag <- @selected_prompt.tags do %>
                    <span class="badge badge-secondary">{tag}</span>
                  <% end %>
                </div>
              <% end %>

              <%= if @selected_prompt.prompt do %>
                <div class="bg-base-300 rounded-lg p-4 mb-6">
                  <.svelte
                    name="MarkdownRenderer"
                    props={%{content: @selected_prompt.prompt}}
                    socket={@socket}
                    ssr={false}
                  />
                </div>

                <div class="flex gap-4 items-center border-t border-base-300 pt-4">
                  <.svelte
                    name="PromptActions"
                    props={
                      %{
                        upvotes: @drawer_upvotes,
                        downvotes: @drawer_downvotes,
                        savesCount: Map.get(@selected_prompt, :saves_count, 0),
                        userVote: @drawer_user_vote,
                        userSaved: Map.get(@selected_prompt, :user_saved, false),
                        promptId: to_string(@selected_prompt.id),
                        detailUrl: ~p"/prompts/#{@selected_prompt.id}"
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
                      <.um_icon name="hero-clipboard-document" class="w-5 h-5" />
                    </button>
                  </.svelte>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp serialize_prompt(prompt, user) do
    tag_names = Enum.map(prompt.tag_records, & &1.name)

    %{
      id: prompt.id,
      title: prompt.title,
      url: prompt.url,
      prompt: prompt.prompt,
      category: prompt.category,
      tags: tag_names,
      likes_count: prompt.likes_count,
      saves_count: prompt.saves_count,
      user_liked: user && Content.user_liked_prompt?(user.id, prompt.id),
      user_saved: user && Content.user_saved_prompt?(user.id, prompt.id)
    }
  end

  defp serialize_prompts(prompts) do
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
