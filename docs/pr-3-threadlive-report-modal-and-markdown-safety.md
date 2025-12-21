# PR 3 — UI Safety + `ThreadLive` Maintainability

This PR focuses on two high-payoff improvements that reduce risk and keep the codebase easier to change:

1. **Markdown embed safety** (avoid HTML/attribute injection and remove inline JS)
2. **`ThreadLive` template simplification** (remove one-modal-per-comment DOM bloat)

It also includes targeted test improvements so juniors can refactor UI without breaking brittle assertions.

---

## Why this PR exists (context for juniors)

### 1) Raw HTML + string interpolation can create XSS risks

`assets/svelte/MarkdownRenderer.svelte` renders markdown to HTML and then uses regex replacements to insert embeds. Today it:

- injects URLs directly into HTML attributes
- includes inline JS (`onclick="window.open(...)"`)

Even if markdown itself is safe, string-built HTML is easy to get wrong. A malicious URL containing quotes can break out of attributes unless we escape/sanitize.

### 2) `ThreadLive` renders a report modal per comment

`lib/urielm_web/live/thread_live.ex` currently builds:

- 1 thread report modal
- **N comment report modals** (`N = number of comments`, including nested replies)

This creates:

- huge HTML payloads
- slower diffing/patching
- harder-to-edit templates (more merge conflicts)

We can keep the same UX with **one reusable modal**.

---

## Goals

- Remove inline JS from markdown embed output and properly escape any interpolated values.
- Keep embed rendering behavior the same for normal users.
- Replace “one modal per comment” with a single comment-report modal.
- Make comment reporting still work end-to-end (UI → LiveView event → DB insert).
- Update tests to use stable selectors (`data-testid`, IDs) rather than raw HTML substrings.

## Non-goals

- No redesign of markdown renderer UI/typography.
- No change to report validation rules or moderation workflow.
- No “rewrite everything into components” for `ThreadLive`.

---

## Files you will likely touch

### Frontend

- `assets/svelte/MarkdownRenderer.svelte`
- (Recommended) Add a helper module:
  - `assets/js/markdown/embeds.js`
- (Optional but recommended) Add a Node unit test:
  - `assets/js/markdown/embeds.test.js`
- `assets/js/app.js` (add a reusable “open modal” handler)

### LiveView

- `lib/urielm_web/live/thread_live.ex`
- `assets/svelte/CommentTree.svelte` (change report button behavior)

### Tests

- `test/urielm_web/live/thread_live_test.exs`

---

## Part A — Make markdown embeds safe

### Step A1 — Remove inline JS (`onclick`) from embed output

In `assets/svelte/MarkdownRenderer.svelte`:

Replace the image embed output:

- From: `<img ... onclick="window.open('...')">`
- To: a safe HTML-only pattern:
  - Wrap image in an `<a>` tag:
    - `href="..."`
    - `target="_blank"`
    - `rel="noopener noreferrer"`

This keeps the “click to open” UX without inline JavaScript.

### Step A2 — Escape attribute values before interpolating into HTML strings

Even if you remove `onclick`, you still interpolate URLs into `href` and `src`.

You must prevent quotes from breaking attributes.

Recommended approach:

1. Extract embed processing to a JS module so it’s testable:

Create `assets/js/markdown/embeds.js`:

- `export function escapeAttr(value) { ... }`
- `export function processEmbeds(htmlContent) { ... }`

2. Update `MarkdownRenderer.svelte` to:

- `import { processEmbeds } from "../js/markdown/embeds"` (adjust path as needed)

Suggested `escapeAttr` implementation:

```js
export function escapeAttr(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&#39;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
}
```

Then use:

- `const safeUrl = escapeAttr(url)`

before injecting into `href`/`src`.

### Step A3 — Tighten URL regexes to avoid matching quotes

This is not a replacement for escaping, but it reduces weird edge cases.

For image URLs, prefer excluding quotes explicitly:

- Replace `[^\\s<]+` with something like `[^\\s<"'`]+`

Still escape, because regex-based “security” is never complete.

---

### Step A4 (optional but strongly recommended) — Add a Node unit test for embeds

Add `assets/js/markdown/embeds.test.js` using Node’s built-in runner:

```js
import test from "node:test"
import assert from "node:assert/strict"
import { processEmbeds } from "./embeds.js"

