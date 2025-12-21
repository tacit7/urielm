# Action Plan: Standalone Videos (YouTube Embed) With Gating, SEO, Comments, and “Mark Complete”

Owner: JR Dev  
Stack: Phoenix LiveView + LiveSvelte, existing forum comments system

## Goal
Add a **Standalone Video** content type that:
- is hosted via **YouTube embed**
- supports **free + gated access** (signed-in, subscriber, admin/mod)
- has **SEO-friendly pages**
- includes **description (Markdown), resources section, author credit/bio**
- uses the **same layout as lectures**
- supports **comments**
- supports **manual “Mark Complete”** tracking per user

## Core decisions
- Create a canonical `videos` table (even if duplication is acceptable); this avoids duplicated metadata and makes gating/SEO consistent.
- Use `/videos/:slug` for standalone video pages.
- Keep progress tracking minimal: `video_completions` with `completed_at`.
- Comments reuse your existing system by **attaching each video to a forum thread** via `videos.thread_id`.

---

# Phase 0: Prep and inventory (0.5 day)

### Ticket 0.1: Confirm existing forum comment dependency
**Deliverable:** short note in PR description summarizing:
- how thread comments are loaded for `ThreadLive` today
- how `CommentTree` is rendered (props needed)
- what board will host video threads (new board vs existing)

**Acceptance:** You can create a thread in some board and render comments for it.

---

# Phase 1: Database (1 day)

## Ticket 1.1: Create `videos` table
Create migration:
- `videos.id` uuid pk
- `videos.title` string, required
- `videos.slug` string, required, unique
- `videos.youtube_url` text, required (or store `youtube_id`, but url is easiest now)
- `videos.description_md` text, default ""
- `videos.resources_md` text, default ""
- `videos.author_name` string, nullable
- `videos.author_url` string, nullable
- `videos.author_bio_md` text, default ""
- `videos.visibility` string/enum, required, default "public"
  - allowed: `public | signed_in | subscriber`
- `videos.published_at` utc_datetime, nullable
- `videos.thread_id` references `threads.id`, nullable (set on publish or manually)
- timestamps

Add DB constraints:
- unique index on `slug`
- optional check constraint on `visibility` (if you use Postgres enum or string check)

**Acceptance:**
- `mix ecto.migrate` succeeds
- inserting a record with duplicate slug fails

## Ticket 1.2: Create `video_completions` table
Migration:
- `video_completions.id` uuid pk (or composite key, your call)
- `video_completions.user_id` references users, required
- `video_completions.video_id` references videos, required
- `video_completions.completed_at` utc_datetime, required
- unique composite index on `(user_id, video_id)`

**Acceptance:**
- duplicates prevented by DB
- can upsert/update `completed_at`

## Ticket 1.3: Minimal subscription storage (stub)
Since you have no entitlement logic today, implement a minimal table:
- `subscriptions.user_id` references users, unique
- `subscriptions.status` string (allowed: `active | canceled | past_due`)
- `subscriptions.current_period_end` utc_datetime, nullable
- timestamps

This is a placeholder until Stripe (or equivalent) later.

**Acceptance:**
- you can mark a user active via SQL for manual testing

---

# Phase 2: Context layer (1 day)

Create a new context module: `Urielm.Content` (or put under existing context if you already have one; keep consistent).

## Ticket 2.1: Video schema + changeset
- `Urielm.Content.Video` schema with fields above
- validations:
  - title required
  - slug required, format: `^[a-z0-9-]+$`
  - youtube_url required, basic URL validation
  - visibility inclusion

**Acceptance:**
- invalid slugs rejected
- changeset errors show correctly

## Ticket 2.2: Video queries
Functions:
- `get_video_by_slug!(slug)`
- `list_published_videos()` (where `published_at IS NOT NULL`)
- `video_published?(video)`
- `create_video(attrs)` (for now used by seeds or console)
- `update_video(video, attrs)`

**Acceptance:**
- can fetch by slug
- unpublished videos don’t show in list

## Ticket 2.3: Authorization checks
Create policy-style functions (keep it simple):
- `can_view_video?(user, video)`
Rules:
- `public`: anyone
- `signed_in`: requires user
- `subscriber`: requires `user.is_admin || Billing.active_subscription?(user)`
Also allow `user.is_admin` override for everything.

**Acceptance:**
- unit tests for the 3 visibility levels

## Ticket 2.4: Completion tracking
Functions:
- `completed_video?(user, video)` -> boolean
- `mark_video_complete(user, video)` -> upsert completion
- `unmark_video_complete(user, video)` -> delete row

