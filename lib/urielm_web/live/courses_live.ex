defmodule UrielmWeb.CoursesLive do
  use UrielmWeb, :live_view
  alias Phoenix.LiveView.JS
  alias Urielm.Learning
  alias Urielm.Content

  @page_size 20

  @impl true
  def mount(params, session, socket) do
    _child_params = case params do
      :not_mounted_at_router -> session["child_params"] || %{}
      params -> params
    end

    courses = Learning.list_courses()
    videos = Content.list_published_videos(limit: @page_size, offset: 0)

    {:ok,
     socket
     |> assign(:courses, courses)
     |> assign(:video_page, 1)
     |> assign(:has_more_videos, length(videos) == @page_size)
     |> assign(:current_page, "courses")
     |> assign(:page_title, "Courses")
     |> stream(:videos, videos, reset: true)}
  end

  @impl true
  def handle_event("load_more_videos", _params, socket) do
    %{video_page: page} = socket.assigns
    offset = page * @page_size

    new_videos = Content.list_published_videos(limit: @page_size, offset: offset)

    {:noreply,
     socket
     |> assign(:video_page, page + 1)
     |> assign(:has_more_videos, length(new_videos) == @page_size)
     |> stream(:videos, new_videos)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-8">
      <.swimlane title="Courses" show_all_link={~p"/courses"}>
        <.course_card :for={course <- @courses} course={course} />
      </.swimlane>

      <section class="mb-10">
        <div class="flex items-center justify-between px-4 md:px-8 mb-4">
          <h2 class="text-xl font-bold text-base-content">Videos</h2>
        </div>
        <div id="videos-grid" phx-update="stream" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 px-4 md:px-8">
          <.video_card :for={{dom_id, video} <- @streams.videos} id={dom_id} video={video} />
        </div>
        <%= if @has_more_videos do %>
          <div
            id="videos-infinite-scroll"
            phx-hook="InfiniteScroll"
            data-event="load_more_videos"
            class="h-20 flex items-center justify-center"
          >
            <span class="loading loading-spinner loading-md text-primary"></span>
          </div>
        <% end %>
      </section>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :show_all_link, :string, default: nil
  slot :inner_block, required: true

  defp swimlane(assigns) do
    ~H"""
    <section class="mb-10 group/swimlane">
      <div class="flex items-center justify-between px-4 md:px-8 mb-4">
        <h2 class="text-xl font-bold text-base-content">{@title}</h2>
        <.link :if={@show_all_link} navigate={@show_all_link} class="text-sm text-primary hover:underline">
          Show all
        </.link>
      </div>
      <div class="relative">
        <button
          type="button"
          phx-click={JS.dispatch("scroll-left", to: "#swimlane-#{slug(@title)}")}
          class="hidden md:flex absolute left-0 top-1/2 -translate-y-1/2 z-10 w-10 h-10 items-center justify-center bg-base-100/90 hover:bg-base-200 rounded-full shadow-lg opacity-0 group-hover/swimlane:opacity-100 transition-opacity"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <div
          id={"swimlane-#{slug(@title)}"}
          phx-hook="HorizontalScroll"
          class="flex gap-4 overflow-x-auto px-4 md:px-8 pb-4 scrollbar-hide snap-x snap-mandatory scroll-smooth"
        >
          {render_slot(@inner_block)}
        </div>
        <button
          type="button"
          phx-click={JS.dispatch("scroll-right", to: "#swimlane-#{slug(@title)}")}
          class="hidden md:flex absolute right-0 top-1/2 -translate-y-1/2 z-10 w-10 h-10 items-center justify-center bg-base-100/90 hover:bg-base-200 rounded-full shadow-lg opacity-0 group-hover/swimlane:opacity-100 transition-opacity"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>
    </section>
    """
  end

  defp slug(title) do
    title |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")
  end

  attr :course, :map, required: true

  defp course_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/courses/#{@course.slug}"}
      class="flex-none w-72 md:w-80 group snap-start"
    >
      <div class="relative aspect-video rounded-xl overflow-hidden bg-base-300 mb-2">
        <%= if first_lesson = List.first(@course.lessons) do %>
          <img
            src={"https://img.youtube.com/vi/#{first_lesson.youtube_video_id}/mqdefault.jpg"}
            alt={@course.title}
            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
          />
        <% else %>
          <div class="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-primary/20 to-secondary/20">
            <svg class="w-12 h-12 text-primary/50" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z" />
            </svg>
          </div>
        <% end %>
        <div class="absolute bottom-2 right-2 bg-black/80 text-white text-xs px-1.5 py-0.5 rounded">
          {length(@course.lessons)} videos
        </div>
      </div>
      <h3 class="font-medium text-base-content line-clamp-2 group-hover:text-primary transition-colors">
        {@course.title}
      </h3>
      <p class="text-sm text-base-content/60 mt-1">Course</p>
    </.link>
    """
  end

  attr :video, :map, required: true
  attr :id, :string, default: nil

  defp video_card(assigns) do
    assigns = assign(assigns, :video_id, extract_youtube_id(assigns.video.youtube_url))
    assigns = assign(assigns, :time_ago, time_ago(assigns.video.published_at || assigns.video.inserted_at))

    ~H"""
    <.link id={@id} navigate={~p"/videos/#{@video.slug}"} class="group">
      <div class="relative aspect-video rounded-xl overflow-hidden bg-base-300 mb-3">
        <img
          src={"https://img.youtube.com/vi/#{@video_id}/mqdefault.jpg"}
          alt={@video.title}
          class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
        />
      </div>
      <div class="flex gap-3">
        <div class="flex-shrink-0">
          <div class="w-9 h-9 rounded-full bg-base-300 flex items-center justify-center text-xs font-bold text-base-content/70">
            {String.first(@video.author_name || "U")}
          </div>
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="font-medium text-base-content line-clamp-2 text-sm leading-tight group-hover:text-primary transition-colors">
            {@video.title}
          </h3>
          <p class="text-xs text-base-content/60 mt-1">
            {@video.author_name || "Unknown"}
          </p>
          <p class="text-xs text-base-content/60">
            {@time_ago}
          </p>
        </div>
      </div>
    </.link>
    """
  end

  defp extract_youtube_id(nil), do: nil
  defp extract_youtube_id(url) do
    cond do
      String.contains?(url, "v=") ->
        url |> String.split("v=") |> List.last() |> String.split("&") |> List.first()
      String.contains?(url, "youtu.be/") ->
        url |> String.split("youtu.be/") |> List.last() |> String.split("?") |> List.first()
      true ->
        nil
    end
  end

  defp time_ago(nil), do: ""
  defp time_ago(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 604_800 -> "#{div(diff, 86400)} days ago"
      diff < 2_592_000 -> "#{div(diff, 604_800)} weeks ago"
      diff < 31_536_000 -> "#{div(diff, 2_592_000)} months ago"
      true -> "#{div(diff, 31_536_000)} years ago"
    end
  end
end
