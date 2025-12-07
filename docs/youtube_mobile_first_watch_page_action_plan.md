# Action Plan; Mobile-first “YouTube-style” Lesson Watch Page (Phoenix LiveView + Tailwind + DaisyUI)

## Goal
Make the lesson page behave like a modern YouTube watch page:
- Mobile; player first, metadata under it; “Up next” and other secondary panels open via drawer/bottom sheet.
- Desktop; two-column layout; main content left, “Up next” sidebar right; persistent and scrollable.

## Non-goals
- Pixel-perfect YouTube clone; do not copy their exact styling or icons.
- Rebuilding YouTube’s entire watch ecosystem (ads, recommendations ML, etc).

## Current state (what to change)
- You are using a grid with a conditional sidebar and fixed-position toggle buttons.
- Fixed `calc(...)` positioning for toggles is fragile and not mobile-first.
- “Up next” should not be a persistent sidebar on mobile; it should be a drawer.

---

## Phase 0; Safety and baseline
1. Create a branch:
   - `git checkout -b ui/mobile-first-watch-page`
2. Ensure dev is stable on desktop before refactor:
   - Load a lesson page; confirm player renders; confirm comments render; confirm navigation works.
3. If you want phone testing; keep `dev.exs` bound to `{0,0,0,0}` in dev and confirm you can hit `http://<mac-ip>:4000`.

Acceptance criteria:
- No runtime errors; lesson page renders; LiveView websocket connects.

---

## Phase 1; Implement the YouTube layout skeleton (drawer-based)
### 1.1 Replace the outer grid with DaisyUI `drawer`
File: `lib/urielm_web/live/lesson_live.ex` (render/1 HEEx)

Actions:
- Wrap the whole page in:
  - `<div class="drawer lg:drawer-open">`
  - `<input id="upnext" type="checkbox" class="drawer-toggle" />`
  - `<div class="drawer-content"> ...main... </div>`
  - `<div class="drawer-side"> ...up next... </div>`

Acceptance criteria:
- On mobile, “Up next” is hidden until opened.
- On desktop (`lg:`), “Up next” sidebar is visible by default.

### 1.2 Move your “Course Videos” sidebar into `drawer-side`
Actions:
- Take the existing sidebar list markup and place it inside `drawer-side > aside`.
- Add a `drawer-overlay` label so tapping outside closes on mobile:
  - `<label for="upnext" class="drawer-overlay"></label>`
- Add a mobile close button inside the aside:
  - `<label for="upnext" class="btn btn-ghost btn-sm lg:hidden">Close</label>`

Acceptance criteria:
- Mobile; open and close works; overlay closes drawer.
- Desktop; sidebar is visible; no overlay blocks anything.

### 1.3 Remove fixed toggle buttons and `sidebar_open` logic for mobile
Actions:
- Delete the fixed toggle buttons that use `right-[calc(...)]`.
- Stop using `sidebar_open` for layout control; use drawer checkbox instead.
- You can keep `sidebar_open` for desktop-only toggles if you really want, but it is unnecessary for YouTube behavior.

Acceptance criteria:
- No fixed-position toggle buttons remain.
- Layout works without `sidebar_open` toggling.

---

## Phase 2; Mobile-first watch page content blocks
### 2.1 Add a mobile sticky header (YouTube-ish)
Actions:
- Add a sticky header inside `drawer-content` that is `lg:hidden`.
- Include:
  - Back link to course
  - Truncated lesson title
  - “Up next” button to open drawer; implemented as:
    - `<label for="upnext" class="btn btn-primary btn-sm">Up next</label>`

Acceptance criteria:
- Mobile header stays at top while scrolling.
- Desktop does not show the sticky header.

### 2.2 Player section; keep `aspect-video`, add optional scrim
Actions:
- Ensure player container is:
  - `class="aspect-video bg-black rounded-none lg:rounded-xl overflow-hidden"`
- Optional; add a top gradient scrim overlay to mimic YouTube’s control area:
  - `bg-gradient-to-b from-black/70 to-transparent`