**Acceptance:**
- marking twice does not error
- unmark works

## Ticket 2.5: Billing helper
Add module `Urielm.Billing` with:
- `active_subscription?(user)` reads `subscriptions` table

**Acceptance:**
- returns true when subscription is active and not expired (if end date present)

---

# Phase 3: LiveView page `/videos/:slug` (1–2 days)

## Ticket 3.1: Routes
Add route:
- `live "/videos/:slug", VideoLive.Show, :show`

**Acceptance:** route compiles

## Ticket 3.2: VideoLive.Show mount
In `mount/3`:
- load video by slug
- if not found: 404
- if unpublished: allow only admin
- enforce `can_view_video?`; if not allowed, redirect to sign-in or show a gated message

Assigns:
- `:video`
- `:completed` boolean (signed-in)
- `:thread` (if you attach a forum thread)
- `:comment_tree` (built like ThreadLive does)

**Acceptance:**
- gated visibility works as expected
- page loads without full reload issues

## Ticket 3.3: YouTube embed component
Add Svelte component or HEEx partial for embed:
- Use `youtube_url` and convert to embed url
- Add `loading="lazy"` iframe
- Set `referrerpolicy` and reasonable sandbox attributes if you use them

**Acceptance:**
- video plays
- responsive sizing (16:9) on mobile and desktop

## Ticket 3.4: Render markdown sections
- Description: render `description_md` via your existing Markdown renderer
- Resources: render `resources_md`
- Author credit block: show `author_name`, link `author_url`, and optional `author_bio_md` rendered as markdown

**Acceptance:**
- markdown renders
- empty sections collapse cleanly

## Ticket 3.5: Mark complete UI
If signed-in:
- button toggles complete/uncomplete
- show status text “Completed” if set

LiveView events:
- `"mark_video_complete"`
- `"unmark_video_complete"`

**Acceptance:**
- clicking updates UI without refresh
- persists in DB

## Ticket 3.6: Comments
Preferred implementation: attach a `thread_id` to each video.
- If `video.thread_id` exists:
  - load thread, build comment tree (reuse ThreadLive logic)
  - render CommentTree svelte with same props
- If no `thread_id`:
  - show “Comments not enabled yet” for v1, or create thread automatically for admins only (optional)

**Acceptance:**
- comment tree renders under a standalone video
- posting a comment refreshes the comment tree

---

# Phase 4: SEO and metadata (0.5–1 day)

## Ticket 4.1: Meta tags
Set in assigns/layout:
- title: `video.title`
- description: first 160 chars of `description_md` (strip markdown)
- canonical: `/videos/:slug`
- OpenGraph:
  - `og:title`
  - `og:description`
  - `og:type=video.other` (or `website`)
  - `og:url`
  - optional `og:image` (later)

**Acceptance:**
- view source shows meta tags
- lints/formatter okay

---

# Phase 5: Seed and admin workflow (0.5 day)

## Ticket 5.1: SQL insert template doc
Add `docs/VIDEO_SQL_TEMPLATE.md` with:
- insert example
- visibility options
- how to attach `thread_id`

**Acceptance:** devs can create videos without UI

## Ticket 5.2: Add a “Videos” board (if using forum threads)
Create a board record for video comment threads:
- `name=Videos`
- `slug=videos`
- optionally hidden from main forum lists if you don’t want it visible

**Acceptance:** threads can be created in that board

---

# Phase 6: Testing (1 day)

## Ticket 6.1: Context unit tests
- `can_view_video?/2` for each visibility
- completion upsert
- slug validation

## Ticket 6.2: LiveView tests
- public video renders for anon
- signed_in video redirects/blocks anon
- subscriber video blocks signed-in non-subscriber
- mark complete toggles state
- comments section renders when thread_id present

**Acceptance:** CI green

---

# Done definition (release criteria)
- `/videos/:slug` works
- gating behaves correctly
- SEO meta present
- comments render
- mark complete works and persists
- no runtime errors on missing optional fields

---

# Nice-to-haves (explicitly out of scope for v1)
- scheduled publishing (use `published_at`)
- versioning/replacing video while keeping URL
- Cloudflare Stream hosting
- progress resume via YouTube IFrame API
- rich text editor for comments (do not do this yet)

---

# Notes (keep the dev from stepping on rakes)
- Do not trust the client for HTML; always render and sanitize server-side.
- YouTube URLs come in many formats; normalize them to an embed URL and store the original too.
- If you reuse forum threads for comments, make sure the video page cannot delete thread content accidentally.
