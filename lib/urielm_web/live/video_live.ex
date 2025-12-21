defmodule UrielmWeb.VideoLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Content
  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, session, socket) do
    # Handle both direct mount and child mount via live_render
    slug = case params do
      %{"slug" => slug} -> slug
      :not_mounted_at_router -> session["child_params"]["slug"]
    end

    video =
      try do
        Content.get_video_by_slug!(slug)
      rescue
        Ecto.NoResultsError ->
          # Video not found - will handle below
          nil
      end

    if is_nil(video) do
      {:ok,
       socket
       |> put_flash(:error, "Video not found")
       |> redirect(to: ~p"/")}
    else

    %{current_user: user} = socket.assigns

    # Enforce published check (unpublished = admin only)
    if not Content.video_published?(video) and (is_nil(user) or not user.is_admin) do
      {:ok,
       socket
       |> put_flash(:error, "This video is not yet published")
       |> redirect(to: ~p"/")}
    else
      # Enforce visibility authorization
      if not Content.can_view_video?(user, video) do
        handle_unauthorized(socket, video, user)
      else
        # Load thread and comments if thread_id present
        {thread, comment_tree} = load_thread_and_comments(video, user)

        completed = if user, do: Content.completed_video?(user, video), else: false

        nav_items = build_nav_items(video, thread)

        {:ok,
         socket
         |> assign(:page_title, video.title)
         |> assign(:video, video)
         |> assign(:completed, completed)
         |> assign(:thread, thread)
         |> assign(:comment_tree, comment_tree)
         |> assign(:nav_items, nav_items)
         |> assign(:active_section, "description")
         |> assign_meta_tags(video, slug)}
      end
    end
    end
  end

  defp handle_unauthorized(socket, video, nil) do
    # Not signed in - redirect to sign in
    message =
      case video.visibility do
        "signed_in" -> "Sign in to watch this video"
        "subscriber" -> "Subscribe to watch this video"
        _ -> "You cannot access this video"
      end

    {:ok,
     socket
     |> put_flash(:info, message)
     |> redirect(to: ~p"/signin")}
  end

  defp handle_unauthorized(socket, video, _user) do
    # Signed in but not authorized (e.g., not subscribed)
    message =
      case video.visibility do
        "subscriber" -> "Subscribe to access this video"
        _ -> "You do not have permission to view this video"
      end

    {:ok,
     socket
     |> put_flash(:error, message)
     |> redirect(to: ~p"/")}
  end

  defp load_thread_and_comments(%{thread_id: nil}, _user), do: {nil, []}

  defp load_thread_and_comments(%{thread_id: thread_id}, user) do
    thread = Forum.get_thread!(thread_id, include_comments?: true)
    comment_tree = LiveHelpers.build_comment_tree(thread.comments, user)
    {thread, comment_tree}
  end

  defp build_nav_items(video, _thread) do
    items = []

    items =
      if video.description_md && video.description_md != "",
        do: items ++ [%{key: "description", label: "Description"}],
        else: items

    items =
      if video.resources_md && video.resources_md != "",
        do: items ++ [%{key: "resources", label: "Resources"}],
        else: items

    items =
      if video.author_name,
        do: items ++ [%{key: "author", label: "About the Author"}],
        else: items

    items
  end

  defp assign_meta_tags(socket, video, slug) do
    description = strip_markdown_and_truncate(video.description_md, 160)
    canonical_url = url(~p"/videos/#{slug}")

    socket
    |> assign(:meta_description, description)
    |> assign(:canonical_url, canonical_url)
    |> assign(:og_title, video.title)
    |> assign(:og_type, "video.other")
  end

  defp strip_markdown_and_truncate(nil, _length), do: ""
  defp strip_markdown_and_truncate("", _length), do: ""

  defp strip_markdown_and_truncate(markdown, max_length) do
    markdown
    |> String.replace(~r/#+ /, "")
    |> String.replace(~r/\*\*(.+?)\*\*/, "\\1")
    |> String.replace(~r/\*(.+?)\*/, "\\1")
    |> String.replace(~r/\[(.+?)\]\(.+?\)/, "\\1")
    |> String.replace(~r/`(.+?)`/, "\\1")
    |> String.trim()
    |> String.slice(0, max_length)
  end

  @impl true
  def handle_event("tab_change", %{"key" => key}, socket) do
    {:noreply, assign(socket, :active_section, key)}
  end

  @impl true
  def handle_event("mark_video_complete", _params, socket) do
    %{current_user: user, video: video} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to track progress")}

      user ->
        case Content.mark_video_complete(user, video) do
          {:ok, _completion} ->
            {:noreply, assign(socket, :completed, true)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to mark complete")}
        end
    end
  end

  @impl true
  def handle_event("unmark_video_complete", _params, socket) do
    %{current_user: user, video: video} = socket.assigns

    case user do
      nil ->
        {:noreply, socket}

      user ->
        case Content.unmark_video_complete(user, video) do
          {:ok, _count} ->
            {:noreply, assign(socket, :completed, false)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to unmark")}
        end
    end
  end

  @impl true
  def handle_event("create_comment", %{"body" => body} = params, socket) do
    %{current_user: user, thread: thread} = socket.assigns

    cond do
      is_nil(user) ->
        {:noreply, put_flash(socket, :error, "Sign in to comment")}

      is_nil(thread) ->
        {:noreply, put_flash(socket, :error, "Comments not enabled for this video")}

      true ->
        thread_id = thread.id
        parent_id = Map.get(params, "parent_id")

        attrs = %{"body" => body}
        attrs = if parent_id, do: Map.put(attrs, "parent_id", parent_id), else: attrs

        case Forum.create_comment(thread_id, user.id, attrs) do
          {:ok, _comment} ->
            {:noreply,
             socket
             |> refresh_video_comments(user)
             |> put_flash(:info, "Comment posted")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to post comment")}
        end
    end
  end

  @impl true
  def handle_event("edit_comment", %{"id" => comment_id, "body" => body}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      user ->
        comment = Forum.get_comment!(comment_id)

        case Forum.edit_comment(comment, body, user) do
          {:ok, _} ->
            {:noreply,
             socket
             |> refresh_video_comments(user)
             |> put_flash(:info, "Comment updated")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Not authorized")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update comment")}
        end
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      user ->
        comment = Forum.get_comment!(comment_id)

        case Forum.remove_comment(comment, user) do
          {:ok, _} ->
            {:noreply,
             socket
             |> refresh_video_comments(user)
             |> put_flash(:info, "Comment deleted")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Not authorized")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to delete comment")}
        end
    end
  end

  defp refresh_video_comments(socket, user) do
    thread = Forum.get_thread!(socket.assigns.thread.id, include_comments?: true)
    comment_tree = LiveHelpers.build_comment_tree(thread.comments, user)

    socket
    |> assign(:thread, thread)
    |> assign(:comment_tree, comment_tree)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content pt-20">
        <div class="container mx-auto px-4 py-8 max-w-4xl">
          <!-- Video Header -->
          <div class="mb-6">
            <h1 class="text-4xl font-bold text-base-content mb-2">{@video.title}</h1>
          </div>

          <!-- YouTube Embed -->
          <div class="mb-8">
            <.svelte
              name="YouTubeEmbed"
              props={%{youtubeUrl: @video.youtube_url}}
              socket={@socket}
            />
          </div>

          <!-- Section Navigation -->
          <%= if length(@nav_items) > 0 do %>
            <div class="mb-8">
              <.svelte
                name="UnderlineNav"
                props={%{
                  items: @nav_items,
                  activeKey: @active_section,
                  showCounts: false,
                  size: "md"
                }}
                socket={@socket}
              />
            </div>
          <% end %>

          <!-- Description -->
          <%= if @video.description_md && @video.description_md != "" && @active_section == "description" do %>
            <div id="description" class="mb-8">
              <h2 class="text-2xl font-semibold text-base-content mb-4">Description</h2>
              <div class="prose prose-lg max-w-none">
                <.svelte
                  name="MarkdownRenderer"
                  props={%{content: @video.description_md}}
                  socket={@socket}
                />
              </div>
            </div>
          <% end %>

          <!-- Resources -->
          <%= if @video.resources_md && @video.resources_md != "" && @active_section == "resources" do %>
            <div id="resources" class="mb-8">
              <h2 class="text-2xl font-semibold text-base-content mb-4">Resources</h2>
              <div class="prose max-w-none">
                <.svelte
                  name="MarkdownRenderer"
                  props={%{content: @video.resources_md}}
                  socket={@socket}
                />
              </div>
            </div>
          <% end %>

          <!-- Author Credit -->
          <%= if @video.author_name && @active_section == "author" do %>
            <div id="author" class="mb-8 p-6 bg-base-200 rounded-lg">
              <h3 class="text-lg font-semibold text-base-content mb-2">About the Author</h3>
              <div class="flex items-start gap-4">
                <div>
                  <%= if @video.author_url do %>
                    <a href={@video.author_url} target="_blank" rel="noopener" class="link link-primary font-medium">
                      {@video.author_name}
                    </a>
                  <% else %>
                    <p class="font-medium text-base-content">{@video.author_name}</p>
                  <% end %>

                  <%= if @video.author_bio_md && @video.author_bio_md != "" do %>
                    <div class="mt-2 prose prose-sm max-w-none">
                      <.svelte
                        name="MarkdownRenderer"
                        props={%{content: @video.author_bio_md}}
                        socket={@socket}
                      />
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <!-- Comments Section (Always Visible) -->
          <%= if @thread do %>
            <div class="divider"></div>

            <div id="comments" class="mt-8">
              <!-- Comments Header -->
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-xl font-semibold text-base-content">
                  {@thread.comment_count} Comments
                </h2>
                <div class="dropdown dropdown-end">
                  <button tabindex="0" class="btn btn-ghost btn-sm gap-2">
                    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M3 18h6v-2H3v2zM3 6v2h18V6H3zm0 7h12v-2H3v2z"/>
                    </svg>
                    Sort by
                  </button>
                  <ul tabindex="0" class="dropdown-content menu bg-base-200 rounded-box z-[1] w-40 p-2 shadow">
                    <li><a>Top</a></li>
                    <li><a>Newest</a></li>
                  </ul>
                </div>
              </div>

              <!-- Add Comment Form -->
              <%= if @current_user do %>
                <div class="flex gap-3 mb-8">
                  <div class="avatar placeholder">
                    <div class="bg-primary text-primary-content w-10 h-10 rounded-full">
                      <span class="text-sm">
                        {String.upcase(String.slice(@current_user.username || @current_user.email || "U", 0, 1))}
                      </span>
                    </div>
                  </div>
                  <div class="flex-1">
                    <form phx-submit="create_comment" class="space-y-3">
                      <textarea
                        name="body"
                        placeholder="Add a comment..."
                        required
                        class="textarea textarea-ghost w-full focus:textarea-bordered bg-transparent resize-none"
                        rows="1"
                        onfocus="this.rows=3"
                        onblur="if(!this.value) this.rows=1"
                      ></textarea>
                      <div class="flex justify-end gap-2">
                        <button type="submit" class="btn btn-primary btn-sm">Comment</button>
                      </div>
                    </form>
                  </div>
                </div>
              <% else %>
                <div class="flex gap-3 mb-8 items-center p-4 bg-base-200/50 rounded-lg">
                  <div class="avatar placeholder">
                    <div class="bg-base-300 w-10 h-10 rounded-full">
                      <span class="text-sm">?</span>
                    </div>
                  </div>
                  <span class="text-base-content/70">
                    <.link navigate={~p"/signin"} class="link link-primary">Sign in</.link>
                    to comment
                  </span>
                </div>
              <% end %>

              <.svelte
                name="CommentTree"
                props={%{
                  comments: @comment_tree,
                  current_user_id: (@current_user && @current_user.id) || nil,
                  current_user_is_admin: (@current_user && @current_user.is_admin) || false,
                  thread_author_id: @thread.author_id,
                  solved_comment_id: nil
                }}
                socket={@socket}
              />
            </div>
          <% end %>
        </div>
    </div>
    """
  end
end
