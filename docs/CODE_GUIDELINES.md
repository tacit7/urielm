# Code Guidelines

A living guide for how we build, style, test, and ship this Phoenix 1.8 + Tailwind v4 + daisyUI app.

These rules apply across the app unless a file or directory explicitly documents an exception.

## Related Docs (Action Plans)
- `docs/MAINTAINABILITY_AUDIT.md` (ranked findings + 3-PR plan)
- `docs/audit-2025-pr-1-param-safety-and-not-found-handling.md` (crash-proof URLs)
- `docs/audit-2025-pr-2-bulk-thread-user-state.md` (kill N+1 queries in feeds)
- `docs/audit-2025-pr-3-deployment-hygiene-ssr-bundles.md` (stop committing SSR build output)
- Legacy/previous plans:
  - `docs/pr-1-fix-routing-auth-invariants.md`
  - `docs/pr-2-forum-thread-fetch-purity-view-count.md`
  - `docs/pr-3-threadlive-report-modal-and-markdown-safety.md`

## Toolchain & Imports
- Phoenix 1.8, LiveView ≥ 1.1, Tailwind v4, daisyUI.
- app.css must keep Tailwind v4 imports and sources:

```css
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../svelte";
@source "../../lib/urielm_web";
```

- Only the `assets/js/app.js` and `assets/css/app.css` bundles are supported. Do not link vendor scripts/styles in layouts; import them into the bundles.

---

## UI (Design System)
- Use Tailwind utilities + daisyUI components. Do not use `@apply`.
- Prefer theme tokens in custom CSS (e.g., `var(--color-primary)`).
- Keep gradients/surfaces theme‑aware using tokens + `color-mix`.
- Keep spacing/typography consistent; avoid arbitrary values unless justified.

### Theme‑aware gradients
```css
.bg-hero-primary {
  background: radial-gradient(circle,
    color-mix(in oklch, var(--color-primary) 40%, transparent) 0%,
    color-mix(in oklch, var(--color-primary) 10%, transparent) 40%,
    transparent 70%);
}

.bg-hero-secondary {
  background: radial-gradient(circle,
    color-mix(in oklch, var(--color-secondary) 30%, transparent) 0%,
    transparent 70%);
}
```

---

## UX (Interaction)
- Provide micro‑interactions (hover/focus, motion‑safe transitions).
- Show loading/empty states; prefer optimistic UI when safe.
- Use client‑side navigation for internal transitions: `<.link navigate>` / `push_navigate`.
- Add stable IDs on key controls for testing.

---

## LiveView & HEEx
- Always wrap with `<Layouts.app ...>`; never call `<.flash_group>` outside Layouts.
- Use Verified Routes (`~p`), `<.link navigate/patch>`; do not use deprecated `live_redirect/live_patch`.
- Forms: build changesets in LV, assign `@form = to_form(changeset_or_params)` and use `<.form for={@form}>` with `<.input field={@form[:field]}>`. Do not access changesets directly in templates.
- Streams: use `stream/3` and `stream_delete/3`; for filters, re‑fetch and `reset: true`. Track counts separately (streams are not enumerable).
- Stream containers must set `phx-update="stream"` and each child must have an `id`. If you show a sibling empty‑state, ensure it is the only non‑stream sibling or give it a stable `id`.
- Hooks: if a hook manages its own DOM, set `phx-update="ignore"`.
- Params: never use `String.to_integer/1` on user input (`params`, query strings, path params). Use `Integer.parse/1` with a safe default (or `UrielmWeb.Param.*` once PR1 lands).

### LiveView Lifecycle & Side Effects (Important)
- LiveViews mount twice (disconnected + connected). Only perform DB writes and other side effects when `connected?(socket)` is true.
- Avoid hidden side effects in “read” functions (e.g., don’t increment counters inside `get_*` functions). Prefer explicit command functions like `increment_*` that callers opt into.
- Keep event handlers cheap: prefer updating one item via streams (e.g., `LiveHelpers.update_thread_in_stream/4`) over re-fetching entire pages.
- Avoid rendering one modal/component per collection item when the list can grow large. Prefer a single reusable modal with a `selected_*_id` assign.

### Forum & LiveView Patterns
- Use `UrielmWeb.LiveHelpers` to centralize serialization and common UI helpers:
  - `serialize_thread_card/2`, `serialize_thread_full/2`, `serialize_thread_list/2`
  - `serialize_comment/2`
  - `build_comment_tree/2` for nested comments
  - `update_thread_in_stream/4` to refresh a single card after an action (vote/save/subscribe)
  - `format_relative/1`, `format_short/1` for time labels
