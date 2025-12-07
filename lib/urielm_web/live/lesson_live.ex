defmodule UrielmWeb.LessonLive do
  use UrielmWeb, :live_view
  alias Urielm.Learning
  alias Urielm.Learning.LessonComment

  @impl true
  def mount(%{"course_slug" => course_slug, "lesson_slug" => lesson_slug}, _session, socket) do
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

            {:ok,
             socket
             |> assign(:course, course)
             |> assign(:lesson, lesson)
             |> assign(:lessons, lessons)
             |> assign(:comment_changeset, changeset)
             |> assign(:comment_form, Phoenix.Component.to_form(changeset, as: :comment))
             |> assign(:current_page, "courses")
             |> assign(:page_title, lesson.title)
             |> assign(:dock_tab, "home")}
        end
    end
  end

  @impl true
  def handle_event("set_dock_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :dock_tab, tab)}
  end

  @impl true
  def handle_event("comment_focus", _params, socket) do
    user = socket.assigns[:current_user]

    if !user do
      {:noreply,
       socket
       |> put_flash(:info, "Sign in to comment on this lesson.")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_comment", %{"comment" => params}, socket) do
    user = socket.assigns[:current_user]

    if !user do
      {:noreply,
       socket
       |> put_flash(:info, "Sign in to comment on this lesson.")}
    else
      lesson = socket.assigns.lesson

      attrs =
        params
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
          />
        </div>

        <!-- Main Content -->
        <div class="max-w-[1800px] mx-auto w-full px-4 py-6">
          <!-- Mobile Sticky Header -->
          <div class="flex items-center justify-between gap-2 mb-4 lg:hidden">
            <.link
              navigate={~p"/courses/#{@course.slug}"}
              class="btn btn-ghost btn-sm btn-circle"
              title="Back to course"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
            </.link>
            <h1 class="text-lg font-bold text-base-content truncate flex-1">{@lesson.title}</h1>
          </div>

          <!-- Video Title -->
          <h1 class="text-2xl font-bold text-base-content mb-3 hidden lg:block">{@lesson.title}</h1>

          <!-- Dock Content Sections -->
          <div class="space-y-4 pb-24 lg:pb-0">
            <!-- HOME TAB -->
            <div class={["space-y-4", if(@dock_tab != "home", do: "hidden lg:block")]}>
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

              <div :if={@lesson.body} class="bg-base-200 rounded-xl p-4">
                <p class="text-sm text-base-content/80 whitespace-pre-wrap">{@lesson.body}</p>
              </div>

              <div :if={@course.description} class="mt-4 bg-base-200 rounded-xl p-4">
                <h3 class="font-semibold text-base-content mb-2">About this course</h3>
                <p class="text-sm text-base-content/70">{@course.description}</p>
              </div>
            </div>

            <!-- NOTES TAB -->
            <div class={["space-y-4", if(@dock_tab != "notes", do: "hidden lg:block")]}>
              <h3 class="text-lg font-semibold text-base-content">Lesson notes</h3>
              <div :if={@lesson.body} class="bg-base-200 rounded-xl p-4">
                <p class="text-sm text-base-content/80 whitespace-pre-wrap">{@lesson.body}</p>
              </div>
              <div :if={!@lesson.body} class="text-sm text-base-content/60 text-center py-8">
                No notes available for this lesson.
              </div>
            </div>

            <!-- RESOURCES TAB -->
            <div class={["space-y-4", if(@dock_tab != "resources", do: "hidden lg:block")]}>
              <h3 class="text-lg font-semibold text-base-content">Resources</h3>
              <p class="text-sm text-base-content/70">Coming soon: links, downloads, repo, and more resources.</p>
            </div>

            <!-- TIMESTAMPS TAB -->
            <div class={["space-y-4", if(@dock_tab != "timestamps", do: "hidden lg:block")]}>
              <h3 class="text-lg font-semibold text-base-content">Timestamps</h3>
              <ul class="text-sm text-primary space-y-2">
                <li>
                  <button type="button" class="link">00:00 Introduction</button>
                </li>
                <li>
                  <button type="button" class="link">02:30 Core concepts</button>
                </li>
                <li>
                  <button type="button" class="link">05:00 Examples</button>
                </li>
              </ul>
            </div>
          </div>

          <!-- Comments Section -->
          <section class="mt-8 space-y-4">
            <h2 class="text-xl font-semibold text-base-content">Comments</h2>

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
                  phx-focus="comment_focus"
                  class="w-full bg-base-200 rounded-lg p-3 text-sm text-base-content placeholder-base-content/50 border-0 focus:outline-none focus:ring-2 focus:ring-primary resize-none"
                  rows="3"
                />
                <div class="flex justify-end gap-2">
                  <button type="reset" class="btn btn-ghost btn-sm">Cancel</button>
                  <button type="submit" class="btn btn-primary btn-sm">Comment</button>
                </div>
              </div>
            </.form>
          </section>
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
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span class="dock-label text-xs">Home</span>
          </button>

          <button
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="notes"
            class={["dock-item", if(@dock_tab == "notes", do: "dock-active", else: "")]}
            aria-label="Notes tab"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            <span class="dock-label text-xs">Notes</span>
          </button>

          <button
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="resources"
            class={["dock-item", if(@dock_tab == "resources", do: "dock-active", else: "")]}
            aria-label="Resources tab"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
            </svg>
            <span class="dock-label text-xs">Resources</span>
          </button>

          <button
            type="button"
            phx-click="set_dock_tab"
            phx-value-tab="timestamps"
            class={["dock-item", if(@dock_tab == "timestamps", do: "dock-active", else: "")]}
            aria-label="Timestamps tab"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span class="dock-label text-xs">Times</span>
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
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
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
                    src={"https://i.ytimg.com/vi/#{course_lesson.youtube_video_id}/mqdefault.jpg"}
                    alt={course_lesson.title}
                    class="w-full h-full object-cover"
                  />
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
