defmodule UrielmWeb.CodeKataLive do
  use UrielmWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="code-kata-page" class="bg-base-100">
      <section id="code-kata-hero" class="px-6 pb-10 pt-10 sm:pb-14 sm:pt-14 lg:pt-16">
        <div class="mx-auto grid max-w-7xl gap-10 lg:grid-cols-[minmax(0,0.95fr)_minmax(0,1.05fr)] lg:items-center">
          <div class="grid justify-items-center text-center lg:justify-items-start lg:text-left">
            <h1 class="max-w-[11ch] text-balance text-4xl font-black leading-tight tracking-[-0.03em] text-base-content sm:text-5xl lg:text-6xl">
              Practice what matters.
            </h1>

            <p class="mt-6 max-w-2xl text-lg leading-8 text-base-content/65 sm:text-xl sm:leading-9 lg:max-w-xl">
              Build deliberate reps for Python and JavaScript. Choose a review queue, solve in
              Monaco, run tests locally, and know exactly what to practice next.
            </p>

            <div
              id="code-kata-download"
              phx-hook="CodeKataDownload"
              data-release-api="https://api.github.com/repos/tacit7/code-kata/releases/latest"
              data-release-page="https://github.com/tacit7/code-kata/releases/latest"
              data-source-page="https://github.com/tacit7/code-kata"
              data-macos-install="#code-kata-macos-install"
              class="mt-8 grid w-full max-w-xl justify-items-center gap-3 lg:justify-items-start"
            >
              <div class="flex w-full flex-col items-stretch gap-3 sm:w-auto sm:flex-row sm:items-center">
                <.link
                  id="code-kata-primary-download"
                  href="https://github.com/tacit7/code-kata/releases/latest"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-primary min-h-12 rounded-xl px-6 font-bold shadow-lg shadow-base-300/25 transition duration-200 hover:-translate-y-0.5"
                >
                  <.um_icon name="hero-arrow-down-tray" class="size-5" />
                  <span id="code-kata-download-label">Download app</span>
                </.link>

                <details
                  id="code-kata-download-fallbacks"
                  class="group text-sm"
                >
                  <summary class="flex min-h-12 cursor-pointer list-none items-center justify-center rounded-xl px-4 font-semibold text-base-content/65 transition hover:bg-base-200 hover:text-primary focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-primary">
                    All downloads
                  </summary>
                  <div
                    class="mt-3 flex flex-wrap justify-center gap-x-4 gap-y-2 font-semibold sm:justify-start"
                    aria-label="All Code Kata downloads"
                  >
                    <.link
                      href="#code-kata-macos-install"
                      class="text-base-content/60 underline-offset-4 transition hover:text-primary hover:underline"
                    >
                      macOS
                    </.link>
                    <.link
                      id="code-kata-windows-download"
                      href="https://github.com/tacit7/code-kata/releases/latest"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="text-base-content/60 underline-offset-4 transition hover:text-primary hover:underline"
                    >
                      Windows
                    </.link>
                    <.link
                      href="https://github.com/tacit7/code-kata/releases/latest"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="text-base-content/60 underline-offset-4 transition hover:text-primary hover:underline"
                    >
                      Linux
                    </.link>
                  </div>
                </details>
              </div>

              <p
                id="code-kata-download-note"
                class="max-w-md text-sm leading-6 text-base-content/65"
              >
                Detecting your computer. You can always choose any installer from the latest GitHub
                release.
              </p>
            </div>
          </div>

          <div class="grid gap-4">
            <div
              id="code-kata-practice-loop"
              class="grid gap-3 rounded-2xl bg-base-200/55 p-4 shadow-2xl shadow-base-300/20 sm:p-5"
              aria-label="Code Kata practice loop"
            >
              <div class="flex items-center justify-between gap-3">
                <p class="font-bold text-base-content">Practice loop</p>
                <span class="badge badge-primary badge-outline font-semibold">Local tests</span>
              </div>

              <div class="grid gap-2">
                <div class="flex items-center gap-3 rounded-xl bg-base-100/75 px-3 py-3 text-left">
                  <span class="grid size-8 shrink-0 place-items-center rounded-lg bg-primary text-primary-content">
                    <.um_icon name="hero-list-bullet" class="size-4" />
                  </span>
                  <div class="min-w-0">
                    <h2 class="font-bold text-base-content">Choose the queue</h2>
                    <p class="truncate text-sm text-base-content/60">
                      Due, failed, daily, speed, or level-based practice.
                    </p>
                  </div>
                </div>

                <div class="flex items-center gap-3 rounded-xl bg-base-100/75 px-3 py-3 text-left">
                  <span class="grid size-8 shrink-0 place-items-center rounded-lg bg-base-200 text-base-content">
                    <.um_icon name="hero-code-bracket" class="size-4" />
                  </span>
                  <div class="min-w-0">
                    <h2 class="font-bold text-base-content">Solve in Monaco</h2>
                    <p class="truncate text-sm text-base-content/60">
                      Run private checks without leaving the editor.
                    </p>
                  </div>
                </div>

                <div class="flex items-center gap-3 rounded-xl bg-base-100/75 px-3 py-3 text-left">
                  <span class="grid size-8 shrink-0 place-items-center rounded-lg bg-success text-success-content">
                    <.um_icon name="hero-check" class="size-4" />
                  </span>
                  <div class="min-w-0">
                    <h2 class="font-bold text-base-content">Review what decays</h2>
                    <p class="truncate text-sm text-base-content/60">
                      Keep stale categories and misses in view.
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <.link
                href="#practice-mode"
                class="inline-flex min-h-11 items-center justify-center gap-2 rounded-xl bg-base-200/65 px-4 font-semibold text-base-content/75 transition hover:bg-base-200 hover:text-base-content sm:justify-start"
              >
                See practice mode <.um_icon name="hero-arrow-right" class="size-5" />
              </.link>
              <.link
                href="#progress"
                class="inline-flex min-h-11 items-center justify-center gap-2 rounded-xl bg-base-200/65 px-4 font-semibold text-base-content/75 transition hover:bg-base-200 hover:text-base-content sm:justify-start"
              >
                Track progress <.um_icon name="hero-arrow-right" class="size-5" />
              </.link>
            </div>
          </div>
        </div>
      </section>

      <section
        id="code-kata-macos-install"
        class="border-t border-base-300/80 bg-base-200/30 px-6 py-8 sm:py-10"
      >
        <div class="mx-auto flex max-w-5xl flex-col gap-4 rounded-2xl border border-base-300 bg-base-100 p-4 sm:p-5 lg:flex-row lg:items-center lg:justify-between">
          <div class="flex items-start gap-3">
            <span class="grid size-9 shrink-0 place-items-center rounded-xl bg-base-200 text-base-content">
              <.um_icon name="hero-command-line" class="size-5" />
            </span>
            <div>
              <h2 class="font-bold text-base-content">Install on macOS from Terminal</h2>
              <p class="mt-1 max-w-2xl text-sm leading-6 text-base-content/65">
                Downloads the latest DMG, installs the app, and removes quarantine from Code Kata
                only.
              </p>
            </div>
          </div>

          <div class="grid min-w-0 gap-2 lg:w-[30rem]">
            <div class="flex items-stretch gap-2">
              <code
                id="code-kata-macos-command"
                class="block min-w-0 flex-1 overflow-x-auto rounded-xl bg-neutral px-4 py-3 font-mono text-xs leading-6 text-neutral-content sm:text-sm"
              >curl -fsSL https://urielm.dev/install/code-kata.sh | bash</code>
              <button
                id="code-kata-copy-macos-command"
                type="button"
                phx-hook="CopyToClipboard"
                data-text="curl -fsSL https://urielm.dev/install/code-kata.sh | bash"
                data-copied-label="Copied macOS install command"
                class="btn btn-ghost min-h-12 w-12 shrink-0 rounded-xl border border-base-300 bg-base-200/55 text-base-content/70 transition hover:bg-base-200 hover:text-primary"
                title="Copy install command"
                aria-label="Copy macOS install command"
              >
                <.um_icon name="hero-clipboard-document" class="size-5" />
              </button>
            </div>
            <.link
              id="code-kata-review-installer"
              href="/install/code-kata.sh"
              target="_blank"
              class="inline-flex items-center gap-1 text-sm font-semibold text-primary underline-offset-4 hover:underline"
            >
              Review installer script
              <.um_icon name="hero-arrow-top-right-on-square" class="size-4" />
            </.link>
          </div>
        </div>
      </section>

      <section
        id="code-kata-editor-preview"
        aria-label="Code Kata editor screenshot"
        class="px-6 pb-16 sm:pb-20"
      >
        <div class="mx-auto max-w-5xl">
          <.screenshot
            src={~p"/images/code-kata/hero-editor-results.png"}
            alt="Code Kata desktop editor showing a Python problem, code solution, and three passing test results."
            width="2560"
            height="1460"
            class="aspect-[2560/1460]"
          />
        </div>
      </section>

      <section id="practice-mode" class="border-t border-base-300/80 bg-base-100 px-6 py-16 sm:py-20">
        <div class="mx-auto max-w-7xl">
          <.centered_section_header
            title="One tight loop for deliberate reps."
            copy="Practice mode turns your problem library into focused queues. Pick the kind of review you need, filter the batch, then start the next set while stale and failed problems stay visible."
          />

          <div class="mx-auto max-w-6xl">
            <.screenshot
              src={~p"/images/code-kata/practice-queue.png"}
              alt="Code Kata practice queue showing spaced review modes, filters, and due problems."
              width="2880"
              height="1740"
              class="aspect-[2880/1740]"
            />
          </div>
        </div>
      </section>

      <section id="progress" class="border-t border-base-300/80 bg-base-200/35 px-6 py-16 sm:py-20">
        <div class="mx-auto max-w-7xl">
          <.centered_section_header
            title="Track your progress."
            copy="The dashboard shows what to practice next and why. Review queues surface failed or stale problems, mastery scores separate strong problems from ones that need review, and trend charts reveal which categories take the most time and where completion speed is improving."
          />

          <div class="grid gap-4">
            <.screenshot
              src={~p"/images/code-kata/progress-overview.png"}
              alt="Code Kata dashboard overview showing next practice focus and a review queue."
              width="2492"
              height="1427"
              class="aspect-[2492/1427]"
            />

            <div class="grid gap-4 lg:grid-cols-2">
              <.screenshot
                src={~p"/images/code-kata/progress-mastery.png"}
                alt="Code Kata progress dashboard showing mastery percentage, collection progress, difficulty counts, and recently improved problems."
                width="2492"
                height="1427"
                class="aspect-[2492/1427]"
              />
              <.screenshot
                src={~p"/images/code-kata/progress-trends.png"}
                alt="Code Kata progress dashboard showing time by category and average completion time trend charts."
                width="2492"
                height="1427"
                class="aspect-[2492/1427]"
              />
            </div>
          </div>
        </div>
      </section>

      <section
        id="code-kata-closing"
        class="border-t border-base-300/80 bg-base-100 px-6 py-14 sm:py-16"
      >
        <div class="mx-auto grid max-w-3xl justify-items-center gap-5 text-center">
          <h2 class="max-w-[13ch] text-balance text-2xl font-black leading-tight tracking-[-0.025em] text-base-content sm:text-4xl">
            Ready for your next rep?
          </h2>
          <p class="max-w-2xl text-base leading-7 text-base-content/65 sm:text-lg sm:leading-8">
            Download Code Kata, practice locally, and keep every review queue pointed at the work
            that still needs another pass.
          </p>
          <div class="flex w-full flex-col justify-center gap-3 sm:w-auto sm:flex-row">
            <.link
              href="https://github.com/tacit7/code-kata/releases/latest"
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-primary min-h-12 rounded-xl px-6 font-bold shadow-lg shadow-base-300/25 transition duration-200 hover:-translate-y-0.5"
            >
              <.um_icon name="hero-arrow-down-tray" class="size-5" /> Download Code Kata
            </.link>
            <.link
              href="https://github.com/tacit7/code-kata/releases/latest"
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-ghost min-h-12 rounded-xl px-6 font-semibold text-base-content/75 hover:bg-base-200 hover:text-base-content"
            >
              View latest release <.um_icon name="hero-arrow-top-right-on-square" class="size-5" />
            </.link>
          </div>
        </div>
      </section>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :copy, :string, required: true

  defp centered_section_header(assigns) do
    ~H"""
    <header class="mx-auto mb-10 grid max-w-3xl justify-items-center gap-5 text-center sm:mb-12">
      <h2 class="max-w-[13ch] text-balance text-2xl font-black leading-tight tracking-[-0.025em] text-base-content sm:text-4xl">
        {@title}
      </h2>
      <p class="max-w-3xl text-base leading-7 text-base-content/60 sm:text-lg sm:leading-8">
        {@copy}
      </p>
    </header>
    """
  end

  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :width, :string, required: true
  attr :height, :string, required: true
  attr :class, :string, default: nil

  defp screenshot(assigns) do
    ~H"""
    <figure class={["overflow-hidden rounded-2xl bg-base-300 shadow-2xl shadow-base-300/30", @class]}>
      <img
        src={@src}
        alt={@alt}
        width={@width}
        height={@height}
        loading="lazy"
        class="block h-full w-full object-cover"
      />
    </figure>
    """
  end
end
