defmodule UrielmWeb.HomeLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_page, "home")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.hero socket={@socket} />
      <.tech_stack />
      <.bento_grid />
      <.footer />
    </div>
    """
  end

  defp hero(assigns) do
    ~H"""
    <section id="hero" class="relative pt-32 pb-20 lg:pt-48 lg:pb-32 overflow-hidden">
      <div class="max-w-7xl mx-auto px-6 relative z-10 flex flex-col items-center text-center">
        <!-- Badge -->
        <.link
          navigate={~p"/blog/building-an-ai-learning-platform"}
          class="inline-flex items-center space-x-2 bg-base-300/50 backdrop-blur-sm border border-base-300 px-3 py-1 rounded-full mb-8 animate-fade-in-up hover:bg-base-300/70 transition-colors"
        >
          <span class="relative flex h-2 w-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75">
            </span>
            <span class="relative inline-flex rounded-full h-2 w-2 bg-success"></span>
          </span>
          <span class="text-[10px] uppercase tracking-wider font-semibold text-base-content/70">
            New Post: Building an AI Learning Platform
          </span>
        </.link>
        
    <!-- Headline -->
        <h1
          id="hero-headline"
          class="text-5xl md:text-7xl lg:text-8xl font-semibold text-base-content tracking-tight mb-8 max-w-5xl mx-auto leading-[1.1] animate-fade-in-up anim-delay-100"
        >
          Building the future with <span class="text-base-content/50">AI & Automation.</span>
        </h1>
        
    <!-- Subhead -->
        <p
          id="hero-subhead"
          class="text-lg md:text-xl text-base-content/70 max-w-2xl mx-auto mb-10 leading-relaxed animate-fade-in-up anim-delay-200"
        >
          I help developers and creators master Claude Code, build n8n workflows, and automate the boring stuff so you can focus on creating.
        </p>
        
    <!-- CTAs -->
        <div class="flex flex-col sm:flex-row items-center space-y-4 sm:space-y-0 sm:space-x-4 animate-fade-in-up anim-delay-300">
          <.link
            id="cta-explore-tutorials"
            navigate={~p"/blog"}
            class="group btn btn-primary h-12 px-8 rounded-full font-medium flex items-center space-x-2 transition-all transform hover:scale-105"
          >
            <span>Explore Tutorials</span>
            <.um_icon
              name="play"
              variant="solid"
              class="h-4 w-4 group-hover:translate-x-1 transition-transform"
            />
          </.link>
          <.link
            id="cta-consult"
            navigate={~p"/chat"}
            class="btn btn-outline h-12 px-8 rounded-full font-medium transition-all"
          >
            Book Consultation
          </.link>
        </div>
      </div>
      
    <!-- Floating Elements -->
      <.CodeSnippetCard delay={0} socket={@socket} />
      
    <!-- Background Gradients -->
      <div
        class="absolute inset-0 z-0 overflow-hidden pointer-events-none select-none"
        aria-hidden="true"
      >
        <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[500px] sm:w-[900px] sm:h-[600px] lg:w-[1200px] lg:h-[800px] rounded-full blur-3xl opacity-100 bg-hero-primary">
        </div>
        <div class="absolute top-0 right-0 w-[400px] h-[400px] sm:w-[500px] sm:h-[500px] lg:w-[600px] lg:h-[600px] rounded-full blur-3xl opacity-100 bg-hero-secondary">
        </div>
      </div>
    </section>
    """
  end

  defp tech_stack(assigns) do
    ~H"""
    <section id="tech-stack" class="py-12 border-y border-base-300 bg-base-200">
      <div class="max-w-7xl mx-auto px-6 text-center">
        <p class="text-xs font-semibold uppercase tracking-widest text-base-content/50 mb-8">
          My Stack & Tools
        </p>
        <div
          id="tools-list"
          class="flex flex-wrap justify-center gap-12 md:gap-20 opacity-50 grayscale hover:grayscale-0 transition-all duration-500"
        >
          <%= for tool <- ["Claude", "OpenAI", "n8n", "Svelte", "Phoenix"] do %>
            <div
              id={"tool-#{String.downcase(tool)}"}
              class="flex items-center space-x-2 group cursor-default"
            >
              <span class="text-xl font-bold font-sans tracking-tight text-base-content/80 group-hover:text-base-content transition-colors">
                {tool}
              </span>
            </div>
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  defp bento_grid(assigns) do
    ~H"""
    <section id="content" class="py-24 bg-base-100">
      <div class="max-w-7xl mx-auto px-6">
        <div class="text-center max-w-3xl mx-auto mb-20">
          <h2 class="text-4xl md:text-5xl font-semibold tracking-tight text-base-content mb-6">
            Learn. Build. Automate.
          </h2>
          <p class="text-lg text-base-content/70">
            Whether you're looking to master the latest LLMs or automate your entire agency, I've got the resources you need.
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 auto-rows-[minmax(300px,auto)]">
          <!-- Large Card - YouTube/Content -->
          <div
            id="card-content"
            class="md:col-span-2 rounded-3xl bg-base-200 p-8 relative overflow-hidden group hover:shadow-2xl transition-all duration-500"
          >
            <div class="relative z-10 h-full flex flex-col justify-between">
              <div>
                <div class="w-12 h-12 bg-base-300 rounded-2xl flex items-center justify-center mb-6 shadow-sm">
                  <.icon name="hero-play-circle" class="h-6 w-6 text-error" />
                </div>
                <h3 class="text-2xl font-semibold mb-2 text-base-content">Deep Dives & Tutorials</h3>
                <p class="text-base-content/70 max-w-sm">
                  Weekly videos breaking down complex topics like Claude Code artifacts, ChatGPT API integration, and advanced prompting strategies.
                </p>
              </div>
              <div class="mt-8 flex items-center space-x-2 text-sm font-medium text-base-content opacity-0 group-hover:opacity-100 transition-opacity transform translate-y-2 group-hover:translate-y-0">
                <span>Watch Now</span> <.icon name="hero-chevron-right" class="h-4 w-4" />
              </div>
            </div>
            <div
              class="absolute right-[-20px] bottom-[-20px] w-64 h-64 bg-card-glow rounded-full opacity-0 group-hover:opacity-50 blur-3xl transition-opacity duration-700 ease-out"
              aria-hidden="true"
            >
            </div>
          </div>
          
    <!-- Tall Card - Automation Services -->
          <div
            id="card-automation"
            class="md:row-span-2 rounded-3xl bg-base-300 p-8 text-base-content relative overflow-hidden group"
          >
            <div class="relative z-10 h-full flex flex-col justify-between">
              <div>
                <div class="w-12 h-12 bg-base-100 rounded-2xl flex items-center justify-center mb-6 border border-base-content/20">
                  <.um_icon name="bolt" class="h-6 w-6 text-warning" />
                </div>
                <h3 class="text-2xl font-semibold mb-2">Automation Systems</h3>
                <p class="text-base-content/60">
                  Custom n8n workflows that run your business while you sleep.
                </p>
              </div>
              
    <!-- Animated Terminal Visual -->
              <div class="mt-12 bg-base-100 rounded-xl p-4 border border-base-300 font-mono text-xs text-success opacity-80">
                <div class="mb-2 text-base-content/50 border-b border-base-300 pb-2">
                  workflow_engine.log
                </div>
                <div class="space-y-2">
                  <div class="flex gap-2">
                    <span class="text-base-content/40">09:00:01</span>
                    <span>Fetching new leads...</span>
                  </div>
                  <div class="flex gap-2">
                    <span class="text-base-content/40">09:00:02</span>
                    <span>Enriching data w/ GPT-4o</span>
                  </div>
                  <div class="flex gap-2">
                    <span class="text-base-content/40">09:00:04</span> <span>Drafting email...</span>
                  </div>
                  <div class="flex gap-2">
                    <span class="text-base-content/40">09:00:05</span>
                    <span class="text-base-content bg-success/50 px-1 rounded">✓ Sent</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Small Card 1 - Prompt Engineering -->
          <div
            id="card-prompting"
            class="rounded-3xl bg-base-200 p-8 relative overflow-hidden group hover:bg-primary/10 transition-colors duration-500"
          >
            <div class="w-12 h-12 bg-base-300 rounded-2xl flex items-center justify-center mb-6 shadow-sm">
              <.um_icon name="topics" class="h-6 w-6 text-primary" />
            </div>
            <h3 class="text-xl font-semibold mb-2 text-base-content">Prompting</h3>
            <p class="text-base-content/70 text-sm">
              Library of system prompts for coding & writing.
            </p>
          </div>
          
    <!-- Small Card 2 - Code/Consulting -->
          <div
            id="card-code"
            class="rounded-3xl bg-base-200 p-8 relative overflow-hidden group hover:bg-success/10 transition-colors duration-500"
          >
            <div class="w-12 h-12 bg-base-300 rounded-2xl flex items-center justify-center mb-6 shadow-sm">
              <.um_icon name="hero-code-bracket" class="h-6 w-6 text-success" />
            </div>
            <h3 class="text-xl font-semibold mb-2 text-base-content">Code</h3>
            <p class="text-base-content/70 text-sm">
              Phoenix + Svelte integration patterns & snippets.
            </p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp footer(assigns) do
    ~H"""
    <footer class="footer footer-center bg-base-200 text-base-content rounded p-10">
      <nav class="grid grid-flow-col gap-4">
        <.link navigate={~p"/prompts"} class="link link-hover">Prompts</.link>
        <.link navigate={~p"/blog"} class="link link-hover">Blog</.link>
        <.link navigate={~p"/courses"} class="link link-hover">Courses</.link>
        <.link navigate={~p"/forum"} class="link link-hover">Community</.link>
      </nav>
      <nav>
        <div class="grid grid-flow-col gap-4">
          <a href="https://github.com/tacit7" target="_blank" rel="noopener noreferrer" class="hover:text-primary transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
            </svg>
          </a>
          <a href="https://www.linkedin.com/in/uriel781" target="_blank" rel="noopener noreferrer" class="hover:text-primary transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/>
            </svg>
          </a>
        </div>
      </nav>
      <aside>
        <p>© 2025 Uriel Maldonado. All rights reserved.</p>
      </aside>
    </footer>
    """
  end
end
