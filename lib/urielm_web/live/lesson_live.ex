defmodule UrielmWeb.LessonLive do
  use UrielmWeb, :live_view
  alias Urielm.Learning

  @impl true
  def mount(%{"course_slug" => course_slug, "lesson_slug" => lesson_slug}, _session, socket) do
    case Learning.get_course_by_slug(course_slug) do
      nil ->
        {:ok, socket
         |> put_flash(:error, "Course not found")
         |> push_navigate(to: ~p"/")}

      course ->
        case Learning.get_lesson_by_slug(course.id, lesson_slug) do
          nil ->
            {:ok, socket
             |> put_flash(:error, "Lesson not found")
             |> push_navigate(to: ~p"/")}

          lesson ->
            {:ok, socket
             |> assign(:course, course)
             |> assign(:lesson, lesson)
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
  def render(assigns) do
    ~H"""
    <div class="max-w-[1800px] mx-auto px-4 py-6">
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

          <!-- Video Title & Toggle -->
          <div class="flex items-start justify-between gap-4 mb-3">
            <h1 class="text-2xl font-bold text-base-content flex-1">{@lesson.title}</h1>
            <button
              phx-click="toggle_sidebar"
              class="btn btn-ghost btn-sm btn-square lg:flex hidden"
              title={if @sidebar_open, do: "Hide sidebar", else: "Show sidebar"}
            >
              <svg :if={@sidebar_open} class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
              <svg :if={!@sidebar_open} class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
            </button>
          </div>

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
        </div>

        <!-- Sidebar - More from this course -->
        <div class={["lg:col-span-1", unless(@sidebar_open, do: "hidden")]}>
          <div class="bg-base-200 rounded-xl p-4 sticky top-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="font-semibold text-base-content">Course Videos</h2>
              <.link navigate={~p"/courses/#{@course.slug}"} class="text-xs text-primary hover:underline">
                View all
              </.link>
            </div>

            <.link
              navigate={~p"/courses/#{@course.slug}"}
              class="block mb-4 pb-4 border-b border-base-300 hover:bg-base-300/50 rounded-lg p-2 transition-colors"
            >
              <div class="flex items-center gap-2 text-sm">
                <svg class="w-4 h-4 text-primary" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M4 4h16v2H4zm0 5h16v2H4zm0 5h16v2H4zm0 5h16v2H4z"/>
                </svg>
                <span class="font-medium text-base-content">View full playlist</span>
              </div>
            </.link>

            <p class="text-xs text-base-content/60 text-center py-8">
              More lessons coming soon...
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
