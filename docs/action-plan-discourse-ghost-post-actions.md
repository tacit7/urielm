# Action Plan: Implement Discourse-Style “Ghost” Post Action Buttons

Owner: Junior dev  
Goal: Add a Discourse-like post action bar with low-visual-noise (“ghost”) icon buttons and one primary action.

This is **not** “random icons slapped under posts.” It is a consistent, reusable component with clear hierarchy, accessibility, and good hover/focus behavior.

---

## 1) Requirements (what we are building)

### 1.1 UI structure
For each post (comment) card, render a bottom action bar:

Left side (primary):
- **Reply** (text button, optionally with caret for menu later)

Right side (secondary icon actions):
- **Like** (heart) with count
- **Copy link** (chain) OR “Share” (depending on our product choice)

Optional later:
- “More” (ellipsis) menu

### 1.2 Button visual design (“ghost”)
Ghost button means:
- Transparent background
- Low-contrast icon/text at rest
- On hover: increase contrast + subtle background
- On keyboard focus: visible focus ring and same hover treatment
- Icon-only buttons must have `aria-label`

### 1.3 Interaction rules
- Like toggles immediately (optimistic UI), count updates
- Copy link copies permalink to clipboard, shows toast
- Reply triggers our existing reply flow (open composer, focus input)
- All buttons have clear disabled/loading states

### 1.4 Accessibility requirements
- Icon buttons: `aria-label`
- Focus styles: `:focus-visible` is visible
- Hit targets: minimum 36px (44px preferred)
- Works with keyboard only
- No “click-only” interactions, no hidden functionality without focus equivalents

---

## 2) Implementation strategy (choose the layer)

We have two implementation paths. Pick the one that matches our post rendering:

### Path A: Phoenix LiveView-first
- Render action bar in HEEx
- Use `phx-click` and `JS` commands for behavior
- Use PubSub/broadcast only if likes must update across clients instantly

### Path B: Svelte component inside Phoenix
- Implement `<PostActions />` in Svelte
- Receive post id, liked state, counts, permalink
- Call backend endpoints (JSON) for like/copy/reply events
- Use a shared “ghost button” CSS class in Tailwind

If posts are already Svelte-driven, do Path B. Otherwise, do Path A.

---

## 3) Tasks (step-by-step)

### Task 1: Add a reusable GhostButton style (Tailwind)
Create a shared class in our CSS layer.

**File**
- `assets/css/components/buttons.css` (or whatever our convention is)

**Class spec**
- `.btn-ghost` (or `btn-ghost-icon`)
  - `bg-transparent`
  - `text-[muted]`
  - `hover:bg-[subtle] hover:text-[stronger]`
  - `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[primary]`
  - `rounded-md`
  - `h-9 w-9` for icon-only, `px-2 h-9` for text buttons

Also create:
- `.btn-ghost-text` for the Reply button
- `.btn-ghost-icon` for icon-only

**Acceptance**
- Hover and focus states are visually distinct
- Dark mode looks good
- Buttons have consistent sizing and spacing

---

### Task 2: Build the PostActions UI component
Create a component that takes a post model and renders the bar.

#### If LiveView (HEEx)
**File**
- `lib/my_app_web/components/post_actions.ex`

**API**
- `<.post_actions post={post} current_user={@current_user} />`

**Renders**
- Reply button (left)
- Like and Link icons (right)
- Counts next to icons when count > 0

#### If Svelte
**File**
- `assets/js/components/PostActions.svelte`

**Props**
- `postId: string`
- `permalink: string`
- `liked: boolean`
- `likeCount: number`
- `canReply: boolean`

**Events**
- `onReply(postId)`
- `onToggleLike(postId)`
- `onCopyLink(permalink)`

**Acceptance**
- Matches the layout, spacing, and “ghost” style from Task 1
- Buttons align consistently even when counts are absent

---

### Task 3: Wire up Reply behavior
- Reply button should focus the composer
- If we have per-post inline replies, open that composer; otherwise, route to reply form

**LiveView**
- Use `phx-click={JS.push("reply", value: %{post_id: post.id})}`  
- In `handle_event("reply", ...)`, set assigns and `JS.focus(...)`

**Svelte**
- Emit `reply` event to parent; parent opens composer and focuses it

**Acceptance**
- Clicking Reply always results in focused input within 200ms
- Keyboard activation works (Enter/Space)

---

### Task 4: Wire up Like toggle (optimistic)
Backend:
- Add endpoint or LiveView event to toggle like
- Return updated count and liked state

Frontend:
- Update UI optimistically
- Reconcile with server response

**Edge cases**
- Not logged in: show login modal or toast
- Duplicate requests: disable button briefly during request

**Acceptance**
- Like toggles immediately
- Count updates correctly
- No double increments on rapid clicking

---

### Task 5: Copy permalink + toast
- Copy permalink to clipboard
- Show “Link copied” toast

**Implementation**
- Use `navigator.clipboard.writeText(permalink)` where available
- Fallback: hidden input selection if needed

**Acceptance**
- Works in modern browsers
- Toast appears and auto-dismisses
- No page navigation happens

---

### Task 6: Add hover-only visual polish (optional but recommended)
Discourse makes these controls feel “quiet” until you interact.

Implement:
- Action bar icons slightly muted by default
- On post hover: actions increase opacity slightly
- On action hover: highlight that action

**Acceptance**
- Bar stays discoverable; it is not invisible
- Keyboard focus still reveals controls without hover

---

## 4) Data and API needs

### Like endpoint/event
Choose one:

**LiveView event**
- `handle_event("toggle_like", %{post_id: id}, socket)`

**JSON endpoint**
- `POST /api/posts/:id/like` -> `{liked, like_count}`

### Permalink strategy
- Decide a canonical post URL format (ex: `/t/:topic_slug/:topic_id/:post_number`)
- Post actions should use that permalink consistently

---

## 5) Styling rules (do not wing it)

- Use a single icon set consistently
- Icon size: 18–20px
- Hit area: 36px min
- Spacing:
  - Left group and right group separated with `justify-between`
  - Right icons with `gap-2` or `gap-3`
- Counts:
  - Render count text with muted color
  - Keep count aligned baseline with icon

---

## 6) Testing checklist

### Unit
- Like toggle returns correct state transitions
- Permissions: anonymous cannot like, or gets a predictable response

### Integration/UI
- Keyboard navigation: tab to each button, focus ring visible
- Screen reader labels read correctly
- Copy link works and shows toast

### Regression checks
- Action bar doesn’t reflow post card weirdly
- No duplicate IDs
- No LiveView reconnect loop triggers from these actions

---

## 7) Definition of Done

- Post action bar renders on every post
- Reply works and focuses composer
- Like toggles and count updates, no double increments
- Copy link works and shows toast
- Ghost style is consistent across all buttons and responsive
- Accessible: aria-labels, focus-visible rings, usable hit targets
- Reviewed in both desktop and mobile widths

---

## 8) Deliverables (PR contents)

- New button styles (ghost variants)
- PostActions component (HEEx or Svelte)
- Backend wiring for like/reply
- Copy link + toast
- Minimal tests for like behavior + UI smoke checks
- Screenshots or short video demo in PR description
