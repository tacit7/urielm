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
         |> assign(:lesson_count, length(lessons))
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
      <section
        id="course-detail-hero"
        class="relative overflow-hidden border-b border-base-300/70 bg-base-200/35"
      >
        <div
          :if={@first_lesson && @first_lesson.youtube_video_id}
          aria-hidden="true"
          class="pointer-events-none absolute inset-x-0 top-0 h-80 overflow-hidden opacity-30 blur-2xl"
        >
          <img
            src={thumbnail_url(@first_lesson, "maxresdefault")}
            alt=""
            class="h-full w-full scale-110 object-cover"
          />
          <div class="absolute inset-0 bg-base-100/45" />
        </div>

        <div class="relative mx-auto max-w-7xl px-4 py-5 sm:px-6 lg:px-8">
          <.link
            navigate={~p"/courses"}
            class="inline-flex min-h-11 items-center gap-2 rounded-lg px-2 text-sm font-semibold text-base-content/65 transition hover:bg-base-200 hover:text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-base-100"
          >
            <.um_icon name="hero-arrow-left" class="size-4" /> Courses
          </.link>

          <div class="grid gap-6 py-5 lg:grid-cols-[minmax(18rem,23rem)_minmax(0,1fr)] lg:items-start lg:gap-8">
            <aside
              id="course-playlist-panel"
              class="rounded-2xl border border-base-300/80 bg-base-100/85 p-3 shadow-xl shadow-base-content/5 backdrop-blur md:p-4 lg:sticky lg:top-24"
            >
              <div class="relative aspect-video overflow-hidden rounded-xl bg-base-300">
                <img
                  :if={@first_lesson && @first_lesson.youtube_video_id}
                  src={thumbnail_url(@first_lesson, "hqdefault")}
                  alt={@course.title}
                  class="h-full w-full object-cover"
                />
                <div
                  :if={!@first_lesson || !@first_lesson.youtube_video_id}
                  class="grid h-full w-full place-items-center bg-base-300 text-base-content/40"
                >
                  <.um_icon name="hero-academic-cap" class="size-10" />
                </div>
                <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-[#10121f]/85 to-transparent p-3">
                  <div class="flex items-center gap-2 text-xs font-bold text-white">
                    <.um_icon name="hero-list-bullet" class="size-4" />
                    <span>{lesson_count_text(@lesson_count)}</span>
                  </div>
                </div>
              </div>

              <div class="px-1 pb-1 pt-4">
                <h1 class="text-2xl font-black leading-tight tracking-tight text-base-content md:text-3xl">
                  {@course.title}
                </h1>

                <div class="mt-3 flex flex-wrap items-center gap-2 text-sm text-base-content/60">
                  <span class="font-semibold">Urielm</span>
                  <span aria-hidden="true">·</span>
                  <span>{lesson_count_text(@lesson_count)}</span>
                </div>

                <div class="mt-4 grid grid-cols-2 gap-2">
                  <.link
                    :if={@first_lesson}
                    id="course-start-button"
                    navigate={~p"/courses/#{@course.slug}/lessons/#{@first_lesson.slug}"}
                    class="btn btn-primary min-h-11 rounded-full"
                  >
                    <.um_icon name="hero-play" class="size-4" /> Play all
                  </.link>

                  <a
                    :if={@course.youtube_playlist_id}
                    id="course-youtube-link"
                    href={youtube_playlist_url(@course)}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="btn min-h-11 rounded-full border-base-300 bg-base-200 text-base-content hover:border-primary/35 hover:bg-base-300"
                  >
                    <.um_icon name="hero-arrow-top-right-on-square" class="size-4" /> YouTube
                  </a>
                </div>

                <div
                  :if={@course.description}
                  id="course-description"
                  class="mt-4 border-t border-base-content/10 pt-4"
                >
                  <div class={[
                    "whitespace-pre-line text-sm leading-relaxed text-base-content/70",
                    if(!@show_description, do: "line-clamp-3", else: "")
                  ]}>
                    {@course.description}
                  </div>
                  <button
                    id="course-description-toggle"
                    phx-click="toggle_description"
                    class="mt-2 rounded-md text-sm font-bold text-base-content transition-colors hover:text-primary focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-base-100"
                  >
                    {if @show_description, do: "Show less", else: "Show more"}
                  </button>
                </div>
              </div>
            </aside>

            <div id="course-playlist-content" class="min-w-0">
              <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
                <div>
                  <h2 class="text-xl font-black tracking-tight text-base-content md:text-2xl">
                    Lessons
                  </h2>
                  <p class="mt-1 text-sm text-base-content/60">
                    Watch in order or jump to the lesson you need.
                  </p>
                </div>

                <span class="badge badge-outline h-auto self-start px-3 py-2 font-mono text-xs text-base-content/60 sm:self-auto">
                  {lesson_count_text(@lesson_count)}
                </span>
              </div>

              <section
                id="course-lessons"
                class="rounded-2xl border border-base-300/80 bg-base-100/80 p-2 shadow-lg shadow-base-content/5"
              >
                <.empty_state
                  :if={Enum.empty?(@lessons)}
                  id="course-lessons-empty"
                  title="Lessons are coming soon"
                  description="This course outline is ready and the first lessons are being prepared."
                  icon="hero-video-camera"
                  compact
                  class="min-h-56 border border-dashed border-base-300"
                />

                <div
                  :if={!Enum.empty?(@lessons)}
                  id="course-lessons-list"
                  class="divide-y divide-base-300/70"
                >
                  <.lesson_row :for={lesson <- @lessons} lesson={lesson} course={@course} />
                </div>
              </section>
            </div>
          </div>
        </div>
      </section>
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
      class="group grid grid-cols-[1.5rem_minmax(7rem,9rem)_minmax(0,1fr)] items-center gap-3 rounded-xl px-2 py-2 transition duration-200 hover:bg-base-200/80 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-base-100 sm:grid-cols-[2.5rem_11rem_minmax(0,1fr)_2.5rem] sm:gap-4 sm:px-3"
    >
      <div class="text-center font-mono text-xs font-semibold tabular-nums text-base-content/45 transition-colors group-hover:text-base-content/70">
        {@lesson.lesson_number}
      </div>

      <div class="relative aspect-video overflow-hidden rounded-lg bg-base-300">
        <img
          :if={@lesson.youtube_video_id}
          src={thumbnail_url(@lesson, "mqdefault")}
          alt={@lesson.title}
          class="h-full w-full object-cover transition-transform duration-500 ease-out group-hover:scale-105"
        />
        <div :if={!@lesson.youtube_video_id} class="w-full h-full bg-base-300" />
        <div class="absolute inset-0 flex items-center justify-center bg-[#10121f]/25 opacity-0 transition-opacity duration-200 group-hover:opacity-100">
          <div class="flex size-9 items-center justify-center rounded-full bg-white/95 text-[#10121f] shadow-md">
            <.um_icon name="hero-play" class="ml-0.5 size-3.5" />
          </div>
        </div>
      </div>

      <div class="flex-1 min-w-0">
        <h3 class="line-clamp-2 text-sm font-bold leading-snug text-base-content transition-colors duration-200 group-hover:text-primary sm:text-base">
          {@lesson.title}
        </h3>
        <p
          :if={@lesson.notes_md}
          class="mt-1 hidden line-clamp-1 text-xs leading-relaxed text-base-content/50 sm:block"
        >
          {String.replace(@lesson.notes_md, ~r/[#*_`\[\]>]/, "")}
        </p>
        <p :if={!@lesson.notes_md} class="mt-1 hidden text-xs text-base-content/45 sm:block">
          Lesson {String.pad_leading(to_string(@lesson.lesson_number), 2, "0")}
        </p>
      </div>

      <.um_icon
        name="hero-play-circle"
        class="mx-auto hidden size-5 flex-shrink-0 text-base-content/35 transition duration-200 group-hover:scale-110 group-hover:text-primary sm:block"
      />
    </.link>
    """
  end

  defp lesson_count_text(1), do: "1 lesson"
  defp lesson_count_text(count), do: "#{count} lessons"

  defp youtube_playlist_url(course) do
    "https://www.youtube.com/playlist?list=#{course.youtube_playlist_id}"
  end

  defp thumbnail_url(%{youtube_video_id: video_id}, quality) do
    "https://i.ytimg.com/vi/#{video_id}/#{quality}.jpg"
  end
end
