defmodule UrielmWeb.LatestLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns[:current_user]
    page = parse_page(params["page"])

    if connected?(socket) do
      categories = Forum.list_categories_with_boards()

      flop_params = %{
        page: page,
        page_size: LiveHelpers.page_size(),
        order_by: [:updated_at, :id],
        order_directions: [:desc, :desc]
      }

      {threads, meta} =
        case Forum.paginate_latest_threads(flop_params) do
          {:ok, {data, meta}} -> {data, meta}
          {:error, _meta} -> {[], nil}
        end

      {:ok,
       socket
       |> assign(:page_title, "Latest")
       |> assign(:all_categories, categories)
       |> assign(:page, page)
       |> assign(:meta, meta)
       |> stream(:threads, serialize_threads(threads, user), reset: true)}
    else
      {:ok,
       socket
       |> assign(:page_title, "Latest")
       |> assign(:all_categories, [])
       |> assign(:page, page)
       |> assign(:meta, nil)
       |> stream(:threads, [])}
    end
  end

  @impl true
  def handle_event(
        "vote",
        %{"target_type" => target_type, "target_id" => target_id, "value" => value},
        socket
      ) do
    user = socket.assigns.current_user

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to vote")}

      user ->
        value_int =
          case Integer.parse(value) do
            {n, ""} when n in [-1, 0, 1] -> n
            _ -> nil
          end

        case value_int && Forum.cast_vote(user.id, target_type, target_id, value_int) do
          nil ->
            {:noreply, socket}

          {:ok, _} ->
            {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, target_id, user)}

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

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories}
      flash={@flash}
      current_user={@current_user}
      unread_notification_count={@unread_notification_count}
      current_path="/forum"
    >
      <UrielmWeb.Components.ForumLayout.discovery_header active_view="latest" />

      <%!-- Thread table --%>
      <section id="latest-discussions" aria-labelledby="latest-discussions-title">
        <div class="mb-3 flex items-center justify-between">
          <h2 id="latest-discussions-title" class="ui-eyebrow text-base-content/55">
            Latest discussions
          </h2>
        </div>
        <div id="latest-discussions-surface" class="ui-card ui-card-compact h-auto">
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

          <%!-- Threads --%>
          <div id="threads" phx-update="stream">
            <.empty_state
              id="empty-state"
              title="No topics yet"
              description="New community discussions will appear here."
              icon="hero-chat-bubble-left-right"
              compact
              class="hidden only:grid rounded-none border-0 bg-transparent"
            />
            <div :for={{id, thread} <- @streams.threads} id={id}>
              <.svelte name="ThreadCard" props={thread} socket={@socket} ssr={false} />
            </div>
          </div>
        </div>
      </section>

      <%!-- Pagination --%>
      <div class="mt-8 flex items-center justify-center gap-2">
        <%= if @meta do %>
          <.pagination
            meta={@meta}
            path={fn n -> ~p"/forum?page=#{n}" end}
          />
        <% end %>
      </div>
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  defp serialize_threads(threads, current_user) do
    LiveHelpers.serialize_thread_list_with_board(threads, current_user)
  end

  defp parse_page(nil), do: 1

  defp parse_page(p) when is_binary(p) do
    case Integer.parse(p) do
      {n, ""} when n >= 1 -> n
      _ -> 1
    end
  end

  defp parse_page(p) when is_integer(p), do: max(p, 1)
end
