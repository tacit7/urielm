defmodule UrielmWeb.HomeLive do
  use UrielmWeb, :live_view

  alias Urielm.Content
  alias Urielm.Learning

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:prompt_variant, :before)
      |> then(fn socket ->
        if connected?(socket) do
          assign(socket,
            page_title: "Home",
            courses: Learning.list_courses() |> Enum.take(3),
            posts: Content.list_published_posts(limit: 4),
            prompts: Content.list_prompts(limit: 6),
            shorts: Content.list_published_shorts(limit: 5)
          )
        else
          assign(socket,
            page_title: "Home",
            courses: [],
            posts: [],
            prompts: [],
            shorts: []
          )
        end
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("show_prompt_variant", %{"variant" => variant}, socket)
      when variant in ["before", "improved"] do
    {:noreply, assign(socket, :prompt_variant, String.to_existing_atom(variant))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <.hero prompt_variant={@prompt_variant} />
      <.app_purpose />
      <.shorts shorts={@shorts} />
      <.courses courses={@courses} />
      <.blog_posts posts={@posts} />
      <.prompts prompts={@prompts} />
      <.footer />
    </div>
    """
  end

  defp hero(assigns) do
    assigns = assign(assigns, :improved_prompt, improved_prompt())

    ~H"""
    <section id="home-hero" class="relative overflow-hidden bg-base-100">
      <div class="relative mx-auto grid w-full max-w-7xl items-center gap-12 px-6 py-16 sm:py-20 lg:min-h-[38rem] lg:grid-cols-[0.96fr_1.04fr] lg:gap-16 lg:py-24">
        <div class="max-w-2xl">
          <h1 class="max-w-[12ch] text-4xl font-black leading-[1.02] tracking-[-0.038em] text-balance text-base-content sm:text-5xl">
            Build useful things with AI.
          </h1>

          <p class="mt-6 max-w-[58ch] text-lg leading-8 text-base-content/65">
            Learn through practical tutorials, reusable prompts, and guided projects—then apply what
            works to something of your own.
          </p>

          <div class="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
            <.link
              id="hero-primary-cta"
              navigate={~p"/courses"}
              class="group btn btn-primary min-h-12 rounded-xl px-6 font-bold shadow-lg shadow-base-300/25 transition duration-200 hover:-translate-y-0.5"
            >
              Start learning
              <.um_icon
                name="hero-arrow-right"
                class="size-5 transition-transform group-hover:translate-x-0.5"
              />
            </.link>
            <.link
              id="hero-prompts-cta"
              navigate={~p"/prompts"}
              class="btn btn-ghost min-h-12 rounded-xl px-6 font-semibold text-base-content/75 hover:bg-base-200 hover:text-base-content"
            >
              Browse prompts
            </.link>
          </div>

          <p class="mt-5 flex items-start gap-2 text-sm leading-6 text-base-content/50">
            <.um_icon name="hero-globe-alt" class="mt-0.5 size-4 shrink-0 text-accent" />
            Public resources are available without an account.
          </p>
        </div>

        <article
          id="prompt-improvement-example"
          class="card overflow-hidden bg-base-200 shadow-xl shadow-base-300/20"
          aria-label="Example prompt improvement"
        >
          <header class="flex flex-col gap-3 border-b border-base-300/80 bg-base-300/25 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-center gap-2 text-sm font-bold text-base-content">
              <.um_icon name="hero-chat-bubble-left-right" class="size-5 text-primary" />
              Make a prompt more effective
            </div>

            <div
              class="tabs tabs-box bg-base-100/65 p-1"
              role="tablist"
              aria-label="Prompt comparison"
            >
              <button
                id="prompt-variant-before"
                type="button"
                role="tab"
                aria-selected={to_string(@prompt_variant == :before)}
                phx-click="show_prompt_variant"
                phx-value-variant="before"
                class={[
                  "tab h-8 rounded-lg px-3 text-xs font-bold",
                  @prompt_variant == :before && "tab-active bg-base-300/70 text-base-content"
                ]}
              >
                Before
              </button>
              <button
                id="prompt-variant-improved"
                type="button"
                role="tab"
                aria-selected={to_string(@prompt_variant == :improved)}
                phx-click="show_prompt_variant"
                phx-value-variant="improved"
                class={[
                  "tab h-8 rounded-lg px-3 text-xs font-bold",
                  @prompt_variant == :improved && "tab-active bg-base-300/70 text-base-content"
                ]}
              >
                Improved
              </button>
            </div>
          </header>

          <div :if={@prompt_variant == :before} id="prompt-before-pane" class="min-h-72 p-5 sm:p-7">
            <p class="font-mono text-xs font-bold uppercase tracking-[0.12em] text-base-content/45">
              Original prompt
            </p>
            <p class="mt-4 font-mono text-sm leading-7 text-base-content sm:text-base">
              Write a blog post about effective AI prompts.
            </p>

            <ul class="mt-8 space-y-3 border-t border-base-300/80 pt-6 text-sm text-base-content/60">
              <li class="flex items-center gap-3">
                <.um_icon name="hero-check" class="size-4 shrink-0 text-success" />
                Add a clear audience and goal
              </li>
              <li class="flex items-center gap-3">
                <.um_icon name="hero-check" class="size-4 shrink-0 text-success" />
                Specify the structure and constraints
              </li>
              <li class="flex items-center gap-3">
                <.um_icon name="hero-check" class="size-4 shrink-0 text-success" />
                Describe what a useful answer contains
              </li>
            </ul>
          </div>

          <div
            :if={@prompt_variant == :improved}
            id="prompt-improved-pane"
            class="min-h-72 p-5 sm:p-7"
          >
            <p class="font-mono text-xs font-bold uppercase tracking-[0.12em] text-base-content/45">
              Improved prompt
            </p>
            <p class="mt-4 line-clamp-7 whitespace-pre-line font-mono text-sm leading-7 text-base-content sm:text-base">
              {@improved_prompt}
            </p>

            <p class="mt-8 flex items-start gap-3 border-t border-base-300/80 pt-6 text-sm leading-6 text-base-content/60">
              <.um_icon name="hero-check" class="mt-1 size-4 shrink-0 text-success" />
              Audience, outcome, structure, and limits are explicit.
            </p>
          </div>

          <footer class="flex flex-col gap-3 border-t border-base-300/80 px-5 py-4 text-xs text-base-content/45 sm:flex-row sm:items-center sm:justify-between">
            <span>Illustrative learning example</span>
            <button
              id="hero-prompt-copy"
              type="button"
              phx-hook="CopyToClipboard"
              data-text={@improved_prompt}
              class="btn btn-ghost btn-sm justify-start gap-2 rounded-lg text-primary hover:bg-primary/10 sm:justify-center"
              aria-label="Copy improved prompt"
            >
              Copy example
            </button>
          </footer>
        </article>
      </div>
    </section>
    """
  end

  defp app_purpose(assigns) do
    ~H"""
    <section id="app-purpose" class="bg-base-100 px-6 pb-20 sm:pb-24">
      <div
        id="learning-outcomes"
        class="mx-auto grid max-w-7xl gap-10 border-t border-base-300/80 pt-14 lg:grid-cols-[0.72fr_1.28fr] lg:gap-16 lg:pt-18"
      >
        <div>
          <h2 class="max-w-[14ch] text-3xl font-black leading-tight tracking-[-0.03em] text-balance text-base-content sm:text-4xl">
            What do you want to make progress on?
          </h2>
          <p class="mt-5 max-w-md leading-7 text-base-content/60">
            Urielm is a public learning platform. Choose an outcome and start with the most useful
            tutorials, prompts, workflows, videos, or community resources for it.
          </p>
        </div>

        <nav class="border-t border-base-300/80" aria-label="Learning outcomes">
          <.outcome_link
            id="outcome-learn"
            href={~p"/courses"}
            icon="hero-book-open"
            title="Learn a concept"
            description="Follow a focused tutorial or structured course."
          />
          <.outcome_link
            id="outcome-prompt"
            href={~p"/prompts"}
            icon="hero-command-line"
            title="Improve a prompt"
            description="Start with a reusable prompt and adapt it to your project."
          />
          <.outcome_link
            id="outcome-workflow"
            href={~p"/blog"}
            icon="hero-arrows-right-left"
            title="Build a workflow"
            description="Connect practical steps into a repeatable process."
          />
          <.outcome_link
            id="outcome-video"
            href={~p"/videos"}
            icon="hero-play"
            title="Watch a quick demo"
            description="See one useful technique in a few focused minutes."
          />
        </nav>
      </div>
    </section>
    """
  end

  attr :id, :string, required: true
  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true

  defp outcome_link(assigns) do
    ~H"""
    <.link
      id={@id}
      navigate={@href}
      class="group grid min-h-24 grid-cols-[2.75rem_minmax(0,1fr)_1.25rem] items-center gap-4 border-b border-base-300/80 py-4 transition duration-200 hover:translate-x-1 hover:text-primary"
    >
      <span class="grid size-11 place-items-center rounded-xl bg-base-200 text-primary transition-colors group-hover:bg-primary/12">
        <.um_icon name={@icon} class="size-5" />
      </span>
      <span>
        <strong class="block font-bold tracking-[-0.015em] text-base-content group-hover:text-primary">
          {@title}
        </strong>
        <span class="mt-1 block text-sm leading-6 text-base-content/55">{@description}</span>
      </span>
      <.um_icon
        name="hero-arrow-right"
        class="size-5 text-base-content/30 transition duration-200 group-hover:translate-x-1 group-hover:text-primary"
      />
    </.link>
    """
  end

  defp improved_prompt do
    "Write a concise guide for developers new to AI tools. Explain five principles for effective prompts, show one before-and-after example, and finish with a reusable checklist. Use plain language and keep the guide under 900 words."
  end

  defp shorts(assigns) do
    ~H"""
    <section id="home-shorts" class="ui-section bg-base-200/50">
      <div class="ui-section-shell">
        <div class="mb-6 flex items-start justify-between gap-4 sm:mb-8 sm:items-end">
          <div>
            <h2 class="max-w-xl text-3xl font-bold leading-tight tracking-[-0.035em] text-base-content">
              Learn something useful in a minute.
            </h2>
            <p class="mt-2 max-w-xl text-sm leading-6 text-base-content/55 sm:text-base">
              Short, practical demonstrations you can put to work right away.
            </p>
          </div>
          <.link
            navigate={~p"/videos"}
            class="btn btn-ghost min-h-11 flex-none gap-2 px-2 text-primary"
          >
            View all <.um_icon name="hero-arrow-right" class="size-4" />
          </.link>
        </div>

        <%= if Enum.empty?(@shorts) do %>
          <p class="text-base-content/50 text-sm">No shorts yet.</p>
        <% end %>
        <div
          id="home-shorts-rail"
          class="ui-media-rail -mx-6 grid snap-x snap-mandatory grid-flow-col auto-cols-[10.5rem] gap-4 overflow-x-auto px-6 pb-4 sm:auto-cols-[11rem] lg:mx-0 lg:auto-cols-[13rem] lg:px-0"
          aria-label="Featured short videos"
        >
          <%= for short <- @shorts do %>
            <.home_short_card short={short} />
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  attr :short, :map, required: true

  defp home_short_card(assigns) do
    assigns =
      assigns
      |> assign(:thumbnail, short_thumbnail_url(assigns.short))
      |> assign(:author, short_author_name(assigns.short))
      |> assign(:published_label, short_published_label(assigns.short.published_at))

    ~H"""
    <.link
      id={"home-short-card-#{@short.id}"}
      navigate={~p"/videos/#{@short.slug}"}
      aria-label={"Watch #{@short.title}"}
      class="card ui-card ui-card-interactive ui-card-compact group relative aspect-[9/16] snap-start overflow-hidden bg-base-300 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-primary"
    >
      <div class="absolute inset-0 bg-base-300" aria-hidden="true">
        <div
          :if={!@thumbnail}
          id={"home-short-fallback-#{@short.id}"}
          class="absolute -inset-x-8 top-1/4 h-20 -rotate-12 bg-primary/12"
        >
        </div>
        <div
          :if={!@thumbnail}
          class="absolute -inset-x-8 top-1/2 h-14 -rotate-12 bg-primary/7"
        >
        </div>
        <img
          :if={@thumbnail}
          src={@thumbnail}
          alt=""
          loading="lazy"
          class="h-full w-full object-cover transition duration-500 group-hover:scale-[1.04] motion-reduce:transition-none"
        />
      </div>

      <div class="absolute inset-0 flex flex-col justify-between bg-gradient-to-t from-neutral/95 via-neutral/10 to-neutral/40 p-3.5">
        <div class="flex items-start justify-between gap-2">
          <span class="badge badge-sm border-white/20 bg-neutral/75 font-bold uppercase tracking-[0.12em] text-white">
            Short
          </span>
          <span
            id={"home-short-play-#{@short.id}"}
            class="btn btn-circle btn-sm min-h-11 min-w-11 border-0 bg-primary text-primary-content shadow-lg shadow-neutral/30 transition-transform duration-200 group-hover:scale-105 motion-reduce:transition-none"
            aria-hidden="true"
          >
            <.um_icon name="hero-play-solid" class="ml-0.5 size-4" />
          </span>
        </div>

        <div>
          <div
            :if={@short.tag_records != []}
            id={"home-short-card-tags-#{@short.id}"}
            class="mb-2 flex flex-wrap gap-1"
          >
            <span
              :for={tag <- Enum.take(@short.tag_records, 2)}
              class="badge badge-sm h-auto border-white/20 bg-neutral/75 px-1.5 py-1 text-xs font-bold text-white"
            >
              {tag.name}
            </span>
          </div>

          <h3 class="line-clamp-3 text-sm font-bold leading-snug tracking-[-0.02em] text-white">
            {@short.title}
          </h3>
          <p
            id={"home-short-card-meta-#{@short.id}"}
            class="mt-2 flex items-center justify-between gap-2 text-xs text-white/65"
          >
            <span class="truncate">{@author}</span>
            <span class="flex-none">{@published_label}</span>
          </p>
        </div>
      </div>
    </.link>
    """
  end

  defp courses(assigns) do
    ~H"""
    <section id="home-courses" class="ui-section bg-base-100">
      <div class="ui-section-shell">
        <%!-- Section Header --%>
        <div class="ui-section-header ui-section-header-centered">
          <span class="ui-eyebrow">
            Learn AI Development
          </span>
          <h2 class="ui-section-title">Featured Courses</h2>
          <p class="ui-section-copy">
            Structured learning paths to take you from curious beginner to confident AI developer.
          </p>
        </div>

        <%!-- Course Cards Grid --%>
        <%= if Enum.empty?(@courses) do %>
          <.empty_state
            id="home-courses-empty-state"
            title="No courses yet."
            icon="hero-book-open"
            compact
          />
        <% end %>
        <div class="grid md:grid-cols-3 gap-8">
          <%= for {course, index} <- Enum.with_index(@courses) do %>
            <% color = course_color_classes(index) %>
            <.link navigate={~p"/courses/#{course.slug}"} class="group">
              <div class="ui-card ui-card-interactive flex h-full flex-col p-8">
                <%!-- Icon --%>
                <div class={"w-14 h-14 rounded-lg #{color.icon_bg} flex items-center justify-center mb-6"}>
                  <.um_icon
                    id={"home-course-icon-#{course.id}"}
                    name="hero-book-open"
                    class={"size-7 #{color.icon_text}"}
                  />
                </div>

                <%!-- Content --%>
                <h3 class="text-xl font-bold text-base-content mb-3 group-hover:text-primary transition-colors">
                  {course.title}
                </h3>
                <p class="text-base-content/60 text-sm leading-relaxed mb-6">
                  {course.description}
                </p>

                <%!-- Badge --%>
                <div class="mt-auto pt-6 border-t border-base-300">
                  <span class={"badge badge-outline #{color.badge}"}>Start Course</span>
                </div>
              </div>
            </.link>
          <% end %>
        </div>

        <%!-- CTA --%>
        <div class="text-center mt-12">
          <.link navigate={~p"/courses"} class="btn btn-outline btn-lg rounded-full px-8 gap-2">
            View All Courses
            <.um_icon id="home-courses-cta-icon" name="hero-arrow-right" class="size-5" />
          </.link>
        </div>
      </div>
    </section>
    """
  end

  defp blog_posts(assigns) do
    ~H"""
    <section id="home-articles" class="ui-section bg-base-200/30">
      <div class="ui-section-shell">
        <%!-- Section Header --%>
        <div class="ui-section-header">
          <div>
            <span class="ui-eyebrow">
              From the Blog
            </span>
            <h2 class="ui-section-title">Latest Articles</h2>
          </div>
          <.link navigate={~p"/blog"} class="btn btn-ghost gap-2 hidden md:flex">
            Read All <.um_icon id="home-articles-cta-icon" name="hero-arrow-right" class="size-4" />
          </.link>
        </div>

        <%!-- Blog Grid --%>
        <%= if Enum.empty?(@posts) do %>
          <.empty_state
            id="home-articles-empty-state"
            title="No posts yet."
            icon="hero-document-text"
            compact
          />
        <% end %>
        <div class="grid lg:grid-cols-2 gap-8">
          <%!-- Featured Post (Large) - first post --%>
          <%= for post <- Enum.take(@posts, 1) do %>
            <.link navigate={~p"/blog/#{post.slug}"} class="group lg:row-span-2">
              <div class="ui-card ui-card-interactive flex h-full flex-col p-8">
                <h3 class="text-2xl md:text-3xl font-bold text-base-content mt-2 mb-4 group-hover:text-primary transition-colors leading-tight">
                  {post.title}
                </h3>
                <p class="text-base-content/60 text-lg leading-relaxed mb-8">
                  {post.excerpt}
                </p>
                <div class="flex items-center justify-between mt-auto pt-6 border-t border-base-300">
                  <span class="text-sm text-base-content/50">
                    {Calendar.strftime(post.published_at, "%b %d, %Y")}
                  </span>
                </div>
              </div>
            </.link>
          <% end %>

          <%!-- Other Posts --%>
          <%= for post <- Enum.drop(@posts, 1) do %>
            <.link navigate={~p"/blog/#{post.slug}"} class="group">
              <div class="ui-card ui-card-interactive ui-card-compact p-6">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1">
                    <h3 class="text-lg font-semibold text-base-content mb-2 group-hover:text-secondary transition-colors">
                      {post.title}
                    </h3>
                    <p class="text-base-content/60 text-sm line-clamp-2">
                      {post.excerpt}
                    </p>
                  </div>
                </div>
                <div class="flex items-center gap-4 mt-4 text-xs text-base-content/50">
                  <span>{Calendar.strftime(post.published_at, "%b %d, %Y")}</span>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  defp prompts(assigns) do
    ~H"""
    <section id="home-prompts" class="ui-section relative overflow-hidden bg-base-100">
      <%!-- Background Pattern --%>
      <div class="absolute inset-0 opacity-[0.02]" aria-hidden="true">
        <div
          class="absolute inset-0"
          style="background-image: radial-gradient(circle at 1px 1px, currentColor 1px, transparent 0); background-size: 40px 40px;"
        >
        </div>
      </div>

      <div class="ui-section-shell relative">
        <%!-- Section Header --%>
        <div class="ui-section-header ui-section-header-centered">
          <span class="ui-eyebrow">
            Prompt Library
          </span>
          <h2 class="ui-section-title">Ready-to-Use Prompts</h2>
          <p class="ui-section-copy">
            Battle-tested prompts for common tasks. Copy, customize, and use in your projects.
          </p>
        </div>

        <%!-- Prompts Grid --%>
        <%= if Enum.empty?(@prompts) do %>
          <.empty_state
            id="home-prompts-empty-state"
            title="No prompts yet."
            icon="hero-command-line"
            compact
          />
        <% end %>
        <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for prompt <- @prompts do %>
            <.link navigate={~p"/prompts/#{prompt.id}"} class="group min-w-0">
              <div class="ui-card ui-card-interactive ui-card-compact flex items-center gap-4 p-5">
                <div class="w-12 h-12 rounded-lg bg-accent/10 flex items-center justify-center flex-shrink-0">
                  <.um_icon
                    id={"home-prompt-icon-#{prompt.id}"}
                    name="hero-command-line"
                    class="size-6 text-accent"
                  />
                </div>
                <div class="flex-1 min-w-0">
                  <h3 class="font-semibold text-base-content group-hover:text-accent transition-colors truncate">
                    {prompt.title}
                  </h3>
                  <div class="flex items-center gap-2 mt-1">
                    <span class="text-xs text-base-content/50">{prompt.category}</span>
                    <span class="text-xs text-base-content/30">•</span>
                    <span class="text-xs text-base-content/50">{prompt.likes_count} likes</span>
                  </div>
                </div>
                <.um_icon
                  id={"home-prompt-chevron-#{prompt.id}"}
                  name="hero-chevron-right"
                  class="size-5 text-base-content/30 group-hover:text-accent group-hover:translate-x-1 transition-all"
                />
              </div>
            </.link>
          <% end %>
        </div>

        <%!-- CTA --%>
        <div class="text-center mt-12">
          <.link navigate={~p"/prompts"} class="btn btn-accent btn-lg rounded-full px-8 gap-2">
            Explore All Prompts
            <.um_icon id="home-prompts-cta-icon" name="hero-arrow-right" class="size-5" />
          </.link>
        </div>
      </div>
    </section>
    """
  end

  defp footer(assigns) do
    ~H"""
    <footer class="bg-base-200 border-t border-base-300">
      <div class="max-w-7xl mx-auto px-6 py-16">
        <div class="grid md:grid-cols-4 gap-12">
          <!-- Brand -->
          <div class="md:col-span-2">
            <div class="text-2xl font-bold text-base-content mb-4">urielm.dev</div>
            <p class="text-base-content/60 max-w-sm mb-6">
              Helping developers and creators master AI development through practical tutorials, courses, and ready-to-use prompts.
            </p>
            <div class="flex gap-4">
              <a
                href="https://github.com/tacit7"
                target="_blank"
                rel="noopener"
                class="btn btn-ghost btn-circle btn-sm"
              >
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                </svg>
              </a>
              <a
                href="https://linkedin.com/in/uriel781"
                target="_blank"
                rel="noopener"
                class="btn btn-ghost btn-circle btn-sm"
              >
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
                </svg>
              </a>
              <a
                href="https://youtube.com/@urielm"
                target="_blank"
                rel="noopener"
                class="btn btn-ghost btn-circle btn-sm"
              >
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
                </svg>
              </a>
            </div>
          </div>

          <!-- Quick Links -->
          <div>
            <h4 class="font-semibold text-base-content mb-4">Learn</h4>
            <ul class="space-y-3">
              <li>
                <.link
                  navigate={~p"/videos"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Videos
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/courses"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Courses
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/blog"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Blog
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/prompts"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Prompts
                </.link>
              </li>
            </ul>
          </div>

          <!-- Community -->
          <div>
            <h4 class="font-semibold text-base-content mb-4">Community</h4>
            <ul class="space-y-3">
              <li>
                <.link
                  navigate={~p"/forum"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Forum
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/chat"}
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  Chat
                </.link>
              </li>
              <li>
                <a
                  href="https://github.com/tacit7"
                  target="_blank"
                  class="text-base-content/60 hover:text-primary transition-colors"
                >
                  GitHub
                </a>
              </li>
            </ul>
          </div>
        </div>

        <!-- Bottom Bar -->
        <div class="border-t border-base-300 mt-12 pt-8 flex flex-col md:flex-row items-center justify-between gap-4">
          <p class="text-sm text-base-content/50">
            © 2026 Uriel Maldonado. All rights reserved.
          </p>
          <nav aria-label="Legal" class="flex items-center gap-5 text-sm">
            <.link
              id="home-footer-privacy-link"
              navigate={~p"/privacy"}
              class="text-base-content/60 transition-colors hover:text-primary focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-primary"
            >
              Privacy Policy
            </.link>
            <.link
              id="home-footer-terms-link"
              navigate={~p"/terms"}
              class="text-base-content/60 transition-colors hover:text-primary focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-primary"
            >
              Terms of Use
            </.link>
          </nav>
        </div>
      </div>
    </footer>
    """
  end

  defp course_color_classes(0),
    do: %{icon_bg: "bg-primary/10", icon_text: "text-primary", badge: "badge-primary"}

  defp course_color_classes(1),
    do: %{icon_bg: "bg-secondary/10", icon_text: "text-secondary", badge: "badge-secondary"}

  defp course_color_classes(2),
    do: %{icon_bg: "bg-accent/10", icon_text: "text-accent", badge: "badge-accent"}

  defp course_color_classes(_),
    do: %{icon_bg: "bg-base-300", icon_text: "text-base-content", badge: "badge-neutral"}

  defp short_thumbnail_url(%{id: id, tiktok_url: url}) when is_binary(url) and url != "" do
    ~p"/video-thumbnails/#{id}"
  end

  defp short_thumbnail_url(%{youtube_url: url}) when is_binary(url) and url != "" do
    case Urielm.EmbedParser.extract_youtube_id(url) do
      nil -> nil
      id -> "https://img.youtube.com/vi/#{id}/hqdefault.jpg"
    end
  end

  defp short_thumbnail_url(_short), do: nil

  defp short_author_name(%{author_name: author}) when is_binary(author) and author != "",
    do: author

  defp short_author_name(_short), do: "Uriel Maldonado"

  defp short_published_label(nil), do: ""
  defp short_published_label(date), do: Calendar.strftime(date, "%b %d, %Y")
end
