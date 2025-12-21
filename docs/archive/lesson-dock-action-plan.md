# Lesson Dock – Implementation Action Plan (Phoenix LiveView + daisyUI)

Goal: Add a bottom **dock** on mobile for lesson-level navigation, with tabs like:
`Home | Notes | Resources | Timestamps`

Desktop keeps a full stacked layout; the dock is mainly for mobile.

---

## 0. Assumptions

- Phoenix 1.7+ with LiveView.
- Current lesson page is `UrielmWeb.LessonLive`.
- daisyUI is already configured.
- Existing layout:
  - Video at top (YouTube Svelte component)
  - Lesson metadata and description
  - Comments
  - Sidebar with course lessons (`@lessons`).

---

## 1. Add dock state in LiveView

### 1.1 Default dock tab in `mount/3`

In `UrielmWeb.LessonLive.mount/3`, after existing assigns, add:

```elixir
|> assign(:dock_tab, "home")
```

So the pipeline ends like:

```elixir
{:ok,
 socket
 |> assign(:course, course)
 |> assign(:lesson, lesson)
 |> assign(:lessons, lessons)
 |> assign(:comment_changeset, changeset)
 |> assign(:comment_form, Phoenix.Component.to_form(changeset, as: :comment))
 |> assign(:current_page, "courses")
 |> assign(:sidebar_open, true)
 |> assign(:page_title, lesson.title)
 |> assign(:dock_tab, "home")
}
```

### 1.2 Handle dock tab switching

Add to `UrielmWeb.LessonLive`:

```elixir
@impl true
def handle_event("set_dock_tab", %{"tab" => tab}, socket) do
  {:noreply, assign(socket, :dock_tab, tab)}
end
```

This is the only new event you need for the dock itself.

---

## 2. Add the daisyUI dock (mobile bottom bar)

Place this **near the bottom** of the `render/1` template, just before the outer `</div>` (main container).

```heex
<!-- Mobile lesson dock -->
<div class="dock dock-bottom z-30 lg:hidden">
  <div class="dock-item">
    <button
      type="button"
      phx-click="set_dock_tab"
      phx-value-tab="home"
      class={[
        "btn btn-ghost btn-sm flex flex-col gap-0 text-[11px]",
        if(@dock_tab == "home", do: "btn-active text-primary", else: "text-base-content/70")
      ]}
    >
      <svg class="w-5 h-5 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M3 12l9-9 9 9M4 10v10h16V10" />
      </svg>
      <span>Home</span>
    </button>
  </div>

  <div class="dock-item">
    <button
      type="button"
      phx-click="set_dock_tab"
      phx-value-tab="notes"
      class={[
        "btn btn-ghost btn-sm flex flex-col gap-0 text-[11px]",
        if(@dock_tab == "notes", do: "btn-active text-primary", else: "text-base-content/70")
      ]}
    >
      <svg class="w-5 h-5 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M9 4h10v16H5V4h4z" />
      </svg>
      <span>Notes</span>
    </button>
  </div>

  <div class="dock-item">
    <button
      type="button"
      phx-click="set_dock_tab"
      phx-value-tab="resources"
      class={[
        "btn btn-ghost btn-sm flex flex-col gap-0 text-[11px]",
        if(@dock_tab == "resources", do: "btn-active text-primary", else: "text-base-content/70")
      ]}
    >
      <svg class="w-5 h-5 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M12 6l7 6-7 6-7-6 7-6z" />
      </svg>
      <span>Resources</span>
    </button>
  </div>

  <div class="dock-item">
    <button
      type="button"
      phx-click="set_dock_tab"
      phx-value-tab="timestamps"
      class={[
        "btn btn-ghost btn-sm flex flex-col gap-0 text-[11px]",
        if(@dock_tab == "timestamps", do: "btn-active text-primary", else: "text-base-content/70")
      ]}
    >
      <svg class="w-5 h-5 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M12 6v6l3 3M4 12a8 8 0 1016 0 8 8 0 10-16 0z" />
      </svg>
      <span>Times</span>
    </button>
  </div>
</div>
```

Notes:

- `dock dock-bottom` uses daisyUI dock.
- `lg:hidden` makes this **mobile-only**.
- Active tab styling is controlled by comparing `@dock_tab`.

---

## 3. Make main content respond to dock tab

Under the video and title, wrap the existing sections into tab-specific containers.  
Goal: on mobile, only the active tab’s section shows; on desktop (`lg:`) everything is visible.

### 3.1 Existing title (keep always visible)

```heex
<h1 class="text-2xl font-bold text-base-content mb-3">
  {@lesson.title}
</h1>
```

### 3.2 Wrap sections by tab

Replace current description / course info block with something like:

