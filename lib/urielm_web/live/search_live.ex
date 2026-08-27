defmodule UrielmWeb.SearchLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    all_categories = Forum.list_categories_with_boards()
    default_filters = default_search_filters()

    category_options =
      [{"All categories", ""} | Enum.map(all_categories, &{&1.name, to_string(&1.id)})]

    {:ok,
     socket
     |> assign(:page_title, "Search Forum")
     |> assign(:query, "")
     |> assign(:search_filters, default_filters)
     |> assign(:search_form, to_form(default_filters))
     |> assign(:search_active, false)
     |> assign(:page, 1)
     |> assign(:meta, nil)
     |> assign(:has_more, false)
     |> assign(:all_categories, all_categories)
     |> assign(:category_options, category_options)
     |> stream(:results, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search_filters = search_filters(params)
    query = search_filters["query"]
    search_active = search_active?(search_filters)

    page =
      case params["page"] do
        nil ->
          1

        p when is_binary(p) ->
          case Integer.parse(p) do
            {n, ""} when n > 0 -> n
            _ -> 1
          end

        p when is_integer(p) ->
          p
      end

    socket =
      if search_active do
        search_opts = search_opts(search_filters)

        {:ok, {results, meta}} =
          Forum.paginate_search_threads(
            query,
            %{page: page, page_size: LiveHelpers.page_size()},
            search_opts
          )

        socket
        |> assign(:query, query)
        |> assign(:search_filters, search_filters)
        |> assign(:search_form, to_form(search_filters))
        |> assign(:search_active, true)
        |> assign(:page, page)
        |> assign(:meta, meta)
        |> stream(:results, serialize_threads(results, socket.assigns.current_user), reset: true)
      else
        socket
        |> assign(:query, query)
        |> assign(:search_filters, search_filters)
        |> assign(:search_form, to_form(search_filters))
        |> assign(:search_active, false)
        |> assign(:page, page)
        |> assign(:meta, nil)
        |> stream(:results, [], reset: true)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", params, socket) do
    search_filters = search_filters(params)
    {:noreply, push_patch(socket, to: search_path(search_filters, 1))}
  end

  @impl true
  def handle_event(
        "vote",
        %{"target_type" => target_type, "target_id" => target_id, "value" => value},
        socket
      ) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to vote")}

      user ->
        target_id_binary = target_id

        value_int =
          case Integer.parse(value) do
            {n, ""} -> n
            _ -> nil
          end

        case value_int do
          nil ->
            {:noreply, put_flash(socket, :error, "Invalid vote value")}

          value_int ->
            case Forum.cast_vote(user.id, target_type, target_id_binary, value_int) do
              {:ok, _vote} ->
                {:noreply,
                 LiveHelpers.update_thread_in_stream(socket, :results, target_id_binary, user)}

              {:error, _} ->
                {:noreply, put_flash(socket, :error, "Failed to vote")}
            end
        end
    end
  end

  @impl true
  def handle_event("save_thread", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.handle_save_thread(thread_id, :results, socket)
  end

  @impl true
  def handle_event("subscribe", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.handle_subscribe_thread(thread_id, :results, socket)
  end

  @impl true
  def handle_event("unsubscribe", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.handle_unsubscribe_thread(thread_id, :results, socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories}
      flash={@flash}
      current_user={@current_user}
      unread_notification_count={@unread_notification_count}
      current_path="/forum/search"
    >
      <div id="forum-search-page" class="mx-auto w-full max-w-3xl">
        <header id="forum-search-header" class="ui-page-header ui-page-heading">
          <h1 class="ui-section-title">Search discussions</h1>
          <p class="ui-section-copy">
            Find useful conversations by topic, phrase, or tag.
          </p>
        </header>

        <section id="forum-search-surface" class="ui-card h-auto p-4 sm:p-5">
          <.form
            for={@search_form}
            id="forum-search-form"
            phx-submit="search"
            class="space-y-4"
          >
            <div class="grid gap-3 lg:grid-cols-[minmax(0,1.6fr)_auto]">
              <.input
                field={@search_form[:query]}
                id="forum-search-query"
                type="search"
                label="Search discussions"
                placeholder="Search threads by title, content, or tags..."
                class="input input-bordered min-h-11 w-full"
              />

              <div class="flex items-end">
                <.button
                  id="forum-search-submit"
                  type="submit"
                  loading_label="Searching…"
                  class="btn btn-primary min-h-11 w-full lg:w-auto"
                >
                  <.icon name="hero-magnifying-glass" class="size-5" /> Search
                </.button>
              </div>
            </div>

            <div
              id="forum-search-advanced-row"
              class="grid gap-3 rounded-2xl border border-base-300/70 bg-base-200/40 p-3 sm:grid-cols-2 xl:grid-cols-4"
            >
              <.input
                field={@search_form[:author]}
                id="forum-search-author"
                type="search"
                label="Author"
                placeholder="Search by username"
                class="input input-bordered min-h-11 w-full"
              />
              <.input
                field={@search_form[:category_id]}
                id="forum-search-category"
                type="select"
                label="Category"
                options={@category_options}
                class="select select-bordered min-h-11 w-full"
              />
              <.input
                field={@search_form[:from_date]}
                id="forum-search-from-date"
                type="date"
                label="From"
                class="input input-bordered min-h-11 w-full"
              />
              <.input
                field={@search_form[:to_date]}
                id="forum-search-to-date"
                type="date"
                label="To"
                class="input input-bordered min-h-11 w-full"
              />
            </div>
          </.form>
        </section>

        <%= if not @search_active do %>
          <.empty_state
            id="search-start-state"
            title="Search the community"
            description="Enter a topic, phrase, or tag to find relevant discussions."
            icon="hero-magnifying-glass"
            compact
            class="mt-6"
          />
        <% else %>
          <div id="results" phx-update="stream" class="mt-6 space-y-4">
            <.empty_state
              id="search-empty-state"
              title="No matching discussions"
              description="Try a broader phrase, check the spelling, or search for another tag."
              icon="hero-magnifying-glass"
              compact
              class="hidden only:grid"
            />
            <div :for={{id, result} <- @streams.results} id={id}>
              <.svelte
                name="ThreadCard"
                props={result}
                socket={@socket}
                ssr={false}
              />
            </div>
          </div>

          <div class="mt-8 flex items-center justify-center gap-2">
            <%= if @meta do %>
              <.pagination meta={@meta} path={fn n -> search_path(@search_filters, n) end} />
            <% end %>
          </div>
        <% end %>
      </div>
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  defp serialize_threads(threads, current_user),
    do: LiveHelpers.serialize_thread_list(threads, current_user)

  defp default_search_filters do
    %{
      "query" => "",
      "author" => "",
      "category_id" => "",
      "from_date" => "",
      "to_date" => ""
    }
  end

  defp search_filters(params) do
    default_search_filters()
    |> Map.merge(Map.take(params, ["author", "category_id", "from_date", "to_date"]))
    |> Map.put("query", Map.get(params, "query", Map.get(params, "q", "")))
  end

  defp search_opts(search_filters) do
    search_filters
    |> Map.take(["author", "category_id", "from_date", "to_date"])
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> Enum.map(fn {key, value} ->
      case key do
        "category_id" -> {:category_id, value}
        "from_date" -> {:from_date, value}
        "to_date" -> {:to_date, value}
        "author" -> {:author, value}
      end
    end)
  end

  defp search_active?(search_filters) do
    search_filters["query"] != "" or search_opts(search_filters) != []
  end

  defp search_path(search_filters, page) do
    search_filters
    |> Map.put("q", search_filters["query"])
    |> Map.delete("query")
    |> Map.put("page", page)
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> Enum.into(%{})
    |> then(fn params ->
      "/forum/search?#{URI.encode_query(params)}"
    end)
  end

  # serialization and vote lookups now live in LiveHelpers
end
