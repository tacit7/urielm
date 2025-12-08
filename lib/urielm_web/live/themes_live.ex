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
    "catppuccin-latte"
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
                  <div
                    phx-click="select_theme"
                    phx-value-theme={theme}
                    class={"p-3 rounded-lg cursor-pointer transition-all border-2 #{if @selected_theme == theme, do: "border-primary bg-primary/10", else: "border-transparent hover:bg-base-200"}"}>
                    <div class="flex items-center justify-between">
                      <span class="font-medium text-sm capitalize"><%= String.replace(theme, "-", " ") %></span>
                      <div class="flex gap-1">
                        <div class="w-4 h-4 rounded bg-primary"></div>
                        <div class="w-4 h-4 rounded bg-secondary"></div>
                        <div class="w-4 h-4 rounded bg-accent"></div>
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
                  <div
                    phx-click="select_theme"
                    phx-value-theme={theme}
                    class={"p-3 rounded-lg cursor-pointer transition-all border-2 #{if @selected_theme == theme, do: "border-primary bg-primary/10", else: "border-transparent hover:bg-base-200"}"}>
                    <div class="flex items-center justify-between">
                      <span class="font-medium text-sm capitalize"><%= theme %></span>
                      <div class="flex gap-1">
                        <div class="w-4 h-4 rounded bg-primary"></div>
                        <div class="w-4 h-4 rounded bg-secondary"></div>
                        <div class="w-4 h-4 rounded bg-accent"></div>
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
                <%= String.replace(@selected_theme, "-", " ") |> String.split() |> Enum.map(&String.capitalize/1) |> Enum.join(" ") %>
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
