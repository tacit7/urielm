# Action Plan: Topic Creation With Markdown + Rich Text Support

## Goal
Ship a **New Topic** flow that supports:
- **Markdown (source mode)** composer
- **Rich text (WYSIWYG) composer**
- A **single canonical stored format** that keeps rendering and moderation sane

This plan assumes Phoenix LiveView + LiveSvelte (your current stack).

---

## Product decisions (lock these first)
### Canonical storage format
**Store canonical content as Markdown** (`topics.body_md`).  
Reason: simple, portable, easy to diff, easy to sanitize, and matches your existing Markdown renderer.

### Rich text strategy
Rich text editor must **serialize back into Markdown** on save.  
That keeps storage and rendering unified.

### Mode defaults
- Default mode: **Markdown** for now
- User can toggle: **Markdown ↔ Rich**
- Remember choice: store `users.composer_mode` (enum: `markdown | rich`)

### Non-goals (for v1)
- Attachments, uploads, drag-drop images
- Collaborative editing
- Tables, complex embeds
- Full round-trip fidelity between rich and markdown (you will not get perfect fidelity)

---

## Phase 0: Data model and plumbing

### 0.1 Add fields and defaults
**Migration**
- `topics.body_md` (text, required)
- Optional: `topics.body_html` (text, nullable) for “cooked” HTML cache (optional now)
- `users.composer_mode` (string or enum), default `markdown`

**Validation**
- `title` required
- `board_id` required
- `body_md` required, min length (ex: 10)

### 0.2 Rendering pipeline
Pick one:
1) **Render Markdown on demand** (simplest)
2) Render on save and store `body_html` (faster page render, but more complexity)

Recommendation for now: **render on demand** with caching later.

### 0.3 Sanitization
Even if you render Markdown server-side, sanitize the HTML output.
- Use a strict allowlist sanitizer
- Strip scripts, inline event handlers, and unsafe URLs

---

## Phase 1: New Topic page (Markdown first)

### 1.1 Route + LiveView
Create `NewThreadLive` (or `NewTopicLive`) route:
- `GET /forum/b/:board_slug/new`
- optional global: `GET /forum/new?board=:slug`

### 1.2 UI layout
- Title input
- Board selector (if not already scoped to a board)
- Body editor (Markdown mode)
- Submit button + disabled state + validation errors
- Draft autosave (keyed by board + user)

### 1.3 Events
On submit:
- `Forum.create_thread(user, board, %{title, body_md})`
- Redirect to created thread URL

### 1.4 Tests
- LiveView test: renders form
- LiveView test: validates missing fields
- LiveView test: creates topic, redirects

Deliverable: Users can create topics with Markdown only.

---

## Phase 2: Add rich text mode (WYSIWYG) using ProseMirror/Tiptap

### 2.1 Editor choice
Use **Tiptap (ProseMirror)** in Svelte for the rich editor.  
Why: mature, plugin ecosystem, controllable schema.

### 2.2 Markdown conversion
You need two conversions:
- **Rich doc JSON → Markdown** (required for save)
- **Markdown → Rich doc JSON** (for switching modes and editing existing topics)

Implementation approaches:
- Use a Markdown extension for Tiptap if you choose one you trust
- Or implement a limited conversion set that covers your allowed nodes:
  - paragraphs, bold, italic, links, headings, lists, code, code blocks, blockquote

Recommendation: keep formatting scope small at first to make conversion reliable.

### 2.3 Component architecture
Create one composer component that supports both modes:

**Svelte component:** `TopicComposer.svelte`
Props:
- `initialTitle`
- `initialBodyMd`
- `initialMode` (`markdown` or `rich`)
- `onSubmit({title, body_md})`
- `draftKey`

Internals:
- Markdown mode: your existing `MarkdownInput`
- Rich mode: `RichTextEditor` (Tiptap)
- Toggle mode UI:
  - segmented control: “Write (Markdown)” | “Rich”
  - confirm modal only if conversion loses formatting

### 2.4 Mode persistence
On toggle, update user preference via LiveView event:
- `live.pushEvent("set_composer_mode", { mode: "rich" })`
- Store `users.composer_mode`

### 2.5 Save behavior
Regardless of mode, final submit sends:
- `title`
- `body_md`

In rich mode:
- On submit: `body_md = richEditor.getMarkdown()`

### 2.6 Edit topic behavior (optional but recommended)
- If you allow editing topics, the editor must load existing `body_md`
- When user selects rich mode, convert markdown to rich doc

Deliverable: Users can write rich text, but backend stores markdown.

---

## Phase 3: Preview, cooked HTML, and performance

### 3.1 Preview
- Markdown mode: show live preview (you already have renderer)
- Rich mode: preview is basically the editor itself; optional “Preview” shows cooked HTML

### 3.2 Cooked HTML cache (optional)
If performance becomes an issue:
- On create/update, render markdown to HTML and sanitize, store in `topics.body_html`
- Thread view uses `body_html` directly (already sanitized)

### 3.3 Security and abuse controls
- Rate limit topic creation
- Block too many links for new accounts
- Sanitize HTML output always

---

## Phase 4: UX polish (make it feel like Discourse)

### 4.1 Drafts
- Auto-save every few seconds
- Restore on revisit
- “Discard draft” action

### 4.2 Keyboard shortcuts
- Ctrl/Cmd+Enter to submit
- Esc to close composer or clear focus

### 4.3 Error handling
- Inline field errors
- Preserve editor content on failed submit
- Show toast only for global errors

---

## Work breakdown for a junior dev

### Ticket 1: NewTopicLive (Markdown-only)
- Add route + LV
- Implement form
- Hook to `Forum.create_thread`
- Add tests

### Ticket 2: Composer preference
- Add `users.composer_mode`
- Add event to save preference
- Default behavior for new users

### Ticket 3: RichTextEditor component
- Add Tiptap editor in Svelte
- Implement minimal toolbar: bold, italic, link, heading, list, code, quote
- Implement export-to-markdown function

### Ticket 4: Mode toggle + conversion
- Markdown ↔ Rich conversion
- Warn on conversion loss
- Persist mode

### Ticket 5: Hardening
- Sanitization review
- Rate limiting (if you have it)
- E2E smoke test: create topic in both modes

---

## Acceptance criteria
- User can create a topic using Markdown mode
- User can create a topic using Rich mode
- Server stores a single canonical `body_md`
- Thread page renders correctly and safely
- Switching modes does not destroy content for the supported formatting set
- Composer mode preference persists per user

---

## Notes and pitfalls
- Perfect round-trip conversion is not realistic; limit your rich formatting scope.
- Rich editor bugs show up on mobile first; test on an actual phone.
- Do not store raw HTML from the client; always generate and sanitize server-side.
