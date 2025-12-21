# PR 1 — Fix Routing/Auth Invariants

This PR tightens up **route-level access control** and removes a few **foot-guns** that currently make authentication behavior inconsistent and brittle.

The goal is not to “redesign auth”, but to make the existing behavior **predictable**, **testable**, and **hard to accidentally bypass**.

---

## Why this PR exists (context for juniors)

Right now, access control is split across:

- Router `live_session` definitions (some routes are “authenticated”)
- `UrielmWeb.UserAuth` `on_mount` hooks (loads user / redirects)
- Individual LiveViews (some do `if current_user && current_user.is_admin do ... else redirect`)

That mix creates two concrete problems:

1. **Duplicate `/settings` route definition** means the route can resolve through the wrong `live_session`, and `SettingsLive` assumes a user exists.
2. **Admin enforcement is inconsistent** (some pages redirect in `mount/3`, but nothing prevents a junior dev from adding a new admin route without the guard).

We want the router to be the “front door” for access control and keep LiveViews simpler.

---

## Goals

- Ensure `/settings` is only reachable via the authenticated LiveView session.
- Make “admin pages require admin” a router-level invariant (via `live_session` + `on_mount`), not a per-LiveView convention.
- Remove duplicated `current_user` loading logic in `UrielmWeb.UserAuth`.
- Add/adjust tests so access rules are enforced and regressions are caught quickly.

## Non-goals

- No UI redesign.
- No changes to OAuth/email signup flows (unless required for redirects to work).
- No big refactor of all auth plumbing (controllers/plugs/etc).

---

## Files you will likely touch

- `lib/urielm_web/router.ex`
- `lib/urielm_web/user_auth.ex`
- `lib/urielm_web/live/settings_live.ex`
- `lib/urielm_web/live/admin/moderation_queue_live.ex`
- `lib/urielm_web/live/admin/trust_level_settings_live.ex`
- `test/urielm_web/live/moderation_queue_live_test.exs`
- Add: `test/urielm_web/live/settings_live_test.exs`

---

## Step-by-step implementation plan

### Step 0 — Understand how LiveView auth works in this repo

Important details in `lib/urielm_web.ex`:

- All LiveViews automatically run:
  - `on_mount {UrielmWeb.UserAuth, :mount_current_user}`

And then, the router can add additional `on_mount` hooks via `live_session`, e.g.:

- `live_session :authenticated, on_mount: [{UrielmWeb.UserAuth, :ensure_authenticated}]`

That means a route can have **both**:

- “Load `current_user`” (always)
- “Require auth” (only on authenticated session)
- “Require admin” (we will add)

Keep that mental model while editing routes.

---

### Step 1 — Fix the duplicate `/settings` route

In `lib/urielm_web/router.ex`:

1. Find the `live "/settings", SettingsLive` entry inside `live_session :default`.
2. Remove it from `:default`.
3. Keep `/settings` only inside `live_session :authenticated`.

Why: `/settings` should never be reachable without auth. If it is, `SettingsLive.mount/3` will receive `current_user = nil` and can crash (or behave unpredictably).

Acceptance check:

- Visiting `/settings` when logged out should redirect (not crash).
- Visiting `/settings` when logged in should render Settings normally.

---

### Step 2 — Add a defensive guard in `SettingsLive`

Even if routes are correct, we still guard the LiveView to prevent future mistakes.

In `lib/urielm_web/live/settings_live.ex`:

1. At the top of `mount/3`, check `socket.assigns.current_user`.
2. If `nil`, return `{:ok, redirect(socket, to: ~p"/signup")}` (or `/` if that’s the preferred UX — choose one and keep it consistent).
3. Only build forms when `user` exists.

Why: “Defense in depth”. A future route mistake should not become a production crash.

Tip:

- Don’t build changesets/forms if `user` is nil.
- Keep the code path simple:
  - `nil` → redirect
  - user → current logic

---

### Step 3 — Centralize admin enforcement via `on_mount`

#### 3.1 Add a shared “load current user” helper in `UrielmWeb.UserAuth`

In `lib/urielm_web/user_auth.ex` you currently have nearly identical code in:

- `on_mount(:mount_current_user, ...)`
- `on_mount(:ensure_authenticated, ...)`

Refactor it so both call one helper, e.g.:

- `load_current_user(session, socket)` (private)

Pseudo-shape:

