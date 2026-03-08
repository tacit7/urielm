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
    <div class="min-h-screen">
      <!-- Header -->
      <div class="px-6 md:px-12 lg:px-16 pt-12 pb-10">
        <div class="flex items-end justify-between">
          <div>
            <p class="text-xs font-mono tracking-widest text-base-content/40 uppercase mb-2">
              Learning / Courses
            </p>
            <h1 class="text-5xl font-black tracking-tight text-base-content leading-none">
              Courses
            </h1>
          </div>
          <p class="text-sm font-mono text-base-content/40 pb-1">
            {length(@courses)} {if length(@courses) == 1, do: "course", else: "courses"}
          </p>
        </div>
        <div class="mt-6 h-px bg-base-content/10" />
      </div>

      <!-- Content -->
      <div class="px-6 md:px-12 lg:px-16 pb-16">
        <!-- Empty state -->
        <div :if={@courses == []} class="flex flex-col items-center justify-center py-36">
          <p class="font-mono font-black text-8xl text-base-content/10 select-none mb-6">00</p>
          <p class="text-base-content/40 text-xs font-mono tracking-[0.3em] uppercase">
            No courses yet
          </p>
        </div>

        <!-- Featured first + grid -->
        <div :if={@courses != []}>
          <.featured_course course={hd(@courses)} index={1} />

          <div :if={tl(@courses) != []} class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
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
      navigate={~p"/courses/#{@course.slug}"}
      class="group block relative rounded-2xl overflow-hidden h-[400px] md:h-[480px]"
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

      <div class="absolute inset-0 bg-gradient-to-t from-base-content/90 via-base-content/30 to-base-content/5" />

      <div class="absolute top-4 right-6 font-mono font-black text-[8rem] leading-none select-none text-base-100/10 group-hover:text-primary/20 transition-colors duration-500">
        {@num}
      </div>

      <div class="absolute inset-0 flex flex-col justify-end p-8">
        <div class="flex items-center gap-3 mb-3">
          <span class="font-mono text-xs tracking-widest uppercase text-base-100/50">
            Course {@num}
          </span>
          <span class="w-1 h-1 rounded-full bg-base-100/30" />
          <span class="font-mono text-xs text-base-100/50">
            {@lesson_count} {if @lesson_count == 1, do: "lesson", else: "lessons"}
          </span>
        </div>

        <h2 class="text-3xl md:text-4xl font-black text-base-100 leading-tight mb-3 group-hover:text-primary transition-colors duration-300">
          {@course.title}
        </h2>

        <p
          :if={@course.description}
          class="text-base-100/70 text-sm leading-relaxed max-w-xl line-clamp-2 mb-6"
        >
          {@course.description}
        </p>

        <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 translate-y-2 group-hover:translate-y-0 transition-all duration-300">
          <span class="text-sm font-bold text-primary">Start watching</span>
          <svg class="w-4 h-4 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2.5"
              d="M17 8l4 4m0 0l-4 4m4-4H3"
            />
          </svg>
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
      navigate={~p"/courses/#{@course.slug}"}
      class="group block relative rounded-2xl overflow-hidden h-[260px] md:h-[300px]"
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

      <div class="absolute inset-0 bg-gradient-to-t from-base-content/88 via-base-content/20 to-transparent" />

      <div class="absolute top-3 right-5 font-mono font-black text-[5rem] leading-none select-none text-base-100/10 group-hover:text-primary/20 transition-colors duration-500">
        {@num}
      </div>

      <div class="absolute inset-0 flex flex-col justify-end p-5">
        <div class="flex items-center gap-2 mb-2">
          <span class="font-mono text-xs tracking-widest uppercase text-base-100/50">
            {@num}
          </span>
          <span class="w-1 h-1 rounded-full bg-base-100/30" />
          <span class="font-mono text-xs text-base-100/50">
            {@lesson_count} {if @lesson_count == 1, do: "lesson", else: "lessons"}
          </span>
        </div>

        <h2 class="text-xl font-black text-base-100 leading-tight mb-1 group-hover:text-primary transition-colors duration-300 line-clamp-2">
          {@course.title}
        </h2>

        <p
          :if={@course.description}
          class="text-base-100/60 text-xs leading-relaxed line-clamp-1 mb-4"
        >
          {@course.description}
        </p>

        <div class="flex items-center gap-1.5 opacity-0 group-hover:opacity-100 translate-y-1.5 group-hover:translate-y-0 transition-all duration-300">
          <span class="text-xs font-bold text-primary">View course</span>
          <svg class="w-3 h-3 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2.5"
              d="M17 8l4 4m0 0l-4 4m4-4H3"
            />
          </svg>
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