- Do not block pointer events on the player:
  - scrim should have `pointer-events-none`.

Acceptance criteria:
- Player always displays properly on mobile and desktop.
- No overlay prevents tapping player controls.

### 2.3 Metadata section below player
Actions:
- Immediately under the player; render:
  - Title
  - Course row (course title, lesson number, optional playlist link)
  - Actions row; horizontally scrollable pill buttons on mobile

Suggested classes:
- Title: `text-lg lg:text-2xl font-bold leading-snug`
- Actions row: `flex gap-2 overflow-x-auto pb-1`

Acceptance criteria:
- Mobile; meta reads clean; no cramped UI; actions are tappable.

---

## Phase 3; “Up next” list should feel like YouTube
### 3.1 Make each “Up next” item a clean card row
Actions:
- Increase tap target; at least 44px high.
- Use a thumbnail left, title right; show “Now playing” state.
- On mobile drawer; use a little tighter thumbnail; on desktop sidebar; same component is fine.

Acceptance criteria:
- “Now playing” state is obvious.
- Tapping an item navigates; LiveView updates without layout breaking.

### 3.2 Make the Up next sidebar scroll independently
Actions:
- Keep a fixed header inside the aside; make the list scroll:
  - `overflow-y-auto h-[calc(100%-<headerHeight>px)]`

Acceptance criteria:
- Desktop; Up next list scrolls while the player area remains visible.
- Mobile; drawer list scrolls normally.

---

## Phase 4; Comments and description; mobile-first UX
### 4.1 Comments section defaults
Actions:
- Keep comments below metadata and description on mobile.
- Make the comment form simple:
  - textarea; 3–5 rows
  - button; `btn btn-primary btn-sm`

Acceptance criteria:
- On mobile; comment input is comfortable; no tiny text; no awkward spacing.

### 4.2 Optional; add “Tabs” like YouTube (only if you want)
If you want closer YouTube behavior:
- Use DaisyUI tabs or a simple segmented control for:
  - Up next; Comments; About
- Mobile only; desktop can remain with sidebar.
This is optional; drawer is usually enough.

Acceptance criteria:
- Tabs do not break LiveView; state is controlled predictably.

---

## Phase 5; Cleanup and correctness
### 5.1 Remove stray indentation and comment blocks in HEEx
Your current render has misaligned HTML comments; clean those for readability.

Acceptance criteria:
- Template is readable; consistent indentation; no stray comment blocks.

### 5.2 Reduce assigns and event handlers
If you remove `sidebar_open`, also remove:
- `handle_event("toggle_sidebar", ...)`
- any assigns for `:sidebar_open`

Acceptance criteria:
- No dead code; no unused events; warnings reduced.

---

## Phase 6; Testing checklist
### 6.1 Manual test cases
- Mobile Safari (iPhone); open lesson; play video; open Up next; select next lesson.
- Rotate phone; ensure player stays aspect-video.
- Scroll; sticky header behaves; no overlaps.
- Desktop; sidebar visible; selecting lessons updates content; no layout jumps.
- Keyboard; drawer can be opened and closed; focus order makes sense.

### 6.2 Performance sanity
- Ensure the Up next list uses reasonable thumbnails (`mqdefault.jpg` is fine).
- Avoid re-rendering huge lists unnecessarily; if it grows, paginate or virtualize later.

Acceptance criteria:
- No obvious jank; acceptable load times; no console spam.

---

## Deliverables
- Updated layout in: `lib/urielm_web/live/lesson_live.ex`
- Removed fixed toggle buttons; removed `sidebar_open` logic if not used.
- Mobile sticky header; Up next drawer; desktop persistent sidebar.
- Documented behavior in a short note in your UI docs (optional).

## Definition of Done
- Mobile feels like a watch page; player first; Up next is a drawer; comments are readable and usable.
- Desktop feels like YouTube watch page; two columns; Up next persistent on the right.
- No fragile fixed-position math; no broken navigation; no LiveView websocket issues.
