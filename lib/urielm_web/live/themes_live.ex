defmodule UrielmWeb.ThemesLive do
  use UrielmWeb, :live_view

  @daisyui_themes []
  @custom_themes ["tokyo-day", "tokyo-night"]

  @all_themes @daisyui_themes ++ @custom_themes

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Themes")
     |> assign(:daisyui_themes, @daisyui_themes)
     |> assign(:custom_themes, @custom_themes)
     |> assign(:all_themes, @all_themes)
     |> assign(:selected_theme, "tokyo-night")}
  end

  @impl true
  def handle_event("select_theme", %{"theme" => theme}, socket) when theme in @all_themes do
    {:noreply, assign(socket, :selected_theme, theme)}
  end

  def handle_event("select_theme", _params, socket), do: {:noreply, socket}

  @theme_colors %{
    "tokyo-night" => %{primary: "#7aa2f7", secondary: "#6b82bd", accent: "#73daca"},
    "tokyo-day" => %{primary: "#2e7de9", secondary: "#304b80", accent: "#007c79"},
    "midnight" => %{primary: "#7aa2f7", secondary: "#bb9af7", accent: "#73daca"},
    "catppuccin-mocha" => %{primary: "#89b4fa", secondary: "#cba6f7", accent: "#94e2d5"},
    "catppuccin-latte" => %{primary: "#1e66f5", secondary: "#ea76cb", accent: "#179299"},
    "dracula-custom" => %{primary: "#ff79c6", secondary: "#8be9fd", accent: "#50fa7b"},
    "github-light" => %{primary: "#0969da", secondary: "#6e40aa", accent: "#1298f3"},
    "github-dark" => %{primary: "#58a6ff", secondary: "#bc8ef9", accent: "#79c0ff"},
    "light" => %{primary: "#0d47a1", secondary: "#7c3aed", accent: "#06b6d4"},
    "dark" => %{primary: "#60a5fa", secondary: "#a78bfa", accent: "#22d3ee"},
    "cupcake" => %{primary: "#f97316", secondary: "#f472b6", accent: "#06b6d4"},
    "bumblebee" => %{primary: "#fbbf24", secondary: "#60a5fa", accent: "#34d399"},
    "emerald" => %{primary: "#10b981", secondary: "#8b5cf6", accent: "#06b6d4"},
    "corporate" => %{primary: "#194e8c", secondary: "#7c3aed", accent: "#06b6d4"},
    "synthwave" => %{primary: "#ff006e", secondary: "#8338ec", accent: "#ffbe0b"},
    "retro" => %{primary: "#fbbf24", secondary: "#f87171", accent: "#60a5fa"},
    "cyberpunk" => %{primary: "#ffbe0b", secondary: "#fb5607", accent: "#00f5ff"},
    "valentine" => %{primary: "#eb6f92", secondary: "#f1a7d8", accent: "#f8ad9d"},
    "halloween" => %{primary: "#ff7a00", secondary: "#7c3aed", accent: "#a3e635"},
    "garden" => %{primary: "#15803d", secondary: "#ec4899", accent: "#06b6d4"},
    "forest" => %{primary: "#166534", secondary: "#7c3aed", accent: "#22d3ee"},
    "aqua" => %{primary: "#0891b2", secondary: "#06b6d4", accent: "#22d3ee"},
    "lofi" => %{primary: "#0f172a", secondary: "#64748b", accent: "#94a3b8"},
    "pastel" => %{primary: "#d946ef", secondary: "#f472b6", accent: "#fbbf24"},
    "fantasy" => %{primary: "#7c3aed", secondary: "#f472b6", accent: "#fbbf24"},
    "wireframe" => %{primary: "#000000", secondary: "#666666", accent: "#999999"},
    "black" => %{primary: "#1f2937", secondary: "#374151", accent: "#4b5563"},
    "luxury" => %{primary: "#5a3a7a", secondary: "#8b5cf6", accent: "#fbbf24"},
    "dracula" => %{primary: "#ff79c6", secondary: "#8be9fd", accent: "#50fa7b"},
    "cmyk" => %{primary: "#00ffff", secondary: "#ff00ff", accent: "#ffff00"},
    "autumn" => %{primary: "#c2410c", secondary: "#dc2626", accent: "#f97316"},
    "business" => %{primary: "#1e40af", secondary: "#0284c7", accent: "#06b6d4"},
    "acid" => %{primary: "#ffff00", secondary: "#00ffff", accent: "#ff00ff"},
    "lemonade" => %{primary: "#84cc16", secondary: "#06b6d4", accent: "#fbbf24"},
    "night" => %{primary: "#38bdf8", secondary: "#818cf8", accent: "#c084fc"},
    "coffee" => %{primary: "#6d28d9", secondary: "#7c3aed", accent: "#a78bfa"},
    "winter" => %{primary: "#0ea5e9", secondary: "#06b6d4", accent: "#22d3ee"}
  }

  defp theme_colors(theme) do
    Map.get(@theme_colors, theme, %{primary: "#60a5fa", secondary: "#a78bfa", accent: "#22d3ee"})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="themes-page" class="ui-page-shell">
      <header id="themes-page-header" class="ui-page-header ui-page-heading">
        <h1 class="ui-section-title">Appearance</h1>
        <p class="ui-section-copy">
          Choose a color mode and preview the shared interface components before applying it.
        </p>
      </header>

      <div class="grid items-start gap-6 lg:grid-cols-[18rem_minmax(0,1fr)] lg:gap-8">
        <aside aria-labelledby="theme-options-label">
          <fieldset id="theme-options">
            <legend id="theme-options-label" class="ui-eyebrow mb-3">Color mode</legend>
            <div class="grid grid-cols-1 gap-3 min-[360px]:grid-cols-2 lg:grid-cols-1">
              <.theme_option
                :for={theme <- @custom_themes}
                theme={theme}
                selected={@selected_theme == theme}
              />
            </div>
          </fieldset>

          <fieldset :if={@daisyui_themes != []} id="additional-theme-options" class="mt-8">
            <legend class="ui-eyebrow mb-3">Additional themes</legend>
            <div class="grid grid-cols-1 gap-3 min-[360px]:grid-cols-2 lg:grid-cols-1">
              <.theme_option
                :for={theme <- @daisyui_themes}
                theme={theme}
                selected={@selected_theme == theme}
              />
            </div>
          </fieldset>
        </aside>

        <section
          id="theme-preview"
          data-theme={@selected_theme}
          class="ui-card h-auto bg-base-100 text-base-content"
          aria-labelledby="theme-preview-title"
        >
          <header class="flex flex-col gap-5 border-b border-base-300 px-5 py-5 sm:flex-row sm:items-center sm:justify-between sm:px-7">
            <div>
              <p class="ui-eyebrow">Preview</p>
              <h2 id="theme-preview-title" class="mt-1 text-2xl font-black text-base-content">
                {theme_name(@selected_theme)}
              </h2>
            </div>
            <button
              id="apply-theme-button"
              type="button"
              class="btn btn-primary w-full gap-2 sm:w-auto"
              phx-click={JS.dispatch("phx:set-theme", detail: %{theme: @selected_theme})}
            >
              <.um_icon name="hero-check" class="size-4" /> Apply theme
            </button>
          </header>

          <div class="grid gap-0 xl:grid-cols-2">
            <div class="space-y-8 border-b border-base-300 p-5 sm:p-7 xl:border-b-0 xl:border-r">
              <.preview_group title="Buttons">
                <div class="flex flex-wrap gap-2">
                  <button type="button" class="btn btn-primary btn-sm">Primary</button>
                  <button type="button" class="btn btn-secondary btn-sm">Secondary</button>
                  <button type="button" class="btn btn-accent btn-sm">Accent</button>
                  <button type="button" class="btn btn-ghost btn-sm">Ghost</button>
                </div>
              </.preview_group>

              <.preview_group title="Form controls">
                <div class="space-y-2">
                  <.input
                    id="theme-preview-input"
                    name="theme_preview_input"
                    type="text"
                    value=""
                    placeholder="Text input"
                  />
                  <.input
                    id="theme-preview-select"
                    name="theme_preview_select"
                    type="select"
                    value="option-one"
                    options={[{"Option one", "option-one"}, {"Option two", "option-two"}]}
                  />
                </div>
              </.preview_group>

              <.preview_group title="Badges">
                <div class="flex flex-wrap gap-2">
                  <span class="badge badge-primary">Primary</span>
                  <span class="badge badge-secondary">Secondary</span>
                  <span class="badge badge-accent">Accent</span>
                  <span class="badge badge-success">Success</span>
                  <span class="badge badge-warning">Warning</span>
                  <span class="badge badge-error">Error</span>
                </div>
              </.preview_group>
            </div>

            <div class="space-y-8 p-5 sm:p-7">
              <.preview_group title="Color palette">
                <div class="grid grid-cols-3 gap-3 sm:grid-cols-6 xl:grid-cols-3">
                  <.color_swatch label="Primary" class="bg-primary" />
                  <.color_swatch label="Secondary" class="bg-secondary" />
                  <.color_swatch label="Accent" class="bg-accent" />
                  <.color_swatch label="Success" class="bg-success" />
                  <.color_swatch label="Warning" class="bg-warning" />
                  <.color_swatch label="Error" class="bg-error" />
                </div>
              </.preview_group>

              <.preview_group title="Alerts">
                <div class="space-y-2">
                  <div class="alert alert-info py-3"><span>Information message</span></div>
                  <div class="alert alert-success py-3"><span>Success message</span></div>
                  <div class="alert alert-warning py-3"><span>Warning message</span></div>
                  <div class="alert alert-error py-3"><span>Error message</span></div>
                </div>
              </.preview_group>
            </div>
          </div>
        </section>
      </div>
    </div>
    """
  end

  attr :theme, :string, required: true
  attr :selected, :boolean, required: true

  defp theme_option(assigns) do
    assigns =
      assigns
      |> assign(:colors, theme_colors(assigns.theme))
      |> assign(:label, theme_name(assigns.theme))

    ~H"""
    <button
      id={"theme-option-#{@theme}"}
      type="button"
      phx-click="select_theme"
      phx-value-theme={@theme}
      aria-pressed={to_string(@selected)}
      class={[
        "btn h-auto min-h-16 justify-between rounded-xl border px-3 py-3 text-left normal-case sm:px-4",
        if(@selected,
          do: "border-primary bg-primary/10 text-base-content hover:bg-primary/15",
          else:
            "border-base-300 bg-base-100 text-base-content hover:border-primary/40 hover:bg-base-200"
        )
      ]}
    >
      <span class="min-w-0">
        <span class="block truncate text-xs font-bold sm:text-sm">{@label}</span>
        <span class="mt-0.5 block text-xs font-normal text-base-content/55">
          {if @theme == "tokyo-night", do: "Dark", else: "Light"}
        </span>
      </span>
      <span class="flex shrink-0 gap-0.5 sm:gap-1" aria-hidden="true">
        <span class="size-3.5 rounded sm:size-4" style={"background-color: #{@colors.primary}"}>
        </span>
        <span class="size-3.5 rounded sm:size-4" style={"background-color: #{@colors.secondary}"}>
        </span>
        <span class="size-3.5 rounded sm:size-4" style={"background-color: #{@colors.accent}"}></span>
      </span>
    </button>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp preview_group(assigns) do
    ~H"""
    <section>
      <h3 class="mb-3 text-sm font-black text-base-content">{@title}</h3>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :label, :string, required: true
  attr :class, :string, required: true

  defp color_swatch(assigns) do
    ~H"""
    <div class="min-w-0">
      <div class={["aspect-square w-full rounded-lg", @class]}></div>
      <span class="mt-1.5 block truncate text-center text-xs font-medium">{@label}</span>
    </div>
    """
  end

  defp theme_name(theme) do
    theme
    |> String.replace("-", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
