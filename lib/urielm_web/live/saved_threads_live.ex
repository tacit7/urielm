defmodule UrielmWeb.SavedThreadsLive do
  use UrielmWeb, :live_view

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:ok, redirect(socket, to: ~p"/auth/signin")}

      _user ->
        {:ok,
         socket
         |> assign(:page_title, "Saved Threads")
         |> assign(:page, 1)
         |> assign(:meta, nil)
         |> stream(:threads, [])}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    %{current_user: user} = socket.assigns
    page =
      Map.get(params, "page", "1")
      |> case do
        p when is_binary(p) ->
          case Integer.parse(p) do
            {n, ""} when n > 0 -> n
            _ -> 1
          end
        p when is_integer(p) -> p
      end

    {:ok, {threads, meta}} =
      Forum.paginate_saved_threads(user.id, %{page: page, page_size: LiveHelpers.page_size()})

    {:noreply,
     socket
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

    value_int =
      case Integer.parse(value) do
        {n, ""} -> n
        _ -> nil
      end

    case value_int do
      nil ->
        {:noreply, put_flash(socket, :error, "Invalid vote value")}

      value_int ->
        case Forum.cast_vote(user.id, target_type, target_id, value_int) do
          {:ok, _vote} ->
            {:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, target_id, user)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to vote")}
        end
    end
  end

  @impl true
  def handle_event("unsave_thread", %{"thread_id" => thread_id}, socket) do
    %{current_user: user} = socket.assigns

    case Forum.toggle_save_thread(user.id, thread_id) do
      {:ok, _} ->
        {:noreply, stream_delete(socket, :threads, %{id: thread_id})}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unsave thread")}
    end
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

          <div class="flex items-center justify-center gap-2 mt-8">
            <%= if @meta do %>
              <.pagination meta={@meta} path={fn n -> ~p"/saved?page=#{n}" end} />
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp serialize_threads(threads, current_user),
    do: LiveHelpers.serialize_thread_list(threads, current_user)

  # serialization handled in LiveHelpers; LiveView only streams
end
