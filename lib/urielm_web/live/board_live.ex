defmodule UrielmWeb.BoardLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @page_size 20

  @impl true
  def mount(%{"board_slug" => slug}, _session, socket) do
    board = Forum.get_board!(slug)
    categories = Forum.list_categories_with_boards()

    {:ok,
     socket
     |> assign(:page_title, board.name)
     |> assign(:board, board)
     |> assign(:all_categories, categories)
     |> assign(:sort, "new")
     |> assign(:page, 1)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    sort = Map.get(params, "sort", "latest")
    filter = Map.get(params, "filter", "all")
    page = Map.get(params, "page", "1") |> String.to_integer()
    %{board: board, current_user: user} = socket.assigns

    {threads, meta} =
      case filter do
        "unread" when not is_nil(user) ->
          case Forum.paginate_unread_threads(user.id, board.id, %{
                 page: page,
                 page_size: @page_size
               }) do
            {:ok, {data, meta}} -> {data, meta}
            {:error, _meta} -> {[], nil}
          end

        "new" ->
          case Forum.paginate_new_threads(board.id, %{page: page, page_size: @page_size}) do
            {:ok, {data, meta}} -> {data, meta}
            {:error, _meta} -> {[], nil}
          end

        _ ->
          flop_order =
            case sort do
              "latest" ->
                %{order_by: [:updated_at, :id], order_directions: [:desc, :desc]}

              "top" ->
                %{order_by: [:score, :inserted_at, :id], order_directions: [:desc, :desc, :desc]}

              "new" ->
                %{order_by: [:inserted_at, :id], order_directions: [:desc, :desc]}

              _ ->
                %{order_by: [:updated_at, :id], order_directions: [:desc, :desc]}
            end

          flop_params = Map.merge(%{page: page, page_size: @page_size}, flop_order)

          case Forum.paginate_threads(board.id, flop_params) do
            {:ok, {data, meta}} -> {data, meta}
            {:error, _meta} -> {[], nil}
          end
      end

    {:noreply,
     socket
     |> assign(:sort, sort)
     |> assign(:filter, filter)
     |> assign(:page, page)
     |> assign(:meta, meta)
     |> stream(:threads, serialize_threads(threads, user), reset: true)}
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
            {:noreply,
             LiveHelpers.update_thread_in_stream(socket, :threads, target_id_binary, user)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to vote")}
        end
    end
  end

  @impl true
  def handle_event("save_thread", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.with_auth(socket, "save threads", fn socket, user ->
      case Forum.toggle_save_thread(user.id, thread_id) do
        {:ok, _} ->
          {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, thread_id, user)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to save thread")}
      end
    end)
  end

  @impl true
  def handle_event("subscribe", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.with_auth(socket, "subscribe", fn socket, user ->
      case Forum.subscribe_to_thread(user.id, thread_id) do
        {:ok, _} ->
          {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, thread_id, user)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to subscribe")}
      end
    end)
  end

  @impl true
  def handle_event("unsubscribe", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.with_auth(socket, "unsubscribe", fn socket, user ->
      case Forum.unsubscribe_from_thread(user.id, thread_id) do
        {:ok, _} ->
          {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, thread_id, user)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to unsubscribe")}
      end
    end)
  end

  # No load_more; pagination is handled via Flop and patch navigation

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="" socket={@socket}>
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
          
    <!-- Filter Tabs -->
          <div class="flex gap-4 border-b border-base-300 pb-0">
            <%= if @current_user do %>
              <a
                href={~p"/forum/b/#{@board.slug}?filter=unread"}
                class={[
                  "px-4 py-3 font-medium border-b-2 transition-colors",
                  if(@filter == "unread",
                    do: "border-primary text-primary",
                    else: "border-transparent text-base-content/60 hover:text-base-content"
                  )
                ]}
              >
                Unread
              </a>
            <% end %>
            <a
              href={~p"/forum/b/#{@board.slug}?filter=new"}
              class={[
                "px-4 py-3 font-medium border-b-2 transition-colors",
                if(@filter == "new",
                  do: "border-primary text-primary",
                  else: "border-transparent text-base-content/60 hover:text-base-content"
                )
              ]}
            >
              New
            </a>
            <a
              href={~p"/forum/b/#{@board.slug}"}
              class={[
                "px-4 py-3 font-medium border-b-2 transition-colors",
                if(@filter == "all",
                  do: "border-primary text-primary",
                  else: "border-transparent text-base-content/60 hover:text-base-content"
                )
              ]}
            >
              Latest
            </a>
            <a
              href={~p"/forum/b/#{@board.slug}?sort=top&filter=all"}
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
            <div
              :for={{id, thread} <- @streams.threads}
              id={id}
              class="border-t border-base-300 first:border-t-0"
            >
              <.svelte
                name="ThreadCard"
                props={thread}
                socket={@socket}
              />
            </div>
          </div>
        </div>
        
    <!-- Pager -->
        <div class="flex items-center justify-center gap-2 mt-8">
          <%= if @meta do %>
            <.pagination
              meta={@meta}
              path={fn n -> ~p"/forum/b/#{@board.slug}?sort=#{@sort}&filter=#{@filter}&page=#{n}" end}
            />
          <% end %>
        </div>
      </UrielmWeb.Components.ForumLayout.forum_layout>
    </Layouts.app>
    """
  end

  defp serialize_threads(threads, current_user),
    do: LiveHelpers.serialize_thread_list(threads, current_user)

  # per-ThreadCard serialization and vote lookups now live in LiveHelpers
end
