defmodule UrielmWeb.ThemesLive do
  use UrielmWeb, :live_view

  @daisyui_themes [
    "light",
    "dark",
    "cupcake",
    "bumblebee",
    "emerald",
    "corporate",
    "synthwave",
    "retro",
    "cyberpunk",
    "valentine",
    "halloween",
    "garden",
    "forest",
    "aqua",
    "lofi",
    "pastel",
    "fantasy",
    "wireframe",
    "black",
    "luxury",
    "cmyk",
    "autumn",
    "business",
    "acid",
    "lemonade",
    "night",
    "coffee",
    "winter"
  ]

  @custom_themes [
    "tokyo-night",
    "catppuccin-mocha",
    "catppuccin-latte",
    "dracula-custom",
    "github-light",
    "github-dark"
  ]

  @all_themes @daisyui_themes ++ @custom_themes

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Themes")
     |> assign(:daisyui_themes, @daisyui_themes)
     |> assign(:custom_themes, @custom_themes)
     |> assign(:all_themes, @all_themes)
     |> assign(:selected_theme, "tokyo-night")}
  end

  def handle_event("select_theme", %{"theme" => theme}, socket) do
    {:noreply, assign(socket, :selected_theme, theme)}
  end

  defp theme_colors(theme) do
    case theme do
      # Custom themes
      "tokyo-night" -> %{primary: "#7aa2f7", secondary: "#bb9af7", accent: "#73daca"}
      "catppuccin-mocha" -> %{primary: "#89b4fa", secondary: "#cba6f7", accent: "#94e2d5"}
      "catppuccin-latte" -> %{primary: "#1e66f5", secondary: "#ea76cb", accent: "#179299"}
      "dracula-custom" -> %{primary: "#ff79c6", secondary: "#8be9fd", accent: "#50fa7b"}
      "github-light" -> %{primary: "#0969da", secondary: "#6e40aa", accent: "#1298f3"}
      "github-dark" -> %{primary: "#58a6ff", secondary: "#bc8ef9", accent: "#79c0ff"}
      # DaisyUI themes
      "light" -> %{primary: "#0d47a1", secondary: "#7c3aed", accent: "#06b6d4"}
      "dark" -> %{primary: "#60a5fa", secondary: "#a78bfa", accent: "#22d3ee"}
      "cupcake" -> %{primary: "#f97316", secondary: "#f472b6", accent: "#06b6d4"}
      "bumblebee" -> %{primary: "#fbbf24", secondary: "#60a5fa", accent: "#34d399"}
      "emerald" -> %{primary: "#10b981", secondary: "#8b5cf6", accent: "#06b6d4"}
      "corporate" -> %{primary: "#194e8c", secondary: "#7c3aed", accent: "#06b6d4"}
      "synthwave" -> %{primary: "#ff006e", secondary: "#8338ec", accent: "#ffbe0b"}
      "retro" -> %{primary: "#fbbf24", secondary: "#f87171", accent: "#60a5fa"}
      "cyberpunk" -> %{primary: "#ffbe0b", secondary: "#fb5607", accent: "#00f5ff"}
      "valentine" -> %{primary: "#eb6f92", secondary: "#f1a7d8", accent: "#f8ad9d"}
      "halloween" -> %{primary: "#ff7a00", secondary: "#7c3aed", accent: "#a3e635"}
      "garden" -> %{primary: "#15803d", secondary: "#ec4899", accent: "#06b6d4"}
      "forest" -> %{primary: "#166534", secondary: "#7c3aed", accent: "#22d3ee"}
      "aqua" -> %{primary: "#0891b2", secondary: "#06b6d4", accent: "#22d3ee"}
      "lofi" -> %{primary: "#0f172a", secondary: "#64748b", accent: "#94a3b8"}
      "pastel" -> %{primary: "#d946ef", secondary: "#f472b6", accent: "#fbbf24"}
      "fantasy" -> %{primary: "#7c3aed", secondary: "#f472b6", accent: "#fbbf24"}
      "wireframe" -> %{primary: "#000000", secondary: "#666666", accent: "#999999"}
      "black" -> %{primary: "#1f2937", secondary: "#374151", accent: "#4b5563"}
      "luxury" -> %{primary: "#5a3a7a", secondary: "#8b5cf6", accent: "#fbbf24"}
      "dracula" -> %{primary: "#ff79c6", secondary: "#8be9fd", accent: "#50fa7b"}
      "cmyk" -> %{primary: "#00ffff", secondary: "#ff00ff", accent: "#ffff00"}
      "autumn" -> %{primary: "#c2410c", secondary: "#dc2626", accent: "#f97316"}
      "business" -> %{primary: "#1e40af", secondary: "#0284c7", accent: "#06b6d4"}
      "acid" -> %{primary: "#ffff00", secondary: "#00ffff", accent: "#ff00ff"}
      "lemonade" -> %{primary: "#84cc16", secondary: "#06b6d4", accent: "#fbbf24"}
      "night" -> %{primary: "#38bdf8", secondary: "#818cf8", accent: "#c084fc"}
      "coffee" -> %{primary: "#6d28d9", secondary: "#7c3aed", accent: "#a78bfa"}
      "winter" -> %{primary: "#0ea5e9", secondary: "#06b6d4", accent: "#22d3ee"}
      _ -> %{primary: "#cccccc", secondary: "#cccccc", accent: "#cccccc"}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <div class="px-4 py-6 border-b border-base-300">
        <h1 class="text-3xl font-bold">Themes</h1>
        <p class="text-base-content/70">Select from a variety of beautiful color schemes</p>
      </div>

      <div class="flex flex-1 overflow-hidden">
        <%!-- Left Pane: Theme List --%>
        <div class="w-80 border-r border-base-300 overflow-y-auto">
          <div class="p-4 space-y-6">
            <%!-- Custom Themes Section --%>
            <div>
              <h2 class="text-sm font-bold uppercase text-base-content/60 mb-3">Custom Themes</h2>
              <div class="space-y-2">
                <%= for theme <- @custom_themes do %>
                  <% colors = theme_colors(theme) %>
                  <div
                    phx-click="select_theme"
                    phx-value-theme={theme}
                    class={"p-3 rounded-lg cursor-pointer transition-all border-2 #{if @selected_theme == theme, do: "border-primary bg-primary/10", else: "border-transparent hover:bg-base-200"}"}
                  >
                    <div class="flex items-center justify-between">
                      <span class="font-medium text-sm capitalize">
                        {String.replace(theme, "-", " ")}
                      </span>
                      <div class="flex gap-1">
                        <div class="w-4 h-4 rounded" style={"background-color: #{colors.primary}"}>
                        </div>
                        <div class="w-4 h-4 rounded" style={"background-color: #{colors.secondary}"}>
                        </div>
                        <div class="w-4 h-4 rounded" style={"background-color: #{colors.accent}"}>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- DaisyUI Themes Section --%>
            <div>
              <h2 class="text-sm font-bold uppercase text-base-content/60 mb-3">DaisyUI Themes</h2>
              <div class="space-y-2 max-h-96 overflow-y-auto">
                <%= for theme <- @daisyui_themes do %>
                  <% colors = theme_colors(theme) %>
                  <div
                    phx-click="select_theme"
                    phx-value-theme={theme}
                    class={"p-3 rounded-lg cursor-pointer transition-all border-2 #{if @selected_theme == theme, do: "border-primary bg-primary/10", else: "border-transparent hover:bg-base-200"}"}
                  >
                    <div class="flex items-center justify-between">
                      <span class="font-medium text-sm capitalize">{theme}</span>
                      <div class="flex gap-1">
                        <div class="w-4 h-4 rounded" style={"background-color: #{colors.primary}"}>
                        </div>
                        <div class="w-4 h-4 rounded" style={"background-color: #{colors.secondary}"}>
                        </div>
                        <div class="w-4 h-4 rounded" style={"background-color: #{colors.accent}"}>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <%!-- Right Pane: Theme Preview --%>
        <div class="flex-1 overflow-y-auto p-8">
          <div data-theme={@selected_theme} class="card bg-base-100 shadow-xl sticky top-8">
            <div class="card-body">
              <h2 class="card-title text-2xl">
                {String.replace(@selected_theme, "-", " ")
                |> String.split()
                |> Enum.map(&String.capitalize/1)
                |> Enum.join(" ")}
              </h2>
              <p class="text-base-content/70">This is a preview of how the theme looks in action.</p>

              <div class="divider"></div>

              <div class="space-y-6">
                <%!-- Button Variants --%>
                <div>
                  <p class="font-semibold mb-3">Buttons</p>
                  <div class="flex gap-2 flex-wrap">
                    <button class="btn btn-primary">Primary</button>
                    <button class="btn btn-secondary">Secondary</button>
                    <button class="btn btn-accent">Accent</button>
                    <button class="btn btn-success">Success</button>
                    <button class="btn btn-warning">Warning</button>
                    <button class="btn btn-error">Error</button>
                  </div>
                </div>

                <%!-- Form Elements --%>
                <div>
                  <p class="font-semibold mb-3">Form Elements</p>
                  <div class="space-y-3">
                    <input
                      type="text"
                      placeholder="Text input"
                      class="input input-bordered w-full"
                    />
                    <select class="select select-bordered w-full">
                      <option>Select option</option>
                      <option>Option 1</option>
                      <option>Option 2</option>
                    </select>
                  </div>
                </div>

                <%!-- Color Swatches --%>
                <div>
                  <p class="font-semibold mb-3">Color Palette</p>
                  <div class="grid grid-cols-3 gap-4">
                    <div class="flex flex-col items-center">
                      <div class="w-20 h-20 rounded bg-primary mb-2"></div>
                      <span class="text-xs font-medium">Primary</span>
                    </div>
                    <div class="flex flex-col items-center">
                      <div class="w-20 h-20 rounded bg-secondary mb-2"></div>
                      <span class="text-xs font-medium">Secondary</span>
                    </div>
                    <div class="flex flex-col items-center">
                      <div class="w-20 h-20 rounded bg-accent mb-2"></div>
                      <span class="text-xs font-medium">Accent</span>
                    </div>
                    <div class="flex flex-col items-center">
                      <div class="w-20 h-20 rounded bg-success mb-2"></div>
                      <span class="text-xs font-medium">Success</span>
                    </div>
                    <div class="flex flex-col items-center">
                      <div class="w-20 h-20 rounded bg-warning mb-2"></div>
                      <span class="text-xs font-medium">Warning</span>
                    </div>
                    <div class="flex flex-col items-center">
                      <div class="w-20 h-20 rounded bg-error mb-2"></div>
                      <span class="text-xs font-medium">Error</span>
                    </div>
                  </div>
                </div>

                <%!-- Badge Examples --%>
                <div>
                  <p class="font-semibold mb-3">Badges</p>
                  <div class="flex gap-2 flex-wrap">
                    <div class="badge badge-primary">Primary</div>
                    <div class="badge badge-secondary">Secondary</div>
                    <div class="badge badge-accent">Accent</div>
                    <div class="badge badge-success">Success</div>
                    <div class="badge badge-warning">Warning</div>
                    <div class="badge badge-error">Error</div>
                  </div>
                </div>

                <%!-- Alert Examples --%>
                <div>
                  <p class="font-semibold mb-3">Alerts</p>
                  <div class="space-y-2">
                    <div class="alert alert-info">
                      <span>Info alert example</span>
                    </div>
                    <div class="alert alert-success">
                      <span>Success alert example</span>
                    </div>
                    <div class="alert alert-warning">
                      <span>Warning alert example</span>
                    </div>
                    <div class="alert alert-error">
                      <span>Error alert example</span>
                    </div>
                  </div>
                </div>
              </div>

              <div class="card-actions justify-end mt-8">
                <button
                  class="btn btn-primary btn-lg"
                  phx-click={JS.dispatch("phx:set-theme", detail: %{theme: @selected_theme})}
                >
                  Apply Theme
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
