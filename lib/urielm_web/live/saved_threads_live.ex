defmodule UrielmWeb.SavedThreadsLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias Urielm.Repo

  @page_size 20

  @impl true
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:ok, redirect(socket, to: ~p"/auth/signin")}

      user ->
        saved_threads =
          Forum.list_saved_threads(user.id, limit: @page_size, offset: 0)

        {:ok,
         socket
         |> assign(:page_title, "Saved Threads")
         |> assign(:page, 0)
         |> assign(:has_more, length(saved_threads) == @page_size)
         |> stream(:threads, serialize_threads(saved_threads, user))}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{current_user: user, page: page, has_more: has_more} = socket.assigns

    if not has_more do
      {:noreply, socket}
    else
      offset = (page + 1) * @page_size

      threads =
        Forum.list_saved_threads(user.id, limit: @page_size, offset: offset)

      {:noreply,
       socket
       |> assign(:page, page + 1)
       |> assign(:has_more, length(threads) == @page_size)
       |> stream(:threads, serialize_threads(threads, user))}
    end
  end

  def handle_event(
        "vote",
        %{"target_type" => target_type, "target_id" => target_id, "value" => value},
        socket
      ) do
    %{current_user: user} = socket.assigns

    value_int = String.to_integer(value)

    case Forum.cast_vote(user.id, target_type, target_id, value_int) do
      {:ok, _vote} ->
        thread = Forum.get_thread!(target_id) |> Repo.preload(:author)
        serialized = serialize_thread(thread, user)

        {:noreply, stream_insert(socket, :threads, serialized)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to vote")}
    end
  end

  def handle_event("unsave_thread", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case Forum.toggle_save_thread(user.id, thread_id) do
      {:ok, _} ->
        {:noreply, stream_delete(socket, :threads, thread_id)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unsave thread")}
    end
  end

  def handle_event("subscribe", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case Forum.subscribe_to_thread(user.id, thread_id) do
      {:ok, _} ->
        thread = Forum.get_thread!(thread_id) |> Repo.preload(:author)
        serialized = serialize_thread(thread, user)

        {:noreply, stream_insert(socket, :threads, serialized)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to subscribe")}
    end
  end

  def handle_event("unsubscribe", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case Forum.unsubscribe_from_thread(user.id, thread_id) do
      {:ok, _} ->
        thread = Forum.get_thread!(thread_id) |> Repo.preload(:author)
        serialized = serialize_thread(thread, user)

        {:noreply, stream_insert(socket, :threads, serialized)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unsubscribe")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="saved" socket={@socket}>
    <div class="min-h-screen bg-base-100">
      <div class="container mx-auto px-4 py-8 max-w-3xl">
        <div class="mb-8">
          <h1 class="text-4xl font-bold text-base-content mb-2">Saved Threads</h1>
          <p class="text-base-content/60">Threads you've bookmarked for later</p>
        </div>

        <div id="threads" phx-update="stream" class="space-y-4">
          <div id="empty-state" class="hidden only:block text-center py-12 text-base-content/50">
            You haven't saved any threads yet. Save interesting discussions for later!
          </div>
          <div :for={{id, thread} <- @streams.threads} id={id}>
            <.svelte
              name="ThreadCard"
              props={thread}
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
    is_subscribed = Forum.is_subscribed?(current_user.id, thread.id)

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
      is_saved: true,
      is_subscribed: is_subscribed
    }
  end

  defp get_user_vote(user, target_type, target_id) do
    case Forum.get_user_vote(user.id, target_type, target_id) do
      nil -> nil
      vote -> vote.value
    end
  end
end
