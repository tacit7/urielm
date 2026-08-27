defmodule UrielmWeb.Admin.TagManagementLive do
  use UrielmWeb, :live_view

  import UrielmWeb.AdminComponents

  alias Urielm.Forum
  alias Urielm.Forum.Tag
  alias Urielm.Forum.TagGroup

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Tag management")
     |> assign(:editing_tag, nil)
     |> assign(:editing_tag_group, nil)
     |> assign(:tag_form, tag_form())
     |> assign(:tag_group_form, tag_group_form())
     |> refresh_directory()}
  end

  @impl true
  def handle_event("save_tag", %{"tag" => attrs}, socket) do
    result =
      case socket.assigns.editing_tag do
        nil -> Forum.create_tag(attrs)
        tag -> Forum.update_tag(tag, attrs)
      end

    case result do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> assign(:editing_tag, nil)
         |> assign(:tag_form, tag_form())
         |> refresh_directory()
         |> put_flash(:info, "Tag saved")}

      {:error, changeset} ->
        {:noreply, assign(socket, :tag_form, to_form(changeset))}
    end
  end

  def handle_event("edit_tag", %{"id" => id}, socket) do
    tag = Forum.get_tag!(id)
    {:noreply, assign(socket, editing_tag: tag, tag_form: tag_form(tag))}
  end

  def handle_event("cancel_tag", _params, socket) do
    {:noreply, assign(socket, editing_tag: nil, tag_form: tag_form())}
  end

  def handle_event("delete_tag", %{"id" => id}, socket) do
    id |> Forum.get_tag!() |> Forum.delete_tag()

    {:noreply,
     socket
     |> assign(:editing_tag, nil)
     |> assign(:tag_form, tag_form())
     |> refresh_directory()
     |> put_flash(:info, "Tag deleted")}
  end

  def handle_event("save_tag_group", %{"tag_group" => attrs}, socket) do
    tag_ids = Map.get(attrs, "tag_ids", [])

    result =
      case socket.assigns.editing_tag_group do
        nil -> Forum.create_tag_group(attrs, tag_ids)
        tag_group -> Forum.update_tag_group(tag_group, attrs, tag_ids)
      end

    case result do
      {:ok, _tag_group} ->
        {:noreply,
         socket
         |> assign(:editing_tag_group, nil)
         |> assign(:tag_group_form, tag_group_form())
         |> refresh_directory()
         |> put_flash(:info, "Tag group saved")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :tag_group_form, to_form(changeset))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not save tag group")}
    end
  end

  def handle_event("edit_tag_group", %{"id" => id}, socket) do
    tag_group = Forum.get_tag_group!(id)

    {:noreply,
     assign(socket,
       editing_tag_group: tag_group,
       tag_group_form: tag_group_form(tag_group)
     )}
  end

  def handle_event("cancel_tag_group", _params, socket) do
    {:noreply, assign(socket, editing_tag_group: nil, tag_group_form: tag_group_form())}
  end

  def handle_event("delete_tag_group", %{"id" => id}, socket) do
    id |> Forum.get_tag_group!() |> Forum.delete_tag_group()

    {:noreply,
     socket
     |> assign(:editing_tag_group, nil)
     |> assign(:tag_group_form, tag_group_form())
     |> refresh_directory()
     |> put_flash(:info, "Tag group deleted")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="admin"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div id="admin-tag-management-page" class="ui-page-shell max-w-7xl">
        <header class="ui-page-header ui-page-heading">
          <p class="ui-eyebrow text-primary">Forum organization</p>
          <h1 class="ui-section-title">Tag management</h1>
          <p class="ui-section-copy">
            Create durable tags and organize the public tag directory into clear groups.
          </p>
        </header>

        <.admin_nav current="tags" />

        <div class="grid gap-6 xl:grid-cols-2">
          <section id="admin-tags-panel" class="ui-card h-auto p-5 sm:p-6">
            <div class="mb-5">
              <h2 class="text-lg font-black text-base-content">Tags</h2>
              <p class="mt-1 text-sm text-base-content/55">
                Editing a slug changes its browse URL. Deleting a tag removes it from discussions.
              </p>
            </div>

            <.form
              for={@tag_form}
              id="admin-tag-form"
              phx-submit="save_tag"
              class="mb-6 grid gap-3 sm:grid-cols-2"
            >
              <.input field={@tag_form[:name]} label="Name" placeholder="Question" />
              <.input field={@tag_form[:slug]} label="Slug" placeholder="question" />
              <div class="flex gap-2 sm:col-span-2">
                <button id="save-tag" type="submit" class="btn btn-primary btn-sm">
                  {if @editing_tag, do: "Update tag", else: "Create tag"}
                </button>
                <button
                  :if={@editing_tag}
                  id="cancel-tag"
                  type="button"
                  phx-click="cancel_tag"
                  class="btn btn-ghost btn-sm"
                >
                  Cancel
                </button>
              </div>
            </.form>

            <div id="admin-tags" class="divide-y divide-base-300/50 border-t border-base-300/50">
              <p :if={@tags == []} class="py-5 text-sm text-base-content/50">No tags yet.</p>
              <article
                :for={tag <- @tags}
                id={"admin-tag-#{tag.id}"}
                class="flex items-center justify-between gap-4 py-4"
              >
                <div class="min-w-0">
                  <p class="font-bold">{tag.name}</p><p class="truncate font-mono text-xs text-base-content/40">
                    /{tag.slug}
                  </p>
                </div>
                <div class="flex gap-2">
                  <button
                    id={"edit-tag-#{tag.id}"}
                    type="button"
                    phx-click="edit_tag"
                    phx-value-id={tag.id}
                    class="btn btn-ghost btn-xs"
                  >Edit</button>
                  <button
                    id={"delete-tag-#{tag.id}"}
                    type="button"
                    phx-click="delete_tag"
                    phx-value-id={tag.id}
                    data-confirm="Delete this tag and remove it from every discussion?"
                    class="btn btn-ghost btn-xs text-error"
                  >Delete</button>
                </div>
              </article>
            </div>
          </section>

          <section id="admin-tag-groups-panel" class="ui-card h-auto p-5 sm:p-6">
            <div class="mb-5">
              <h2 class="text-lg font-black text-base-content">Tag groups</h2><p class="mt-1 text-sm text-base-content/55">
                Each tag belongs to at most one directory group.
              </p>
            </div>

            <.form
              for={@tag_group_form}
              id="admin-tag-group-form"
              phx-submit="save_tag_group"
              class="mb-6 space-y-3"
            >
              <.input field={@tag_group_form[:name]} label="Group name" placeholder="Workflow" />
              <.input
                field={@tag_group_form[:description]}
                type="textarea"
                label="Description"
                placeholder="How discussions are framed"
              />
              <.input
                field={@tag_group_form[:tag_ids]}
                type="select"
                multiple
                label="Tags"
                options={@tag_options}
                class="select select-bordered min-h-32 w-full rounded-xl border-base-300 bg-base-100/70"
              />
              <div class="flex gap-2">
                <button id="save-tag-group" type="submit" class="btn btn-primary btn-sm">{if @editing_tag_group,
                  do: "Update group",
                  else: "Create group"}</button>
                <button
                  :if={@editing_tag_group}
                  id="cancel-tag-group"
                  type="button"
                  phx-click="cancel_tag_group"
                  class="btn btn-ghost btn-sm"
                >Cancel</button>
              </div>
            </.form>

            <div id="admin-tag-groups" class="space-y-3 border-t border-base-300/50 pt-4">
              <p :if={@tag_groups == []} class="text-sm text-base-content/50">No groups yet.</p>
              <article
                :for={group <- @tag_groups}
                id={"admin-tag-group-#{group.id}"}
                class="rounded-xl border border-base-300/60 bg-base-100/45 p-4"
              >
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <h3 class="font-black">{group.name}</h3><p
                      :if={group.description}
                      class="mt-1 text-sm text-base-content/50"
                    >
                      {group.description}
                    </p>
                  </div><div class="flex gap-2">
                    <button
                      id={"edit-tag-group-#{group.id}"}
                      type="button"
                      phx-click="edit_tag_group"
                      phx-value-id={group.id}
                      class="btn btn-ghost btn-xs"
                    >Edit</button><button
                      id={"delete-tag-group-#{group.id}"}
                      type="button"
                      phx-click="delete_tag_group"
                      phx-value-id={group.id}
                      data-confirm="Delete this group? Its tags will remain available."
                      class="btn btn-ghost btn-xs text-error"
                    >Delete</button>
                  </div>
                </div>
                <div class="mt-3 flex flex-wrap gap-2">
                  <span :for={tag <- group.tags} class="badge badge-outline badge-secondary">{tag.name}</span><span
                    :if={group.tags == []}
                    class="text-xs text-base-content/40"
                  >No tags assigned</span>
                </div>
              </article>
            </div>
          </section>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp refresh_directory(socket) do
    tags = Forum.list_tags()

    socket
    |> assign(:tags, tags)
    |> assign(:tag_groups, Forum.list_tag_groups_with_tags())
    |> assign(:tag_options, Enum.map(tags, &{&1.name, &1.id}))
  end

  defp tag_form(tag \\ %Tag{}), do: tag |> Tag.changeset(%{}) |> to_form()

  defp tag_group_form(tag_group \\ %TagGroup{}) do
    tag_ids =
      if Ecto.assoc_loaded?(tag_group.tags), do: Enum.map(tag_group.tags, & &1.id), else: []

    tag_group
    |> TagGroup.changeset(%{tag_ids: tag_ids})
    |> to_form()
  end
end
