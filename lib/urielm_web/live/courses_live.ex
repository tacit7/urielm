defmodule UrielmWeb.CoursesLive do
  use UrielmWeb, :live_view
  alias Urielm.Learning

  @impl true
  def mount(params, session, socket) do
    # Handle both direct mount and child mount via live_render
    _child_params = case params do
      :not_mounted_at_router -> session["child_params"] || %{}
      params -> params
    end

    courses = Learning.list_courses()

    {:ok,
     socket
     |> assign(:courses, courses)
     |> assign(:current_page, "courses")
     |> assign(:page_title, "Courses")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-12">
      <div class="text-center mb-12">
        <h1 class="text-4xl font-bold text-base-content mb-4">Courses</h1>
        <p class="text-lg text-base-content/70 max-w-2xl mx-auto">
          Learn AI development through hands-on video tutorials
        </p>
      </div>

      <div :if={Enum.empty?(@courses)} class="text-center py-16 text-base-content/50">
        <svg
          class="w-20 h-20 mx-auto mb-4 text-base-content/40"
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
        <p class="text-xl font-semibold mb-2">No courses yet</p>
        <p class="text-sm">Check back soon for new content</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <.link
          :for={course <- @courses}
          navigate={~p"/courses/#{course.slug}"}
          class="group card bg-base-200 hover:bg-base-300 transition-colors overflow-hidden"
        >
          <figure class="relative aspect-video bg-base-300">
            <div class="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-primary/20 to-secondary/20">
              <svg class="w-16 h-16 text-primary/50" fill="currentColor" viewBox="0 0 24 24">
                <path d="M8 5v14l11-7z" />
              </svg>
            </div>
          </figure>
          <div class="card-body">
            <h2 class="card-title text-base-content group-hover:text-primary transition-colors">
              {course.title}
            </h2>
            <p :if={course.description} class="text-sm text-base-content/70 line-clamp-2">
              {course.description}
            </p>
            <div class="card-actions justify-end mt-4">
              <span class="btn btn-primary btn-sm">View Course</span>
            </div>
          </div>
        </.link>
      </div>
    </div>
    """
  end
end