```heex
<div class="space-y-4">
  <!-- HOME TAB -->
  <div class={["space-y-4", if(@dock_tab != "home", do: "hidden lg:block")]}>
    <div class="flex items-start justify-between gap-4 pb-4 border-b border-base-300 mb-4">
      <!-- existing course/channel info -->
      ... your course header + playlist button ...
    </div>

    <div :if={@lesson.body} class="bg-base-200 rounded-xl p-4">
      <p class="text-sm text-base-content/80 whitespace-pre-wrap">
        {@lesson.body}
      </p>
    </div>

    <div :if={@course.description} class="mt-4 bg-base-200 rounded-xl p-4">
      <h3 class="font-semibold text-base-content mb-2">About this course</h3>
      <p class="text-sm text-base-content/70">
        {@course.description}
      </p>
    </div>
  </div>

  <!-- NOTES TAB -->
  <div class={["space-y-3", if(@dock_tab != "notes", do: "hidden lg:block")]}>
    <h3 class="font-semibold text-base-content">Lesson notes</h3>
    <p class="text-sm text-base-content/80 whitespace-pre-wrap">
      {@lesson.body || "No notes yet."}
    </p>
  </div>

  <!-- RESOURCES TAB -->
  <div class={["space-y-3", if(@dock_tab != "resources", do: "hidden lg:block")]}>
    <h3 class="font-semibold text-base-content">Resources</h3>
    <p class="text-sm text-base-content/70">
      Coming soon: links, downloads, repo, etc.
    </p>
  </div>

  <!-- TIMESTAMPS TAB -->
  <div class={["space-y-3", if(@dock_tab != "timestamps", do: "hidden lg:block")]}>
    <h3 class="font-semibold text-base-content">Timestamps</h3>
    <ul class="text-sm text-primary space-y-1">
      <!-- placeholder entries, to be wired later to YouTube seek -->
      <li>
        <button type="button" class="link">00:00 Intro</button>
      </li>
      <li>
        <button type="button" class="link">01:00 Pattern matching</button>
      </li>
    </ul>
  </div>

  <!-- COMMENTS (always shown for now) -->
  <section class="mt-4 space-y-4">
    <!-- keep your existing comments section here -->
    ... existing comments list + form ...
  </section>
</div>
```

Behavior:

- Mobile (`< lg`):
  - Only the block whose tab matches `@dock_tab` is visible (`hidden` on non-active tabs).
- Desktop (`>= lg`):
  - `lg:block` forces the sections to show regardless of `@dock_tab`, so you get a full page view.

---

## 4. Optional: Hook timestamps into YouTube seek

Once the dock is working, you can connect the `timestamps` tab entries to your YouTube Svelte component.

### 4.1 LiveView: add `:seek_to` assign and event

In `mount/3`:

```elixir
|> assign(:seek_to, nil)
```

Add handler:

```elixir
def handle_event("seek_to", %{"seconds" => seconds}, socket) do
  {:noreply, assign(socket, :seek_to, String.to_integer(seconds))}
end
```

### 4.2 Pass `seekToSeconds` into Svelte YouTube component

In the video player section:

```heex
<div class="aspect-video bg-base-content rounded-xl overflow-hidden mb-4">
  <.svelte
    name="YouTubePlayer"
    props={%{
      videoId: @lesson.youtube_video_id,
      controls: true,
      seekToSeconds: @seek_to
    }}
    socket={@socket}
    class="w-full h-full"
  />
</div>
```

Ensure the Svelte component already has `export let seekToSeconds` and reacts to it.

### 4.3 Wire timestamp buttons

Replace placeholder timestamp buttons with:

```heex
<li>
  <button
    type="button"
    class="link"
    phx-click="seek_to"
    phx-value-seconds="0"
  >
    00:00 Intro
  </button>
</li>
<li>
  <button
    type="button"
    class="link"
    phx-click="seek_to"
    phx-value-seconds="60"
  >
    01:00 Pattern matching
  </button>
</li>
```

Now the dock’s “Timestamps” tab becomes a real controller for the video position.

---

## 5. Execution Checklist

1. **State**: add `:dock_tab` assign + `handle_event("set_dock_tab", ...)`.
2. **Dock UI**: add daisyUI `dock dock-bottom` block (mobile-only via `lg:hidden`).
3. **Content switching**: wrap sections with tab-specific visibility classes using `@dock_tab`.
4. **Sanity test (UI)**:
   - On mobile viewport: dock appears, tapping tab changes visible section under the video.
   - On desktop: dock hidden, all sections visible as normal stacked content.
5. **Optional**: implement YouTube seeking via `seek_to` assign and timestamp tab buttons.

Keep it minimal first; timestamps + resources can start as placeholders and evolve later.