```elixir
defp load_current_user(session, socket) do
  case session do
    %{"user_id" => user_id} ->
      assign_new(socket, :current_user, fn -> Accounts.get_user(user_id) end)
    _ ->
      assign_new(socket, :current_user, fn -> nil end)
  end
end
```

Then:

- `:mount_current_user` just loads and `{:cont, socket}`
- `:ensure_authenticated` loads and halts/redirects when `current_user` is nil

#### 3.2 Add `on_mount(:ensure_admin, ...)`

Add a new clause:

- `on_mount(:ensure_admin, _params, session, socket)`

Behavior:

1. Ensure `current_user` is loaded (reuse the helper above).
2. If `current_user && current_user.is_admin`, continue: `{:cont, socket}`
3. If logged in but not admin: `{:halt, redirect(socket, to: "/")}`
4. If not logged in:
   - Let `:ensure_authenticated` handle it (recommended), or
   - Redirect to `/signup` here.

Recommended wiring:

- Keep admin session with both checks in order:
  - `:ensure_authenticated` first
  - then `:ensure_admin`

That yields:

- Anonymous user → `/signup`
- Logged in non-admin → `/`

#### 3.3 Apply it in the router

In `lib/urielm_web/router.ex`, update:

```elixir
live_session :admin,
  on_mount: [{UrielmWeb.UserAuth, :ensure_authenticated}] do
  ...
end
```

to:

```elixir
live_session :admin,
  on_mount: [
    {UrielmWeb.UserAuth, :ensure_authenticated},
    {UrielmWeb.UserAuth, :ensure_admin}
  ] do
  ...
end
```

---

### Step 4 — Remove redundant admin checks inside admin LiveViews (optional but recommended)

Once the router enforces admin access, you can simplify:

- `lib/urielm_web/live/admin/moderation_queue_live.ex`
- `lib/urielm_web/live/admin/trust_level_settings_live.ex`

Currently they do:

- `if current_user && current_user.is_admin do ... else redirect "/" end`

After router enforcement, those can become “assume admin”, which reduces duplication and makes the LiveViews easier to modify.

Safe approach (recommended for juniors):

1. Keep the guards for the first commit.
2. Add tests for router enforcement.
3. Remove the guards in a second commit (same PR is fine, but do it after tests pass).

---

## Tests to add/update

### 1) Add `SettingsLive` access tests

Create: `test/urielm_web/live/settings_live_test.exs`

Use `UrielmWeb.ConnCase` (like `thread_live_test.exs`) because you’ll want to set session state easily.

Test cases:

1. **Anonymous redirects**
   - `{:error, {:redirect, %{to: ...}}} = live(conn, "/settings")`
2. **Authenticated renders**
   - Create a user with `Urielm.Fixtures.user_fixture()`
   - `conn = log_in_user(conn, user)`
   - `{:ok, view, _html} = live(conn, "/settings")`
   - Assert key elements exist (prefer stable selectors):
     - At minimum: `assert has_element?(view, "form")`
     - If needed, add IDs to the two forms in the template (profile + password) and assert those.

### 2) Expand admin access tests

Update or add tests so both admin pages are covered:

- Existing: `test/urielm_web/live/moderation_queue_live_test.exs` already checks non-admin redirect for `/admin/moderation`.
- Add a similar test for `/admin/trust-levels`:
  - non-admin logged in → redirect to `/`

If you remove per-LiveView admin guards, these tests become even more important.

---

## Manual QA checklist

Do these in a browser (or via `mix phx.server`):

1. Logged out:
   - Visit `/settings` → redirected (no crash)
   - Visit `/admin/moderation` → redirected to signup or home (based on `ensure_authenticated`)
2. Logged in normal user:
   - Visit `/settings` → renders
   - Visit `/admin/moderation` and `/admin/trust-levels` → redirected to `/`
3. Logged in admin:
   - Visit `/admin/moderation` and `/admin/trust-levels` → renders

---

## Definition of Done (acceptance criteria)

- `/settings` is defined only once in the router and requires auth.
- Admin routes are protected centrally via `live_session :admin` on_mount hooks.
- No LiveView crashes on anonymous access for auth-required pages.
- Tests exist for:
  - anonymous `/settings` redirect
  - authenticated `/settings` render
  - non-admin redirect from both admin pages
- `mix precommit` passes.