- Prefer small, focused LiveViews that delegate mapping/formatting to helpers; avoid duplicating serialization across views.
- Event handlers (vote/save/subscribe/unsubscribe): refresh the affected item in the stream using `update_thread_in_stream/4` instead of reloading whole pages.
- Authorization checks: use an owner‑or‑admin helper in contexts (e.g., `authorized?/2`) and avoid scattering `is_admin or ... == user_id` across code.
- Stable ordering: when sorting by timestamps, add an `id` tiebreaker, e.g., `order_by([x], desc: x.inserted_at, desc: x.id)` to prevent jitter and duplicate rows across pages.
- Query preloads: use a local helper (e.g., `thread_preloads/1`) to DRY repeated `preload([:author, :board])` on Thread queries.

### Examples
Verified navigation:
```heex
<.link navigate={~p"/settings"} class="btn btn-primary">Settings</.link>
```

Form setup:
```elixir
# LiveView
form = to_form(changeset)
assign(socket, form: form)
```
```heex
<.form for={@form} id="user-form" phx-submit="save">
  <.input field={@form[:email]} type="email" />
</.form>
```

Stream container:
```heex
<div id="threads" phx-update="stream">
  <div class="hidden only:block" id="threads-empty">No threads yet</div>
  <div :for={{id, t} <- @streams.threads} id={id}>{t.title}</div>
</div>
```

---

## Styling (Tailwind + daisyUI)
- Keep Tailwind v4 import/source syntax in `app.css`.
- Use the `<.icon>` component with `hero-*` names; do not import icon JS into templates.
- Put custom utilities in `assets/css/app.css`; prefer tokens and `color-mix`.
- Mark decorative layers as `aria-hidden` and non‑interactive (`pointer-events-none`).

---

## JavaScript & Svelte
- No inline `<script>` tags in templates. Write hooks/components under `assets/js` or `assets/svelte` and import in `assets/js/app.js`.
- Name custom events dispatched to LV with `phx:` prefix (e.g., `phx:set-theme`).
- Keep hooks small and composable; if a hook owns its DOM, set `phx-update="ignore"` on its root.
- Svelte via `live_svelte`: prefer props/events to global state. Avoid direct DOM mutation outside component boundaries.
- Avoid generating HTML strings that include inline JS handlers (`onclick=...`). Use LiveView events or hook-based behavior instead.
- If you must render raw HTML (`{@html ...}` in Svelte), the content must be sanitized and any interpolated attribute values must be escaped.
- Do not edit `priv/svelte/*` by hand; it is generated by `assets/build.js` (see PR3 doc). Rebuild via `mix assets.build` / `mix assets.deploy`.

---

## Accessibility
- Decorative containers: `aria-hidden="true"` and `pointer-events-none`.
- Preserve focus rings and keyboard navigation; use semantic elements/roles.
- Maintain contrast ratios. Token usage must not reduce readability across themes.
- Provide `aria-label`/`title` for icon‑only controls.

---

## Routing & Auth
- Each path should be defined in exactly one `live_session`. Avoid duplicate route definitions across sessions (they create unreachable clauses and auth bypass risks).
- Group LiveViews in `live_session` and enforce access with `on_mount` hooks (preferred over per-LiveView `if current_user ...` checks).
  - Authenticated pages: `live_session :authenticated, on_mount: [{UrielmWeb.UserAuth, :ensure_authenticated}]`
  - Admin pages: `live_session :admin, on_mount: [{UrielmWeb.UserAuth, :ensure_authenticated}, {UrielmWeb.UserAuth, :ensure_admin}]`
- `<Layouts.app>` supports `current_user` and `current_scope`. If you introduce scope-based auth, ensure routes are in the correct `live_session` and pass `current_scope` through to the layout.
- Be mindful of router scope aliasing; never duplicate module prefixes.

---

## HTTP & Integrations (Req)
- Use `Req` (no `:httpoison`, `:tesla`, or `:httpc`).
- Prefer `Urielm.HTTP.ReqClient` for consistent defaults (timeouts, retry policy, telemetry).
- Apply retries only for idempotent requests; do not retry endpoints that can double-create, double-charge, or trigger external side effects.
- Map errors into domain errors; do not leak raw HTTP errors to the UI.

### Default policy (ReqClient)
- Retries: 3 attempts total with jittered backoff ~200–500ms between retries
- Retries allowed for idempotent methods only: GET, HEAD, OPTIONS, TRACE, PUT, DELETE
- Do NOT retry:
  - Auth endpoints
  - Non-idempotent writes (e.g., POST that creates, PATCH with side effects)
  - Anything that could double-charge, double-create, or trigger external side effects
- Escape hatch: set `retry_exempt?: true` or `retry?: false` per request to disable retries.
- Timeouts: 5s request/connect by default; override per call when needed.
- Telemetry: emits `[:external, :req, :request]` and `[:external, :req, :response]`

