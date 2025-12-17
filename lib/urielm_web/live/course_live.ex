defmodule UrielmWeb.CourseLive do
  use UrielmWeb, :live_view
  alias Urielm.Learning

  @impl true
  def mount(%{"course_slug" => course_slug}, _session, socket) do
    case Learning.get_course_by_slug(course_slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Course not found")
         |> push_navigate(to: ~p"/")}

      course ->
        lessons = Learning.list_lessons(course.id)

        {:ok,
         socket
         |> assign(:course, course)
         |> assign(:lessons, lessons)
         |> assign(:current_page, "courses")
         |> assign(:page_title, course.title)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="courses" socket={@socket}>
    <div class="max-w-7xl mx-auto px-4 py-6">
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Playlist Header (YouTube-style) -->
        <div class="lg:col-span-1">
          <div class="bg-base-200 rounded-xl overflow-hidden sticky top-6">
            <!-- Playlist Thumbnail -->
            <div class="relative aspect-video bg-base-300">
              <img
                :if={@lessons != [] && hd(@lessons).youtube_video_id}
                src={"https://i.ytimg.com/vi/#{hd(@lessons).youtube_video_id}/hqdefault.jpg"}
                alt={@course.title}
                class="w-full h-full object-cover"
              />
              <div class="absolute inset-0 bg-base-content/60 flex items-center justify-center">
                <div class="text-center">
                  <svg
                    class="w-16 h-16 mx-auto mb-2 text-base-100"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path d="M8 5v14l11-7z" />
                  </svg>
                  <p class="text-base-100 font-semibold text-sm">PLAY ALL</p>
                </div>
              </div>
              <div class="absolute bottom-2 right-2 bg-base-content/90 text-base-100 px-2 py-1 rounded text-xs font-semibold">
                {length(@lessons)} videos
              </div>
            </div>
            
    <!-- Playlist Info -->
            <div class="p-4">
              <h1 class="text-xl font-bold text-base-content mb-2">{@course.title}</h1>
              <p :if={@course.description} class="text-sm text-base-content/70 mb-4 line-clamp-3">
                {@course.description}
              </p>

              <a
                :if={@course.youtube_playlist_id}
                href={"https://www.youtube.com/playlist?list=#{@course.youtube_playlist_id}"}
                target="_blank"
                rel="noopener noreferrer"
                class="btn btn-primary btn-sm w-full"
              >
                <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
                </svg>
                View on YouTube
              </a>
            </div>
          </div>
        </div>
        
    <!-- Videos List (YouTube-style) -->
        <div class="lg:col-span-2">
          <div :if={Enum.empty?(@lessons)} class="text-center py-12 text-base-content/50">
            <svg
              class="w-16 h-16 mx-auto mb-4 text-base-content/40"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
              />
            </svg>
            <p class="text-lg font-semibold mb-2">No videos yet</p>
            <p class="text-sm">Check back soon for new content</p>
          </div>

          <div class="space-y-3">
            <div :for={lesson <- @lessons} class="group">
              <.link
                navigate={~p"/courses/#{@course.slug}/lessons/#{lesson.slug}"}
                class="flex gap-3 hover:bg-base-200 rounded-lg p-2 transition-colors"
              >
                <!-- Video Thumbnail -->
                <div class="relative flex-shrink-0 w-40 aspect-video bg-base-300 rounded-lg overflow-hidden">
                  <img
                    src={"https://i.ytimg.com/vi/#{lesson.youtube_video_id}/mqdefault.jpg"}
                    alt={lesson.title}
                    class="w-full h-full object-cover"
                  />
                  <div class="absolute inset-0 bg-base-content/0 group-hover:bg-base-content/10 transition-colors flex items-center justify-center">
                    <svg
                      class="w-8 h-8 text-base-100 opacity-0 group-hover:opacity-100 transition-opacity"
                      fill="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path d="M8 5v14l11-7z" />
                    </svg>
                  </div>
                  <div class="absolute top-1 left-1 bg-base-content text-base-100 px-1.5 py-0.5 rounded text-xs font-bold">
                    #{lesson.lesson_number}
                  </div>
                </div>
                
    <!-- Video Info -->
                <div class="flex-1 min-w-0">
                  <h3 class="font-semibold text-base-content group-hover:text-primary transition-colors mb-1 line-clamp-2">
                    {lesson.title}
                  </h3>
                  <p :if={lesson.body} class="text-sm text-base-content/70 line-clamp-2 mb-2">
                    {lesson.body}
                  </p>
                  <div class="flex items-center gap-2 text-xs text-base-content/60">
                    <span>Lesson {lesson.lesson_number}</span>
                  </div>
                </div>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    </Layouts.app>
    """
  end
end
