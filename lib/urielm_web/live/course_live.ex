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
    <div>
      <!-- Cinematic hero -->
      <div class="relative w-full h-[480px] md:h-[560px] overflow-hidden">
        <!-- Background -->
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
        
    <!-- Dual gradient: bottom-heavy + left edge -->
        <div class="absolute inset-0 bg-gradient-to-t from-base-content/95 via-base-content/40 to-base-content/10" />
        <div class="absolute inset-0 bg-gradient-to-r from-base-content/40 to-transparent" />
        
    <!-- Back link -->
        <div class="absolute top-6 left-6 md:left-12 lg:left-16">
          <.link
            navigate={~p"/courses"}
            class="inline-flex items-center gap-2 font-mono text-xs tracking-widest uppercase text-base-100/60 hover:text-base-100 transition-colors"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2.5"
                d="M15 19l-7-7 7-7"
              />
            </svg>
            Courses
          </.link>
        </div>
        
    <!-- Hero content -->
        <div class="absolute inset-0 flex flex-col justify-end px-6 md:px-12 lg:px-16 pb-10">
          <p class="font-mono text-xs tracking-widest uppercase text-base-100/50 mb-3">
            {length(@lessons)} {if length(@lessons) == 1, do: "lesson", else: "lessons"}
          </p>

          <h1 class="text-4xl md:text-5xl lg:text-6xl font-black text-base-100 leading-none tracking-tight mb-4 max-w-3xl">
            {@course.title}
          </h1>

          <div class="flex items-center gap-6">
            <.link
              :if={@first_lesson}
              navigate={~p"/courses/#{@course.slug}/lessons/#{@first_lesson.slug}"}
              class="inline-flex items-center gap-2.5 bg-primary text-primary-content font-bold text-sm px-6 py-3 rounded-full hover:opacity-90 transition-opacity"
            >
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M8 5v14l11-7z" />
              </svg>
              Start watching
            </.link>

            <a
              :if={@course.youtube_playlist_id}
              href={"https://www.youtube.com/playlist?list=#{@course.youtube_playlist_id}"}
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-2 font-mono text-xs tracking-widest uppercase text-base-100/50 hover:text-base-100 transition-colors"
            >
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
              </svg>
              YouTube
            </a>
          </div>
        </div>
      </div>
      
    <!-- Description (YouTube-style) -->
      <div :if={@course.description} class="px-6 md:px-12 lg:px-16 pt-8 pb-2">
        <div class="max-w-3xl">
          <div class={[
            "text-base-content/80 text-sm leading-relaxed whitespace-pre-line",
            if(!@show_description, do: "line-clamp-2", else: "")
          ]}>
            {@course.description}
          </div>
          <button
            phx-click="toggle_description"
            class="mt-2 font-mono text-xs font-bold tracking-wide text-base-content hover:text-primary transition-colors"
          >
            {if @show_description, do: "Show less", else: "Show more"}
          </button>
        </div>
      </div>
      
    <!-- Lesson table of contents -->
      <div class="px-6 md:px-12 lg:px-16 py-10">
        <!-- Section header -->
        <div class="flex items-center gap-6 mb-8">
          <p class="font-mono text-xs tracking-widest uppercase text-base-content/40 flex-shrink-0">
            Course content
          </p>
          <div class="flex-1 h-px bg-base-content/10" />
          <p class="font-mono text-xs text-base-content/40 flex-shrink-0">
            {length(@lessons)} lessons
          </p>
        </div>
        
    <!-- Empty state -->
        <div :if={Enum.empty?(@lessons)} class="flex flex-col items-center justify-center py-24">
          <p class="font-mono font-black text-8xl text-base-content/10 select-none mb-4">00</p>
          <p class="font-mono text-xs tracking-[0.3em] uppercase text-base-content/30">
            No lessons yet
          </p>
        </div>
        
    <!-- Lesson rows -->
        <div :if={!Enum.empty?(@lessons)}>
          <.lesson_row :for={lesson <- @lessons} lesson={lesson} course={@course} />
        </div>
      </div>
    </div>
    """
  end

  attr :lesson, :map, required: true
  attr :course, :map, required: true

  defp lesson_row(assigns) do
    ~H"""
    <.link
      navigate={~p"/courses/#{@course.slug}/lessons/#{@lesson.slug}"}
      class="group flex items-center gap-6 md:gap-8 py-5 border-t border-base-content/8 hover:border-primary/20 transition-colors last:border-b"
    >
      <!-- Thumbnail -->
      <div class="relative flex-shrink-0 w-28 md:w-36 aspect-video rounded-lg overflow-hidden bg-base-300">
        <img
          :if={@lesson.youtube_video_id}
          src={"https://i.ytimg.com/vi/#{@lesson.youtube_video_id}/mqdefault.jpg"}
          alt={@lesson.title}
          class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 ease-out"
        />
        <div :if={!@lesson.youtube_video_id} class="w-full h-full bg-base-300" />
        <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-200">
          <div class="w-8 h-8 rounded-full bg-base-100/90 flex items-center justify-center shadow-md">
            <svg class="w-3.5 h-3.5 text-base-content ml-0.5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z" />
            </svg>
          </div>
        </div>
      </div>
      
    <!-- Title + notes -->
      <div class="flex-1 min-w-0">
        <h3 class="font-black text-lg md:text-xl text-base-content leading-snug group-hover:text-primary transition-colors duration-200 line-clamp-1">
          {@lesson.title}
        </h3>
        <p
          :if={@lesson.notes_md}
          class="text-sm text-base-content/50 line-clamp-1 mt-1 leading-relaxed"
        >
          {String.replace(@lesson.notes_md, ~r/[#*_`\[\]>]/, "")}
        </p>
      </div>
      
    <!-- Slide-in arrow -->
      <div class="flex-shrink-0 opacity-0 group-hover:opacity-100 -translate-x-2 group-hover:translate-x-0 transition-all duration-200">
        <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2.5"
            d="M17 8l4 4m0 0l-4 4m4-4H3"
          />
        </svg>
      </div>
    </.link>
    """
  end
end
