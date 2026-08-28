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
        <header id="forum-tag-header" class="ui-page-header mb-5">
          <h1 class="text-2xl font-bold tracking-tight text-base-content sm:text-3xl">
            {@tag.name}
          </h1>
          <p class="mt-1 max-w-2xl text-sm text-base-content/55">
            Browse threads grouped under this tag and jump back into the conversations that use it.
          </p>
        </header>

        <section id="forum-tag-summary" class="ui-card mb-6 h-auto p-5 sm:p-6">
          <div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p class="text-xs font-bold uppercase tracking-[0.16em] text-base-content/35">
                Thread coverage
              </p>
              <p id="forum-tag-thread-count" class="mt-2 text-3xl font-black text-base-content">
                {@thread_count}
              </p>
              <p class="mt-1 text-sm text-base-content/45">
                discussions currently use this tag.
              </p>
            </div>
            <div
              id="forum-tag-management-note"
              class="max-w-xl rounded-xl border border-base-300/70 bg-base-200/50 px-4 py-3 text-sm text-base-content/60"
            >
              Tags are attached to discussions. Use the thread list below to review what is tagged and follow a thread to adjust its tags in context.
            </div>
          </div>
        </section>

        <section id="forum-tag-discussions" class="space-y-4">
          <div id="tag-threads" phx-update="stream" class="space-y-4">
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

          <div class="flex justify-center">
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
