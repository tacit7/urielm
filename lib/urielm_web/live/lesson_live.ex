defmodule UrielmWeb.LessonLive do
  use UrielmWeb, :live_view
  alias Urielm.Engagement
  alias Urielm.Learning
  alias Urielm.Learning.LessonComment
  alias Urielm.Params
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, session, socket) do
    # Handle both direct mount and child mount via live_render
    child_params =
      case params do
        :not_mounted_at_router -> session["child_params"] || %{}
        params -> params
      end

    course_slug = child_params["course_slug"]
    lesson_slug = child_params["lesson_slug"]

    case Learning.get_course_by_slug(course_slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Course not found")
         |> push_navigate(to: ~p"/")}

      course ->
        case Learning.get_lesson_with_comments(course.id, lesson_slug) do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, "Lesson not found")
             |> push_navigate(to: ~p"/")}

          lesson ->
            lessons = Learning.list_lessons(course.id)
            changeset = Learning.change_lesson_comment(%LessonComment{})
            nav_items = build_nav_items(lesson, course)
            current_index = Enum.find_index(lessons, &(&1.id == lesson.id))

            prev_lesson =
              if current_index && current_index > 0,
                do: Enum.at(lessons, current_index - 1),
                else: nil

            next_lesson = if current_index, do: Enum.at(lessons, current_index + 1), else: nil

            # Load vote data
            %{current_user: user} = socket.assigns

            {upvotes, downvotes, _score} =
              Engagement.get_vote_counts("lesson", to_string(lesson.id))

            user_vote =
              if user, do: Engagement.get_vote(user.id, "lesson", to_string(lesson.id)), else: nil

            {:ok,
             socket
             |> assign(:course, course)
             |> assign(:lesson, lesson)
             |> assign(:lessons, lessons)
             |> assign(:comment_changeset, changeset)
             |> assign(:comment_form, Phoenix.Component.to_form(changeset, as: :comment))
             |> assign(:current_page, "courses")
             |> assign(:page_title, lesson.title)
             |> assign(:dock_tab, "home")
             |> assign(:active_section, "home")
             |> assign(:nav_items, nav_items)
             |> assign(:upvotes, upvotes)
             |> assign(:downvotes, downvotes)
             |> assign(:user_vote, user_vote && user_vote.value)
             |> assign(:prev_lesson, prev_lesson)
             |> assign(:next_lesson, next_lesson)}
        end
    end
  end

  defp build_nav_items(lesson, _course) do
    items = [%{key: "home", label: "Overview"}]

    items =
      if lesson.notes_md && lesson.notes_md != "",
        do: items ++ [%{key: "notes", label: "Notes"}],
        else: items

    items =
      if lesson.resources_md && lesson.resources_md != "",
        do: items ++ [%{key: "resources", label: "Resources"}],
        else: items

    items =
      if lesson.timestamps_md && lesson.timestamps_md != "",
        do: items ++ [%{key: "timestamps", label: "Timestamps"}],
        else: items

    # Always show comments
    items ++ [%{key: "comments", label: "Comments", count: length(lesson.comments || [])}]
  end

  # Visibility helper for mobile dock + desktop tabs
  # Mobile: show if dock_tab matches
  # Desktop: show if active_section matches
  defp section_visibility(dock_tab, active_section, section_key) do
    mobile_matches = dock_tab == section_key
    desktop_matches = active_section == section_key

    case {mobile_matches, desktop_matches} do
      {true, true} -> ""
      {true, false} -> "lg:hidden"
      {false, true} -> "hidden lg:block"
      {false, false} -> "hidden"
    end
  end

  @impl true
  def handle_event("set_dock_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :dock_tab, tab)}
  end

  @impl true
  def handle_event("tab_change", %{"key" => key}, socket) do
    {:noreply, assign(socket, :active_section, key)}
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
  def handle_event("save_comment", %{"comment" => params0}, socket) do
    user = socket.assigns[:current_user]

    if !user do
      {:noreply,
       socket
       |> put_flash(:info, "Sign in to comment on this lesson.")}
    else
      lesson = socket.assigns.lesson

      attrs =
        Params.normalize(params0)
        |> Map.put("lesson_id", lesson.id)
        |> Map.put("user_id", user.id)

      case Learning.create_lesson_comment(attrs) do
        {:ok, _comment} ->
          lesson = Learning.get_lesson_with_comments(socket.assigns.course.id, lesson.slug)

          {:noreply,
           socket
           |> put_flash(:info, "Comment added.")
           |> assign(:lesson, lesson)
           |> assign(:comment_changeset, Learning.change_lesson_comment(%LessonComment{}))
           |> assign(
             :comment_form,
             Phoenix.Component.to_form(Learning.change_lesson_comment(%LessonComment{}),
               as: :comment
             )
           )}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply,
           socket
           |> assign(:comment_changeset, changeset)
           |> assign(:comment_form, Phoenix.Component.to_form(changeset, as: :comment))}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="drawer drawer-end lg:drawer-open">
      <input id="lesson-drawer" type="checkbox" class="drawer-toggle" />
      
    <!-- Drawer Content (Main) -->
      <div class="drawer-content flex flex-col">
        <!-- Video Player -->
        <div class="aspect-video bg-base-content overflow-hidden max-w-[1800px] mx-auto w-full lg:rounded-xl">
          <.svelte
            name="YouTubePlayer"
            props={%{videoId: @lesson.youtube_video_id, controls: true}}
            socket={@socket}
            class="w-full h-full"
          ssr={false}
          />
        </div>
        
    <!-- Prev / Next navigation -->
        <div class="max-w-[1800px] mx-auto w-full px-4 py-3 flex items-center justify-between border-b border-base-300">
          <div class="flex-1">
            <.link
              :if={@prev_lesson}
              navigate={~p"/courses/#{@course.slug}/lessons/#{@prev_lesson.slug}"}
              class="inline-flex items-center gap-2 text-sm text-base-content/60 hover:text-primary transition-colors"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
              <span class="line-clamp-1 max-w-[180px] md:max-w-xs">{@prev_lesson.title}</span>
            </.link>
          </div>
          <div class="flex-1 flex justify-end">
            <.link
              :if={@next_lesson}
              navigate={~p"/courses/#{@course.slug}/lessons/#{@next_lesson.slug}"}
              class="inline-flex items-center gap-2 text-sm text-base-content/60 hover:text-primary transition-colors"
            >
              <span class="line-clamp-1 max-w-[180px] md:max-w-xs text-right">
                {@next_lesson.title}
              </span>
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </.link>
          </div>
        </div>
        
    <!-- Main Content -->
        <div class="max-w-[1800px] mx-auto w-full px-4 py-6">
          <!-- Mobile Sticky Header -->
          <div class="flex items-center gap-2 mb-4 lg:hidden">
            <.link
              navigate={~p"/courses/#{@course.slug}"}
              class="btn btn-ghost btn-sm btn-circle flex-shrink-0"
              title="Back to course"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
            </.link>
            <h1 class="text-lg font-bold text-base-content truncate flex-1">{@lesson.title}</h1>
            <div class="flex items-center bg-base-200 rounded-full px-2 py-1 flex-shrink-0">
              <.svelte
                name="VoteButtons"
                props={
                  %{
                    target_type: "lesson",
                    target_id: to_string(@lesson.id),
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
            <label
              for="lesson-drawer"
              class="btn btn-ghost btn-sm btn-circle flex-shrink-0"
              title="Course videos"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                />
              </svg>
            </label>
          </div>
          
    <!-- Video Title & Actions -->
          <div class="hidden lg:flex items-start justify-between gap-4 mb-3">
            <h1 class="text-2xl font-bold text-base-content">{@lesson.title}</h1>
            <!-- Vote Buttons -->
            <div class="flex items-center bg-base-200 rounded-full px-2 py-1">
              <.svelte
                name="VoteButtons"
                props={
                  %{
                    target_type: "lesson",
                    target_id: to_string(@lesson.id),
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
          </div>
          
    <!-- Desktop: UnderlineNav -->
          <div class="hidden lg:block mb-6">
            <.svelte
              name="UnderlineNav"
              props={%{items: @nav_items, activeKey: @active_section, showCounts: true, size: "md"}}
              socket={@socket}
            ssr={false}
            />
          </div>
          
    <!-- Dock Content Sections -->
          <div class="space-y-4 pb-24 lg:pb-0">
            <!-- HOME TAB -->
            <div class={["space-y-4", section_visibility(@dock_tab, @active_section, "home")]}>
              <!-- Course/Channel Info -->
              <div class="flex items-center gap-3 pb-4 border-b border-base-300 mb-4">
                <div class="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0">
                  <svg
                    class="w-5 h-5 text-primary"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                    />
                  </svg>
                </div>
                <div>
                  <.link
                    navigate={~p"/courses/#{@course.slug}"}
                    class="font-semibold text-base-content hover:text-primary"
                  >
                    {@course.title}
                  </.link>
                  <p class="text-xs text-base-content/60">Lesson {@lesson.lesson_number}</p>
                </div>
              </div>

              <div :if={@course.description} class="mt-4 bg-base-200 rounded-xl p-4">
                <h3 class="font-semibold text-base-content mb-2">About this course</h3>
                <p class="text-sm text-base-content/70">{@course.description}</p>
              </div>
            </div>
            
    <!-- NOTES TAB -->
            <div class={["space-y-4", section_visibility(@dock_tab, @active_section, "notes")]}>
              <h3 class="text-lg font-semibold text-base-content">Lesson notes</h3>
              <div :if={@lesson.notes_md} class="prose prose-sm max-w-none">
                <.svelte
                  name="MarkdownRenderer"
                  props={%{content: @lesson.notes_md}}
                  socket={@socket}
                ssr={false}
                />
              </div>
              <div :if={!@lesson.notes_md} class="text-sm text-base-content/60 text-center py-8">
                No notes available for this lesson.
              </div>
            </div>
            
    <!-- RESOURCES TAB -->
            <div class={["space-y-4", section_visibility(@dock_tab, @active_section, "resources")]}>
              <h3 class="text-lg font-semibold text-base-content">Resources</h3>
              <div :if={@lesson.resources_md} class="prose prose-sm max-w-none">
                <.svelte
                  name="MarkdownRenderer"
                  props={%{content: @lesson.resources_md}}
                  socket={@socket}
                ssr={false}
                />
              </div>
              <div :if={!@lesson.resources_md} class="text-sm text-base-content/60 text-center py-8">
                No resources available for this lesson.
              </div>
            </div>
            
    <!-- TIMESTAMPS TAB -->
            <div class={["space-y-4", section_visibility(@dock_tab, @active_section, "timestamps")]}>
              <h3 class="text-lg font-semibold text-base-content">Timestamps</h3>
              <div :if={@lesson.timestamps_md} class="prose prose-sm max-w-none">
                <.svelte
                  name="MarkdownRenderer"
                  props={%{content: @lesson.timestamps_md}}
                  socket={@socket}
                ssr={false}
                />
              </div>
              <div :if={!@lesson.timestamps_md} class="text-sm text-base-content/60 text-center py-8">
                No timestamps available for this lesson.
              </div>
            </div>
            
    <!-- COMMENTS TAB -->
            <div class={["space-y-4", section_visibility(@dock_tab, @active_section, "comments")]}>
              <h3 class="text-lg font-semibold text-base-content">Comments</h3>

              <%= if @lesson.comments == [] do %>
                <p class="text-sm text-base-content/60 text-center py-8">
                  No comments yet. Be the first to share your thoughts!
                </p>
              <% end %>

              <ul class="space-y-3">
                <%= for comment <- @lesson.comments do %>
                  <li class="bg-base-200 rounded-xl p-4">
                    <p class="text-sm text-base-content whitespace-pre-line mb-3">
                      {comment.body}
                    </p>
                    <p class="text-xs text-base-content/60">
                      <%= if comment.user do %>
                        <span class="font-medium">{comment.user.name || comment.user.email}</span>
                      <% else %>
                        <span class="font-medium">Anonymous</span>
                      <% end %>
                      · {Calendar.strftime(comment.inserted_at, "%b %d, %Y at %H:%M")}
                    </p>
                  </li>
                <% end %>
              </ul>

              <%= if @current_user do %>
                <.form
                  for={@comment_form}
                  id="lesson-comment-form"
                  phx-submit="save_comment"
                  class="mt-6"
                >
                  <div class="space-y-2">
                    <textarea
                      name="comment[body]"
                      placeholder="Add a comment..."
                      class="w-full bg-base-200 rounded-lg p-3 text-sm text-base-content placeholder-base-content/50 border-0 focus:outline-none focus:ring-2 focus:ring-primary resize-none"
                      rows="3"
                    />
                    <div class="flex justify-end gap-2">
                      <button type="reset" class="btn btn-ghost btn-sm">Cancel</button>
                      <button type="submit" class="btn btn-primary btn-sm">Comment</button>
                    </div>
                  </div>
                </.form>
              <% else %>
                <div class="mt-6 bg-base-200 rounded-xl p-4 text-center">
                  <p class="text-sm text-base-content/60 mb-3">Sign in to join the discussion</p>
                  <.link navigate={~p"/signin"} class="btn btn-primary btn-sm">Sign in</.link>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Mobile Lesson Dock -->
        <div class="dock fixed bottom-0 left-0 right-0 z-20 lg:hidden bg-base-200 border-t border-base-300">
          <button
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="home"
            class={["dock-item", if(@dock_tab == "home", do: "dock-active", else: "")]}
            aria-label="Home tab"
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
            :if={@lesson.notes_md}
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="notes"
            class={["dock-item", if(@dock_tab == "notes", do: "dock-active", else: "")]}
            aria-label="Notes tab"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            <span class="dock-label text-xs">Notes</span>
          </button>

          <button
            :if={@lesson.resources_md}
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="resources"
            class={["dock-item", if(@dock_tab == "resources", do: "dock-active", else: "")]}
            aria-label="Resources tab"
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

          <button
            :if={@lesson.timestamps_md}
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="timestamps"
            class={["dock-item", if(@dock_tab == "timestamps", do: "dock-active", else: "")]}
            aria-label="Timestamps tab"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span class="dock-label text-xs">Times</span>
          </button>

          <button
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="comments"
            class={["dock-item", if(@dock_tab == "comments", do: "dock-active", else: "")]}
            aria-label="Comments tab"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
            <span class="dock-label text-xs">Comments</span>
          </button>
        </div>
      </div>
      
    <!-- Drawer Side (Up Next) -->
      <div class="drawer-side">
        <label for="lesson-drawer" class="drawer-overlay"></label>
        <aside class="bg-base-200 w-80 flex flex-col">
          <div class="p-4 border-b border-base-300">
            <div class="flex items-center justify-between">
              <div>
                <h2 class="font-semibold text-base-content">Course Videos</h2>
                <p class="text-xs text-base-content/60">{@course.title}</p>
              </div>
              <label for="lesson-drawer" class="btn btn-ghost btn-sm lg:hidden">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </label>
            </div>
          </div>

          <div class="overflow-y-auto flex-1">
            <div :for={course_lesson <- @lessons} class="group">
              <.link
                navigate={~p"/courses/#{@course.slug}/lessons/#{course_lesson.slug}"}
                class={[
                  "flex gap-2 p-2 transition-colors",
                  if(course_lesson.id == @lesson.id,
                    do: "bg-primary/10 border-l-4 border-primary",
                    else: "hover:bg-base-300 border-l-4 border-transparent"
                  )
                ]}
              >
                <div class="relative flex-shrink-0 w-32 aspect-video bg-base-300 rounded overflow-hidden">
                  <img
                    :if={course_lesson.youtube_video_id}
                    src={"https://i.ytimg.com/vi/#{course_lesson.youtube_video_id}/mqdefault.jpg"}
                    alt={course_lesson.title}
                    class="w-full h-full object-cover"
                  />
                  <div :if={!course_lesson.youtube_video_id} class="w-full h-full bg-base-300" />
                  <div
                    :if={course_lesson.id == @lesson.id}
                    class="absolute inset-0 bg-base-content/20 flex items-center justify-center"
                  >
                    <div class="bg-base-content/90 text-base-100 px-2 py-1 rounded text-xs font-bold flex items-center gap-1">
                      <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M6 4h4v16H6zm8 0h4v16h-4z" />
                      </svg>
                      NOW PLAYING
                    </div>
                  </div>
                  <div class="absolute top-1 left-1 bg-base-content text-base-100 px-1.5 py-0.5 rounded text-xs font-bold">
                    #{course_lesson.lesson_number}
                  </div>
                </div>

                <div class="flex-1 min-w-0">
                  <h3 class={[
                    "text-sm font-medium line-clamp-2 mb-1",
                    if(course_lesson.id == @lesson.id,
                      do: "text-primary",
                      else: "text-base-content group-hover:text-primary"
                    )
                  ]}>
                    {course_lesson.title}
                  </h3>
                  <p class="text-xs text-base-content/60">
                    Lesson {course_lesson.lesson_number}
                  </p>
                </div>
              </.link>
            </div>
          </div>

          <div class="p-3 border-t border-base-300">
            <.link
              navigate={~p"/courses/#{@course.slug}"}
              class="btn btn-ghost btn-sm w-full justify-start"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                />
              </svg>
              View all lessons
            </.link>
          </div>
        </aside>
      </div>
    </div>
    """
  end
end
