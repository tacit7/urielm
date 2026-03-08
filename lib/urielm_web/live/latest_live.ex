defmodule UrielmWeb.LatestLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @page_size 30

  @impl true
  def mount(params, _session, socket) do
    categories = Forum.list_categories_with_boards()
    user = socket.assigns[:current_user]

    page = parse_page(params["page"])

    flop_params = %{
      page: page,
      page_size: @page_size,
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
          nil -> {:noreply, socket}
          {:ok, _} -> {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, target_id, user)}
          {:error, _} -> {:noreply, put_flash(socket, :error, "Failed to vote")}
        end
    end
  end

  @impl true
  def handle_event("save_thread", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.with_auth(socket, "save threads", fn socket, user ->
      case Forum.toggle_save_thread(user.id, thread_id) do
        {:ok, _} -> {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, thread_id, user)}
        {:error, _} -> {:noreply, put_flash(socket, :error, "Failed to save thread")}
      end
    end)
  end

  @impl true
  def handle_event("subscribe", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.with_auth(socket, "subscribe", fn socket, user ->
      case Forum.subscribe_to_thread(user.id, thread_id) do
        {:ok, _} -> {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, thread_id, user)}
        {:error, _} -> {:noreply, put_flash(socket, :error, "Failed to subscribe")}
      end
    end)
  end

  @impl true
  def handle_event("unsubscribe", %{"thread_id" => thread_id}, socket) do
    LiveHelpers.with_auth(socket, "unsubscribe", fn socket, user ->
      case Forum.unsubscribe_from_thread(user.id, thread_id) do
        {:ok, _} -> {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, thread_id, user)}
        {:error, _} -> {:noreply, put_flash(socket, :error, "Failed to unsubscribe")}
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories}
      flash={@flash}
      current_path="/forum/latest"
    >
      <!-- Header -->
      <div class="mb-6">
        <p class="font-mono text-xs tracking-widest uppercase text-base-content/40 mb-2">
          Community / Latest
        </p>
        <h1 class="text-4xl font-black tracking-tight text-base-content leading-none mb-4">
          Latest
        </h1>
        <div class="h-px bg-base-content/10" />
      </div>

      <!-- Thread table -->
      <div class="rounded-xl border border-base-300/60 overflow-hidden">
        <!-- Column headers -->
        <div class="hidden md:grid md:grid-cols-[auto_1fr_56px_56px_72px] items-center gap-x-4 px-4 py-2 bg-base-200/60 border-b border-base-300/40">
          <div class="w-2" />
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider">Topic</span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider text-center">
            Replies
          </span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider text-center">
            Views
          </span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider text-right">
            Activity
          </span>
        </div>

        <!-- Threads -->
        <div id="threads" phx-update="stream">
          <div id="empty-state" class="hidden only:flex justify-center py-16">
            <div class="text-center">
              <p class="font-mono font-black text-6xl text-base-content/10 mb-3">0</p>
              <p class="font-mono text-xs tracking-widest uppercase text-base-content/30">
                No topics yet
              </p>
            </div>
          </div>
          <div :for={{id, thread} <- @streams.threads} id={id}>
            <.svelte name="ThreadCard" props={thread} socket={@socket} />
          </div>
        </div>
      </div>

      <!-- Pagination -->
      <div class="flex items-center justify-center gap-2 mt-8">
        <%= if @meta do %>
          <.pagination
            meta={@meta}
            path={fn n -> ~p"/forum/latest?page=#{n}" end}
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
