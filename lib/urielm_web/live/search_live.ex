defmodule UrielmWeb.SearchLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias Urielm.Repo

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

    if String.length(String.trim(query)) > 0 do
      results =
        Forum.search_threads(query, limit: @page_size, offset: 0)

      {:noreply,
       socket
       |> assign(:query, query)
       |> assign(:page, 0)
       |> assign(:has_more, length(results) == @page_size)
       |> stream(:results, serialize_threads(results, socket.assigns.current_user), reset: true)}
    else
      {:noreply,
       socket
       |> assign(:query, query)
       |> assign(:page, 0)
       |> assign(:has_more, false)
       |> stream(:results, [], reset: true)}
    end
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_patch(socket, to: ~p"/forum/search?q=#{query}")}
  end

  def handle_event("load_more", _params, socket) do
    %{query: query, page: page, has_more: has_more} = socket.assigns

    if not has_more or String.length(String.trim(query)) == 0 do
      {:noreply, socket}
    else
      offset = (page + 1) * @page_size

      results =
        Forum.search_threads(query, limit: @page_size, offset: offset)

      {:noreply,
       socket
       |> assign(:page, page + 1)
       |> assign(:has_more, length(results) == @page_size)
       |> stream(:results, serialize_threads(results, socket.assigns.current_user))}
    end
  end

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
            thread = Forum.get_thread!(target_id_binary) |> Repo.preload(:author)
            serialized = serialize_thread(thread, user)

            {:noreply, stream_insert(socket, :results, serialized)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to vote")}
        end
    end
  end

  def handle_event("save_thread", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to save threads")}

      user ->
        case Forum.toggle_save_thread(user.id, thread_id) do
          {:ok, _} ->
            thread = Forum.get_thread!(thread_id) |> Repo.preload(:author)
            serialized = serialize_thread(thread, user)

            {:noreply, stream_insert(socket, :results, serialized)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to save thread")}
        end
    end
  end

  def handle_event("subscribe", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to subscribe")}

      user ->
        case Forum.subscribe_to_thread(user.id, thread_id) do
          {:ok, _} ->
            thread = Forum.get_thread!(thread_id) |> Repo.preload(:author)
            serialized = serialize_thread(thread, user)

            {:noreply, stream_insert(socket, :results, serialized)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to subscribe")}
        end
    end
  end

  def handle_event("unsubscribe", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, socket}

      user ->
        case Forum.unsubscribe_from_thread(user.id, thread_id) do
          {:ok, _} ->
            thread = Forum.get_thread!(thread_id) |> Repo.preload(:author)
            serialized = serialize_thread(thread, user)

            {:noreply, stream_insert(socket, :results, serialized)}

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

          <%= if @has_more do %>
            <div
              id="infinite-scroll-marker"
              phx-hook="InfiniteScroll"
              class="h-20 flex items-center justify-center mt-8"
            >
              <div class="text-base-content/40 text-sm">Loading more...</div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    </Layouts.app>
    """
  end

  defp serialize_threads(threads, current_user) do
    threads = Repo.preload(threads, :author)

    Enum.map(threads, fn thread ->
      serialize_thread(thread, current_user)
    end)
  end

  defp serialize_thread(thread, current_user) do
    is_saved = current_user && Forum.is_thread_saved?(current_user.id, thread.id)
    is_subscribed = current_user && Forum.is_subscribed?(current_user.id, thread.id)
    is_unread = current_user && Forum.is_thread_unread?(current_user.id, thread.id)

    %{
      id: to_string(thread.id),
      title: thread.title,
      body: String.slice(thread.body, 0, 150),
      score: thread.score,
      comment_count: thread.comment_count,
      author: %{
        id: thread.author.id,
        username: thread.author.username
      },
      created_at: thread.inserted_at,
      user_vote: get_user_vote(current_user, "thread", thread.id),
      is_saved: is_saved,
      is_subscribed: is_subscribed,
      is_unread: is_unread
    }
  end

  defp get_user_vote(nil, _target_type, _target_id), do: nil

  defp get_user_vote(user, target_type, target_id) do
    case Forum.get_user_vote(user.id, target_type, target_id) do
      nil -> nil
      vote -> vote.value
    end
  end
end
