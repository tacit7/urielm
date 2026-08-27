defmodule UrielmWeb.CourseLive do
  use UrielmWeb, :live_view
  alias Urielm.Learning

  @impl true
  def mount(params, session, socket) do
    child_params =
      case params do
        :not_mounted_at_router -> session["child_params"] || %{}
        params -> params
      end

    course_slug = child_params["course_slug"]

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
         |> assign(:first_lesson, List.first(lessons))
         |> assign(:show_description, false)
         |> assign(:current_page, "courses")
         |> assign(:page_title, course.title)}
    end
  end

  @impl true
  def handle_event("toggle_description", _params, socket) do
    {:noreply, assign(socket, :show_description, !socket.assigns.show_description)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="course-detail" class="min-h-screen bg-base-100">
      <section id="course-detail-hero" class="relative h-[420px] w-full overflow-hidden md:h-[500px]">
        <div class="absolute inset-0">
          <img
            :if={@first_lesson && @first_lesson.youtube_video_id}
            src={"https://i.ytimg.com/vi/#{@first_lesson.youtube_video_id}/hqdefault.jpg"}
            alt={@course.title}
            class="w-full h-full object-cover"
          />
          <div
            :if={!@first_lesson || !@first_lesson.youtube_video_id}
            class="w-full h-full bg-base-300"
          />
        </div>

        <div class="absolute inset-0 bg-gradient-to-t from-[#10121f]/95 via-[#10121f]/45 to-[#10121f]/15" />

        <div class="absolute inset-x-0 top-0 mx-auto max-w-7xl px-5 pt-6 sm:px-7 lg:px-10">
          <.link
            navigate={~p"/courses"}
            class="inline-flex items-center gap-2 font-mono text-xs uppercase tracking-widest text-[#c0caf5] transition-colors hover:text-white"
          >
            <.um_icon name="hero-arrow-left" class="size-3.5" /> Courses
          </.link>
        </div>

        <div class="absolute inset-x-0 bottom-0 mx-auto max-w-7xl px-5 pb-9 sm:px-7 md:pb-11 lg:px-10">
          <p class="mb-3 font-mono text-xs uppercase tracking-widest text-[#c0caf5]">
            {length(@lessons)} {if length(@lessons) == 1, do: "lesson", else: "lessons"}
          </p>

          <h1 class="mb-5 max-w-4xl text-4xl font-black leading-none tracking-tight text-[#f2f4ff] md:text-5xl lg:text-6xl">
            {@course.title}
          </h1>

          <div class="flex flex-wrap items-center gap-4 sm:gap-6">
            <.link
              :if={@first_lesson}
              navigate={~p"/courses/#{@course.slug}/lessons/#{@first_lesson.slug}"}
              class="btn btn-primary btn-sm gap-2 rounded-full px-5 sm:btn-md"
            >
              <.um_icon name="hero-play" class="size-4" /> Start watching
            </.link>

            <a
              :if={@course.youtube_playlist_id}
              href={"https://www.youtube.com/playlist?list=#{@course.youtube_playlist_id}"}
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-2 font-mono text-xs uppercase tracking-widest text-[#c0caf5] transition-colors hover:text-white"
            >
              <.um_icon name="hero-arrow-top-right-on-square" class="size-4" /> YouTube
            </a>
          </div>
        </div>
      </section>

      <div class="mx-auto max-w-7xl px-5 sm:px-7 lg:px-10">
        <section
          :if={@course.description}
          id="course-description"
          class="border-b border-base-content/10 py-8 md:py-10"
        >
          <div class="max-w-3xl">
            <p class="ui-eyebrow mb-3">About this course</p>
            <div class={[
              "whitespace-pre-line text-sm leading-relaxed text-base-content/70 sm:text-base",
              if(!@show_description, do: "line-clamp-2", else: "")
            ]}>
              {@course.description}
            </div>
            <button
              id="course-description-toggle"
              phx-click="toggle_description"
              class="mt-3 font-mono text-xs font-bold tracking-wide text-base-content transition-colors hover:text-primary"
            >
              {if @show_description, do: "Show less", else: "Show more"}
            </button>
          </div>
        </section>

        <section id="course-lessons" class="py-10 md:py-14">
          <div class="mb-7 flex items-end justify-between gap-5">
            <div>
              <p class="ui-eyebrow mb-2">Course content</p>
              <h2 class="text-2xl font-black tracking-tight text-base-content md:text-3xl">
                Lessons
              </h2>
            </div>
            <span class="badge badge-outline h-auto px-3 py-2 font-mono text-xs text-base-content/60">
              {length(@lessons)} {if length(@lessons) == 1, do: "lesson", else: "lessons"}
            </span>
          </div>

          <.empty_state
            :if={Enum.empty?(@lessons)}
            id="course-lessons-empty"
            title="Lessons are coming soon"
            description="This course outline is ready and the first lessons are being prepared."
            icon="hero-video-camera"
            compact
            class="min-h-56 border border-dashed border-base-300"
          />

          <div :if={!Enum.empty?(@lessons)} id="course-lessons-list" class="grid gap-3">
            <.lesson_row :for={lesson <- @lessons} lesson={lesson} course={@course} />
          </div>
        </section>
      </div>
    </div>
    """
  end

  attr :lesson, :map, required: true
  attr :course, :map, required: true

  defp lesson_row(assigns) do
    ~H"""
    <.link
      id={"lesson-#{@lesson.id}"}
      navigate={~p"/courses/#{@course.slug}/lessons/#{@lesson.slug}"}
      class="ui-card ui-card-interactive ui-card-compact group flex items-center gap-4 p-3 sm:gap-5 sm:p-4"
    >
      <div class="relative aspect-video w-24 flex-shrink-0 overflow-hidden rounded-lg bg-base-300 sm:w-32 md:w-36">
        <img
          :if={@lesson.youtube_video_id}
          src={"https://i.ytimg.com/vi/#{@lesson.youtube_video_id}/mqdefault.jpg"}
          alt={@lesson.title}
          class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 ease-out"
        />
        <div :if={!@lesson.youtube_video_id} class="w-full h-full bg-base-300" />
        <div class="absolute inset-0 flex items-center justify-center bg-[#10121f]/15 opacity-0 transition-opacity duration-200 group-hover:opacity-100">
          <div class="flex size-8 items-center justify-center rounded-full bg-white/90 text-[#10121f] shadow-md">
            <.um_icon name="hero-play" class="ml-0.5 size-3.5" />
          </div>
        </div>
      </div>

      <div class="flex-1 min-w-0">
        <p class="mb-1 font-mono text-[0.68rem] uppercase tracking-widest text-base-content/45">
          Lesson {String.pad_leading(to_string(@lesson.lesson_number), 2, "0")}
        </p>
        <h3 class="line-clamp-2 text-base font-black leading-snug text-base-content transition-colors duration-200 group-hover:text-primary sm:text-lg md:text-xl">
          {@lesson.title}
        </h3>
        <p
          :if={@lesson.notes_md}
          class="mt-1 hidden line-clamp-1 text-sm leading-relaxed text-base-content/50 sm:block"
        >
          {String.replace(@lesson.notes_md, ~r/[#*_`\[\]>]/, "")}
        </p>
      </div>

      <.um_icon
        name="hero-arrow-right"
        class="size-5 flex-shrink-0 text-primary transition-transform duration-200 group-hover:translate-x-1"
      />
    </.link>
    """
  end
end
