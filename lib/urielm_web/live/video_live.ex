defmodule UrielmWeb.VideoLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Content
  alias Urielm.Forum
  alias Urielm.Engagement
  alias UrielmWeb.CommentHandlers
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

    if not connected?(socket) do
      {:ok,
       socket
       |> assign(:page_title, "Loading...")
       |> assign(:video, nil)
       |> assign(:completed, false)
       |> assign(:thread, nil)
       |> assign(:comment_tree, [])
       |> assign(:comment_form, to_form(%{"body" => ""}))
       |> assign(:nav_items, [])
       |> assign(:active_section, "description")
       |> assign(:next_video, nil)
       |> assign(:reporting_comment_id, nil)
       |> assign(:upvotes, 0)
       |> assign(:downvotes, 0)
       |> assign(:user_vote, nil)
       |> assign(:meta_description, "")
       |> assign(:canonical_url, "")
       |> assign(:og_title, "")
       |> assign(:og_type, "video.other")
       |> assign(:og_image, nil)}
    else
      video = Content.get_video_by_slug(slug, preload_tags: true)

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
            default_section = (List.first(nav_items) || %{key: "description"}).key
            next_video = next_accessible_video(video, user)

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
             |> assign(:comment_form, to_form(%{"body" => ""}))
             |> assign(:nav_items, nav_items)
             |> assign(:active_section, default_section)
             |> assign(:next_video, next_video)
             |> assign(:reporting_comment_id, nil)
             |> assign(:upvotes, upvotes)
             |> assign(:downvotes, downvotes)
             |> assign(:user_vote, user_vote && user_vote.value)
             |> assign_meta_tags(video, slug)}
          end
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
    items = [%{key: "description", label: "Overview"}]

    items =
      if video.resources_md && video.resources_md != "",
        do: items ++ [%{key: "resources", label: "Resources"}],
        else: items

    comment_count = if thread, do: thread.comment_count, else: 0
    items ++ [%{key: "comments", label: "Comments", count: comment_count}]
  end

  defp next_accessible_video(video, user) do
    Content.list_published_videos(limit: 12)
    |> Enum.find(fn candidate ->
      candidate.id != video.id and candidate.format == "standard" and
        Content.can_view_video?(user, candidate)
    end)
  end

  defp assign_meta_tags(socket, video, slug) do
    description = strip_markdown_and_truncate(video.description_md, 160)
    canonical_url = url(~p"/videos/#{slug}")

    og_image =
      case extract_youtube_id(video.youtube_url) do
        nil -> nil
        id -> "https://img.youtube.com/vi/#{id}/maxresdefault.jpg"
      end

    socket
    |> assign(:meta_description, description)
    |> assign(:canonical_url, canonical_url)
    |> assign(:og_title, video.title)
    |> assign(:og_type, "video.other")
    |> assign(:og_image, og_image)
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
  def handle_event(
        "vote",
        %{"target_type" => "comment", "target_id" => id, "value" => value},
        socket
      ) do
    LiveHelpers.with_auth(socket, "vote", fn socket, user ->
      case CommentHandlers.vote(socket.assigns.thread, id, value, user, :toggle) do
        {:ok, _} ->
          {:noreply, refresh_video_comments(socket, user)}

        {:error, :not_found} ->
          {:noreply, put_flash(socket, :error, "Comment not found")}

        {:error, :invalid_vote} ->
          {:noreply, put_flash(socket, :error, "Invalid vote value")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to vote")}
      end
    end)
  end

  @impl true
  def handle_event(
        "vote",
        %{"target_type" => target_type, "target_id" => id, "value" => value},
        socket
      ) do
    LiveHelpers.handle_vote(target_type, id, value, socket)
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
        {:ok, _count} = Content.unmark_video_complete(user, video)
        {:noreply, assign(socket, :completed, false)}
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
        parent_id = Map.get(params, "parent_id")

        case CommentHandlers.create(thread, body, parent_id, user) do
          {:ok, _comment} ->
            {:noreply,
             socket
             |> refresh_video_comments(user)
             |> put_flash(:info, "Comment posted")}

          {:error, :thread_locked} ->
            {:noreply, put_flash(socket, :error, "This thread is locked")}

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
        case CommentHandlers.edit(socket.assigns.thread, comment_id, body, user) do
          {:error, :not_found} ->
            {:noreply, put_flash(socket, :error, "Comment not found")}

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
        case CommentHandlers.delete(socket.assigns.thread, comment_id, user) do
          {:error, :not_found} ->
            {:noreply, put_flash(socket, :error, "Comment not found")}

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
        case CommentHandlers.report(
               socket.assigns.thread,
               comment_id,
               %{
                 reason: reason,
                 description: description
               },
               user
             ) do
          {:ok, _report} ->
            {:noreply,
             socket
             |> put_flash(:info, "Report submitted successfully")
             |> push_event("close_modal", %{"id" => "report_comment_modal"})}

          {:error, :unique_constraint} ->
            {:noreply, put_flash(socket, :error, "You've already reported this")}

          {:error, :not_found} ->
            {:noreply, put_flash(socket, :error, "Comment not found")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to submit report")}
        end
    end
  end

  defp refresh_video_comments(socket, user) do
    case Forum.get_thread(socket.assigns.thread.id, include_comments?: true) do
      nil ->
        socket
        |> assign(:thread, nil)
        |> assign(:comment_tree, [])
        |> assign(:nav_items, build_nav_items(socket.assigns.video, nil))

      thread ->
        comment_tree = LiveHelpers.build_comment_tree(thread.comments, user)

        socket
        |> assign(:thread, thread)
        |> assign(:comment_tree, comment_tree)
        |> assign(:nav_items, build_nav_items(socket.assigns.video, thread))
    end
  end

  @impl true
  def render(assigns) do
    if is_nil(assigns.video) do
      ~H"""
      <div class="min-h-screen bg-base-100 flex items-center justify-center">
        <span class="loading loading-spinner loading-lg"></span>
      </div>
      """
    else
      render_standard(assigns)
    end
  end

  defp render_standard(assigns) do
    assigns =
      assigns
      |> assign(:viewer_id, viewer_id(assigns.current_user))
      |> assign(:viewer_admin?, viewer_admin?(assigns.current_user))
      |> assign(:has_nav_items?, assigns.nav_items != [])

    ~H"""
    <div
      id="standard-video-page"
      data-video-format={@video.format}
      class="min-h-screen bg-base-100 text-base-content"
    >
      <main class="mx-auto w-full max-w-7xl px-0 pb-28 pt-5 sm:px-6 sm:pt-8 lg:px-8 lg:pb-16">
        <.link
          id="video-back-link"
          navigate={~p"/videos"}
          class="btn btn-ghost btn-sm mx-2 mb-4 gap-2 text-base-content/55 hover:text-primary sm:-ml-2"
        >
          <.um_icon
            name="hero-arrow-left"
            class="size-4 transition-transform group-hover:-translate-x-0.5"
          /> All videos
        </.link>

        <.learning_media_player
          id="video-player-shell"
          label="Video player"
          class={[
            "relative mx-auto w-full",
            if(@video.format == "short",
              do: "h-[min(62dvh,38rem)] min-h-[26rem]",
              else: "aspect-video max-w-[960px]"
            )
          ]}
        >
          <%= if @video.tiktok_url && @video.tiktok_url != "" do %>
            <.svelte
              name="TikTokEmbed"
              props={%{tiktokUrl: @video.tiktok_url}}
              socket={@socket}
              class="relative z-10 h-full w-full"
              ssr={false}
            />
          <% else %>
            <.svelte
              name="YouTubePlayer"
              props={
                %{
                  videoId: extract_youtube_id(@video.youtube_url),
                  controls: true,
                  shorts: @video.format == "short"
                }
              }
              socket={@socket}
              class="relative z-10 h-full w-full"
              ssr={false}
            />
          <% end %>
        </.learning_media_player>

        <section
          id="video-detail-header"
          class="grid gap-6 px-4 py-7 sm:px-0 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-start lg:py-9"
        >
          <div>
            <p class="ui-eyebrow flex items-center gap-2">
              <span class="size-1.5 rounded-full bg-primary"></span>
              {if @video.format == "short", do: "Short video", else: "Standard video"}
            </p>
            <h1 class="mt-3 max-w-4xl text-3xl font-black leading-tight text-base-content sm:text-4xl">
              {@video.title}
            </h1>

            <div class="mt-5 flex items-center gap-3 text-sm text-base-content/55">
              <span class="grid size-10 place-items-center rounded-full border border-primary/25 bg-primary/10 font-black text-primary">
                {author_initial(@video.author_name)}
              </span>
              <div>
                <%= if @video.author_url do %>
                  <a
                    href={@video.author_url}
                    target="_blank"
                    rel="noopener"
                    class="font-bold text-base-content transition-colors hover:text-primary"
                  >
                    {author_name(@video)}
                  </a>
                <% else %>
                  <p class="font-bold text-base-content">{author_name(@video)}</p>
                <% end %>
                <p class="mt-0.5 text-xs">
                  Published {format_video_date(video_date(@video))}
                </p>
              </div>
            </div>

            <div
              :if={@video.tag_records != []}
              id="video-detail-tags"
              aria-label="Video tags"
              class="mt-5 flex flex-wrap items-center gap-2"
            >
              <span class="ui-eyebrow mr-1 text-base-content/45">Tags</span>
              <.link
                :for={tag <- @video.tag_records}
                id={"video-detail-tag-#{tag.slug}"}
                navigate={~p"/videos?tag=#{tag.slug}"}
                class="badge badge-outline border-primary/25 bg-primary/5 px-3 py-2 text-xs font-bold text-primary transition-colors hover:bg-primary/10"
              >
                {tag.name}
              </.link>
            </div>
          </div>

          <div class="flex flex-wrap items-center gap-2 lg:justify-end lg:pt-7">
            <button
              :if={@current_user}
              id="video-completion-control"
              type="button"
              phx-click={if(@completed, do: "unmark_video_complete", else: "mark_video_complete")}
              aria-pressed={@completed}
              class={[
                "btn btn-sm h-10 rounded-full px-4 transition duration-200",
                if(@completed,
                  do: "btn-success",
                  else: "btn-primary"
                )
              ]}
            >
              <.um_icon name="hero-check-circle" class="size-4" />
              {if @completed, do: "Completed", else: "Mark complete"}
            </button>

            <div class="flex h-10 items-center rounded-full border border-base-300/80 bg-base-200/70 px-2">
              <.svelte
                name="VoteButtons"
                props={
                  %{
                    target_type: "video",
                    target_id: @video.id,
                    upvotes: @upvotes,
                    downvotes: @downvotes,
                    user_vote: @user_vote,
                    layout: "horizontal",
                    size: "sm"
                  }
                }
                socket={@socket}
                ssr={false}
              />
            </div>

            <button
              id="video-share-button"
              type="button"
              aria-label="Copy video link"
              phx-hook="CopyToClipboard"
              data-text={@canonical_url}
              class="btn btn-ghost btn-circle btn-sm size-10 border border-base-300/80 bg-base-200/70 transition hover:border-primary/35 hover:text-primary"
            >
              <.um_icon name="hero-arrow-up-on-square" class="size-4" />
            </button>
          </div>
        </section>

        <div class={[
          "grid gap-6 px-4 sm:px-0 lg:items-start",
          if(@has_nav_items?,
            do: "lg:grid-cols-[minmax(0,1fr)_19rem]",
            else: "lg:grid-cols-1"
          )
        ]}>
          <article
            :if={@has_nav_items?}
            id="video-content-panel"
            class="card ui-card h-auto overflow-hidden"
          >
            <.learning_media_tabs
              id="video-detail-tabs"
              label="Video details"
              items={@nav_items}
              active_key={@active_section}
              item_id_prefix="video-tab"
            />

            <section
              :if={@active_section == "description"}
              id="video-description-section"
              class="card-body p-5 sm:p-7"
            >
              <h2 class="text-xl font-black text-base-content">Overview</h2>
              <div
                :if={@video.description_md && @video.description_md != ""}
                class="prose prose-sm mt-1 max-w-none text-base-content/75 sm:prose-base"
              >
                <.svelte
                  name="MarkdownRenderer"
                  props={
                    %{
                      content: @video.description_md,
                      localTimestampVideoId: extract_youtube_id(@video.youtube_url)
                    }
                  }
                  socket={@socket}
                  ssr={false}
                />
              </div>
              <.empty_state
                :if={is_nil(@video.description_md) or @video.description_md == ""}
                id="video-overview-empty"
                title="Overview coming soon"
                description="This video does not have an overview yet. You can still watch it and continue the discussion."
                icon="hero-document-text"
                compact
                class="mt-4"
              />
            </section>

            <section
              :if={@active_section == "resources"}
              id="video-resources-section"
              class="card-body p-5 sm:p-7"
            >
              <h2 class="text-xl font-black text-base-content">Resources</h2>
              <div class="prose prose-sm mt-1 max-w-none text-base-content/75 sm:prose-base">
                <.svelte
                  name="MarkdownRenderer"
                  props={%{content: @video.resources_md}}
                  socket={@socket}
                  ssr={false}
                />
              </div>
            </section>

            <section
              :if={@active_section == "comments"}
              id="video-comments-section"
              class="card-body p-5 sm:p-7"
            >
              <div class="flex items-center justify-between gap-4">
                <h2 class="text-xl font-black text-base-content">
                  Discussion
                </h2>
                <span class="badge badge-ghost font-mono text-xs">
                  {if @thread, do: @thread.comment_count, else: 0} comments
                </span>
              </div>

              <%= if is_nil(@thread) do %>
                <.empty_state
                  id="video-comments-disabled"
                  title="Discussion is not enabled"
                  description="There is no discussion thread for this video yet."
                  icon="hero-chat-bubble-left-right"
                  compact
                  class="mt-5"
                />
              <% else %>
                <%= cond do %>
                  <% @thread.is_locked -> %>
                    <div
                      id="video-discussion-locked"
                      role="status"
                      class="alert alert-warning mt-5 items-start text-sm"
                    >
                      <.um_icon name="lock_closed" class="size-5 shrink-0" />
                      <div class="min-w-0">
                        <p class="font-semibold text-base-content">This discussion is locked</p>
                        <p class="mt-1 max-w-2xl text-base-content/55">
                          New comments are closed, but the existing conversation remains available to read.
                        </p>
                      </div>
                    </div>
                  <% @current_user -> %>
                    <div class="mt-5 flex gap-3 border-b border-base-300/60 pb-6">
                      <span class="grid size-10 flex-none place-items-center rounded-full bg-primary text-sm font-black text-primary-content">
                        {user_initial(@current_user)}
                      </span>
                      <.form
                        for={@comment_form}
                        id="video-comment-form"
                        phx-submit="create_comment"
                        class="min-w-0 flex-1 space-y-3"
                      >
                        <.input
                          field={@comment_form[:body]}
                          id="video-comment-input"
                          type="textarea"
                          placeholder="Add to the discussion…"
                          required
                          phx-hook="ExpandingTextarea"
                          phx-focus={JS.show(to: "#video-comment-actions")}
                          rows="2"
                          class="textarea textarea-bordered w-full resize-none bg-base-200/60"
                        />
                        <div id="video-comment-actions" class="flex justify-end gap-2">
                          <button
                            type="button"
                            class="btn btn-ghost btn-sm rounded-full"
                            phx-click={
                              JS.dispatch("reset", to: "#video-comment-form")
                              |> JS.set_attribute({"rows", "2"}, to: "#video-comment-input")
                            }
                          >
                            Cancel
                          </button>
                          <button type="submit" class="btn btn-primary btn-sm rounded-full px-5">
                            Comment
                          </button>
                        </div>
                      </.form>
                    </div>
                  <% true -> %>
                    <div
                      id="video-sign-in-to-comment"
                      class="ui-card ui-card-compact mt-5 flex h-auto items-center gap-3 p-4"
                    >
                      <span class="grid size-9 place-items-center rounded-full bg-base-300 font-bold">
                        ?
                      </span>
                      <p class="text-sm text-base-content/60">
                        <.link navigate={~p"/signin"} class="font-bold text-primary hover:underline">
                          Sign in
                        </.link>
                        to join the discussion.
                      </p>
                    </div>
                <% end %>

                <div class="mt-6">
                  <.svelte
                    name="CommentTree"
                    props={
                      %{
                        comments: @comment_tree,
                        current_user_id: @viewer_id,
                        current_user_is_admin: @viewer_admin?,
                        thread_author_id: @thread.author_id,
                        solved_comment_id: nil
                      }
                    }
                    socket={@socket}
                    ssr={false}
                  />
                </div>
              <% end %>
            </section>
          </article>

          <aside
            id="video-context-sidebar"
            class={[
              "space-y-4 lg:sticky lg:top-24",
              !@has_nav_items? && "lg:max-w-sm"
            ]}
          >
            <section
              :if={@video.author_name}
              id="video-creator-card"
              class="card ui-card h-auto"
            >
              <div class="card-body p-5">
                <p class="ui-eyebrow text-base-content/45">
                  About the creator
                </p>
                <div class="mt-2 flex items-center gap-3">
                  <span class="grid size-11 place-items-center rounded-full border border-primary/25 bg-primary/10 font-black text-primary">
                    {author_initial(@video.author_name)}
                  </span>
                  <div class="min-w-0">
                    <p class="truncate font-black text-base-content">{@video.author_name}</p>
                    <p class="text-xs text-base-content/45">Video creator</p>
                  </div>
                </div>
                <div
                  :if={@video.author_bio_md && @video.author_bio_md != ""}
                  class="prose prose-sm mt-3 max-w-none text-base-content/65"
                >
                  <.svelte
                    name="MarkdownRenderer"
                    props={%{content: @video.author_bio_md}}
                    socket={@socket}
                    ssr={false}
                  />
                </div>
                <a
                  :if={@video.author_url}
                  href={@video.author_url}
                  target="_blank"
                  rel="noopener"
                  class="btn btn-ghost btn-sm mt-2 justify-start rounded-lg px-0 text-primary hover:bg-transparent"
                >
                  Visit creator profile <.um_icon name="hero-arrow-up-right" class="size-4" />
                </a>
              </div>
            </section>

            <section
              :if={@video.resources_md && @video.resources_md != ""}
              id="video-resources-card"
              class="card ui-card h-auto"
            >
              <div class="card-body p-5">
                <p class="ui-eyebrow text-base-content/45">
                  Included resources
                </p>
                <button
                  type="button"
                  phx-click="tab_change"
                  phx-value-key="resources"
                  class="btn btn-ghost mt-2 h-auto min-h-0 justify-start gap-3 rounded-lg border-t border-base-300/60 px-0 pt-4 text-left hover:bg-transparent hover:text-primary"
                >
                  <span class="grid size-9 flex-none place-items-center rounded-lg bg-base-300/70 text-primary">
                    <.um_icon name="hero-link" class="size-4" />
                  </span>
                  <span>
                    <span class="block text-sm font-bold">Open video resources</span>
                    <span class="mt-0.5 block text-xs font-normal text-base-content/40">
                      Links, notes, and downloads
                    </span>
                  </span>
                </button>
              </div>
            </section>

            <.link
              :if={@next_video}
              id={"video-next-card-#{@next_video.id}"}
              navigate={~p"/videos/#{@next_video.slug}"}
              class="card ui-card ui-card-interactive group h-auto overflow-hidden"
            >
              <div class="relative aspect-video overflow-hidden bg-base-300">
                <img
                  :if={video_thumbnail(@next_video)}
                  src={video_thumbnail(@next_video)}
                  alt=""
                  loading="lazy"
                  class="h-full w-full object-cover transition duration-500 group-hover:scale-[1.04]"
                />
                <span class="absolute inset-0 grid place-items-center bg-black/10">
                  <span class="grid size-10 place-items-center rounded-full bg-white/90 text-[#173467] shadow-lg">
                    <.um_icon name="hero-play-solid" class="ml-0.5 size-4" />
                  </span>
                </span>
              </div>
              <div class="card-body p-5">
                <p class="ui-eyebrow">
                  Up next
                </p>
                <h2 class="mt-1 line-clamp-2 text-sm font-black leading-snug text-base-content transition-colors group-hover:text-primary">
                  {@next_video.title}
                </h2>
              </div>
            </.link>
          </aside>
        </div>
      </main>

      <.report_modal
        id="report_comment_modal"
        title="Report Comment"
        form_event="report_comment"
        comment_id={@reporting_comment_id}
        submit_disabled={is_nil(@reporting_comment_id)}
        description_label="Description"
        description_placeholder="Explain why you're reporting this comment..."
      />
    </div>
    """
  end

  defp author_name(%{author_name: name}) when is_binary(name) and name != "", do: name
  defp author_name(_video), do: "Urielm"

  defp author_initial(name) when is_binary(name) and name != "" do
    case name |> String.trim() |> String.first() do
      nil -> "U"
      initial -> String.upcase(initial)
    end
  end

  defp author_initial(_name), do: "U"

  defp user_initial(%{username: username}) when is_binary(username) and username != "",
    do: author_initial(username)

  defp user_initial(%{email: email}), do: author_initial(email)

  defp viewer_id(nil), do: nil
  defp viewer_id(user), do: user.id

  defp viewer_admin?(nil), do: false
  defp viewer_admin?(user), do: user.is_admin

  defp video_date(%{published_at: nil, inserted_at: inserted_at}), do: inserted_at
  defp video_date(%{published_at: published_at}), do: published_at

  defp format_video_date(nil), do: "recently"
  defp format_video_date(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp video_thumbnail(video) do
    case extract_youtube_id(video.youtube_url) do
      nil -> nil
      id -> "https://img.youtube.com/vi/#{id}/hqdefault.jpg"
    end
  end
end
