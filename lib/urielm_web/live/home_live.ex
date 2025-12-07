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
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page={@current_page}
      socket={@socket}
    >
      <.hero socket={@socket} />
      <.tech_stack />
      <.bento_grid />
      <.footer />
    </Layouts.app>
    """
  end

  defp hero(assigns) do
    ~H"""
    <section class="relative pt-32 pb-20 lg:pt-48 lg:pb-32 overflow-hidden">
      <div class="max-w-7xl mx-auto px-6 relative z-10 flex flex-col items-center text-center">
        <!-- Badge -->
        <div class="inline-flex items-center space-x-2 bg-base-300/50 backdrop-blur-sm border border-base-300 px-3 py-1 rounded-full mb-8 animate-fade-in-up">
          <span class="relative flex h-2 w-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75">
            </span>
            <span class="relative inline-flex rounded-full h-2 w-2 bg-success"></span>
          </span>
          <span class="text-[10px] uppercase tracking-wider font-semibold text-base-content/70">
            New Video: Claude 3.5 Opus Workflow
          </span>
        </div>
        
    <!-- Headline -->
        <h1 class="text-5xl md:text-7xl lg:text-8xl font-semibold text-base-content tracking-tight mb-8 max-w-5xl mx-auto leading-[1.1] animate-fade-in-up delay-100">
          Building the future with <span class="text-base-content/50">AI & Automation.</span>
        </h1>
        
    <!-- Subhead -->
        <p class="text-lg md:text-xl text-base-content/70 max-w-2xl mx-auto mb-10 leading-relaxed animate-fade-in-up delay-200">
          I help developers and creators master Claude Code, build n8n workflows, and automate the boring stuff so you can focus on creating.
        </p>
        
    <!-- CTAs -->
        <div class="flex flex-col sm:flex-row items-center space-y-4 sm:space-y-0 sm:space-x-4 animate-fade-in-up delay-300">
          <button class="btn btn-primary h-12 px-8 rounded-full font-medium flex items-center space-x-2 transition-all transform hover:scale-105">
            <span>Explore Tutorials</span>
            <.icon
              name="hero-play-solid"
              class="h-4 w-4 group-hover:translate-x-1 transition-transform"
            />
          </button>
          <button class="btn btn-outline h-12 px-8 rounded-full font-medium transition-all">
            Book Consultation
          </button>
        </div>
      </div>
      
    <!-- Floating Elements -->
      <.CodeSnippetCard delay={0} socket={@socket} />
      
    <!-- Background Gradients -->
      <div class="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[600px] bg-gradient-to-b from-blue-50 to-white rounded-full blur-3xl -z-10 opacity-60">
      </div>
    </section>
    """
  end

  defp tech_stack(assigns) do
    ~H"""
    <section class="py-12 border-y border-base-300 bg-base-200">
      <div class="max-w-7xl mx-auto px-6 text-center">
        <p class="text-xs font-semibold uppercase tracking-widest text-base-content/50 mb-8">
          My Stack & Tools
        </p>
        <div class="flex flex-wrap justify-center gap-12 md:gap-20 opacity-50 grayscale hover:grayscale-0 transition-all duration-500">
          <%= for tool <- ["Claude", "OpenAI", "n8n", "Svelte", "Phoenix"] do %>
            <div class="flex items-center space-x-2 group cursor-default">
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
          <div class="md:col-span-2 rounded-3xl bg-base-200 p-8 relative overflow-hidden group hover:shadow-2xl transition-all duration-500">
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
            <div class="absolute right-[-20px] bottom-[-20px] w-64 h-64 bg-gradient-to-tl from-red-500/20 to-transparent rounded-full opacity-0 group-hover:opacity-50 blur-3xl transition-opacity duration-700 ease-out">
            </div>
          </div>
          
    <!-- Tall Card - Automation Services -->
          <div class="md:row-span-2 rounded-3xl bg-base-300 p-8 text-base-content relative overflow-hidden group">
            <div class="relative z-10 h-full flex flex-col justify-between">
              <div>
                <div class="w-12 h-12 bg-base-100 rounded-2xl flex items-center justify-center mb-6 border border-base-content/20">
                  <.icon name="hero-bolt" class="h-6 w-6 text-warning" />
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
          <div class="rounded-3xl bg-base-200 p-8 relative overflow-hidden group hover:bg-primary/10 transition-colors duration-500">
            <div class="w-12 h-12 bg-base-300 rounded-2xl flex items-center justify-center mb-6 shadow-sm">
              <.icon name="hero-chat-bubble-left-right" class="h-6 w-6 text-primary" />
            </div>
            <h3 class="text-xl font-semibold mb-2 text-base-content">Prompting</h3>
            <p class="text-base-content/70 text-sm">
              Library of system prompts for coding & writing.
            </p>
          </div>
          
    <!-- Small Card 2 - Code/Consulting -->
          <div class="rounded-3xl bg-base-200 p-8 relative overflow-hidden group hover:bg-success/10 transition-colors duration-500">
            <div class="w-12 h-12 bg-base-300 rounded-2xl flex items-center justify-center mb-6 shadow-sm">
              <.icon name="hero-code-bracket" class="h-6 w-6 text-success" />
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
    <footer class="bg-base-100 border-t border-base-300 py-16">
      <div class="max-w-7xl mx-auto px-6 flex flex-col md:flex-row justify-between items-center md:items-start">
        <div class="mb-8 md:mb-0 text-center md:text-left">
          <div class="text-2xl font-bold tracking-tight text-base-content mb-4">UrielM.dev</div>
          <p class="text-base-content/70 text-sm max-w-xs">
            Building with AI, automation, and modern web technologies.
          </p>
        </div>

        <div class="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-12 text-sm text-base-content/60">
          <a href="#" class="hover:text-base-content transition-colors">Projects</a>
          <a href="#" class="hover:text-base-content transition-colors">Blog</a>
          <a href="#" class="hover:text-base-content transition-colors">Twitter/X</a>
          <a href="#" class="hover:text-base-content transition-colors">GitHub</a>
        </div>
      </div>
      <div class="max-w-7xl mx-auto px-6 mt-16 pt-8 border-t border-base-300 text-center text-xs text-base-content/50">
        © 2025 Uriel Maldonado. All rights reserved.
      </div>
    </footer>
    """
  end
end
