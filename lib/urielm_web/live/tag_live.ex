defmodule UrielmWeb.TagLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(%{"tag_slug" => tag_slug} = params, _session, socket) do
    page = parse_page(params["page"])
    categories = Forum.list_categories_with_boards()

    case Forum.get_tag_by_slug(tag_slug) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/forum/tags")}

      tag ->
        thread_count = Forum.count_threads_by_tag(tag.id)

        flop_params = %{
          page: page,
          page_size: LiveHelpers.page_size(),
          order_by: [:inserted_at, :id],
          order_directions: [:desc, :desc]
        }

        {threads, meta} =
          case Forum.paginate_threads_by_tag(tag.id, flop_params) do
            {:ok, {data, meta}} -> {data, meta}
            {:error, _meta} -> {[], nil}
          end

        {:ok,
         socket
         |> assign(:page_title, "#{tag.name} Tags")
         |> assign(:all_categories, categories)
         |> assign(:tag, tag)
         |> assign(:thread_count, thread_count)
         |> assign(:page, page)
         |> assign(:meta, meta)
         |> stream(:threads, serialize_threads(threads, socket.assigns.current_user), reset: true)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories}
      flash={@flash}
      current_user={@current_user}
      unread_notification_count={@unread_notification_count}
      current_path={"/forum/tags/#{@tag.slug}"}
    >
      <div id="forum-tag-page" class="mx-auto w-full max-w-5xl">
        <header
          id="forum-tag-header"
          class="mb-4 flex flex-col gap-2 px-1 sm:flex-row sm:items-end sm:justify-between"
        >
          <div>
            <h1 class="text-2xl font-bold leading-tight text-base-content sm:text-3xl">
              {@tag.name}
            </h1>
            <p class="mt-1 max-w-2xl text-sm text-base-content/55">
              Threads using this tag.
            </p>
          </div>
          <.link
            id="forum-tag-back-link"
            navigate={~p"/forum/tags"}
            class="btn btn-ghost btn-sm h-9 min-h-9 rounded-full px-3 text-base-content/55 hover:text-secondary"
          >
            All tags
          </.link>
        </header>

        <section
          id="forum-tag-summary"
          class="mb-4 rounded-xl border border-base-300/70 bg-base-200/35 px-4 py-3"
        >
          <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p class="text-xs font-bold uppercase tracking-[0.14em] text-base-content/35">Tag</p>
              <p class="mt-1 font-mono text-xs text-base-content/40">/{@tag.slug}</p>
            </div>
            <div
              id="forum-tag-thread-count"
              class="font-mono text-sm font-black tabular-nums text-base-content/70"
            >
              {@thread_count} {if @thread_count == 1, do: "thread", else: "threads"}
            </div>
          </div>
        </section>

        <section id="forum-tag-discussions">
          <div class="mb-2 grid grid-cols-[minmax(0,1fr)_64px_64px_92px] items-center px-4 text-xs font-semibold text-base-content/35 max-md:hidden">
            <span>Topic</span>
            <span class="text-center">Replies</span>
            <span class="text-center">Views</span>
            <span class="text-right">Activity</span>
          </div>

          <div
            id="tag-threads"
            phx-update="stream"
            class="divide-y divide-base-300/45 border-y border-base-300/55"
          >
            <.empty_state
              id="forum-tag-empty-state"
              title="No discussions for this tag yet"
              description="Once a thread is tagged, it will appear here."
              icon="hero-tag"
              compact
              class="hidden only:grid rounded-none border-0 bg-transparent"
            />
            <div :for={{id, thread} <- @streams.threads} id={id} data-thread-id={thread.id}>
              <.svelte name="ThreadCard" props={thread} socket={@socket} ssr={false} />
            </div>
          </div>

          <div class="mt-8 flex justify-center">
            <%= if @meta do %>
              <.pagination
                meta={@meta}
                path={fn n -> ~p"/forum/tags/#{@tag.slug}?page=#{n}" end}
              />
            <% end %>
          </div>
        </section>
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
