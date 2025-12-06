defmodule UrielmWeb.LessonLive do
  use UrielmWeb, :live_view
  alias Urielm.Learning
  alias Urielm.Learning.LessonComment

  @impl true
  def mount(%{"course_slug" => course_slug, "lesson_slug" => lesson_slug}, _session, socket) do
    case Learning.get_course_by_slug(course_slug) do
      nil ->
        {:ok, socket
         |> put_flash(:error, "Course not found")
         |> push_navigate(to: ~p"/")}

      course ->
        case Learning.get_lesson_with_comments(course.id, lesson_slug) do
          nil ->
            {:ok, socket
             |> put_flash(:error, "Lesson not found")
             |> push_navigate(to: ~p"/")}

          lesson ->
            lessons = Learning.list_lessons(course.id)
            changeset = Learning.change_lesson_comment(%LessonComment{})

            {:ok, socket
             |> assign(:course, course)
             |> assign(:lesson, lesson)
             |> assign(:lessons, lessons)
             |> assign(:comment_changeset, changeset)
             |> assign(:comment_form, Phoenix.Component.to_form(changeset, as: :comment))
             |> assign(:current_page, "courses")
             |> assign(:sidebar_open, true)
             |> assign(:page_title, lesson.title)}
        end
    end
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("save_comment", %{"comment" => params}, socket) do
    lesson = socket.assigns.lesson
    user = socket.assigns[:current_user]

    attrs =
      params
      |> Map.put("lesson_id", lesson.id)
      |> Map.put("user_id", user && user.id)

    case Learning.create_lesson_comment(attrs) do
      {:ok, _comment} ->
        lesson = Learning.get_lesson_with_comments(socket.assigns.course.id, lesson.slug)

        {:noreply,
         socket
         |> put_flash(:info, "Comment added.")
         |> assign(:lesson, lesson)
         |> assign(:comment_changeset, Learning.change_lesson_comment(%LessonComment{}))
         |> assign(:comment_form,
           Phoenix.Component.to_form(Learning.change_lesson_comment(%LessonComment{}), as: :comment)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:comment_changeset, changeset)
         |> assign(:comment_form, Phoenix.Component.to_form(changeset, as: :comment))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[1800px] mx-auto px-4 py-6 relative">
      <div class={["grid grid-cols-1 gap-6", if(@sidebar_open, do: "lg:grid-cols-3", else: "lg:grid-cols-1")]}>
        <!-- Main Content -->
        <div class={if @sidebar_open, do: "lg:col-span-2", else: "lg:col-span-1"}>
          <!-- Video Player -->
          <div class="aspect-video bg-base-content rounded-xl overflow-hidden mb-4">
            <iframe
              src={"https://www.youtube.com/embed/#{@lesson.youtube_video_id}"}
              title={@lesson.title}
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowfullscreen
              class="w-full h-full"
            >
            </iframe>
          </div>

          <!-- Video Title -->
          <h1 class="text-2xl font-bold text-base-content mb-3">{@lesson.title}</h1>

          <!-- Course/Channel Info -->
          <div class="flex items-start justify-between gap-4 pb-4 border-b border-base-300 mb-4">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
              <div>
                <.link navigate={~p"/courses/#{@course.slug}"} class="font-semibold text-base-content hover:text-primary">
                  {@course.title}
                </.link>
                <p class="text-xs text-base-content/60">Lesson {@lesson.lesson_number}</p>
              </div>
            </div>

            <a
              :if={@course.youtube_playlist_id}
              href={"https://www.youtube.com/playlist?list=#{@course.youtube_playlist_id}"}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-primary btn-sm"
            >
              <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 24 24">
                <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
              </svg>
              YouTube
            </a>
          </div>

          <!-- Description -->
          <div :if={@lesson.body} class="bg-base-200 rounded-xl p-4">
            <p class="text-sm text-base-content/80 whitespace-pre-wrap">{@lesson.body}</p>
          </div>

          <div :if={@course.description} class="mt-4 bg-base-200 rounded-xl p-4">
            <h3 class="font-semibold text-base-content mb-2">About this course</h3>
            <p class="text-sm text-base-content/70">{@course.description}</p>
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
                    <%= comment.body %>
                  </p>
                  <p class="text-xs text-base-content/60">
                    <%= if comment.user do %>
                      <span class="font-medium"><%= comment.user.name || comment.user.email %></span>
                    <% else %>
                      <span class="font-medium">Anonymous</span>
                    <% end %>
                    · <%= Calendar.strftime(comment.inserted_at, "%b %d, %Y at %H:%M") %>
                  </p>
                </li>
              <% end %>
            </ul>

            <.form for={@comment_form} id="lesson-comment-form" phx-submit="save_comment" class="mt-6 space-y-3">
              <.input
                field={@comment_form[:body]}
                type="textarea"
                rows="3"
                label="Add a comment"
                placeholder="Share your thoughts about this lesson..."
              />
              <button class="btn btn-primary btn-sm">Post Comment</button>
            </.form>
          </section>
        </div>

        <!-- Sidebar - Course Videos -->
        <div class={["lg:col-span-1", unless(@sidebar_open, do: "hidden")]}>
          <div class="bg-base-200 rounded-xl overflow-hidden sticky top-6">
            <div class="p-4 border-b border-base-300">
              <div class="flex items-center justify-between">
                <div>
                  <h2 class="font-semibold text-base-content">Course Videos</h2>
                  <p class="text-xs text-base-content/60">{@course.title}</p>
                </div>
              </div>
            </div>

            <div class="max-h-[calc(100vh-12rem)] overflow-y-auto">
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
                  <!-- Thumbnail -->
                  <div class="relative flex-shrink-0 w-32 aspect-video bg-base-300 rounded overflow-hidden">
                    <img
                      src={"https://i.ytimg.com/vi/#{course_lesson.youtube_video_id}/mqdefault.jpg"}
                      alt={course_lesson.title}
                      class="w-full h-full object-cover"
                    />
                    <div :if={course_lesson.id == @lesson.id} class="absolute inset-0 bg-base-content/20 flex items-center justify-center">
                      <div class="bg-base-content/90 text-base-100 px-2 py-1 rounded text-xs font-bold flex items-center gap-1">
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M6 4h4v16H6zm8 0h4v16h-4z"/>
                        </svg>
                        NOW PLAYING
                      </div>
                    </div>
                    <div class="absolute top-1 left-1 bg-base-content text-base-100 px-1.5 py-0.5 rounded text-xs font-bold">
                      #{course_lesson.lesson_number}
                    </div>
                  </div>

                  <!-- Info -->
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
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
                View all lessons
              </.link>
            </div>
          </div>
        </div>
      </div>

      <!-- Toggle Buttons -->
      <button
        :if={@sidebar_open}
        phx-click="toggle_sidebar"
        class="fixed right-[calc((100vw-1800px)/2+600px)] top-1/2 -translate-y-1/2 -translate-x-1/2 z-20 btn btn-circle btn-sm bg-base-200 border-2 border-base-300 hover:bg-base-300 shadow-lg hidden lg:flex"
        title="Hide sidebar"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
        </svg>
      </button>

      <button
        :if={!@sidebar_open}
        phx-click="toggle_sidebar"
        class="fixed right-8 top-1/2 -translate-y-1/2 z-20 btn btn-circle btn-primary shadow-lg hidden lg:flex"
        title="Show sidebar"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
    </div>
    """
  end
end
