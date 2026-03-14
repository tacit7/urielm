defmodule UrielmWeb.HomeLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.Content.{Prompt, Video}
  alias Urielm.Learning
  alias Urielm.Learning.Course
  alias Urielm.Content

  @impl true
  def mount(_params, _session, socket) do
    courses = Learning.list_courses() |> Enum.take(3)
    posts = Content.list_published_posts() |> Enum.take(4)
    prompts = Content.list_prompts(limit: 6)

    shorts =
      Content.list_published_videos(limit: 20)
      |> Enum.filter(&(&1.format == "short"))
      |> Enum.take(5)

    prompt_count = Repo.aggregate(Prompt, :count)
    course_count = Repo.aggregate(Course, :count)
    video_count = Repo.aggregate(from(v in Video, where: not is_nil(v.published_at)), :count)

    {:ok,
     assign(socket,
       courses: courses,
       posts: posts,
       prompts: prompts,
       shorts: shorts,
       stats: %{
         videos: video_count,
         prompts: prompt_count,
         courses: course_count
       }
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-base-100 min-h-screen">
      <.hero stats={@stats} />
      <.shorts shorts={@shorts} />
      <.courses courses={@courses} />
      <.blog_posts posts={@posts} />
      <.prompts prompts={@prompts} />
      <.footer />
    </div>
    """
  end

  defp hero(assigns) do
    ~H"""
    <section class="relative min-h-[90vh] flex items-center overflow-hidden">
      <!-- Animated Background Grid -->
      <div class="absolute inset-0 opacity-[0.03]" aria-hidden="true">
        <div class="absolute inset-0" style="background-image: linear-gradient(rgba(255,255,255,.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.1) 1px, transparent 1px); background-size: 60px 60px;"></div>
      </div>

      <!-- Glowing Orbs -->
      <div class="absolute top-20 left-10 w-72 h-72 bg-primary/20 rounded-full blur-[100px] animate-pulse" aria-hidden="true"></div>
      <div class="absolute bottom-20 right-10 w-96 h-96 bg-secondary/20 rounded-full blur-[120px] animate-pulse" style="animation-delay: 1s;" aria-hidden="true"></div>
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-accent/10 rounded-full blur-[150px]" aria-hidden="true"></div>

      <div class="relative z-10 max-w-7xl mx-auto px-6 py-20 w-full">
        <div class="grid lg:grid-cols-2 gap-16 items-center">
          <!-- Left: Text Content -->
          <div class="space-y-8">
            <!-- Main Headline -->
            <h1 class="text-5xl md:text-6xl lg:text-7xl font-black tracking-tight leading-[0.95]">
              <span class="text-base-content">Master</span>
              <br />
              <span class="bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent">
                AI Development
              </span>
            </h1>

            <!-- Subheadline -->
            <p class="text-xl text-base-content/60 max-w-lg leading-relaxed">
              Tutorials, courses, and prompts to help you build with Claude, GPT-4, and the latest AI tools. From zero to production.
            </p>

            <!-- CTA Buttons -->
            <div class="flex flex-wrap gap-4 pt-4">
              <.link
                navigate={~p"/courses"}
                class="group btn btn-primary btn-lg rounded-full px-8 gap-2"
              >
                Start Learning
                <svg class="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
              </.link>
              <.link
                navigate={~p"/prompts"}
                class="btn btn-outline btn-lg rounded-full px-8"
              >
                Browse Prompts
              </.link>
            </div>

            <!-- Stats Row -->
            <div class="flex gap-8 pt-8 border-t border-base-300">
              <div>
                <div class="text-3xl font-bold text-base-content">{@stats.videos}</div>
                <div class="text-sm text-base-content/50">Videos</div>
              </div>
              <div>
                <div class="text-3xl font-bold text-base-content">{@stats.prompts}</div>
                <div class="text-sm text-base-content/50">Prompts</div>
              </div>
              <div>
                <div class="text-3xl font-bold text-base-content">{@stats.courses}</div>
                <div class="text-sm text-base-content/50">Courses</div>
              </div>
            </div>
          </div>

          <!-- Right: Feature Cards Stack -->
          <div class="relative hidden lg:block">
            <!-- Floating Cards -->
            <div class="relative h-[500px]">
              <!-- Card 1: Code Preview -->
              <div class="absolute top-0 right-0 w-80 bg-base-200 rounded-2xl p-5 border border-base-300 shadow-2xl transform rotate-3 hover:rotate-0 transition-transform duration-500">
                <div class="flex items-center gap-2 mb-3">
                  <div class="w-3 h-3 rounded-full bg-error"></div>
                  <div class="w-3 h-3 rounded-full bg-warning"></div>
                  <div class="w-3 h-3 rounded-full bg-success"></div>
                  <span class="ml-2 text-xs text-base-content/50 font-mono">claude_agent.py</span>
                </div>
                <pre class="text-xs font-mono text-base-content/80 overflow-hidden"><code><span class="text-secondary">from</span> anthropic <span class="text-secondary">import</span> Anthropic&#10;&#10;client = Anthropic()&#10;response = client.messages.create(&#10;    model=<span class="text-success">"claude-3-5-sonnet"</span>,&#10;    max_tokens=<span class="text-warning">1024</span>,&#10;    messages=[...]&#10;)</code></pre>
              </div>

              <!-- Card 2: Prompt Card -->
              <div class="absolute top-32 left-0 w-72 bg-gradient-to-br from-primary/20 to-secondary/20 backdrop-blur rounded-2xl p-5 border border-primary/30 shadow-2xl transform -rotate-6 hover:rotate-0 transition-transform duration-500">
                <div class="text-xs font-semibold text-primary uppercase tracking-wider mb-2">System Prompt</div>
                <p class="text-sm text-base-content/80 leading-relaxed">
                  "You are an expert code reviewer. Analyze the following code for bugs, security issues, and..."
                </p>
                <div class="flex gap-2 mt-3">
                  <span class="badge badge-primary badge-sm">coding</span>
                  <span class="badge badge-secondary badge-sm">review</span>
                </div>
              </div>

              <!-- Card 3: Video Thumbnail -->
              <div class="absolute bottom-0 right-8 w-64 bg-base-300 rounded-2xl overflow-hidden shadow-2xl transform rotate-2 hover:rotate-0 transition-transform duration-500">
                <div class="aspect-video bg-gradient-to-br from-base-200 to-base-300 flex items-center justify-center">
                  <div class="w-16 h-16 rounded-full bg-primary/20 flex items-center justify-center backdrop-blur">
                    <svg class="w-8 h-8 text-primary ml-1" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M8 5v14l11-7z"/>
                    </svg>
                  </div>
                </div>
                <div class="p-4">
                  <div class="text-sm font-medium text-base-content">Build an AI Agent</div>
                  <div class="text-xs text-base-content/50 mt-1">Watch now</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp shorts(assigns) do
    ~H"""
    <section class="py-20 bg-base-200/50">
      <div class="max-w-7xl mx-auto px-6">
        <!-- Section Header -->
        <div class="flex items-center justify-between mb-10">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-rose-500 to-orange-500 flex items-center justify-center">
              <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17.77 10.32l-1.2-.5L18 9.06a3 3 0 00-3.91-4.57L12 5.97 9.91 4.49A3 3 0 006 9.06l1.43.76-1.2.5a3 3 0 001.62 5.68h.17l-.9 1.12a3 3 0 004.88 3.49l2-2.5 2 2.5a3 3 0 004.88-3.49l-.9-1.12h.17a3 3 0 001.62-5.68z"/>
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
        <div class="flex gap-4 overflow-x-auto pb-4 -mx-6 px-6 snap-x snap-mandatory scrollbar-hide">
          <%= for {short, index} <- Enum.with_index(@shorts) do %>
            <.link navigate={~p"/videos/#{short.slug}"} class="flex-shrink-0 w-44 snap-start group cursor-pointer">
              <div class={"relative aspect-[9/16] rounded-2xl overflow-hidden #{short_gradient(index)}"}>
                <!-- Play Button Overlay -->
                <div class="absolute inset-0 flex items-center justify-center bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity">
                  <div class="w-12 h-12 rounded-full bg-white/20 backdrop-blur flex items-center justify-center">
                    <svg class="w-6 h-6 text-white ml-1" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M8 5v14l11-7z"/>
                    </svg>
                  </div>
                </div>
              </div>
              <div class="mt-3">
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
    <section class="py-24 bg-base-100">
      <div class="max-w-7xl mx-auto px-6">
        <!-- Section Header -->
        <div class="text-center mb-16">
          <span class="text-primary font-semibold text-sm uppercase tracking-wider">Learn AI Development</span>
          <h2 class="text-4xl md:text-5xl font-bold text-base-content mt-3 mb-4">
            Featured Courses
          </h2>
          <p class="text-lg text-base-content/60 max-w-2xl mx-auto">
            Structured learning paths to take you from curious beginner to confident AI developer.
          </p>
        </div>

        <!-- Course Cards Grid -->
        <div class="grid md:grid-cols-3 gap-8">
          <%= for {course, index} <- Enum.with_index(@courses) do %>
            <% color = course_color_classes(index) %>
            <.link navigate={~p"/courses/#{course.slug}"} class="group">
              <div class="h-full bg-base-200 rounded-3xl p-8 border border-base-300 hover:border-primary/50 transition-all duration-300 hover:shadow-xl hover:shadow-primary/5 hover:-translate-y-1">
                <!-- Icon -->
                <div class={"w-14 h-14 rounded-2xl #{color.icon_bg} flex items-center justify-center mb-6"}>
                  <svg class={"w-7 h-7 #{color.icon_text}"} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
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
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3" />
            </svg>
          </.link>
        </div>
      </div>
    </section>
    """
  end

  defp blog_posts(assigns) do
    ~H"""
    <section class="py-24 bg-base-200/30">
      <div class="max-w-7xl mx-auto px-6">
        <!-- Section Header -->
        <div class="flex items-end justify-between mb-12">
          <div>
            <span class="text-secondary font-semibold text-sm uppercase tracking-wider">From the Blog</span>
            <h2 class="text-4xl font-bold text-base-content mt-2">Latest Articles</h2>
          </div>
          <.link navigate={~p"/blog"} class="btn btn-ghost gap-2 hidden md:flex">
            Read All
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3" />
            </svg>
          </.link>
        </div>

        <!-- Blog Grid -->
        <div class="grid lg:grid-cols-2 gap-8">
          <!-- Featured Post (Large) — first post -->
          <%= for post <- Enum.take(@posts, 1) do %>
            <.link navigate={~p"/blog/#{post.slug}"} class="group lg:row-span-2">
              <div class="h-full bg-gradient-to-br from-primary/10 via-base-200 to-secondary/10 rounded-3xl p-8 border border-base-300 hover:border-primary/30 transition-all duration-300">
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
              <div class="bg-base-200 rounded-2xl p-6 border border-base-300 hover:border-secondary/30 transition-all duration-300 hover:shadow-lg">
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
    <section class="py-24 bg-base-100 relative overflow-hidden">
      <!-- Background Pattern -->
      <div class="absolute inset-0 opacity-[0.02]" aria-hidden="true">
        <div class="absolute inset-0" style="background-image: radial-gradient(circle at 1px 1px, currentColor 1px, transparent 0); background-size: 40px 40px;"></div>
      </div>

      <div class="relative max-w-7xl mx-auto px-6">
        <!-- Section Header -->
        <div class="text-center mb-16">
          <span class="text-accent font-semibold text-sm uppercase tracking-wider">Prompt Library</span>
          <h2 class="text-4xl md:text-5xl font-bold text-base-content mt-3 mb-4">
            Ready-to-Use Prompts
          </h2>
          <p class="text-lg text-base-content/60 max-w-2xl mx-auto">
            Battle-tested prompts for common tasks. Copy, customize, and use in your projects.
          </p>
        </div>

        <!-- Prompts Grid -->
        <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for prompt <- @prompts do %>
            <.link navigate={~p"/prompts/#{prompt.id}"} class="group">
              <div class="flex items-center gap-4 p-5 bg-base-200 rounded-2xl border border-base-300 hover:border-accent/30 hover:bg-base-200/80 transition-all duration-300">
                <div class="w-12 h-12 rounded-xl bg-accent/10 flex items-center justify-center flex-shrink-0">
                  <svg class="w-6 h-6 text-accent" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
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
                <svg class="w-5 h-5 text-base-content/30 group-hover:text-accent group-hover:translate-x-1 transition-all" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
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
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
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
              <a href="https://github.com/tacit7" target="_blank" rel="noopener" class="btn btn-ghost btn-circle btn-sm">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                </svg>
              </a>
              <a href="https://linkedin.com/in/uriel781" target="_blank" rel="noopener" class="btn btn-ghost btn-circle btn-sm">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/>
                </svg>
              </a>
              <a href="https://youtube.com/@urielm" target="_blank" rel="noopener" class="btn btn-ghost btn-circle btn-sm">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                </svg>
              </a>
            </div>
          </div>

          <!-- Quick Links -->
          <div>
            <h4 class="font-semibold text-base-content mb-4">Learn</h4>
            <ul class="space-y-3">
              <li><.link navigate={~p"/courses"} class="text-base-content/60 hover:text-primary transition-colors">Courses</.link></li>
              <li><.link navigate={~p"/blog"} class="text-base-content/60 hover:text-primary transition-colors">Blog</.link></li>
              <li><.link navigate={~p"/prompts"} class="text-base-content/60 hover:text-primary transition-colors">Prompts</.link></li>
            </ul>
          </div>

          <!-- Community -->
          <div>
            <h4 class="font-semibold text-base-content mb-4">Community</h4>
            <ul class="space-y-3">
              <li><.link navigate={~p"/forum"} class="text-base-content/60 hover:text-primary transition-colors">Forum</.link></li>
              <li><.link navigate={~p"/chat"} class="text-base-content/60 hover:text-primary transition-colors">Chat</.link></li>
              <li><a href="https://github.com/tacit7" target="_blank" class="text-base-content/60 hover:text-primary transition-colors">GitHub</a></li>
            </ul>
          </div>
        </div>

        <!-- Bottom Bar -->
        <div class="border-t border-base-300 mt-12 pt-8 flex flex-col md:flex-row items-center justify-between gap-4">
          <p class="text-sm text-base-content/50">
            © 2026 Uriel Maldonado. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
    """
  end

  defp course_color_classes(0), do: %{icon_bg: "bg-primary/10", icon_text: "text-primary", badge: "badge-primary"}
  defp course_color_classes(1), do: %{icon_bg: "bg-secondary/10", icon_text: "text-secondary", badge: "badge-secondary"}
  defp course_color_classes(2), do: %{icon_bg: "bg-accent/10", icon_text: "text-accent", badge: "badge-accent"}
  defp course_color_classes(_), do: %{icon_bg: "bg-base-300", icon_text: "text-base-content", badge: "badge-neutral"}

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