### ReqClient usage
```elixir
alias Urielm.HTTP.ReqClient

client = ReqClient.new(base_url: System.get_env("API_URL"))

# Idempotent GET (retries enabled by default)
{:ok, resp} = ReqClient.get(client, "/v1/items", params: [page: 1])

# Non-idempotent POST (no retries by default)
{:ok, resp} = ReqClient.post(client, "/v1/items", json: %{name: name})

# Force-disable retries (escape hatch)
{:ok, resp} = ReqClient.get(client, "/v1/items", retry_exempt?: true)
```

### Telemetry metadata
- Request: `%{method, url, retry?, max_retries}`
- Response: `%{method, url, status | error, retry?, max_retries}`, measurements include `%{duration}` in ms

---

## Testing
- Prefer `Phoenix.LiveViewTest` and `LazyHTML`; avoid raw HTML string assertions.
- Select with stable IDs (`element/2`, `has_element?/2`).
- Write focused tests per interaction; assert outcomes over implementation details.

```elixir
{:ok, view, _html} = live(conn, ~p"/")
assert has_element?(view, "#hero-headline")
view |> element("#cta-explore-tutorials") |> render_click()
```

---

## Performance
- Use LiveView streams for collections; do not assign large lists.
- For filters, re‑fetch and call `stream/4` with `reset: true`.
- Use `Task.async_stream/3` for concurrent enumeration with back‑pressure; set `timeout: :infinity` only when needed.

---

## Security
- Keep CSRF and secure headers enabled.
- Never use `String.to_atom/1` on user input.
- Normalize params to a single key type (strings preferred) before `cast/4`.
- Do not expose secrets in logs or client bundles.
- Avoid rendering unsanitized HTML. If you render raw HTML (Svelte `{@html}`), sanitize it and escape interpolated attributes; never include inline event handlers.

---

## Internationalization
- Use Gettext for user‑facing text; avoid hard‑coding strings in logic.

---

## Observability
- Use structured logs with meaningful levels.
- Emit telemetry for important actions (e.g., external API calls, long‑running ops).

---

## Docs & Naming
- Predicate functions end with `?` (guards may use `is_*`).
- Document public functions/components; add examples for non‑trivial APIs.
- Keep changelogs and migration notes in `docs/` when behavior changes.

---

## Commits & Precommit
- Run `mix precommit` before pushing (compiles with warnings‑as‑errors, formats, tests).
- Keep commits small and focused; use clear messages.

---

## Default Theme
- Product default theme is `"tokyo-night"`.
- Theme-aware styling is required for all custom CSS; tokyo-night is the baseline reference.
- Server-side theme reads cookie `phx_theme`; first paint renders with the correct theme.

---

## Streams: Empty-State Pattern
- Use a single stable empty-state block with a known ID inside the stream container.
- It may exist alongside streamed items, but must:
  - Have a stable DOM ID (e.g., `id="threads-empty"`)
  - Be shown/hidden based on stream state — do NOT reorder or conditionally render nodes that cause diff churn

Example:
```heex
<div id="threads" phx-update="stream">
  <div id="threads-empty" class="hidden only:block">No threads yet</div>
  <div :for={{id, t} <- @streams.threads} id={id}>{t.title}</div>
</div>
```

---

## Param Normalization
- Standardize on string keys before Ecto `cast/4`.
- Use `UrielmWeb.Params.normalize/1` at the start of `handle_event`.

Example:
```elixir
def handle_event("save", params, socket) do
  params = UrielmWeb.Params.normalize(params)
  changeset = MySchema.changeset(%MySchema{}, params)
  # ...
  {:noreply, socket}
end
```

---

## Svelte Conventions
- Match the existing file’s style; keep diffs minimal (don’t reformat unrelated code).
- Prefer small, focused components; use props/events over global state.
- Avoid direct DOM manipulation when LiveView events/hooks can express the behavior.
- No inline scripts in HEEx; import via `assets/js/app.js`.


---

## Controllers & Params
- Prefer normalizing params in contexts or LiveViews; controllers should not bypass changesets.
- If a controller builds its own map to pass to a changeset, ensure keys are strings or normalize once:

```elixir
# Controller action (example)
attrs = Urielm.Params.normalize(conn.params["widget"] || %{})
case MyContext.create_widget(attrs) do
  {:ok, widget} -> redirect(conn, to: ~p"/widgets/#{widget.id}")
  {:error, changeset} -> render(conn, :new, changeset: changeset)
end
```

- Do not mass-assign; always use Ecto changesets (cast/validate) to whitelist fields.
- For nested payloads, use `cast_assoc/3` or `cast_embed/3` in changesets.

---

## Deviations
Document any local exceptions to the above at the module or directory level.
