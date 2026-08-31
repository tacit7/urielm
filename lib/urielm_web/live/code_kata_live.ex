defmodule UrielmWeb.CodeKataLive do
  use UrielmWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Code Kata")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="code-kata-page" class="bg-base-100">
      <section id="code-kata-hero" class="px-6 pb-20 pt-10 sm:pb-10 sm:pt-14 lg:pt-16">
        <div class="mx-auto grid max-w-4xl justify-items-center text-center">
          <h1 class="max-w-[11ch] text-balance text-4xl font-black leading-tight tracking-[-0.03em] text-base-content sm:text-5xl lg:text-6xl">
            Practice what matters.
          </h1>

          <p class="mt-6 max-w-2xl text-lg leading-8 text-base-content/65 sm:text-xl sm:leading-9">
            Build deliberate reps for Python and JavaScript. Choose a review queue, solve in
            Monaco, run tests locally, and know exactly what to practice next.
          </p>

          <div
            id="code-kata-download"
            phx-hook="CodeKataDownload"
            data-release-api="https://api.github.com/repos/tacit7/code-kata/releases/latest"
            data-release-page="https://github.com/tacit7/code-kata/releases/latest"
            data-source-page="https://github.com/tacit7/code-kata"
            class="mt-8 grid w-full max-w-xl justify-items-center gap-3"
          >
            <.link
              id="code-kata-primary-download"
              href="https://github.com/tacit7/code-kata/releases/latest"
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-primary min-h-12 w-full rounded-xl px-6 font-bold shadow-lg shadow-base-300/25 transition duration-200 hover:-translate-y-0.5 sm:w-auto"
            >
              <.um_icon name="hero-arrow-down-tray" class="size-5" />
              <span id="code-kata-download-label">Download app</span>
            </.link>

            <p
              id="code-kata-download-note"
              class="max-w-md text-sm leading-6 text-base-content/65"
            >
              Detecting your computer. You can always choose any installer from the latest GitHub
              release.
            </p>

            <div
              id="code-kata-release-panel"
              class="grid w-full gap-3 rounded-2xl bg-base-200/55 p-4 text-left shadow-lg shadow-base-300/20 sm:max-w-lg"
              aria-live="polite"
            >
              <div class="flex flex-col gap-1 min-[360px]:flex-row min-[360px]:items-baseline min-[360px]:justify-between">
                <p id="code-kata-release-title" class="font-bold text-base-content">
                  Latest release
                </p>
                <p
                  id="code-kata-release-updated"
                  class="text-sm font-medium text-base-content/60"
                >
                  Checking GitHub
                </p>
              </div>
              <dl class="grid grid-cols-3 gap-3 text-sm">
                <div>
                  <dt class="font-semibold text-base-content/55">Version</dt>
                  <dd id="code-kata-release-version" class="mt-1 font-bold text-base-content">
                    Latest
                  </dd>
                </div>
                <div>
                  <dt class="font-semibold text-base-content/55">Platform</dt>
                  <dd id="code-kata-release-platform" class="mt-1 font-bold text-base-content">
                    Detecting
                  </dd>
                </div>
                <div>
                  <dt class="font-semibold text-base-content/55">Installer</dt>
                  <dd id="code-kata-release-asset" class="mt-1 font-bold text-base-content">
                    GitHub release
                  </dd>
                </div>
              </dl>
              <div class="flex flex-wrap gap-x-4 gap-y-2 text-sm font-semibold">
                <.link
                  id="code-kata-release-notes"
                  href="https://github.com/tacit7/code-kata/releases/latest"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-primary underline-offset-4 hover:underline"
                >
                  Release notes
                </.link>
                <.link
                  id="code-kata-source-code"
                  href="https://github.com/tacit7/code-kata"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-base-content/65 underline-offset-4 transition hover:text-primary hover:underline"
                >
                  Source code
                </.link>
              </div>
            </div>

            <details
              id="code-kata-download-fallbacks"
              class="group text-sm"
            >
              <summary class="cursor-pointer list-none font-semibold text-base-content/60 underline-offset-4 transition hover:text-primary hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-primary">
                All downloads
              </summary>
              <div
                class="mt-3 flex flex-wrap justify-center gap-x-4 gap-y-2 font-semibold"
                aria-label="All Code Kata downloads"
              >
                <.link
                  href="https://github.com/tacit7/code-kata/releases/latest"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-base-content/60 underline-offset-4 transition hover:text-primary hover:underline"
                >
                  macOS
                </.link>
                <.link
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

          <div class="mt-5 flex flex-wrap justify-center gap-x-6 gap-y-3">
            <.link
              href="#practice-mode"
              class="inline-flex min-h-10 items-center gap-2 rounded-xl px-3 font-semibold text-base-content/70 transition hover:bg-base-200 hover:text-base-content"
            >
              See practice mode <.um_icon name="hero-arrow-right" class="size-5" />
            </.link>
            <.link
              href="#progress"
              class="inline-flex min-h-10 items-center gap-2 rounded-xl px-3 font-semibold text-base-content/70 transition hover:bg-base-200 hover:text-base-content"
            >
              Track progress <.um_icon name="hero-arrow-right" class="size-5" />
            </.link>
          </div>
        </div>
      </section>

      <section
        id="code-kata-editor-preview"
        aria-label="Code Kata editor screenshot"
        class="px-6 pb-16 sm:pb-20"
      >
        <div
          id="code-kata-practice-loop"
          class="mx-auto mb-10 grid max-w-5xl gap-px overflow-hidden rounded-2xl bg-base-300/80 sm:mb-12 lg:grid-cols-3"
          aria-label="Code Kata practice loop"
        >
          <div class="grid gap-4 bg-base-200/65 p-4 text-left sm:p-5">
            <div class="flex flex-wrap gap-2">
              <span class="badge badge-primary badge-outline font-semibold">Spaced review</span>
              <span class="badge badge-ghost font-semibold text-base-content/65">Weak spots</span>
            </div>
            <div>
              <h2 class="text-lg font-black tracking-[-0.02em] text-base-content">
                Choose the queue
              </h2>
              <p class="mt-2 text-sm leading-6 text-base-content/65">
                Start with due, failed, daily, speed, or level-based practice instead of scanning
                every problem.
              </p>
            </div>
          </div>

          <div class="grid gap-4 bg-base-200/65 p-4 text-left sm:p-5">
            <div class="rounded-xl bg-base-100/80 p-3 font-mono text-xs leading-5 text-base-content/70">
              <p><span class="text-primary">def</span> solve(nums):</p>
              <p class="pl-4">return window(nums)</p>
            </div>
            <div>
              <h2 class="text-lg font-black tracking-[-0.02em] text-base-content">
                Solve and run tests
              </h2>
              <p class="mt-2 text-sm leading-6 text-base-content/65">
                Work in Monaco and run the checks locally, so the feedback loop stays fast and
                private.
              </p>
            </div>
          </div>

          <div class="grid gap-4 bg-base-200/65 p-4 text-left sm:p-5">
            <div class="grid gap-2 text-sm">
              <div class="flex items-center justify-between rounded-xl bg-base-100/80 px-3 py-2">
                <span class="font-semibold text-base-content/75">Sliding Window</span>
                <span class="badge badge-success badge-sm font-bold">passed</span>
              </div>
              <div class="flex items-center justify-between rounded-xl bg-base-100/80 px-3 py-2">
                <span class="font-semibold text-base-content/75">Dynamic Programming</span>
                <span class="badge badge-warning badge-sm font-bold">review</span>
              </div>
            </div>
            <div>
              <h2 class="text-lg font-black tracking-[-0.02em] text-base-content">
                Review what decays
              </h2>
              <p class="mt-2 text-sm leading-6 text-base-content/65">
                Keep stale categories and recently missed problems visible before they fall out of
                memory.
              </p>
            </div>
          </div>
        </div>

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
