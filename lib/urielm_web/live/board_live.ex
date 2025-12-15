defmodule UrielmWeb.BoardLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias Urielm.Repo

  @page_size 20

  @impl true
  def mount(%{"board_slug" => slug}, _session, socket) do
    board = Forum.get_board!(slug)
    categories = Forum.list_categories() |> Repo.preload(:boards)

    {:ok,
     socket
     |> assign(:page_title, board.name)
     |> assign(:board, board)
     |> assign(:all_categories, categories)
     |> assign(:sort, "new")
     |> assign(:page, 0)
     |> assign(:has_more, true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    sort = Map.get(params, "sort", "new")
    %{board: board} = socket.assigns

    threads =
      Forum.list_threads(board.id, sort: String.to_atom(sort), limit: @page_size, offset: 0)

    {:noreply,
     socket
     |> assign(:sort, sort)
     |> assign(:page, 0)
     |> assign(:has_more, length(threads) == @page_size)
     |> stream(:threads, serialize_threads(threads, socket.assigns.current_user), reset: true)}
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
            # Fetch updated thread and serialize
            thread = Forum.get_thread!(target_id_binary) |> Repo.preload(:author)
            serialized = serialize_thread(thread, user)

            {:noreply, stream_insert(socket, :threads, serialized)}

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

            {:noreply, stream_insert(socket, :threads, serialized)}

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

            {:noreply, stream_insert(socket, :threads, serialized)}

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

            {:noreply, stream_insert(socket, :threads, serialized)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to unsubscribe")}
        end
    end
  end

  # PAGINATION STABILITY NOTE:
  # Offset-based pagination with "Top" sorting may cause missing/duplicate threads
  # if votes change scores mid-scroll. Acceptable for MVP. For high-traffic boards,
  # migrate to cursor-based pagination using (score, inserted_at, id) composite.
  # See: https://use-the-index-luke.com/no-offset
  def handle_event("load_more", _params, socket) do
    %{board: board, sort: sort, page: page, has_more: has_more} = socket.assigns

    if not has_more do
      {:noreply, socket}
    else
      offset = (page + 1) * @page_size

      threads =
        Forum.list_threads(board.id,
          sort: String.to_atom(sort),
          limit: @page_size,
          offset: offset
        )

      {:noreply,
       socket
       |> assign(:page, page + 1)
       |> assign(:has_more, length(threads) == @page_size)
       |> stream(:threads, serialize_threads(threads, socket.assigns.current_user))}
    end
  end

  @impl true
  def render(assigns) do
    categories = Enum.map(assigns.all_categories || [], fn cat ->
      %{id: cat.id, name: cat.name, slug: cat.slug}
    end)

    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout categories={@all_categories || []}>
      <!-- Header -->
      <div class="mb-8">
        <div class="flex items-center justify-between mb-6">
          <div>
            <h1 class="text-3xl font-bold text-base-content">{@board.name}</h1>
            <p class="text-base-content/60 mt-2">{@board.description}</p>
          </div>
          <%= if @current_user do %>
            <a
              href={~p"/forum/b/#{@board.slug}/new"}
              class="btn btn-primary"
            >
              New Topic
            </a>
          <% end %>
        </div>

        <!-- Sort Tabs -->
        <div class="flex gap-4 border-b border-base-300 pb-0">
          <a
            href={~p"/forum/b/#{@board.slug}?sort=new"}
            class={[
              "px-4 py-3 font-medium border-b-2 transition-colors",
              if(@sort == "new",
                do: "border-primary text-primary",
                else: "border-transparent text-base-content/60 hover:text-base-content"
              )
            ]}
          >
            Latest
          </a>
          <a
            href={~p"/forum/b/#{@board.slug}?sort=top"}
            class={[
              "px-4 py-3 font-medium border-b-2 transition-colors",
              if(@sort == "top",
                do: "border-primary text-primary",
                else: "border-transparent text-base-content/60 hover:text-base-content"
              )
            ]}
          >
            Top
          </a>
        </div>
      </div>

      <!-- Threads Table -->
      <div class="border border-base-300 rounded-lg overflow-hidden bg-base-200/20">
        <!-- Table Header -->
        <div class="grid grid-cols-12 gap-4 px-5 py-3 bg-base-300/30 border-b border-base-300 text-sm font-semibold text-base-content/70">
          <div class="col-span-7">Topic</div>
          <div class="col-span-2 text-right">Replies</div>
          <div class="col-span-3 text-right">Activity</div>
        </div>

        <!-- Threads List -->
        <div id="threads" phx-update="stream" class="">
          <div id="empty-state" class="hidden only:flex justify-center py-12">
            <div class="text-center text-base-content/50">
              <p class="text-lg font-medium mb-2">No topics yet</p>
              <p class="text-sm">Be the first to start a discussion!</p>
            </div>
          </div>
          <div :for={{id, thread} <- @streams.threads} id={id} class="border-t border-base-300 first:border-t-0">
            <.svelte
              name="ThreadCard"
              props={thread}
              socket={@socket}
            />
          </div>
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
    </UrielmWeb.Components.ForumLayout.forum_layout>
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
      is_subscribed: is_subscribed
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