test("processEmbeds escapes attribute-breaking quotes", () => {
  const input = `https://example.com/x.jpg' onerror='alert(1)`
  const out = processEmbeds(input)
  assert.equal(out.includes("onerror="), false)
  assert.equal(out.includes("onclick="), false)
})
```

How to run locally:

- `node --test assets/js/markdown/embeds.test.js`

Note:

- `mix precommit` doesn’t run Node tests by default. Run this test manually in this PR.
- If you want it automated later, we can add a `mix assets.test` alias in a follow-up PR.

---

## Part B — Replace per-comment report modals with a single modal

### Step B1 — Add a reusable “open modal” JS handler

You already have close support in `assets/js/app.js`:

- listens for `phx:close_modal`

Add symmetric open support:

- listens for `phx:open_modal`
- finds the `dialog` by id
- calls `showModal()` and adds the `modal-open` class (matching how close removes it)

This allows LiveView to open modals without Svelte doing direct DOM lookups.

### Step B2 — Update `ThreadLive` assigns/state

In `lib/urielm_web/live/thread_live.ex`:

Add assigns for the report modal state:

- `reporting_comment_id` (string or nil)

Initialize it in `mount/3`:

- `assign(:reporting_comment_id, nil)`

### Step B3 — Add a new event: `open_report_comment`

Add `handle_event/3`:

- name: `"open_report_comment"`
- params: `%{"comment_id" => comment_id}`
- behavior:
  1. Assign `reporting_comment_id`
  2. `push_event(socket, "open_modal", %{"id" => "report_comment_modal"})`

This is the only “open” event you need for comment reporting.

### Step B4 — Replace the N modals in the template with one modal

In `render/1`, delete:

- `flatten_comments/1`
- the `for comment <- flatten_comments(@comment_tree)` loop
- all the per-comment `<dialog id={"report_comment_modal_#{comment.id}"} ...>`

Replace with one `<dialog id="report_comment_modal" ...>` whose form includes:

- hidden `comment_id` input set from `@reporting_comment_id`
- stable selectors for tests, e.g.:
  - `id="report-comment-form"`
  - `data-testid="comment-report-modal"`

Important:

- Guard against nil `@reporting_comment_id`:
  - disable submit button when nil, or
  - treat submit with nil id as error and show a flash (defensive)

### Step B5 — Update `report_comment` success close behavior

Currently on success, ThreadLive does:

- `push_event("close_modal", %{"id" => "report_comment_modal_#{comment_id}"})`

Change it to:

- `push_event("close_modal", %{"id" => "report_comment_modal"})`

This matches the new single modal.

### Step B6 — Update Svelte comment report button to trigger LiveView event

In `assets/svelte/CommentTree.svelte`:

Replace:

- `handleReport(commentId)` that does `document.getElementById(...).showModal()`

With:

- `live.pushEvent("open_report_comment", { comment_id: commentId })`

This keeps logic consistent (LiveView owns which comment is being reported; JS owns opening the modal).

---

## Tests to add/update

### 1) `ThreadLive` should render only one comment report modal

Update/add in `test/urielm_web/live/thread_live_test.exs`:

- Visit thread page with at least 2 comments
- Assert:
  - `assert has_element?(view, "[data-testid='comment-report-modal']")`
  - and it appears only once (use `LazyHTML` selector count if needed)

### 2) Comment report flow works

Add a test:

1. Create user + thread + comment
2. Login, `live(conn, "/forum/t/:id")`
3. Trigger:
   - `render_click(view, "open_report_comment", %{"comment_id" => to_string(comment.id)})`
4. Submit the form:
   - `view |> form("#report-comment-form", %{"reason" => "...", "description" => "..."}) |> render_submit()`
5. Assert DB:
   - `Repo.get_by(Urielm.Forum.Report, target_type: "comment", target_id: comment.id)` exists

Why this test approach:

- It avoids brittle reliance on SSR structure of Svelte buttons.
- It validates the actual LiveView events + DB behavior.

### 3) Improve brittle assertions in existing ThreadLive tests

Replace HTML substring tests like:

- `refute html =~ "data-testid=..."`

with selector-based checks:

- `refute has_element?(view, "[data-testid='report-button']")`

This makes the tests resilient to markup formatting changes.

---

## Manual QA checklist

1. Markdown embeds:
   - Paste an image URL and click it → opens in new tab (no inline JS).
   - Try a weird URL containing quotes → it should not break the page.
2. Thread page performance:
   - Open a thread with many comments → page loads and interactions remain snappy.
   - Confirm only one comment report modal exists in the DOM (inspect).
3. Reporting:
   - Report a comment → success flash + modal closes.
   - Report a thread → still works and closes its modal as before.

---

## Definition of Done (acceptance criteria)

- `MarkdownRenderer` no longer emits inline JS and escapes interpolated attribute values.
- `ThreadLive` renders exactly one comment report modal.
- Comment “Report” triggers a LiveView event and opens the modal reliably.
- Comment report submission creates the correct DB report and closes the modal.
- ThreadLive tests use stable selectors and are not brittle.
- `mix precommit` passes (plus manual Node test if you added it).

