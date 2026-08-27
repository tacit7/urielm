defmodule UrielmWeb.TagsLive do
  use UrielmWeb, :live_view

  alias Urielm.Forum

  @impl true
  def mount(_params, _session, socket) do
    categories = Forum.list_categories_with_boards()
    directory = Forum.list_tag_directory()

    tags_count =
      Enum.sum(Enum.map(directory.groups, &length(&1.tags))) + length(directory.ungrouped)

    {:ok,
     socket
     |> assign(:page_title, "Tags")
     |> assign(:all_categories, categories)
     |> assign(:tag_groups, directory.groups)
     |> assign(:ungrouped_tags, directory.ungrouped)
     |> assign(:tags_count, tags_count)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Components.ForumLayout.forum_layout
      categories={@all_categories}
      flash={@flash}
      current_user={@current_user}
      unread_notification_count={@unread_notification_count}
      current_path="/forum/tags"
    >
      <div id="forum-tags-page" class="mx-auto w-full max-w-5xl">
        <UrielmWeb.Components.ForumLayout.discovery_header
          active_view="tags"
          count_label={"#{@tags_count} tags"}
        />

        <section id="forum-tags-surface" class="ui-card h-auto overflow-hidden">
          <div class="flex flex-col gap-2 border-b border-base-300/40 bg-base-200/60 px-5 py-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h2 class="text-sm font-black uppercase tracking-[0.14em] text-base-content/50">
                Browse tags
              </h2>
              <p class="mt-1 text-sm text-base-content/45">
                Explore the tag directory and jump straight into the relevant discussions.
              </p>
            </div>
            <div
              id="forum-tags-management-note"
              class="rounded-lg border border-base-300/70 bg-base-100 px-3 py-2 text-xs text-base-content/55"
            >
              Tags are attached to threads. Browse a tag to review and manage the discussions using it.
            </div>
          </div>

          <.empty_state
            :if={@tags_count == 0}
            id="forum-tags-empty-state"
            title="No tags yet"
            description="Tags will appear here once discussions start using them."
            icon="hero-tag"
            compact
            class="rounded-none border-0 bg-transparent"
          />

          <div :if={@tags_count > 0} id="forum-tag-directory" class="divide-y divide-base-300/60">
            <section
              :for={group <- @tag_groups}
              id={"forum-tag-group-#{group_dom_slug(group)}"}
              class="bg-base-100/20"
            >
              <header class="border-b border-base-300/40 bg-base-200/35 px-5 py-4">
                <h3 class="font-black text-base-content">{group.name}</h3>
                <p :if={group.description} class="mt-1 text-sm text-base-content/50">
                  {group.description}
                </p>
              </header>
              <div class="divide-y divide-base-300/40">
                <.tag_row :for={tag <- group.tags} tag={tag} />
              </div>
            </section>

            <section :if={@ungrouped_tags != []} id="forum-ungrouped-tags">
              <header
                :if={@tag_groups != []}
                class="border-b border-base-300/40 bg-base-200/35 px-5 py-4"
              >
                <h3 class="font-black text-base-content">Other tags</h3>
              </header>
              <div class="divide-y divide-base-300/40">
                <.tag_row :for={tag <- @ungrouped_tags} tag={tag} />
              </div>
            </section>
          </div>
        </section>
      </div>
    </UrielmWeb.Components.ForumLayout.forum_layout>
    """
  end

  attr :tag, :map, required: true

  defp tag_row(assigns) do
    ~H"""
    <article
      id={"forum-tag-#{@tag.slug}"}
      class="grid grid-cols-1 gap-3 px-5 py-4 sm:grid-cols-[minmax(0,1fr)_8rem_10rem] sm:items-center"
    >
      <div class="min-w-0">
        <.link
          navigate={~p"/forum/tags/#{@tag.slug}"}
          class="inline-flex items-center gap-2 font-semibold text-base-content transition-colors hover:text-secondary"
        >
          <span class="badge badge-outline badge-secondary h-auto px-2 py-1 text-[0.65rem] font-bold uppercase tracking-[0.14em]">
            Tag
          </span>
          <span class="truncate">{@tag.name}</span>
        </.link>
        <p class="mt-1 truncate font-mono text-xs text-base-content/35">/{@tag.slug}</p>
      </div>

      <div class="sm:text-center">
        <div class="text-xs font-semibold uppercase tracking-[0.14em] text-base-content/35">
          Discussions
        </div>
        <div class="mt-1 font-mono text-lg font-black text-base-content/70 tabular-nums">
          {@tag.thread_count}
        </div>
      </div>

      <div class="flex sm:justify-end">
        <.link
          navigate={~p"/forum/tags/#{@tag.slug}"}
          class="btn btn-ghost btn-sm border border-base-300/70 bg-base-100"
        >
          Browse threads
        </.link>
      </div>
    </article>
    """
  end

  defp group_dom_slug(group) do
    slug =
      group.name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/u, "-")
      |> String.trim("-")

    if slug == "", do: group.id, else: slug
  end
end
