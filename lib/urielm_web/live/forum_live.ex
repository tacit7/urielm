defmodule UrielmWeb.ForumLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers
  alias UrielmWeb.ForumColors

  @impl true
  def mount(_params, _session, socket) do
    categories = Forum.list_categories_with_boards()
    current_user = socket.assigns[:current_user]

    {:ok,
     socket
     |> assign(:page_title, "Community")
     |> assign(:all_categories, categories)
     |> assign(:categories, serialize_categories(categories, current_user))}
  end

  @impl true
  def handle_event(
        "set_category_notification",
        %{"category_notification" => %{"category_id" => category_id, "level" => level}},
        socket
      ) do
    case socket.assigns[:current_user] do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to change category notifications")}

      user ->
        case Forum.set_category_watch_level(user.id, category_id, level) do
          {:ok, _watch} ->
            {:noreply,
             assign(
               socket,
               :categories,
               serialize_categories(socket.assigns.all_categories, user)
             )}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not update category notifications")}
        end
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
      current_path="/forum/categories"
    >
      <UrielmWeb.Components.ForumLayout.discovery_header
        active_view="categories"
        count_label={"#{Enum.sum(Enum.map(@categories, fn c -> length(c.boards) end))} boards"}
      />

      <.empty_state
        :if={@categories == []}
        id="forum-categories-empty-state"
        title="No categories yet"
        description="Community spaces will appear here as soon as they are available."
        icon="hero-chat-bubble-left-right"
        compact
      >
        <:action>
          <.link navigate={~p"/forum"} class="btn btn-ghost btn-sm rounded-full text-primary">
            View latest discussions <.um_icon name="hero-arrow-right" class="size-4" />
          </.link>
        </:action>
      </.empty_state>
      <%!-- Categories --%>
      <div :if={@categories != []} id="forum-categories" class="space-y-8">
        <.category_section :for={category <- @categories} category={category} />
      </div>
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  attr :category, :map, required: true

  defp category_section(assigns) do
    ~H"""
    <section id={"forum-category-#{@category.id}"}>
      <%!-- Category label --%>
      <div class="mb-3 flex flex-col gap-3 px-1 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h2 class="ui-eyebrow text-base-content/55">
            {@category.name}
          </h2>
          <span class="text-xs text-base-content/30">{length(@category.boards)} boards</span>
        </div>

        <details
          :if={@category.notification_form}
          id={"category-notification-disclosure-#{@category.id}"}
          class="group w-full sm:w-52"
        >
          <summary
            class="flex min-h-8 cursor-pointer list-none items-center justify-between gap-2 rounded-lg border border-base-300/60 bg-base-100/45 px-2.5 text-xs font-semibold text-base-content/55 transition hover:text-base-content sm:px-3 [&::-webkit-details-marker]:hidden"
            aria-label={"#{@category.name} notification settings"}
          >
            <.um_icon name="bell" class="size-3.5 text-base-content/45 sm:hidden" />
            <span class="hidden sm:inline">Notifications</span>
            <.um_icon
              name="hero-chevron-down"
              class="size-3.5 transition-transform group-open:rotate-180"
            />
          </summary>
          <.form
            for={@category.notification_form}
            id={"category-notification-form-#{@category.id}"}
            phx-change="set_category_notification"
            class="mt-2"
          >
            <input
              type="hidden"
              name={@category.notification_form[:category_id].name}
              value={@category.notification_form[:category_id].value}
            />
            <.input
              field={@category.notification_form[:level]}
              id={"category-notification-level-#{@category.id}"}
              type="select"
              label="Level"
              options={[
                {"Regular", "normal"},
                {"Watching", "watching"},
                {"Tracking", "tracking"},
                {"Muted", "muted"}
              ]}
              help={notification_help(@category.notification_form[:level].value)}
              class="select select-bordered select-sm w-full bg-base-100 transition-colors focus:border-primary"
            />
          </.form>
        </details>
      </div>

      <%!-- Board table --%>
      <div id={"forum-category-surface-#{@category.id}"} class="ui-card ui-card-compact h-auto">
        <%!-- Column headers --%>
        <div class="hidden border-b border-base-300/40 bg-base-200/60 px-4 py-2 md:grid md:grid-cols-[minmax(0,1fr)_220px_72px_72px]">
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider">Board</span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider">Latest</span>
          <span class="font-mono text-xs text-base-content/30 uppercase tracking-wider text-center">
            Topics
          </span>
          <span class="text-right font-mono text-xs uppercase tracking-wider text-base-content/30">Posts</span>
        </div>

        <%!-- Board rows --%>
        <div class="divide-y divide-base-300/40">
          <.board_row :for={board <- @category.boards} board={board} />
        </div>
      </div>
    </section>
    """
  end

  attr :board, :map, required: true

  defp board_row(assigns) do
    hex = ForumColors.icon_color(assigns.board.slug)

    assigns =
      assign(
        assigns,
        :icon_style,
        "background: #{hex};"
      )

    ~H"""
    <a
      id={"forum-board-#{@board.id}"}
      href={~p"/forum/b/#{@board.slug}"}
      class="group grid grid-cols-1 items-center gap-x-4 gap-y-2 px-4 py-3 transition-colors duration-150 hover:bg-base-200/55 focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-primary md:grid-cols-[minmax(0,1fr)_220px_72px_72px]"
    >
      <%!-- Board info --%>
      <div class="flex min-w-0 items-center gap-3">
        <div
          class="w-9 h-9 rounded-lg flex-shrink-0 flex items-center justify-center text-white text-sm font-bold select-none"
          style={@icon_style}
        >
          {String.first(@board.name)}
        </div>
        <div class="min-w-0">
          <h3 class="font-semibold text-sm text-base-content group-hover:text-secondary transition-colors duration-150 truncate">
            {@board.name}
          </h3>
          <p
            :if={@board.description}
            class="text-xs text-base-content/45 line-clamp-1 leading-relaxed"
          >
            {@board.description}
          </p>
        </div>
      </div>

      <%!-- Latest thread --%>
      <div class="min-w-0 pl-12 md:block md:pl-0">
        <%= if @board.latest_thread_title do %>
          <span class="block text-xs text-base-content/65 group-hover:text-secondary truncate leading-snug transition-colors">
            {@board.latest_thread_title}
          </span>
          <span class="font-mono text-xs text-base-content/30">
            {LiveHelpers.format_short(@board.last_activity_at)}
          </span>
        <% else %>
          <span class="font-mono text-xs text-base-content/20">—</span>
        <% end %>
      </div>

      <%!-- Topic count --%>
      <div class="flex items-center gap-4 pl-12 md:block md:pl-0 md:text-center">
        <span class="font-mono text-sm text-base-content/60 tabular-nums">
          {@board.thread_count}
        </span>
        <span class="text-xs text-base-content/35 md:hidden">topics</span>
      </div>

      <div class="flex items-center gap-4 pl-12 md:block md:pl-0 md:text-right">
        <span class="font-mono text-sm text-base-content/60 tabular-nums">
          {@board.post_count}
        </span>
        <span class="text-xs text-base-content/35 md:hidden">posts</span>
      </div>
    </a>
    """
  end

  defp serialize_categories(categories, current_user) do
    watch_levels =
      if current_user do
        Forum.list_category_watch_levels(current_user.id, Enum.map(categories, & &1.id))
      else
        %{}
      end

    Enum.map(categories, fn category ->
      notification_form =
        if current_user do
          to_form(
            %{
              "category_id" => to_string(category.id),
              "level" => Map.get(watch_levels, category.id, "normal")
            },
            as: :category_notification
          )
        end

      %{
        id: to_string(category.id),
        name: category.name,
        slug: category.slug,
        notification_form: notification_form,
        boards: serialize_boards(category.boards)
      }
    end)
  end

  defp serialize_boards(boards) do
    Enum.map(boards, fn board ->
      %{
        id: to_string(board.id),
        name: board.name,
        slug: board.slug,
        description: board.description,
        thread_count: board.thread_count || 0,
        post_count: board.post_count || 0,
        last_activity_at: board.last_activity_at,
        latest_thread_title: board.latest_thread_title,
        latest_thread_id: board.latest_thread_id
      }
    end)
  end

  defp notification_help("watching"), do: "Every new topic and reply"
  defp notification_help("tracking"), do: "Unread activity, without every alert"
  defp notification_help("muted"), do: "No category alerts or unread noise"
  defp notification_help(_level), do: "Topic-level defaults"
end
