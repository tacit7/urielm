defmodule UrielmWeb.BoardLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, _session, socket) do
    slug = params["board_slug"]
    board = Forum.get_board!(slug)
    categories = Forum.list_categories_with_boards()

    sort = Map.get(params, "sort", "latest")
    filter = Map.get(params, "filter", "all")

    page =
      case params["page"] do
        nil ->
          1

        p when is_binary(p) ->
          case Integer.parse(p) do
            {n, ""} when n >= 1 -> n
            _ -> 1
          end

        p when is_integer(p) ->
          max(p, 1)
      end

    user = socket.assigns[:current_user]

    {threads, meta} =
      case filter do
        "unread" when not is_nil(user) ->
          case Forum.paginate_unread_threads(user.id, board.id, %{
                 page: page,
                 page_size: LiveHelpers.page_size()
               }) do
            {:ok, {data, meta}} -> {data, meta}
            {:error, _meta} -> {[], nil}
          end

        "new" ->
          case Forum.paginate_new_threads(board.id, %{
                 page: page,
                 page_size: LiveHelpers.page_size()
               }) do
            {:ok, {data, meta}} -> {data, meta}
            {:error, _meta} -> {[], nil}
          end

        "solved" ->
          flop_params = %{
            page: page,
            page_size: LiveHelpers.page_size(),
            order_by: [:updated_at],
            order_directions: [:desc]
          }

          case Forum.paginate_threads(board.id, flop_params, solved: true) do
            {:ok, {data, meta}} -> {data, meta}
            {:error, _meta} -> {[], nil}
          end

        "unsolved" ->
          flop_params = %{
            page: page,
            page_size: LiveHelpers.page_size(),
            order_by: [:updated_at],
            order_directions: [:desc]
          }

          case Forum.paginate_threads(board.id, flop_params, solved: false) do
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

          flop_params = Map.merge(%{page: page, page_size: LiveHelpers.page_size()}, flop_order)

          case Forum.paginate_threads(board.id, flop_params) do
            {:ok, {data, meta}} -> {data, meta}
            {:error, _meta} -> {[], nil}
          end
      end

    {:ok,
     socket
     |> assign(:page_title, board.name)
     |> assign(:board, board)
     |> assign(:all_categories, categories)
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

        value_int =
          case Integer.parse(value) do
            {n, ""} when n in [-1, 0, 1] -> n
            _ -> nil
          end

        case value_int && Forum.cast_vote(user.id, target_type, target_id_binary, value_int) do
          nil ->
            {:noreply, socket}

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
    LiveHelpers.handle_save_thread(thread_id, :threads, socket)
  end

  @impl true
  def handle_event("subscribe", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.handle_subscribe_thread(thread_id, :threads, socket)
  end

  @impl true
  def handle_event("unsubscribe", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.handle_unsubscribe_thread(thread_id, :threads, socket)
  end

  # No load_more; pagination is handled via Flop and patch navigation

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories || []}
      flash={@flash}
      current_user={@current_user}
      current_board={@board.slug}
    >
      <!-- Breadcrumb -->
      <nav class="font-mono text-xs text-base-content/40 mb-3 flex items-center gap-1">
        <a href={~p"/forum/categories"} class="hover:text-base-content transition-colors">
          Categories
        </a>
        <span>/</span>
        <a href={~p"/forum/categories"} class="hover:text-base-content transition-colors">
          {@board.category.name}
        </a>
        <span>/</span>
        <span class="text-base-content/60">{@board.name}</span>
      </nav>

      <div class="mb-4">
        <h1 class="text-3xl font-black tracking-tight text-base-content leading-none">
          {@board.name}
        </h1>
        <p :if={@board.description} class="text-sm text-base-content/50 mt-1">{@board.description}</p>
      </div>
      
    <!-- Locked notice -->
      <div :if={@board.is_locked} class="alert alert-warning mb-4 py-2 text-sm">
        <.um_icon name="lock_closed" class="w-4 h-4" />
        <span>This board is locked and not accepting new threads.</span>
      </div>
      
    <!-- Header -->
      <div class="mb-6">
        <!-- Tabs + New Topic button inline -->
        <div class="flex items-center justify-between border-b border-base-300">
          <div class="flex items-center overflow-x-auto">
            <.tab_link
              href={~p"/forum/b/#{@board.slug}"}
              active={@filter == "all" && @sort != "top"}
              label="Latest"
            />
            <.tab_link
              href={~p"/forum/b/#{@board.slug}?sort=top"}
              active={@sort == "top"}
              label="Top"
            />
            <.tab_link
              href={~p"/forum/b/#{@board.slug}?filter=new"}
              active={@filter == "new"}
              label="New"
            />
            <%= if @current_user do %>
              <.tab_link
                href={~p"/forum/b/#{@board.slug}?filter=unread"}
                active={@filter == "unread"}
                label="Unread"
              />
            <% end %>
            <.tab_link
              href={~p"/forum/b/#{@board.slug}?filter=solved"}
              active={@filter == "solved"}
              label="Solved"
            />
            <.tab_link
              href={~p"/forum/b/#{@board.slug}?filter=unsolved"}
              active={@filter == "unsolved"}
              label="Unsolved"
            />
          </div>

          <%= if @current_user && !@board.is_locked do %>
            <a
              href={~p"/forum/b/#{@board.slug}/new"}
              class="btn btn-primary btn-sm rounded-full px-4 mb-1 flex-shrink-0"
            >
              + New Topic
            </a>
          <% end %>
        </div>
      </div>
      
    <!-- Threads table -->
      <div class="rounded-xl border border-base-300/60 overflow-hidden">
        <!-- Column headers -->
        <div class="hidden md:grid md:grid-cols-[auto_1fr_56px_56px_72px] items-center gap-x-4 px-4 py-2 bg-base-200/60 border-b border-base-300/40">
          <div class="w-2" />
          <span class="text-xs font-medium text-base-content/35 tracking-wide">Topic</span>
          <span class="text-xs font-medium text-base-content/35 tracking-wide text-center">
            Replies
          </span>
          <span class="text-xs font-medium text-base-content/35 tracking-wide text-center">
            Views
          </span>
          <span class="text-xs font-medium text-base-content/35 tracking-wide text-right">
            Activity
          </span>
        </div>
        
    <!-- Threads stream -->
        <div id="threads" phx-update="stream">
          <div id="empty-state" class="hidden only:flex justify-center py-16">
            <div class="text-center">
              <p class="font-mono font-black text-6xl text-base-content/10 mb-3">0</p>
              <p class="font-mono text-xs tracking-widest uppercase text-base-content/30">
                <%= case @filter do %>
                  <% "solved" -> %>
                    No solved topics
                  <% "unsolved" -> %>
                    No unsolved topics
                  <% "unread" -> %>
                    All caught up
                  <% "new" -> %>
                    No new topics
                  <% _ -> %>
                    No topics yet
                <% end %>
              </p>
            </div>
          </div>
          <div :for={{id, thread} <- @streams.threads} id={id}>
            <.svelte name="ThreadCard" props={thread} socket={@socket} ssr={false} />
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
    """
  end

  defp serialize_threads(threads, current_user),
    do: LiveHelpers.serialize_thread_list(threads, current_user)

  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :label, :string, required: true

  defp tab_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "px-3 py-2.5 text-sm font-medium border-b-2 transition-colors whitespace-nowrap",
        if(@active,
          do: "border-primary text-primary",
          else: "border-transparent text-base-content/50 hover:text-base-content"
        )
      ]}
    >
      {@label}
    </.link>
    """
  end
end
