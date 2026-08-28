defmodule UrielmWeb.NewThreadLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias Urielm.Params
  alias Urielm.Forum.Thread

  @impl true
  def mount(%{"board_slug" => slug}, _session, socket) do
    case Forum.get_board(slug) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/forum/categories")}

      board ->
        user = socket.assigns.current_user

        cond do
          board.is_locked ->
            {:ok,
             socket
             |> put_flash(:error, "This board is locked and not accepting new threads")
             |> redirect(to: ~p"/forum/b/#{board.slug}")}

          is_nil(user.username) ->
            {:ok,
             socket
             |> put_flash(:info, "Please set a username before creating a thread")
             |> redirect(to: ~p"/signup/set-handle")}

          true ->
            categories = Forum.list_categories_with_boards()

            {:ok,
             socket
             |> assign(:page_title, "New Discussion")
             |> assign(:board, board)
             |> assign(:all_categories, categories)
             |> assign_composer(Thread.create_changeset(%Thread{}, %{}), %{})}
        end
    end
  end

  @impl true
  def handle_event("validate", %{"thread" => thread_params0}, socket) do
    changeset =
      %Thread{}
      |> Thread.create_changeset(allowed_params(thread_params0))
      |> Map.put(:action, :validate)

    {:noreply, assign_composer(socket, changeset, thread_params0)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("restore_draft", draft_params, socket) do
    params =
      draft_params
      |> Map.take(["title", "body"])
      |> Params.normalize()

    changeset = Thread.create_changeset(%Thread{}, params)

    {:noreply, assign_composer(socket, changeset, params)}
  end

  @impl true
  def handle_event("save", %{"thread" => thread_params0}, socket) do
    %{board: board, current_user: user} = socket.assigns

    # Whitelist client-supplied fields; moderation fields (is_pinned, is_locked,
    # pinned_by_id, ...) must never come from the composer.
    params = allowed_params(thread_params0)

    params_with_slug =
      if params["slug"] && params["slug"] != "" do
        params
      else
        Map.put(params, "slug", Urielm.Slugify.slugify(params["title"] || ""))
      end

    case Forum.create_thread(board.id, user.id, params_with_slug) do
      {:ok, thread} ->
        {:noreply,
         socket
         |> push_event("clear_draft", %{})
         |> put_flash(:info, "Thread created successfully")
         |> redirect(to: ~p"/forum/t/#{thread.id}")}

      {:error, :board_locked} ->
        {:noreply,
         socket
         |> put_flash(:error, "This board is locked and not accepting new threads")
         |> redirect(to: ~p"/forum/b/#{board.slug}")}

      {:error, :silenced} ->
        {:noreply,
         socket
         |> put_flash(:error, "Your account is silenced and cannot create threads")
         |> redirect(to: ~p"/forum/b/#{board.slug}")}

      {:error, changeset} ->
        {:noreply, assign_composer(socket, changeset, params)}
    end
  end

  # Only these fields may be set from the composer form. Everything else
  # (moderation/state fields) is dropped before it can reach the changeset.
  defp allowed_params(thread_params) do
    thread_params
    |> Params.normalize()
    |> Map.take(["title", "body", "slug", "kind"])
  end

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories}
      flash={@flash}
      current_user={@current_user}
      unread_notification_count={@unread_notification_count}
      current_board={@board.slug}
    >
      <div id="new-thread-page">
        <header id="new-thread-header" class="ui-page-header mb-5">
          <.link
            id="new-thread-back-link"
            navigate={~p"/forum/b/#{@board.slug}"}
            class="group inline-flex items-center gap-2 text-sm font-medium text-base-content/50 transition-colors hover:text-secondary"
          >
            <.um_icon
              name="hero-arrow-left"
              class="size-4 transition-transform group-hover:-translate-x-0.5"
            /> Back to {@board.name}
          </.link>

          <h1 class="mt-5 text-2xl font-bold tracking-tight text-base-content sm:text-3xl">
            Start a discussion
          </h1>
          <p class="mt-1 max-w-2xl text-sm text-base-content/55">
            Share a clear question, useful idea, or practical lesson with the community.
          </p>
        </header>

        <section
          id="new-thread-board-context"
          class="ui-card ui-card-compact mb-4 flex h-auto items-center gap-3 px-4 py-3"
          aria-label="Publishing destination"
        >
          <span class={[
            "badge badge-sm shrink-0",
            UrielmWeb.ForumColors.badge_class(@board.slug)
          ]}></span>
          <div class="min-w-0">
            <p class="truncate text-sm font-bold text-base-content">{@board.name}</p>
            <p class="text-xs text-base-content/45">
              Your discussion will be published to this board.
            </p>
          </div>
          <.um_icon name="hero-check-circle" class="ml-auto size-5 shrink-0 text-accent" />
        </section>

        <div class="grid items-start gap-4 lg:grid-cols-[minmax(0,1.5fr)_minmax(16rem,0.62fr)]">
          <section id="new-thread-composer" class="ui-card h-auto">
            <.form
              for={@thread_form}
              id="new-thread-form"
              phx-change="validate"
              phx-submit="save"
              phx-hook="DiscussionDraft"
              data-draft-key={"forum:new-thread:#{@board.id}:#{@current_user.id}"}
              class="p-4 sm:p-5"
            >
              <div>
                <div class="mb-2 flex items-center justify-between gap-4">
                  <label for="new-thread-title" class="text-sm font-bold text-base-content">
                    Title
                  </label>
                  <span id="new-thread-title-count" class="text-xs tabular-nums text-base-content/40">
                    {@title_count} / 300
                  </span>
                </div>
                <.input
                  field={@thread_form[:title]}
                  id="new-thread-title"
                  type="text"
                  placeholder="Summarize the discussion in one clear sentence"
                  class="input input-bordered h-11 min-h-11 w-full border-base-300 bg-base-100/75 text-base shadow-none transition focus:border-secondary focus:outline-none"
                  error_class="input-error"
                  maxlength="300"
                  phx-debounce="250"
                  required
                />
                <p class="mt-1.5 text-xs leading-5 text-base-content/40">
                  A specific title helps the right people find your discussion.
                </p>
              </div>

              <div class="mt-5">
                <div class="mb-2 flex items-center justify-between gap-4">
                  <label for="new-thread-body" class="text-sm font-bold text-base-content">
                    Discussion
                  </label>
                  <span id="new-thread-body-count" class="text-xs tabular-nums text-base-content/40">
                    {@body_count} / 10,000
                  </span>
                </div>
                <.input
                  field={@thread_form[:body]}
                  id="new-thread-body"
                  type="textarea"
                  placeholder="Add context, what you tried, and what kind of response would help…"
                  class="textarea textarea-bordered min-h-56 w-full resize-y border-base-300 bg-base-100/75 px-3.5 py-3 text-sm leading-7 shadow-none transition focus:border-secondary focus:outline-none sm:min-h-64"
                  error_class="textarea-error"
                  maxlength="10000"
                  phx-debounce="250"
                  required
                />
                <div class="mt-1.5 flex items-center gap-2 text-xs leading-5 text-base-content/40">
                  <.um_icon name="hero-pencil-square" class="size-4 shrink-0" />
                  Markdown is supported. Examples and relevant context make discussions easier to answer.
                </div>
              </div>

              <div class="mt-5 flex flex-col-reverse gap-3 border-t border-base-300/50 pt-4 sm:flex-row sm:items-center sm:justify-between">
                <p class="flex items-center gap-2 text-xs text-base-content/40">
                  <.um_icon name="hero-check-circle" class="size-4 text-accent" />
                  Drafts are kept on this device.
                </p>
                <div class="grid grid-cols-2 gap-2 sm:flex">
                  <.link
                    navigate={~p"/forum/b/#{@board.slug}"}
                    class="btn btn-ghost btn-sm rounded-full px-4"
                  >
                    Cancel
                  </.link>
                  <.button
                    id="new-thread-submit"
                    type="submit"
                    loading_label="Publishing…"
                    class="btn btn-primary btn-sm rounded-full px-5"
                  >
                    Publish discussion
                  </.button>
                </div>
              </div>
            </.form>
          </section>

          <aside class="grid gap-3 lg:sticky lg:top-20">
            <section
              id="new-thread-preview"
              class="ui-card h-auto p-4 sm:p-5"
              aria-labelledby="new-thread-preview-label"
            >
              <p id="new-thread-preview-label" class="ui-eyebrow">Live preview</p>
              <h2
                id="new-thread-preview-title"
                class="mt-3 break-words text-base font-bold leading-snug text-base-content"
              >
                {if @draft_title == "", do: "Your title will appear here", else: @draft_title}
              </h2>
              <div
                id="new-thread-preview-body"
                class="mt-3 min-h-14 break-words text-sm leading-6 text-base-content/60"
              >
                <%= if @draft_body == "" do %>
                  <p>Your formatted discussion will appear here as you write.</p>
                <% else %>
                  <.svelte
                    name="MarkdownRenderer"
                    props={%{content: @draft_body}}
                    socket={@socket}
                    ssr={false}
                  />
                <% end %>
              </div>
            </section>

            <section
              id="new-thread-guidance"
              class="ui-card h-auto p-4 sm:p-5"
              aria-labelledby="new-thread-guidance-title"
            >
              <div class="flex items-center gap-2 text-secondary">
                <.um_icon name="hero-sparkles" class="size-5" />
                <h2 id="new-thread-guidance-title" class="text-sm font-bold text-base-content">
                  A useful discussion
                </h2>
              </div>
              <ul class="mt-3 space-y-2.5 text-sm leading-5 text-base-content/55">
                <li class="flex gap-3">
                  <span class="mt-2 size-1.5 shrink-0 rounded-full bg-secondary"></span>
                  Lead with the goal or question.
                </li>
                <li class="flex gap-3">
                  <span class="mt-2 size-1.5 shrink-0 rounded-full bg-accent"></span>
                  Add context and explain what you tried.
                </li>
                <li class="flex gap-3">
                  <span class="mt-2 size-1.5 shrink-0 rounded-full bg-info"></span>
                  Say what a helpful answer would look like.
                </li>
              </ul>
            </section>
          </aside>
        </div>
      </div>
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  defp assign_composer(socket, changeset, params) do
    title = Map.get(params, "title", "") || ""
    body = Map.get(params, "body", "") || ""

    socket
    |> assign(:thread_form, to_form(changeset))
    |> assign(:draft_title, title)
    |> assign(:draft_body, body)
    |> assign(:title_count, String.length(title))
    |> assign(:body_count, String.length(body))
  end
end
