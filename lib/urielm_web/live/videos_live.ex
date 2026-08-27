defmodule UrielmWeb.VideosLive do
  use UrielmWeb, :live_view

  alias Urielm.Content

  @formats ~w(all standard short)

  @impl true
  def mount(params, session, socket) do
    child_params =
      case params do
        :not_mounted_at_router -> session["child_params"] || %{}
        params -> params
      end

    query = normalize_query(child_params["q"])
    format = normalize_format(child_params["format"])
    tag_slugs = normalize_tags(child_params["tag"])
    selected_tags = Content.list_tags_by_slugs(tag_slugs)
    tag_ids = Enum.map(selected_tags, & &1.id)
    all_videos = Content.list_published_videos()

    matching_videos =
      if unresolved_tags?(tag_slugs, selected_tags) do
        []
      else
        Content.list_published_videos(query: query, format: format, tag_ids: tag_ids)
      end

    standard_videos = Enum.filter(matching_videos, &(&1.format == "standard"))
    short_videos = Enum.filter(matching_videos, &(&1.format == "short"))
    featured_video = if format == "short", do: nil, else: List.first(standard_videos)

    standard_videos =
      if featured_video,
        do: Enum.reject(standard_videos, &(&1.id == featured_video.id)),
        else: standard_videos

    search_form = to_form(%{"q" => query, "format" => format})
    tags_param = tags_param(tag_slugs)

    {:ok,
     socket
     |> stream_configure(:standard_videos, dom_id: &"video-card-#{&1.id}")
     |> stream_configure(:short_videos, dom_id: &"short-card-#{&1.id}")
     |> assign(:page_title, "Videos")
     |> assign(:query, query)
     |> assign(:current_format, format)
     |> assign(:tag_slugs, tag_slugs)
     |> assign(:draft_tag_slugs, tag_slugs)
     |> assign(:tags_param, tags_param)
     |> assign(:available_tags, Content.list_content_tags())
     |> assign(:tag_picker_open?, false)
     |> assign(:search_form, search_form)
     |> assign(:featured_video, featured_video)
     |> assign(:library_empty?, all_videos == [])
     |> assign(:results_empty?, matching_videos == [])
     |> assign(:standard_empty?, standard_videos == [])
     |> assign(:shorts_empty?, short_videos == [])
     |> stream(:standard_videos, standard_videos)
     |> stream(:short_videos, short_videos)}
  end

  @impl true
  def handle_event("open_tag_picker", _params, socket) do
    {:noreply,
     socket
     |> assign(:draft_tag_slugs, socket.assigns.tag_slugs)
     |> assign(:tag_picker_open?, true)}
  end

  def handle_event("close_tag_picker", _params, socket) do
    {:noreply, assign(socket, :tag_picker_open?, false)}
  end

  def handle_event("toggle_tag_filter", %{"slug" => slug}, socket) do
    draft_tag_slugs =
      if slug in socket.assigns.draft_tag_slugs do
        Enum.reject(socket.assigns.draft_tag_slugs, &(&1 == slug))
      else
        socket.assigns.draft_tag_slugs ++ [slug]
      end

    {:noreply, assign(socket, :draft_tag_slugs, draft_tag_slugs)}
  end

  def handle_event("clear_tag_filters", _params, socket) do
    {:noreply, assign(socket, :draft_tag_slugs, [])}
  end

  def handle_event("apply_tag_filters", _params, socket) do
    {:noreply,
     push_navigate(socket,
       to:
         filter_href(
           socket.assigns.query,
           socket.assigns.current_format,
           socket.assigns.draft_tag_slugs
         )
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="videos-index" class="min-h-screen bg-base-100">
      <div class="ui-page-shell">
        <header id="videos-index-header" class="ui-page-header ui-page-heading">
          <h1 class="ui-section-title">Videos</h1>
          <p class="ui-section-copy">
            Practical walkthroughs, focused lessons, and quick ideas you can apply right away.
          </p>
        </header>

        <div
          id="video-toolbar"
          class="flex flex-col gap-3 rounded-2xl border border-base-300/70 bg-base-200/40 p-3 md:flex-row md:items-center md:justify-between"
        >
          <.form
            for={@search_form}
            id="video-search-form"
            action={~p"/videos"}
            method="get"
            class="w-full md:max-w-md"
          >
            <div class="relative">
              <.um_icon
                name="search"
                class="pointer-events-none absolute left-3 top-1/2 z-10 size-5 -translate-y-1/2 text-base-content/35"
              />
              <.input
                field={@search_form[:q]}
                type="search"
                placeholder="Search videos"
                aria-label="Search videos"
                class="input input-bordered w-full bg-base-100 pl-10"
              />
              <input type="hidden" name="format" value={@current_format} />
              <input :if={@tags_param != ""} type="hidden" name="tag" value={@tags_param} />
            </div>
          </.form>

          <div
            id="video-filter-controls"
            class="relative flex items-center gap-2 overflow-x-auto pb-0.5"
          >
            <nav
              id="video-format-filters"
              aria-label="Filter videos by format"
              class="flex gap-2"
            >
              <a
                :for={item <- format_filters()}
                id={"video-filter-#{item.key}"}
                href={filter_href(@query, item.key, @tag_slugs)}
                data-format={item.key}
                aria-current={if(@current_format == item.key, do: "page", else: nil)}
                class={[
                  "btn btn-sm flex-none rounded-full px-4 transition duration-200",
                  if(@current_format == item.key,
                    do: "btn-primary",
                    else:
                      "btn-ghost border border-base-300/70 bg-base-100 text-base-content/65 hover:border-primary/35 hover:text-base-content"
                  )
                ]}
              >
                {item.label}
              </a>
            </nav>

            <button
              :if={@available_tags != []}
              id="video-tag-filter-button"
              type="button"
              phx-click="open_tag_picker"
              aria-haspopup="dialog"
              aria-expanded={to_string(@tag_picker_open?)}
              class={[
                "btn btn-sm flex-none rounded-full border px-3 transition duration-200",
                if(@tag_slugs == [],
                  do: "border-base-300/70 bg-base-100 text-base-content/65 hover:border-primary/35",
                  else: "border-primary/35 bg-primary/10 text-primary"
                )
              ]}
            >
              <.icon name="hero-tag" class="size-4" />
              <span>Tags</span>
              <span
                :if={@tag_slugs != []}
                id="video-tag-filter-count"
                class="grid size-5 place-items-center rounded-full bg-primary text-xs font-black text-primary-content"
              >
                {length(@tag_slugs)}
              </span>
            </button>
          </div>
        </div>

        <div
          :if={@tag_picker_open?}
          id="video-tag-picker"
          role="dialog"
          aria-modal="true"
          aria-labelledby="video-tag-picker-title"
          class="fixed inset-0 z-50 flex items-end md:items-start md:justify-end md:px-6 md:pt-40 lg:px-8"
        >
          <button
            id="video-tag-picker-backdrop"
            type="button"
            phx-click="close_tag_picker"
            aria-label="Close tag filters"
            class="absolute inset-0 bg-neutral/45 backdrop-blur-[2px]"
          >
          </button>

          <section class="relative z-10 w-full rounded-t-lg border border-base-300 bg-base-100 shadow-2xl md:w-80 md:rounded-lg">
            <header class="flex items-center justify-between border-b border-base-300 px-5 py-4">
              <div>
                <h2 id="video-tag-picker-title" class="text-sm font-black text-base-content">
                  Filter by tags
                </h2>
                <p class="mt-0.5 text-xs text-base-content/50">
                  {length(@draft_tag_slugs)} selected
                </p>
              </div>
              <button
                id="video-tag-picker-close"
                type="button"
                phx-click="close_tag_picker"
                aria-label="Close tag filters"
                class="btn btn-ghost btn-sm btn-square"
              >
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </header>

            <div id="video-tag-options" class="max-h-[45vh] space-y-1 overflow-y-auto p-3 md:max-h-72">
              <button
                :for={tag <- @available_tags}
                id={"video-tag-option-#{tag.slug}"}
                type="button"
                phx-click="toggle_tag_filter"
                phx-value-slug={tag.slug}
                aria-pressed={to_string(tag.slug in @draft_tag_slugs)}
                class={[
                  "flex min-h-11 w-full items-center gap-3 rounded-md px-3 text-left text-sm font-semibold transition-colors",
                  if(tag.slug in @draft_tag_slugs,
                    do: "bg-primary/10 text-primary",
                    else: "text-base-content/70 hover:bg-base-200 hover:text-base-content"
                  )
                ]}
              >
                <span class={[
                  "grid size-5 place-items-center rounded border",
                  if(tag.slug in @draft_tag_slugs,
                    do: "border-primary bg-primary text-primary-content",
                    else: "border-base-300 bg-base-100"
                  )
                ]}>
                  <.icon :if={tag.slug in @draft_tag_slugs} name="hero-check" class="size-3.5" />
                </span>
                <span class="truncate">{tag.name}</span>
              </button>
            </div>

            <footer class="flex items-center justify-between gap-3 border-t border-base-300 p-4 pb-[max(1rem,env(safe-area-inset-bottom))]">
              <button
                id="clear-video-tag-filters"
                type="button"
                phx-click="clear_tag_filters"
                class="btn btn-ghost btn-sm"
              >
                Clear
              </button>
              <button
                id="apply-video-tag-filters"
                type="button"
                phx-click="apply_tag_filters"
                class="btn btn-primary btn-sm min-w-24"
              >
                Apply
              </button>
            </footer>
          </section>
        </div>

        <.empty_state
          :if={@library_empty?}
          id="videos-empty-state"
          title="New videos are on the way"
          description="Check back soon for practical walkthroughs, quick ideas, and focused developer tutorials."
          icon="hero-video-camera"
          class="mt-6"
        >
          <:action>
            <.link navigate={~p"/courses"} class="btn btn-outline btn-sm rounded-full">
              Explore courses
            </.link>
          </:action>
        </.empty_state>

        <.empty_state
          :if={!@library_empty? && @results_empty?}
          id="videos-no-results"
          title="No videos found"
          description="Nothing matches your current search and format. Try a broader search or clear the filters."
          icon="hero-magnifying-glass"
          class="mt-6"
        >
          <:action>
            <.link
              id="clear-video-filters"
              navigate={~p"/videos"}
              class="btn btn-outline btn-primary btn-sm rounded-full"
            >
              Clear filters
            </.link>
          </:action>
        </.empty_state>

        <div :if={!@library_empty? && !@results_empty?} id="video-results">
          <.featured_video :if={@featured_video} video={@featured_video} />

          <section :if={!@standard_empty?} id="latest-videos" class="mt-12 sm:mt-16">
            <div class="mb-5">
              <h2 class="text-2xl font-black tracking-tight text-base-content">Latest videos</h2>
              <p class="mt-1 text-sm text-base-content/45">
                Longer walkthroughs, demos, and practical lessons.
              </p>
            </div>

            <div
              id="video-grid"
              phx-update="stream"
              class="-mr-4 flex snap-x snap-mandatory gap-4 overflow-x-auto pr-4 pb-3 sm:-mr-6 sm:pr-6 md:mr-0 md:grid md:grid-cols-2 md:overflow-visible md:pr-0 lg:grid-cols-3"
            >
              <.video_card
                :for={{id, video} <- @streams.standard_videos}
                id={id}
                video={video}
              />
            </div>
          </section>

          <section :if={!@shorts_empty?} id="video-shorts" class="mt-12 sm:mt-16">
            <div class="mb-5">
              <h2 class="text-2xl font-black tracking-tight text-base-content">Quick ideas</h2>
              <p class="mt-1 text-sm text-base-content/45">
                Short tips you can apply right away.
              </p>
            </div>

            <div
              id="shorts-grid"
              phx-update="stream"
              class="-mr-4 flex snap-x snap-mandatory gap-3 overflow-x-auto pr-4 pb-3 sm:-mr-6 sm:pr-6 lg:mr-0 lg:grid lg:grid-cols-5 lg:overflow-visible lg:pr-0"
            >
              <.short_card :for={{id, video} <- @streams.short_videos} id={id} video={video} />
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end

  attr :video, :map, required: true

  defp featured_video(assigns) do
    assigns =
      assigns
      |> assign(:thumbnail, thumbnail_url(assigns.video))
      |> assign(:summary, video_summary(assigns.video))

    ~H"""
    <article
      id={"featured-video-#{@video.id}"}
      class="ui-card ui-card-interactive mt-6 overflow-hidden bg-base-200/60"
    >
      <.link navigate={~p"/videos/#{@video.slug}"} class="group grid lg:grid-cols-[1.15fr_0.85fr]">
        <div class="relative min-h-56 overflow-hidden bg-[radial-gradient(circle_at_35%_35%,color-mix(in_oklab,var(--color-primary)_28%,transparent),transparent_35%),linear-gradient(135deg,var(--color-base-300),var(--color-base-100))] sm:min-h-80 lg:min-h-[25rem]">
          <img
            :if={@thumbnail}
            src={@thumbnail}
            alt=""
            loading="eager"
            class="absolute inset-0 h-full w-full object-cover transition duration-700 group-hover:scale-[1.03]"
          />
          <div class="absolute inset-0 bg-gradient-to-t from-[#0a1020]/45 via-transparent to-transparent">
          </div>
          <span class="absolute inset-0 grid place-items-center">
            <span class="grid size-16 place-items-center rounded-full border border-white/25 bg-white/90 text-[#173467] shadow-2xl shadow-black/40 transition duration-300 group-hover:scale-105 sm:size-18">
              <.um_icon name="hero-play-solid" class="ml-1 size-6 sm:size-7" />
            </span>
          </span>
        </div>

        <div class="flex flex-col justify-center p-6 sm:p-8 lg:p-10">
          <div class="flex flex-wrap items-center gap-2">
            <span class="badge border-primary/25 bg-primary/10 font-mono text-xs uppercase tracking-wider text-primary">
              Featured video
            </span>
            <.access_badge video={@video} />
          </div>
          <h1 class="mt-5 text-3xl font-black leading-[1.08] tracking-[-0.04em] text-base-content transition-colors group-hover:text-primary sm:text-4xl">
            {@video.title}
          </h1>
          <p
            :if={@summary != ""}
            class="mt-4 line-clamp-3 text-sm leading-relaxed text-base-content/60 sm:text-base"
          >
            {@summary}
          </p>
          <div
            :if={@video.tag_records != []}
            id={"featured-video-tags-#{@video.id}"}
            class="mt-5 flex flex-wrap gap-1.5"
          >
            <span
              :for={tag <- Enum.take(@video.tag_records, 4)}
              class="badge badge-sm border-primary/20 bg-primary/5 text-xs font-bold text-primary"
            >
              {tag.name}
            </span>
          </div>
          <div class="mt-6 flex flex-wrap items-center gap-2 text-xs text-base-content/45">
            <span>{author_name(@video)}</span>
            <span class="size-1 rounded-full bg-base-content/20" aria-hidden="true"></span>
            <span>{format_date(@video.published_at)}</span>
          </div>
          <span class="mt-7 inline-flex items-center gap-2 self-start text-sm font-bold text-primary">
            Watch video
            <.um_icon
              name="hero-arrow-right"
              class="size-4 transition-transform duration-300 group-hover:translate-x-1"
            />
          </span>
        </div>
      </.link>
    </article>
    """
  end

  attr :id, :string, required: true
  attr :video, :map, required: true

  defp video_card(assigns) do
    assigns = assign(assigns, :thumbnail, thumbnail_url(assigns.video))

    ~H"""
    <article
      id={@id}
      class="ui-card ui-card-interactive group w-[82vw] max-w-[19rem] flex-none snap-start overflow-hidden md:w-auto md:max-w-none"
    >
      <.link navigate={~p"/videos/#{@video.slug}"} class="flex h-full flex-col">
        <div class="relative aspect-video overflow-hidden bg-[radial-gradient(circle_at_70%_25%,color-mix(in_oklab,var(--color-primary)_25%,transparent),transparent_32%),linear-gradient(145deg,var(--color-base-300),var(--color-base-200))]">
          <img
            :if={@thumbnail}
            src={@thumbnail}
            alt=""
            loading="lazy"
            class="h-full w-full object-cover transition duration-500 group-hover:scale-[1.04]"
          />
          <div class="absolute inset-0 bg-gradient-to-t from-[#0a1020]/35 via-transparent to-transparent">
          </div>
          <span class="absolute bottom-3 right-3 grid size-9 place-items-center rounded-full bg-white/90 text-[#173467] shadow-lg shadow-black/30 transition-transform duration-300 group-hover:scale-105">
            <.um_icon name="hero-play-solid" class="ml-0.5 size-4" />
          </span>
        </div>
        <div class="flex flex-1 flex-col p-5">
          <div class="flex items-center justify-between gap-3 text-xs">
            <span class="font-bold uppercase tracking-[0.12em] text-primary">Video</span>
            <.access_badge video={@video} />
          </div>
          <h3 class="mt-3 line-clamp-2 text-lg font-black leading-snug tracking-tight text-base-content transition-colors group-hover:text-primary">
            {@video.title}
          </h3>
          <div
            :if={@video.tag_records != []}
            id={"video-card-tags-#{@video.id}"}
            class="mt-3 flex flex-wrap gap-1.5"
          >
            <span
              :for={tag <- Enum.take(@video.tag_records, 3)}
              class="badge badge-sm border-primary/20 bg-primary/5 text-xs font-bold text-primary"
            >
              {tag.name}
            </span>
          </div>
          <div class="mt-auto flex items-center gap-2 pt-5 text-xs text-base-content/45">
            <span>{author_name(@video)}</span>
            <span class="size-1 rounded-full bg-base-content/20" aria-hidden="true"></span>
            <span>{format_date(@video.published_at)}</span>
          </div>
        </div>
      </.link>
    </article>
    """
  end

  attr :id, :string, required: true
  attr :video, :map, required: true

  defp short_card(assigns) do
    assigns = assign(assigns, :thumbnail, thumbnail_url(assigns.video))

    ~H"""
    <article
      id={@id}
      class="ui-card ui-card-interactive group relative min-h-64 w-36 flex-none snap-start overflow-hidden sm:w-40 lg:w-auto"
    >
      <.link navigate={~p"/videos/#{@video.slug}"} class="absolute inset-0">
        <div class="absolute inset-0 bg-[radial-gradient(circle_at_70%_20%,color-mix(in_oklab,var(--color-primary)_30%,transparent),transparent_34%),linear-gradient(160deg,#294c83,var(--color-base-100)_68%)]">
          <img
            :if={@thumbnail}
            src={@thumbnail}
            alt=""
            loading="lazy"
            class="h-full w-full object-cover transition duration-500 group-hover:scale-[1.04]"
          />
        </div>
        <div class="absolute inset-0 flex flex-col justify-between bg-gradient-to-t from-[#080d19]/95 via-[#080d19]/10 to-transparent p-3.5">
          <div class="flex items-start justify-between gap-2">
            <span class="badge border-white/20 bg-[#0d1423]/70 text-xs font-black uppercase tracking-widest text-white">
              Short
            </span>
            <.access_badge video={@video} compact />
          </div>
          <div>
            <div
              :if={@video.tag_records != []}
              id={"short-card-tags-#{@video.id}"}
              class="mb-2 flex flex-wrap gap-1"
            >
              <span
                :for={tag <- Enum.take(@video.tag_records, 2)}
                class="badge h-auto border-white/20 bg-[#0d1423]/70 px-1.5 py-1 text-xs font-bold text-white"
              >
                {tag.name}
              </span>
            </div>
            <h3 class="line-clamp-3 text-sm font-black leading-snug text-white">
              {@video.title}
            </h3>
            <p class="mt-2 text-xs text-white/55">{format_date(@video.published_at)}</p>
          </div>
        </div>
      </.link>
    </article>
    """
  end

  attr :video, :map, required: true
  attr :compact, :boolean, default: false

  defp access_badge(assigns) do
    assigns = assign(assigns, :label, access_label(assigns.video.visibility))

    ~H"""
    <span
      id={"video-access-#{@video.id}"}
      data-access={@video.visibility}
      class={[
        "badge h-auto border-base-300/80 bg-base-100/70 font-mono text-base-content/55",
        if(@compact, do: "px-1.5 py-1 text-xs", else: "px-2 py-1 text-xs"),
        @video.visibility != "public" && "border-warning/30 bg-warning/10 text-warning"
      ]}
    >
      <.um_icon :if={@video.visibility != "public"} name="lock_closed" class="size-3" />
      {@label}
    </span>
    """
  end

  defp format_filters do
    [
      %{key: "all", label: "All"},
      %{key: "standard", label: "Full videos"},
      %{key: "short", label: "Shorts"}
    ]
  end

  defp filter_href(query, format, tag_slugs) do
    params =
      []
      |> maybe_put_param(:q, query, query != "")
      |> maybe_put_param(:format, format, format != "all")
      |> maybe_put_param(:tag, tags_param(tag_slugs), tag_slugs != [])

    ~p"/videos?#{params}"
  end

  defp maybe_put_param(params, key, value, true), do: params ++ [{key, value}]
  defp maybe_put_param(params, _key, _value, false), do: params

  defp normalize_query(query) when is_binary(query) do
    query
    |> String.trim()
    |> String.slice(0, 100)
  end

  defp normalize_query(_query), do: ""

  defp normalize_format(format) when format in @formats, do: format
  defp normalize_format(_format), do: "all"

  defp normalize_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&Content.slugify_tag_name/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_tags(_tags), do: []

  defp unresolved_tags?([], _selected_tags), do: false
  defp unresolved_tags?(tag_slugs, selected_tags), do: length(tag_slugs) != length(selected_tags)

  defp tags_param(tag_slugs) do
    tag_slugs
    |> Enum.sort()
    |> Enum.join(",")
  end

  defp access_label("signed_in"), do: "Sign in"
  defp access_label("subscriber"), do: "Subscriber"
  defp access_label(_visibility), do: "Public"

  defp author_name(%{author_name: author}) when is_binary(author) and author != "", do: author
  defp author_name(_video), do: "Uriel Maldonado"

  defp format_date(nil), do: ""
  defp format_date(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp video_summary(%{description_md: description}) when is_binary(description) do
    description
    |> String.replace(~r/#+\s*/, "")
    |> String.replace(~r/[`*_>]/, "")
    |> String.replace(~r/\[(.+?)\]\(.+?\)/, "\\1")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 220)
  end

  defp video_summary(_video), do: ""

  defp thumbnail_url(video) do
    case youtube_id(video.youtube_url) do
      nil -> nil
      id -> "https://img.youtube.com/vi/#{id}/hqdefault.jpg"
    end
  end

  defp youtube_id(nil), do: nil
  defp youtube_id(""), do: nil

  defp youtube_id(url) do
    patterns = [
      ~r/youtube\.com\/watch\?.*v=([a-zA-Z0-9_-]{11})/,
      ~r/youtu\.be\/([a-zA-Z0-9_-]{11})/,
      ~r/youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/,
      ~r/youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/
    ]

    Enum.find_value(patterns, fn pattern ->
      case Regex.run(pattern, url) do
        [_, id] -> id
        _ -> nil
      end
    end)
  end
end
