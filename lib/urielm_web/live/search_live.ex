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
        nil -> 1
        p when is_binary(p) -> String.to_integer(p)
        p when is_integer(p) -> p
      end

    socket =
      if String.length(String.trim(query)) > 0 do
        {:ok, {results, meta}} =
          Forum.paginate_search_threads(query, %{page: page, page_size: LiveHelpers.page_size()})

        socket
        |> assign(:query, query)
        |> assign(:page, page)
        |> assign(:meta, meta)
        |> stream(:results, serialize_threads(results, socket.assigns.current_user), reset: true)
      else
        socket
        |> assign(:query, query)
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
        value_int = String.to_integer(value)

        case Forum.cast_vote(user.id, target_type, target_id_binary, value_int) do
          {:ok, _vote} ->
            {:noreply,
             LiveHelpers.update_thread_in_stream(socket, :results, target_id_binary, user)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to vote")}
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
      current_path="/forum/search"
    >
      <div class="container mx-auto px-4 py-8 max-w-3xl">
        <div class="mb-8">
          <h1 class="text-4xl font-bold text-base-content mb-4">Search Forum</h1>

          <form phx-submit="search" class="flex gap-2">
            <input
              type="text"
              name="query"
              value={@query}
              placeholder="Search threads by title, content, or tags..."
              class="input input-bordered flex-1"
            />
            <button type="submit" class="btn btn-primary">Search</button>
          </form>
        </div>

        <%= if String.length(String.trim(@query)) == 0 do %>
          <div class="text-center py-12 text-base-content/50">
            <p>Enter a search query to find threads</p>
          </div>
        <% else %>
          <div id="results" phx-update="stream" class="space-y-4">
            <div id="empty-state" class="hidden only:block text-center py-12 text-base-content/50">
              No threads found matching your search.
            </div>
            <div :for={{id, result} <- @streams.results} id={id}>
              <.svelte
                name="ThreadCard"
                props={result}
                socket={@socket}
              />
            </div>
          </div>

          <div class="flex items-center justify-center gap-2 mt-8">
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
