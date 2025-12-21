# Persistent Navbar Shell (LiveView) – Action Plan for Junior Dev

Goal: eliminate navbar flicker by keeping the navbar in a persistent **ShellLive** that does not unmount during in-app navigation. Pages render inside the shell as **child LiveViews**. Navigation uses **live_patch** (patch) instead of **navigate** (full LiveView swap).

---

## Definition of Done

- Navbar does **not** disappear when navigating between main pages (e.g., `/prompts` → `/forum`).
- Clicking navbar links results in **live_patch** updates (no full remount of the shell).
- Auth state is accurate:
  - Signed out: shows **Sign in / Sign up**
  - Signed in: shows **avatar + notifications**
- Notifications badge updates live via PubSub when unread count changes.
- Minimal coupling: each page remains its own LiveView module (no giant `case` render file).

---

## 1) Create Shell LiveView

### Files
- `lib/my_app_web/live/shell_live.ex`

### Responsibilities
- Render the persistent chrome (navbar, footer if any)
- Decide which child LiveView to render based on `@live_action`
- Keep global assigns available (e.g., `@current_user`, `@unread_notifications`)

### Implementation sketch
- In `handle_params/3`, map `@live_action` to a child page module:
  - `:prompts -> MyAppWeb.PromptsLive`
  - `:forum -> MyAppWeb.ForumLive`
  - etc.
- Render the child with `live_render/3` and **vary the id by live_action**:
  - `id: "page-#{@live_action}"` (forces the child to remount when switching pages)

---

## 2) Update Router to Route Through ShellLive

### File
- `lib/my_app_web/router.ex`

### Change
Replace direct routes like:

- `live "/forum", ForumLive, :index`
- `live "/prompts", PromptsLive, :index`

with:

- `live "/forum", ShellLive, :forum`
- `live "/prompts", ShellLive, :prompts`
- `live "/account", ShellLive, :account`

Keep auth pages (login/register) outside the shell if you want them to have a different layout.

---

## 3) Convert Navbar Links to patch, Not navigate

### File
- Navbar component (ex: `lib/my_app_web/live/navbar_component.ex`)

### Change
Use:

- `<.link patch={~p"/forum"}>Forum</.link>`

NOT:

- `<.link navigate={~p"/forum"}>Forum</.link>`

Rule:
- Use **patch** for in-shell routes.
- Use **navigate** only for leaving the shell (login pages, external links, etc.).

---

## 4) Ensure Auth Assigns Exist for the Shell and Child Pages

### Option A (preferred): `on_mount` hook shared across the live_session
- File: `lib/my_app_web/live/hooks.ex` (or existing hooks file)
- Add `on_mount(:default, ...)` that assigns:
  - `:current_user`
  - `:unread_notifications` (0 when signed out)

Attach in router:

- `live_session :app, on_mount: [{MyAppWeb.Live.Hooks, :default}] do ... end`

Acceptance:
- Any in-shell page has `@current_user` and `@unread_notifications` available.

---

## 5) Notifications Badge Updates via PubSub

### Server side
- Subscribe in `on_mount` when `current_user` exists:
  - Topic: `"notifications:#{user.id}"`

### Broadcast
Wherever notifications are created/marked-read, broadcast:

- `Phoenix.PubSub.broadcast(MyApp.PubSub, "notifications:#{user_id}", :notifications_changed)`

### Handle message
In **ShellLive** (recommended, since navbar lives there):

- `handle_info(:notifications_changed, socket)` recomputes unread count and assigns it.

Acceptance:
- With two browser tabs open, marking a notification read in one tab updates badge in the other.

---

## 6) Child LiveViews Should Not Render Their Own Navbar

### Rule
Pages like `ForumLive`, `PromptsLive` must render **only page content**, not layout chrome.

Acceptance:
- The only navbar render should be from ShellLive.

---

## 7) Smoke Tests / Manual Verification Checklist

- Start app, signed out:
  - `/prompts` shows navbar with Sign in / Sign up
  - Clicking `/forum` keeps navbar visible, no flash
- Sign in:
  - Navbar updates to avatar + bell
- Trigger notification:
  - Badge increments without refresh
- Navigate across pages:
  - Navbar stays present the whole time

---

## Pitfalls (avoid these)

- **Using navigate** between in-shell pages (will remount shell, reintroduce flicker).
- Reusing a constant `id` in `live_render` (child may not remount properly on route changes).
- Accidentally rendering page LiveViews directly from the router in addition to the shell (creates inconsistent behavior).
- Putting too much logic into ShellLive render (keep it a shell; pages belong in child modules).

---

## Deliverables

1. PR: Add `ShellLive`
2. PR: Router updated to route main pages through ShellLive
3. PR: Navbar link updates (patch vs navigate)
4. PR: Notification PubSub wiring + ShellLive handle_info
5. Short Loom or README note: “How persistent shell works; when to use patch vs navigate”
