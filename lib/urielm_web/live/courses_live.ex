defmodule UrielmWeb.CoursesLive do
  use UrielmWeb, :live_view
  alias Urielm.Learning
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, session, socket) do
    _child_params =
      case params do
        :not_mounted_at_router -> session["child_params"] || %{}
        params -> params
      end

    courses = Learning.list_courses_for_index()

    {:ok,
     socket
     |> assign(:courses, courses)
     |> assign(:current_page, "courses")
     |> assign(:page_title, "Courses")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="courses-index" class="min-h-screen bg-base-100">
      <div class="mx-auto w-full max-w-[118rem] px-4 py-6 sm:px-6 lg:px-8">
        <header
          id="courses-index-header"
          class="mb-7 flex items-center justify-between gap-4"
        >
          <h1 class="sr-only">Courses</h1>

          <div>
            <p class="text-sm font-semibold text-base-content/60">
              {length(@courses)} {if length(@courses) == 1, do: "playlist", else: "playlists"}
            </p>
          </div>

          <button
            id="courses-sort-button"
            type="button"
            class="btn btn-ghost min-h-11 gap-2 rounded-lg px-3 text-sm font-bold text-base-content"
          >
            <.um_icon name="hero-bars-arrow-down" class="size-5" />
            <span>Sort by</span>
          </button>
        </header>

        <.empty_state
          :if={@courses == []}
          id="courses-empty-state"
          title="New courses are on the way"
          description="Check back soon for guided lessons, practical examples, and complete learning paths."
          icon="hero-academic-cap"
        />

        <div
          :if={@courses != []}
          id="courses-collection"
          class="grid grid-cols-1 gap-x-5 gap-y-9 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5"
        >
          <.course_card
            :for={{course, i} <- Enum.with_index(@courses, 1)}
            course={course}
            index={i}
          />
        </div>
      </div>
    </div>
    """
  end

  attr :course, :map, required: true
  attr :index, :integer, required: true

  defp course_card(assigns) do
    assigns =
      assigns
      |> assign(:thumb, get_thumb(assigns.course))
      |> assign(:lesson_count, length(assigns.course.lessons))
      |> assign(:card_id, course_card_id(assigns.course, assigns.index))

    ~H"""
    <article id={@card_id} class="group min-w-0">
      <.link
        navigate={~p"/courses/#{@course.slug}"}
        aria-label={"View #{@course.title} playlist"}
        class="block focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-4 focus-visible:ring-offset-base-100"
      >
        <div class="relative mb-3 pt-3">
          <div class="absolute inset-x-5 top-0 h-4 rounded-t-xl bg-base-content/25 transition duration-200 group-hover:inset-x-4 group-hover:bg-primary/25" />
          <div class="absolute inset-x-3 top-1.5 h-4 rounded-t-xl bg-base-content/35 transition duration-200 group-hover:inset-x-2 group-hover:bg-primary/35" />

          <div class="relative aspect-video overflow-hidden rounded-xl bg-base-300 shadow-md shadow-base-content/10">
            <img
              :if={@thumb}
              src={@thumb}
              alt={@course.title}
              class="h-full w-full object-cover transition duration-500 ease-out group-hover:scale-105"
            />
            <div
              :if={!@thumb}
              class="grid h-full w-full place-items-center bg-base-200 text-base-content/35"
            >
              <.um_icon name="hero-academic-cap" class="size-10" />
            </div>

            <div class="absolute inset-x-0 bottom-0 flex justify-end bg-gradient-to-t from-[#10121f]/80 to-transparent p-2">
              <span class="inline-flex items-center gap-1.5 rounded-lg bg-[#10121f]/80 px-2.5 py-1.5 text-xs font-black text-white shadow-sm backdrop-blur">
                <.um_icon name="hero-list-bullet" class="size-4" />
                {video_count_text(@lesson_count)}
              </span>
            </div>
          </div>
        </div>

        <div class="min-w-0">
          <h2 class="line-clamp-2 text-base font-black leading-snug text-base-content transition-colors duration-200 group-hover:text-primary sm:text-lg">
            {@course.title}
          </h2>

          <p class="mt-1 text-sm font-semibold text-base-content/55">
            {updated_label(@course)}
          </p>

          <p class="mt-1 text-sm font-bold text-base-content/70 transition-colors duration-200 group-hover:text-primary">
            View full playlist
          </p>
        </div>
      </.link>
    </article>
    """
  end

  defp course_card_id(course, 1), do: "featured-course-#{course.id}"
  defp course_card_id(course, _index), do: "course-card-#{course.id}"

  defp get_thumb(course) do
    case List.first(course.lessons) do
      nil -> nil
      lesson -> "https://i.ytimg.com/vi/#{lesson.youtube_video_id}/hqdefault.jpg"
    end
  end

  defp video_count_text(1), do: "1 video"
  defp video_count_text(count), do: "#{count} videos"

  defp updated_label(%{updated_at: nil}), do: "View full playlist"
  defp updated_label(course), do: "Updated #{LiveHelpers.format_relative(course.updated_at)}"
end
