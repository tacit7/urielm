defmodule UrielmWeb.SearchLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @page_size 20

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Search Forum")
     |> assign(:query, "")
     |> assign(:page, 0)
     |> assign(:has_more, false)
     |> stream(:results, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = Map.get(params, "q", "")
    page = Map.get(params, "page", "1") |> String.to_integer()

    if String.length(String.trim(query)) > 0 do
      {:ok, {results, meta}} =
        Forum.paginate_search_threads(query, %{page: page, page_size: @page_size})

      {:noreply,
       socket
       |> assign(:query, query)
       |> assign(:page, page)
       |> assign(:meta, meta)
       |> stream(:results, serialize_threads(results, socket.assigns.current_user), reset: true)}
    else
      {:noreply,
       socket
       |> assign(:query, query)
       |> assign(:page, page)
       |> assign(:meta, nil)
       |> stream(:results, [], reset: true)}
    end
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
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to save threads")}

      user ->
        case Forum.toggle_save_thread(user.id, thread_id) do
          {:ok, _} ->
            {:noreply, LiveHelpers.update_thread_in_stream(socket, :results, thread_id, user)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to save thread")}
        end
    end
  end

  @impl true
  def handle_event("subscribe", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to subscribe")}

      user ->
        case Forum.subscribe_to_thread(user.id, thread_id) do
          {:ok, _} ->
            {:noreply, LiveHelpers.update_thread_in_stream(socket, :results, thread_id, user)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to subscribe")}
        end
    end
  end

  @impl true
  def handle_event("unsubscribe", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, socket}

      user ->
        case Forum.unsubscribe_from_thread(user.id, thread_id) do
          {:ok, _} ->
            {:noreply, LiveHelpers.update_thread_in_stream(socket, :results, thread_id, user)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to unsubscribe")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="search" socket={@socket}>
      <div class="min-h-screen bg-base-100">
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
      </div>
    </Layouts.app>
    """
  end

  defp serialize_threads(threads, current_user),
    do: LiveHelpers.serialize_thread_list(threads, current_user)

  # serialization and vote lookups now live in LiveHelpers
end
