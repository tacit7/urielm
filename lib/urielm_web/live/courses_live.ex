defmodule UrielmWeb.CoursesLive do
  use UrielmWeb, :live_view
  alias Urielm.Learning

  @impl true
  def mount(params, session, socket) do
    _child_params =
      case params do
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
    <div id="courses-index" class="min-h-screen bg-base-100">
      <div class="ui-page-shell">
        <header id="courses-index-header" class="ui-page-header">
          <div class="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
            <div class="ui-page-heading">
              <h1 class="ui-section-title">Courses</h1>
              <p class="ui-section-copy">
                Practical, focused paths for building useful things with AI.
              </p>
            </div>
            <span class="badge badge-outline h-auto self-start px-3 py-2 font-mono text-xs text-base-content/60 sm:self-auto">
              {length(@courses)} {if length(@courses) == 1, do: "course", else: "courses"}
            </span>
          </div>
        </header>

        <.empty_state
          :if={@courses == []}
          id="courses-empty-state"
          title="New courses are on the way"
          description="Check back soon for guided lessons, practical examples, and complete learning paths."
          icon="hero-academic-cap"
        />

        <div :if={@courses != []} id="courses-collection">
          <.featured_course course={hd(@courses)} index={1} />

          <div :if={tl(@courses) != []} class="mt-5 grid grid-cols-1 gap-5 md:grid-cols-2">
            <.course_card
              :for={{course, i} <- Enum.with_index(tl(@courses), 2)}
              course={course}
              index={i}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :course, :map, required: true
  attr :index, :integer, required: true

  defp featured_course(assigns) do
    assigns =
      assigns
      |> assign(:thumb, get_thumb(assigns.course))
      |> assign(:num, String.pad_leading(to_string(assigns.index), 2, "0"))
      |> assign(:lesson_count, length(assigns.course.lessons))

    ~H"""
    <.link
      id={"featured-course-#{@course.id}"}
      navigate={~p"/courses/#{@course.slug}"}
      class="ui-card ui-card-interactive group relative block h-[330px] overflow-hidden sm:h-[380px] lg:h-[420px]"
    >
      <div class="absolute inset-0">
        <img
          :if={@thumb}
          src={@thumb}
          alt={@course.title}
          class="w-full h-full object-cover scale-100 group-hover:scale-105 transition-transform duration-700 ease-out"
        />
        <div :if={!@thumb} class="w-full h-full bg-base-300" />
      </div>

      <div class="absolute inset-0 bg-gradient-to-t from-[#10121f]/95 via-[#10121f]/45 to-[#10121f]/10" />

      <div class="absolute inset-0 flex flex-col justify-end p-6 sm:p-8 lg:p-10">
        <div class="mb-4 flex flex-wrap items-center gap-2.5">
          <span class="badge border-white/20 bg-white/10 font-mono text-xs uppercase tracking-widest text-[#f2f4ff]">
            {@num} · Featured
          </span>
          <span class="font-mono text-xs text-[#c0caf5]">
            {@lesson_count} {if @lesson_count == 1, do: "lesson", else: "lessons"}
          </span>
        </div>

        <h2 class="mb-3 max-w-3xl text-3xl font-black leading-tight text-[#f2f4ff] transition-colors duration-300 group-hover:text-primary sm:text-4xl lg:text-5xl">
          {@course.title}
        </h2>

        <p
          :if={@course.description}
          class="mb-6 max-w-2xl line-clamp-2 text-sm leading-relaxed text-[#c0caf5] sm:text-base"
        >
          {@course.description}
        </p>

        <div class="flex items-center gap-2 text-sm font-bold text-primary">
          <span>Start course</span>
          <.um_icon
            name="hero-arrow-right"
            class="size-4 transition-transform duration-300 group-hover:translate-x-1"
          />
        </div>
      </div>
    </.link>
    """
  end

  attr :course, :map, required: true
  attr :index, :integer, required: true

  defp course_card(assigns) do
    assigns =
      assigns
      |> assign(:thumb, get_thumb(assigns.course))
      |> assign(:num, String.pad_leading(to_string(assigns.index), 2, "0"))
      |> assign(:lesson_count, length(assigns.course.lessons))

    ~H"""
    <.link
      id={"course-card-#{@course.id}"}
      navigate={~p"/courses/#{@course.slug}"}
      class="ui-card ui-card-interactive group relative block h-[230px] overflow-hidden sm:h-[260px] lg:h-[280px]"
    >
      <div class="absolute inset-0">
        <img
          :if={@thumb}
          src={@thumb}
          alt={@course.title}
          class="w-full h-full object-cover scale-100 group-hover:scale-105 transition-transform duration-700 ease-out"
        />
        <div :if={!@thumb} class="w-full h-full bg-base-300" />
      </div>

      <div class="absolute inset-0 bg-gradient-to-t from-[#10121f]/95 via-[#10121f]/35 to-transparent" />

      <div class="absolute inset-0 flex flex-col justify-end p-5 sm:p-6">
        <div class="mb-2.5 flex items-center gap-2.5">
          <span class="badge border-white/20 bg-white/10 font-mono text-xs text-[#f2f4ff]">
            {@num}
          </span>
          <span class="font-mono text-xs text-[#c0caf5]">
            {@lesson_count} {if @lesson_count == 1, do: "lesson", else: "lessons"}
          </span>
        </div>

        <h2 class="mb-1 line-clamp-2 text-xl font-black leading-tight text-[#f2f4ff] transition-colors duration-300 group-hover:text-primary sm:text-2xl">
          {@course.title}
        </h2>

        <p
          :if={@course.description}
          class="mb-4 line-clamp-1 text-xs leading-relaxed text-[#c0caf5]"
        >
          {@course.description}
        </p>

        <div class="flex items-center gap-1.5 text-xs font-bold text-primary">
          <span>View course</span>
          <.um_icon
            name="hero-arrow-right"
            class="size-3.5 transition-transform duration-300 group-hover:translate-x-1"
          />
        </div>
      </div>
    </.link>
    """
  end

  defp get_thumb(course) do
    case List.first(course.lessons) do
      nil -> nil
      lesson -> "https://img.youtube.com/vi/#{lesson.youtube_video_id}/mqdefault.jpg"
    end
  end
end
