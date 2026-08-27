defmodule UrielmWeb.SearchLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    all_categories = Forum.list_categories_with_boards()

    {:ok,
     socket
     |> assign(:page_title, "Search Forum")
     |> assign(:query, "")
     |> assign(:search_form, to_form(%{"query" => ""}))
     |> assign(:page, 1)
     |> assign(:meta, nil)
     |> assign(:has_more, false)
     |> assign(:all_categories, all_categories)
     |> stream(:results, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = Map.get(params, "q", "")

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
      if String.length(String.trim(query)) > 0 do
        {:ok, {results, meta}} =
          Forum.paginate_search_threads(query, %{page: page, page_size: LiveHelpers.page_size()})

        socket
        |> assign(:query, query)
        |> assign(:search_form, to_form(%{"query" => query}))
        |> assign(:page, page)
        |> assign(:meta, meta)
        |> stream(:results, serialize_threads(results, socket.assigns.current_user), reset: true)
      else
        socket
        |> assign(:query, query)
        |> assign(:search_form, to_form(%{"query" => query}))
        |> assign(:page, page)
        |> assign(:meta, nil)
        |> stream(:results, [], reset: true)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_patch(socket, to: ~p"/forum/search?q=#{query}&page=1")}
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
            class="flex flex-col gap-2 sm:flex-row"
          >
            <div class="min-w-0 flex-1">
              <.input
                field={@search_form[:query]}
                id="forum-search-query"
                type="search"
                label="Search discussions"
                placeholder="Search threads by title, content, or tags..."
                class="input input-bordered min-h-11 w-full"
              />
            </div>
            <.button
              id="forum-search-submit"
              type="submit"
              loading_label="Searching…"
              class="btn btn-primary min-h-11 sm:self-end"
            >
              <.icon name="hero-magnifying-glass" class="size-5" /> Search
            </.button>
          </.form>
        </section>

        <%= if String.length(String.trim(@query)) == 0 do %>
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
              <.pagination meta={@meta} path={fn n -> ~p"/forum/search?q=#{@query}&page=#{n}" end} />
            <% end %>
          </div>
        <% end %>
      </div>
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  defp serialize_threads(threads, current_user),
    do: LiveHelpers.serialize_thread_list(threads, current_user)

  # serialization and vote lookups now live in LiveHelpers
end
