defmodule UrielmWeb.BoardLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, _session, socket) do
    slug = params["board_slug"]

    case Forum.get_board(slug) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/forum/categories")}

      board ->
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
                    %{
                      order_by: [:score, :inserted_at, :id],
                      order_directions: [:desc, :desc, :desc]
                    }

                  "new" ->
                    %{order_by: [:inserted_at, :id], order_directions: [:desc, :desc]}

                  _ ->
                    %{order_by: [:updated_at, :id], order_directions: [:desc, :desc]}
                end

              flop_params =
                Map.merge(%{page: page, page_size: LiveHelpers.page_size()}, flop_order)

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
      unread_notification_count={@unread_notification_count}
      current_board={@board.slug}
    >
      <nav id="board-breadcrumbs" class="breadcrumbs mb-4 text-sm text-base-content/50">
        <ul>
          <li><.link navigate={~p"/forum/categories"}>Categories</.link></li>
          <li><.link navigate={~p"/forum/categories"}>{@board.category.name}</.link></li>
          <li>{@board.name}</li>
        </ul>
      </nav>

      <header id="board-header" class="ui-page-header mb-6">
        <p class="ui-eyebrow">Community board</p>
        <h1 class="ui-section-title">{@board.name}</h1>
        <p :if={@board.description} class="ui-section-copy">{@board.description}</p>
      </header>

      <%!-- Locked notice --%>
      <div
        :if={@board.is_locked}
        id="board-locked-notice"
        class="alert alert-warning mb-5 py-3 text-sm"
      >
        <.um_icon name="lock_closed" class="w-4 h-4" />
        <span>This board is locked and not accepting new threads.</span>
      </div>

      <%!-- Filters and primary action --%>
      <div class="mb-6 flex items-end justify-between gap-3 border-b border-base-300">
        <nav id="board-filter-tabs" class="tabs tabs-border min-w-0 overflow-x-auto">
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
        </nav>

        <.link
          :if={@current_user && !@board.is_locked}
          id="board-new-topic-link"
          navigate={~p"/forum/b/#{@board.slug}/new"}
          class="btn btn-primary btn-sm mb-1 shrink-0"
        >
          <.um_icon name="hero-plus" class="size-4" /> New topic
        </.link>
      </div>

      <%!-- Threads table --%>
      <div id="board-discussions-surface" class="ui-card ui-card-compact h-auto">
        <%!-- Column headers --%>
        <div class="hidden items-center gap-x-4 border-b border-base-300/40 bg-base-200/60 px-4 py-2 md:grid md:grid-cols-[auto_1fr_56px_56px_72px]">
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

        <%!-- Threads stream --%>
        <div id="threads" phx-update="stream">
          <.empty_state
            id="empty-state"
            title={empty_title(@filter)}
            description="Try another filter or start a new discussion."
            icon="hero-chat-bubble-left-right"
            compact
            class="hidden only:grid rounded-none border-0 bg-transparent"
          />
          <div :for={{id, thread} <- @streams.threads} id={id}>
            <.svelte name="ThreadCard" props={thread} socket={@socket} ssr={false} />
          </div>
        </div>
      </div>

      <%!-- Pager --%>
      <div class="mt-8 flex items-center justify-center gap-2">
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
        "tab h-11 shrink-0 px-4 text-sm font-semibold",
        @active && "tab-active"
      ]}
      aria-current={if(@active, do: "page", else: nil)}
    >
      {@label}
    </.link>
    """
  end

  defp empty_title("solved"), do: "No solved topics"
  defp empty_title("unsolved"), do: "No unsolved topics"
  defp empty_title("unread"), do: "All caught up"
  defp empty_title("new"), do: "No new topics"
  defp empty_title(_filter), do: "No topics yet"
end
