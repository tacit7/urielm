defmodule UrielmWeb.VideoLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Content
  alias Urielm.Forum
  alias Urielm.Engagement
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, session, socket) do
    # Handle both direct mount and child mount via live_render
    child_params =
      case params do
        :not_mounted_at_router -> session["child_params"] || %{}
        params -> params
      end

    slug = child_params["slug"]

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

          # Load vote data
          {upvotes, downvotes, _score} = Engagement.get_vote_counts("video", video.id)
          user_vote = if user, do: Engagement.get_vote(user.id, "video", video.id), else: nil

          {:ok,
           socket
           |> assign(:page_title, video.title)
           |> assign(:video, video)
           |> assign(:completed, completed)
           |> assign(:thread, thread)
           |> assign(:comment_tree, comment_tree)
           |> assign(:nav_items, nav_items)
           |> assign(:active_section, "description")
           |> assign(:dock_tab, "home")
           |> assign(:reporting_comment_id, nil)
           |> assign(:upvotes, upvotes)
           |> assign(:downvotes, downvotes)
           |> assign(:user_vote, user_vote && user_vote.value)
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

  defp build_nav_items(video, thread) do
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
        do: items ++ [%{key: "author", label: "About"}],
        else: items

    # Add comments tab if thread exists
    items =
      if thread,
        do: items ++ [%{key: "comments", label: "Comments", count: thread.comment_count}],
        else: items

    items
  end

  # Visibility helper for mobile dock + desktop tabs
  # Mobile: show if dock_tab matches
  # Desktop: show if active_section matches
  defp section_visibility(dock_tab, active_section, mobile_key, desktop_key) do
    mobile_matches = dock_tab == mobile_key
    desktop_matches = active_section == desktop_key

    case {mobile_matches, desktop_matches} do
      {true, true} -> ""
      {true, false} -> "lg:hidden"
      {false, true} -> "hidden lg:block"
      {false, false} -> "hidden"
    end
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

  defp extract_youtube_id(nil), do: nil
  defp extract_youtube_id(""), do: nil

  defp extract_youtube_id(url) do
    patterns = [
      ~r/youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/,
      ~r/youtu\.be\/([a-zA-Z0-9_-]{11})/,
      ~r/youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/,
      ~r/youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/
    ]

    Enum.find_value(patterns, fn pattern ->
      case Regex.run(pattern, url) do
        [_, id] -> id
        _ -> nil
      end
    end)
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
  def handle_event("set_dock_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :dock_tab, tab)}
  end

  @impl true
  def handle_event("vote", %{"target_type" => "video", "target_id" => id, "value" => value}, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to vote")}

      user ->
        value_int = String.to_integer(value)

        case Engagement.toggle_vote(user.id, "video", id, value_int) do
          {:ok, _} ->
            # Refresh vote counts
            {upvotes, downvotes, _score} = Engagement.get_vote_counts("video", id)
            user_vote = Engagement.get_vote(user.id, "video", id)

            {:noreply,
             socket
             |> assign(:upvotes, upvotes)
             |> assign(:downvotes, downvotes)
             |> assign(:user_vote, user_vote && user_vote.value)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to vote")}
        end
    end
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

  @impl true
  def handle_event("open_report_comment", %{"comment_id" => comment_id}, socket) do
    {:noreply,
     socket
     |> assign(:reporting_comment_id, comment_id)
     |> push_event("open_modal", %{"id" => "report_comment_modal"})}
  end

  @impl true
  def handle_event(
        "report_comment",
        %{"comment_id" => comment_id, "reason" => reason, "description" => description},
        socket
      ) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to report")}

      user ->
        case Forum.create_report(user.id, "comment", comment_id, %{
               reason: reason,
               description: description
             }) do
          {:ok, _report} ->
            {:noreply,
             socket
             |> put_flash(:info, "Report submitted successfully")
             |> push_event("close_modal", %{"id" => "report_comment_modal"})}

          {:error, :unique_constraint} ->
            {:noreply, put_flash(socket, :error, "You've already reported this")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to submit report")}
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
    if assigns.video.format == "short" do
      render_short(assigns)
    else
      render_standard(assigns)
    end
  end

  defp render_short(assigns) do
    ~H"""
    <!-- DaisyUI Drawer wrapper for comments -->
    <div class="drawer drawer-end">
      <input id="comments-drawer" type="checkbox" class="drawer-toggle" />

      <!-- Main content -->
      <div class="drawer-content">
        <!-- Full-screen vertical snap feed -->
        <div class="h-screen w-screen overflow-y-scroll snap-y snap-mandatory overscroll-contain bg-black text-white">
          <!-- Feed item (single video for now) -->
          <section class="relative h-screen w-screen snap-start">
            <!-- Video container - full bleed -->
            <div class="absolute inset-0">
              <%= if @video.tiktok_url && @video.tiktok_url != "" do %>
                <.svelte
                  name="TikTokEmbed"
                  props={%{tiktokUrl: @video.tiktok_url, fullscreen: true}}
                  socket={@socket}
                  class="h-full w-full object-cover"
                />
              <% else %>
                <.svelte
                  name="YouTubePlayer"
                  props={%{videoId: extract_youtube_id(@video.youtube_url), controls: true, shorts: true}}
                  socket={@socket}
                  class="h-full w-full object-cover"
                />
              <% end %>

              <!-- Gradient overlay for legibility -->
              <div class="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-black/20"></div>
            </div>

            <!-- Right action rail -->
            <aside class="absolute right-3 bottom-24 z-10 flex flex-col items-center gap-3 text-white">
              <!-- Vote Buttons (vertical layout for shorts) -->
              <.svelte
                name="VoteButtons"
                props={%{
                  target_type: "video",
                  target_id: @video.id,
                  upvotes: @upvotes,
                  downvotes: @downvotes,
                  user_vote: @user_vote,
                  layout: "vertical",
                  size: "lg"
                }}
                socket={@socket}
              />

              <!-- Comments drawer trigger -->
              <%= if @thread do %>
                <label for="comments-drawer" class="btn btn-ghost btn-circle text-white hover:text-primary cursor-pointer" aria-label="Comments">
                  <svg class="h-7 w-7" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <path stroke-width="2" d="M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z"/>
                  </svg>
                </label>
                <span class="text-xs opacity-80">{@thread.comment_count}</span>
              <% end %>

              <!-- Share -->
              <button class="btn btn-ghost btn-circle text-white hover:text-primary" aria-label="Share">
                <svg class="h-7 w-7" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                  <path stroke-width="2" d="M4 12v7a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-7"/>
                  <path stroke-width="2" d="M16 6l-4-4-4 4"/>
                  <path stroke-width="2" d="M12 2v14"/>
                </svg>
              </button>
              <span class="text-xs opacity-80">Share</span>
            </aside>

            <!-- Bottom metadata -->
            <div class="absolute left-0 right-16 bottom-0 z-10 p-4 pb-6">
              <div class="max-w-[85%] space-y-2">
                <!-- Author info -->
                <%= if @video.author_name do %>
                  <div class="flex items-center gap-2">
                    <div class="avatar placeholder">
                      <div class="w-10 rounded-full bg-primary text-primary-content">
                        <span class="text-sm font-semibold">
                          {String.upcase(String.slice(@video.author_name, 0, 1))}
                        </span>
                      </div>
                    </div>
                    <%= if @video.author_url do %>
                      <a href={@video.author_url} target="_blank" rel="noopener" class="font-semibold hover:underline">
                        @{@video.author_name}
                      </a>
                    <% else %>
                      <span class="font-semibold">@{@video.author_name}</span>
                    <% end %>
                    <button class="btn btn-xs btn-outline btn-white">Follow</button>
                  </div>
                <% end %>

                <!-- Title/Caption -->
                <p class="text-sm leading-snug line-clamp-3">{@video.title}</p>

                <!-- Description if exists -->
                <%= if @video.description_md && @video.description_md != "" do %>
                  <p class="text-sm opacity-80 line-clamp-2">{@video.description_md}</p>
                <% end %>

                <!-- Tags/metadata -->
                <div class="flex items-center gap-2 text-xs opacity-80">
                  <span class="badge badge-ghost badge-sm">Short</span>
                  <%= if @video.visibility != "public" do %>
                    <span class="badge badge-ghost badge-sm">{@video.visibility}</span>
                  <% end %>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>

      <!-- Comments Drawer (slides in from right) -->
      <div class="drawer-side z-50">
        <label for="comments-drawer" aria-label="close sidebar" class="drawer-overlay"></label>

        <div class="menu w-full max-w-md bg-base-100 text-base-content min-h-full p-0">
          <!-- Header -->
          <div class="flex items-center justify-between p-4 border-b border-base-300">
            <h2 class="text-lg font-semibold">
              Comments <%= if @thread, do: @thread.comment_count, else: 0 %>
            </h2>
            <label for="comments-drawer" class="btn btn-sm btn-ghost btn-circle">✕</label>
          </div>

          <!-- Comments list -->
          <div class="flex-1 overflow-y-auto p-4 max-h-[calc(100vh-140px)]">
            <%= if @thread do %>
              <.svelte
                name="CommentTree"
                props={
                  %{
                    comments: @comment_tree,
                    current_user_id: (@current_user && @current_user.id) || nil,
                    current_user_is_admin: (@current_user && @current_user.is_admin) || false,
                    thread_author_id: @thread.author_id,
                    solved_comment_id: nil,
                    compact: true
                  }
                }
                socket={@socket}
              />
            <% else %>
              <p class="text-sm text-base-content/60 text-center py-8">
                Comments not enabled for this video.
              </p>
            <% end %>
          </div>

          <!-- Add comment input -->
          <div class="p-4 border-t border-base-300">
            <%= if @current_user do %>
              <form phx-submit="create_comment" class="flex gap-2">
                <input
                  type="text"
                  name="body"
                  placeholder="Add a comment..."
                  required
                  class="input input-bordered flex-1"
                />
                <button type="submit" class="btn btn-primary">Send</button>
              </form>
            <% else %>
              <p class="text-sm text-base-content/60 text-center">
                <.link navigate={~p"/signin"} class="link link-primary">Sign in</.link> to comment
              </p>
            <% end %>
          </div>
        </div>
      </div>
    </div>

    <!-- Report Comment Modal -->
    <dialog id="report_comment_modal" class="modal">
      <div class="modal-box bg-base-200">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
        </form>
        <h3 class="font-bold text-lg mb-4">Report Comment</h3>
        <form phx-submit="report_comment" class="space-y-4">
          <input type="hidden" name="comment_id" value={@reporting_comment_id} />
          <div>
            <label class="label"><span class="label-text">Reason</span></label>
            <select name="reason" class="select select-bordered w-full" required>
              <option value="">Select a reason</option>
              <option value="spam">Spam</option>
              <option value="abuse">Abuse</option>
              <option value="offensive">Offensive</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div>
            <label class="label"><span class="label-text">Description</span></label>
            <textarea
              name="description"
              placeholder="Explain why you're reporting this comment..."
              class="textarea textarea-bordered w-full min-h-24"
              required
              minlength="10"
            ></textarea>
          </div>
          <div class="modal-action">
            <button type="button" class="btn btn-ghost" onclick="document.getElementById('report_comment_modal').close()">
              Cancel
            </button>
            <button type="submit" class="btn btn-error">Submit Report</button>
          </div>
        </form>
      </div>
      <form method="dialog" class="modal-backdrop"><button>close</button></form>
    </dialog>
    """
  end

  defp render_standard(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content pt-16">
      <!-- Video Embed -->
      <div class="w-full max-w-[1800px] mx-auto">
        <%= if @video.tiktok_url && @video.tiktok_url != "" do %>
          <.svelte
            name="TikTokEmbed"
            props={%{tiktokUrl: @video.tiktok_url}}
            socket={@socket}
          />
        <% else %>
          <div class="aspect-video bg-base-content overflow-hidden lg:rounded-xl">
            <.svelte
              name="YouTubePlayer"
              props={%{videoId: extract_youtube_id(@video.youtube_url), controls: true}}
              socket={@socket}
              class="w-full h-full"
            />
          </div>
        <% end %>
      </div>

    <!-- Main Content -->
      <div class="max-w-4xl mx-auto px-4 py-6 pb-24 lg:pb-6">
        <!-- Video Title & Actions -->
        <div class="flex flex-wrap items-start justify-between gap-4 mb-4">
          <h1 class="text-2xl font-bold text-base-content">{@video.title}</h1>
          <!-- Vote Buttons -->
          <div class="flex items-center bg-base-200 rounded-full px-2 py-1">
            <.svelte
              name="VoteButtons"
              props={%{
                target_type: "video",
                target_id: @video.id,
                upvotes: @upvotes,
                downvotes: @downvotes,
                user_vote: @user_vote,
                layout: "horizontal",
                size: "sm"
              }}
              socket={@socket}
            />
          </div>
        </div>

    <!-- Author Info (if available) -->
        <%= if @video.author_name do %>
          <div class="flex items-center gap-3 pb-4 border-b border-base-300 mb-4">
            <div class="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
              <span class="text-primary font-semibold">
                {String.upcase(String.slice(@video.author_name, 0, 1))}
              </span>
            </div>
            <div>
              <%= if @video.author_url do %>
                <a
                  href={@video.author_url}
                  target="_blank"
                  rel="noopener"
                  class="font-semibold text-base-content hover:text-primary"
                >
                  {@video.author_name}
                </a>
              <% else %>
                <p class="font-semibold text-base-content">{@video.author_name}</p>
              <% end %>
              <p class="text-xs text-base-content/60">{@video.format || "standard"} video</p>
            </div>
          </div>
        <% end %>
        
    <!-- Desktop: UnderlineNav -->
        <%= if length(@nav_items) > 0 do %>
          <div class="hidden lg:block mb-6">
            <.svelte
              name="UnderlineNav"
              props={
                %{
                  items: @nav_items,
                  activeKey: @active_section,
                  showCounts: true,
                  size: "md"
                }
              }
              socket={@socket}
            />
          </div>
        <% end %>
        
    <!-- Content Sections -->
        <div class="space-y-4">
          <!-- HOME/DESCRIPTION TAB -->
          <div class={[
            "space-y-4",
            section_visibility(@dock_tab, @active_section, "home", "description")
          ]}>
            <%= if @video.description_md && @video.description_md != "" do %>
              <div class="bg-base-200 rounded-xl p-4">
                <div class="prose prose-sm max-w-none">
                  <.svelte
                    name="MarkdownRenderer"
                    props={%{content: @video.description_md}}
                    socket={@socket}
                  />
                </div>
              </div>
            <% end %>
          </div>
          
    <!-- RESOURCES TAB -->
          <div class={[
            "space-y-4",
            section_visibility(@dock_tab, @active_section, "resources", "resources")
          ]}>
            <%= if @video.resources_md && @video.resources_md != "" do %>
              <h3 class="text-lg font-semibold text-base-content">Resources</h3>
              <div class="bg-base-200 rounded-xl p-4">
                <div class="prose prose-sm max-w-none">
                  <.svelte
                    name="MarkdownRenderer"
                    props={%{content: @video.resources_md}}
                    socket={@socket}
                  />
                </div>
              </div>
            <% else %>
              <p class="text-sm text-base-content/60 text-center py-8">
                No resources available for this video.
              </p>
            <% end %>
          </div>
          
    <!-- AUTHOR TAB -->
          <div class={[
            "space-y-4",
            section_visibility(@dock_tab, @active_section, "author", "author")
          ]}>
            <%= if @video.author_name do %>
              <h3 class="text-lg font-semibold text-base-content">About the Author</h3>
              <div class="bg-base-200 rounded-xl p-4">
                <%= if @video.author_url do %>
                  <a
                    href={@video.author_url}
                    target="_blank"
                    rel="noopener"
                    class="link link-primary font-medium"
                  >
                    {@video.author_name}
                  </a>
                <% else %>
                  <p class="font-medium text-base-content">{@video.author_name}</p>
                <% end %>
                <%= if @video.author_bio_md && @video.author_bio_md != "" do %>
                  <div class="mt-3 prose prose-sm max-w-none">
                    <.svelte
                      name="MarkdownRenderer"
                      props={%{content: @video.author_bio_md}}
                      socket={@socket}
                    />
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
          
    <!-- COMMENTS TAB -->
          <div class={[
            "space-y-4",
            section_visibility(@dock_tab, @active_section, "comments", "comments")
          ]}>
            <%= if @thread do %>
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold text-base-content">
                  {@thread.comment_count} Comments
                </h3>
              </div>
              
    <!-- Add Comment Form -->
              <%= if @current_user do %>
                <div class="flex gap-3">
                  <div class="avatar placeholder">
                    <div class="bg-primary text-primary-content w-10 h-10 rounded-full">
                      <span class="text-sm">
                        {String.upcase(
                          String.slice(@current_user.username || @current_user.email || "U", 0, 1)
                        )}
                      </span>
                    </div>
                  </div>
                  <div class="flex-1">
                    <form phx-submit="create_comment" class="space-y-3">
                      <textarea
                        id="video-comment-input"
                        name="body"
                        placeholder="Add a comment..."
                        required
                        phx-hook="ExpandingTextarea"
                        class="textarea textarea-ghost w-full focus:textarea-bordered bg-transparent resize-none"
                        rows="1"
                      ></textarea>
                      <div class="flex justify-end gap-2">
                        <button type="submit" class="btn btn-primary btn-sm">Comment</button>
                      </div>
                    </form>
                  </div>
                </div>
              <% else %>
                <div class="flex gap-3 items-center p-4 bg-base-200/50 rounded-lg">
                  <div class="avatar placeholder">
                    <div class="bg-base-300 w-10 h-10 rounded-full">
                      <span class="text-sm">?</span>
                    </div>
                  </div>
                  <span class="text-base-content/70">
                    <.link navigate={~p"/signin"} class="link link-primary">Sign in</.link> to comment
                  </span>
                </div>
              <% end %>

              <.svelte
                name="CommentTree"
                props={
                  %{
                    comments: @comment_tree,
                    current_user_id: (@current_user && @current_user.id) || nil,
                    current_user_is_admin: (@current_user && @current_user.is_admin) || false,
                    thread_author_id: @thread.author_id,
                    solved_comment_id: nil
                  }
                }
                socket={@socket}
              />
            <% else %>
              <p class="text-sm text-base-content/60 text-center py-8">
                Comments not enabled for this video.
              </p>
            <% end %>
          </div>
        </div>
      </div>
      
    <!-- Mobile Bottom Dock -->
      <div class="dock fixed bottom-0 left-0 right-0 z-20 lg:hidden bg-base-200 border-t border-base-300">
        <button
          type="button"
          phx-click="set_dock_tab"
          phx-value-tab="home"
          class={["dock-item", if(@dock_tab == "home", do: "dock-active", else: "")]}
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
            />
          </svg>
          <span class="dock-label text-xs">Home</span>
        </button>

        <button
          type="button"
          phx-click="set_dock_tab"
          phx-value-tab="resources"
          class={["dock-item", if(@dock_tab == "resources", do: "dock-active", else: "")]}
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 10V3L4 14h7v7l9-11h-7z"
            />
          </svg>
          <span class="dock-label text-xs">Resources</span>
        </button>

        <%= if @video.author_name do %>
          <button
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="author"
            class={["dock-item", if(@dock_tab == "author", do: "dock-active", else: "")]}
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
            <span class="dock-label text-xs">About</span>
          </button>
        <% end %>

        <%= if @thread do %>
          <button
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="comments"
            class={["dock-item", if(@dock_tab == "comments", do: "dock-active", else: "")]}
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
            <span class="dock-label text-xs">{@thread.comment_count}</span>
          </button>
        <% end %>
      </div>
      
    <!-- Report Comment Modal -->
      <dialog id="report_comment_modal" class="modal">
        <div class="modal-box bg-base-200">
          <form method="dialog">
            <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
          </form>
          <h3 class="font-bold text-lg mb-4">Report Comment</h3>
          <form phx-submit="report_comment" class="space-y-4">
            <input type="hidden" name="comment_id" value={@reporting_comment_id} />
            <div>
              <label class="label"><span class="label-text">Reason</span></label>
              <select name="reason" class="select select-bordered w-full" required>
                <option value="">Select a reason</option>
                <option value="spam">Spam</option>
                <option value="abuse">Abuse</option>
                <option value="offensive">Offensive</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div>
              <label class="label"><span class="label-text">Description</span></label>
              <textarea
                name="description"
                placeholder="Explain why you're reporting this comment..."
                class="textarea textarea-bordered w-full min-h-24"
                required
                minlength="10"
              ></textarea>
            </div>
            <div class="modal-action">
              <button
                type="button"
                class="btn btn-ghost"
                onclick="document.getElementById('report_comment_modal').close()"
              >
                Cancel
              </button>
              <button type="submit" class="btn btn-error">Submit Report</button>
            </div>
          </form>
        </div>
        <form method="dialog" class="modal-backdrop"><button>close</button></form>
      </dialog>
    </div>
    """
  end
end
