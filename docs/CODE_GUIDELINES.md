# Code Guidelines

A living guide for how we build, style, test, and ship this Phoenix 1.8 + Tailwind v4 + daisyUI app.

These rules apply across the app unless a file or directory explicitly documents an exception.

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

---

## Accessibility
- Decorative containers: `aria-hidden="true"` and `pointer-events-none`.
- Preserve focus rings and keyboard navigation; use semantic elements/roles.
- Maintain contrast ratios. Token usage must not reduce readability across themes.
- Provide `aria-label`/`title` for icon‑only controls.

---

## Routing & Auth
- Group LiveViews in `live_session`; pass `current_scope` via `<Layouts.app>` as needed.
- Use `on_mount` to enforce authentication on protected sessions.
- Be mindful of router scope aliasing; never duplicate aliases.

---

## HTTP & Integrations (Req)
- Use Req as the HTTP client. Centralize base URL, auth, default headers, timeouts.
- Apply conservative timeouts and retries with backoff for idempotent requests.
- Map error shapes into domain errors; do not leak raw HTTP errors to the UI.

### Examples
```elixir
# Base client
base =
  Req.new()
  |> Req.merge(base_url: System.fetch_env!("API_URL"))
  |> Req.merge(put_timeout: 5_000, connect_options: [timeout: 5_000])

# GET with params
{:ok, resp} = base |> Req.get(url: "/v1/items", params: [page: 1])

# POST with JSON body and simple retry (idempotent endpoints only)
{:ok, resp} =
  base
  |> Req.merge(retry: :transient, retry_delay: 200, max_retries: 3)
  |> Req.post(url: "/v1/items", json: %{name: name})
```

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

## Deviations
Document any local exceptions to the above at the module or directory level.


---

## HTTP & Integrations (Req)
- Use the thin wrapper `Urielm.HTTP.ReqClient` for all HTTP calls.
- Default retry policy (idempotent only):
  - 3 attempts total with jittered backoff ~200–500ms between retries
  - Retries allowed for idempotent methods only: GET, HEAD, OPTIONS, TRACE, PUT, DELETE
  - Do NOT retry:
    - Auth endpoints
    - Non-idempotent writes (e.g., POST that creates, PATCH with side effects)
    - Anything that could double-charge, double-create, or trigger external side effects
- Escape hatch: set `retry_exempt?: true` or `retry?: false` per request to disable retries.
- Timeouts: 5s request and connect by default; override per call when needed.
- Telemetry: emits `[:external, :req, :request]` before and `[:external, :req, :response]` after every call.

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
- 2-space indent
- Single quotes
- Semicolons required
- Keep components small and focused; prefer props/events over global state.
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
