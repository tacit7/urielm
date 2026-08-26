defmodule UrielmWeb.HomeLive do
  use UrielmWeb, :live_view

  alias Urielm.Content
  alias Urielm.Learning

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        assign(socket,
          page_title: "Home",
          courses: Learning.list_courses() |> Enum.take(3),
          posts: Content.list_published_posts(limit: 4),
          prompts: Content.list_prompts(limit: 6),
          shorts: Content.list_published_shorts(limit: 5),
          stats: %{
            videos: Content.count_published_videos(),
            prompts: Content.count_published_prompts(),
            courses: Learning.count_courses()
          }
        )
      else
        assign(socket,
          page_title: "Home",
          courses: [],
          posts: [],
          prompts: [],
          shorts: [],
          stats: %{videos: 0, prompts: 0, courses: 0}
        )
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-base-100 min-h-screen">
      <.hero stats={@stats} courses={@courses} />
      <.shorts shorts={@shorts} />
      <.courses courses={@courses} />
      <.blog_posts posts={@posts} />
      <.prompts prompts={@prompts} />
      <.footer />
    </div>
    """
  end

  defp hero(assigns) do
    assigns = assign(assigns, :featured_course, List.first(assigns.courses))

    ~H"""
    <section id="home-hero" class="relative flex min-h-[70vh] items-center overflow-hidden">
      <div class="absolute inset-0 opacity-[0.03]" aria-hidden="true">
        <div
          class="absolute inset-0"
          style="background-image: linear-gradient(rgba(255,255,255,.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.1) 1px, transparent 1px); background-size: 60px 60px;"
        >
        </div>
      </div>

      <div
        class="absolute left-[8%] top-20 h-64 w-64 rounded-full bg-primary/10 blur-[110px]"
        aria-hidden="true"
      >
      </div>
      <div
        class="absolute bottom-10 right-[6%] h-80 w-80 rounded-full bg-secondary/10 blur-[130px]"
        aria-hidden="true"
      >
      </div>

      <div class="relative z-10 mx-auto w-full max-w-7xl px-6 py-16 sm:py-20">
        <div class="grid items-center gap-12 lg:grid-cols-[1.08fr_0.92fr] lg:gap-20">
          <div class="max-w-2xl">
            <p class="mb-5 text-xs font-bold uppercase tracking-[0.18em] text-primary">
              Practical AI development
            </p>
            <h1 class="text-5xl font-black leading-[0.95] tracking-[-0.045em] text-base-content md:text-6xl lg:text-7xl">
              Learn to build
              <span class="block bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent">
                with AI.
              </span>
            </h1>

            <p class="mt-7 max-w-xl text-lg leading-relaxed text-base-content/60 md:text-xl">
              Practical tutorials, structured courses, and production-ready prompts for developers building with the latest AI tools.
            </p>

            <div class="mt-8 flex flex-wrap items-center gap-3">
              <.link
                id="hero-primary-cta"
                navigate={~p"/courses"}
                class="group btn btn-primary btn-lg rounded-full px-7 shadow-lg shadow-primary/15 transition duration-200 hover:-translate-y-0.5"
              >
                Start Learning
                <.um_icon
                  name="hero-arrow-right"
                  class="size-5 transition-transform group-hover:translate-x-0.5"
                />
              </.link>
              <.link
                navigate={~p"/prompts"}
                class="btn btn-ghost btn-lg rounded-full px-6 text-base-content/70 hover:text-base-content"
              >
                Browse prompts
              </.link>
            </div>

            <div class="mt-10 flex gap-8 border-t border-base-300/70 pt-6">
              <div>
                <div class="text-2xl font-bold tabular-nums text-base-content">{@stats.videos}</div>
                <div class="text-xs font-medium uppercase tracking-wide text-base-content/45">
                  Videos
                </div>
              </div>
              <div>
                <div class="text-2xl font-bold tabular-nums text-base-content">{@stats.prompts}</div>
                <div class="text-xs font-medium uppercase tracking-wide text-base-content/45">
                  Prompts
                </div>
              </div>
              <div>
                <div class="text-2xl font-bold tabular-nums text-base-content">{@stats.courses}</div>
                <div class="text-xs font-medium uppercase tracking-wide text-base-content/45">
                  Courses
                </div>
              </div>
            </div>
          </div>

          <.link
            id="featured-learning-card"
            navigate={
              if(@featured_course, do: ~p"/courses/#{@featured_course.slug}", else: ~p"/courses")
            }
            class="group hidden overflow-hidden rounded-2xl border border-base-300/70 bg-base-200/70 p-3 shadow-xl shadow-base-300/10 transition duration-300 hover:-translate-y-1 hover:border-primary/40 lg:block"
          >
            <div class="relative flex aspect-[16/10] items-center justify-center overflow-hidden rounded-xl bg-gradient-to-br from-primary/25 via-secondary/15 to-base-300">
              <div class="bg-card-glow absolute inset-0"></div>
              <div class="relative flex size-20 items-center justify-center rounded-2xl border border-white/10 bg-base-100/70 shadow-2xl backdrop-blur">
                <.um_icon name="bolt" class="size-9 text-primary" />
              </div>
            </div>
            <div class="p-5">
              <p class="mb-2 text-xs font-bold uppercase tracking-[0.16em] text-primary">
                Featured course
              </p>
              <h2 class="text-2xl font-bold tracking-tight text-base-content group-hover:text-primary">
                {if(@featured_course, do: @featured_course.title, else: "Build your first AI project")}
              </h2>
              <p class="mt-2 line-clamp-2 text-sm leading-relaxed text-base-content/55">
                {if(@featured_course && @featured_course.description,
                  do: @featured_course.description,
                  else:
                    "Follow a practical learning path from first concept to a production-ready result."
                )}
              </p>
              <span class="mt-5 inline-flex items-center gap-1.5 text-sm font-semibold text-base-content/70 group-hover:text-primary">
                Explore the course <.um_icon name="hero-arrow-right" class="size-4" />
              </span>
            </div>
          </.link>
        </div>
      </div>
    </section>
    """
  end

  defp shorts(assigns) do
    ~H"""
    <section id="home-shorts" class="ui-section bg-base-200/50">
      <div class="ui-section-shell">
        <!-- Section Header -->
        <div class="ui-section-header">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-rose-500 to-orange-500 flex items-center justify-center">
              <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17.77 10.32l-1.2-.5L18 9.06a3 3 0 00-3.91-4.57L12 5.97 9.91 4.49A3 3 0 006 9.06l1.43.76-1.2.5a3 3 0 001.62 5.68h.17l-.9 1.12a3 3 0 004.88 3.49l2-2.5 2 2.5a3 3 0 004.88-3.49l-.9-1.12h.17a3 3 0 001.62-5.68z" />
              </svg>
            </div>
            <div>
              <h2 class="text-2xl font-bold text-base-content">Shorts</h2>
              <p class="text-base-content/50 text-sm">Quick AI tips under 60 seconds</p>
            </div>
          </div>
          <.link navigate={~p"/courses"} class="btn btn-ghost btn-sm gap-2">
            View All
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </.link>
        </div>
        
    <!-- Shorts Horizontal Scroll -->
        <%= if Enum.empty?(@shorts) do %>
          <p class="text-base-content/50 text-sm">No shorts yet.</p>
        <% end %>
        <div class="flex gap-4 overflow-x-auto pb-4 -mx-6 px-6 snap-x snap-mandatory scrollbar-hide">
          <%= for {short, index} <- Enum.with_index(@shorts) do %>
            <.link
              navigate={~p"/videos/#{short.slug}"}
              class="ui-card ui-card-interactive ui-card-compact group w-44 flex-shrink-0 cursor-pointer snap-start p-2"
            >
              <div class={"relative aspect-[9/16] overflow-hidden rounded-xl #{short_gradient(index)}"}>
                <!-- Play Button Overlay -->
                <div class="absolute inset-0 flex items-center justify-center bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity">
                  <div class="w-12 h-12 rounded-full bg-white/20 backdrop-blur flex items-center justify-center">
                    <svg class="w-6 h-6 text-white ml-1" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M8 5v14l11-7z" />
                    </svg>
                  </div>
                </div>
              </div>
              <div class="px-1 pb-1 pt-3">
                <h3 class="text-sm font-medium text-base-content line-clamp-2 group-hover:text-primary transition-colors">
                  {short.title}
                </h3>
              </div>
            </.link>
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  defp courses(assigns) do
    ~H"""
    <section id="home-courses" class="ui-section bg-base-100">
      <div class="ui-section-shell">
        <!-- Section Header -->
        <div class="ui-section-header ui-section-header-centered">
          <span class="ui-eyebrow">
            Learn AI Development
          </span>
          <h2 class="ui-section-title">Featured Courses</h2>
          <p class="ui-section-copy">
            Structured learning paths to take you from curious beginner to confident AI developer.
          </p>
        </div>
        
    <!-- Course Cards Grid -->
        <%= if Enum.empty?(@courses) do %>
          <p class="text-base-content/50 text-sm">No courses yet.</p>
        <% end %>
        <div class="grid md:grid-cols-3 gap-8">
          <%= for {course, index} <- Enum.with_index(@courses) do %>
            <% color = course_color_classes(index) %>
            <.link navigate={~p"/courses/#{course.slug}"} class="group">
              <div class="ui-card ui-card-interactive flex h-full flex-col p-8">
                <!-- Icon -->
                <div class={"w-14 h-14 rounded-2xl #{color.icon_bg} flex items-center justify-center mb-6"}>
                  <svg
                    class={"w-7 h-7 #{color.icon_text}"}
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                    />
                  </svg>
                </div>
                
    <!-- Content -->
                <h3 class="text-xl font-bold text-base-content mb-3 group-hover:text-primary transition-colors">
                  {course.title}
                </h3>
                <p class="text-base-content/60 text-sm leading-relaxed mb-6">
                  {course.description}
                </p>
                
    <!-- Badge -->
                <div class="mt-auto pt-6 border-t border-base-300">
                  <span class={"badge badge-outline #{color.badge}"}>Start Course</span>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
        
    <!-- CTA -->
        <div class="text-center mt-12">
          <.link navigate={~p"/courses"} class="btn btn-outline btn-lg rounded-full px-8 gap-2">
            View All Courses
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M17 8l4 4m0 0l-4 4m4-4H3"
              />
            </svg>
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
        <!-- Section Header -->
        <div class="ui-section-header">
          <div>
            <span class="ui-eyebrow">
              From the Blog
            </span>
            <h2 class="ui-section-title">Latest Articles</h2>
          </div>
          <.link navigate={~p"/blog"} class="btn btn-ghost gap-2 hidden md:flex">
            Read All
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M17 8l4 4m0 0l-4 4m4-4H3"
              />
            </svg>
          </.link>
        </div>
        
    <!-- Blog Grid -->
        <%= if Enum.empty?(@posts) do %>
          <p class="text-base-content/50 text-sm">No posts yet.</p>
        <% end %>
        <div class="grid lg:grid-cols-2 gap-8">
          <!-- Featured Post (Large) — first post -->
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
          
    <!-- Other Posts -->
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
      <!-- Background Pattern -->
      <div class="absolute inset-0 opacity-[0.02]" aria-hidden="true">
        <div
          class="absolute inset-0"
          style="background-image: radial-gradient(circle at 1px 1px, currentColor 1px, transparent 0); background-size: 40px 40px;"
        >
        </div>
      </div>

      <div class="ui-section-shell relative">
        <!-- Section Header -->
        <div class="ui-section-header ui-section-header-centered">
          <span class="ui-eyebrow">
            Prompt Library
          </span>
          <h2 class="ui-section-title">Ready-to-Use Prompts</h2>
          <p class="ui-section-copy">
            Battle-tested prompts for common tasks. Copy, customize, and use in your projects.
          </p>
        </div>
        
    <!-- Prompts Grid -->
        <%= if Enum.empty?(@prompts) do %>
          <p class="text-base-content/50 text-sm">No prompts yet.</p>
        <% end %>
        <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for prompt <- @prompts do %>
            <.link navigate={~p"/prompts/#{prompt.id}"} class="group">
              <div class="ui-card ui-card-interactive ui-card-compact flex items-center gap-4 p-5">
                <div class="w-12 h-12 rounded-xl bg-accent/10 flex items-center justify-center flex-shrink-0">
                  <svg
                    class="w-6 h-6 text-accent"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                  </svg>
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
                <svg
                  class="w-5 h-5 text-base-content/30 group-hover:text-accent group-hover:translate-x-1 transition-all"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </div>
            </.link>
          <% end %>
        </div>
        
    <!-- CTA -->
        <div class="text-center mt-12">
          <.link navigate={~p"/prompts"} class="btn btn-accent btn-lg rounded-full px-8 gap-2">
            Explore All Prompts
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 7l5 5m0 0l-5 5m5-5H6"
              />
            </svg>
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

  @short_gradients [
    "bg-gradient-to-br from-rose-500 to-orange-500",
    "bg-gradient-to-br from-violet-500 to-purple-500",
    "bg-gradient-to-br from-cyan-500 to-blue-500",
    "bg-gradient-to-br from-emerald-500 to-teal-500",
    "bg-gradient-to-br from-amber-500 to-yellow-500"
  ]

  defp short_gradient(index) do
    Enum.at(@short_gradients, rem(index, length(@short_gradients)))
  end
end
