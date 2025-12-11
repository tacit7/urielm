# Reddit-Style Forum Feature: Implementation Action Plan (Phoenix 1.8 + LiveView + DaisyUI)

This plan assumes you want a Reddit-like **feed of posts** plus **thread pages with nested comments**, and you want it integrated into your existing Phoenix app (users/auth already exist). If any assumption is false, the plan still works; you’ll just swap the integration points.

---

## 0) Define the feature boundaries (MVP vs v1)

### MVP (ship this first)
- Browse a **feed** of posts (new/top)
- View a **thread** page with **nested comments**
- Create post, create comment
- Upvote/downvote for posts and comments
- Basic moderation: delete/soft-delete your own content, admins can remove anything
- Pagination and sensible indexes

### v1 (next)
- “Hot” ranking, flair/tags
- Search
- Saves/bookmarks
- Subscriptions and notifications (in-app)
- Reporting workflow (spam/abuse)
- Rate limiting + anti-spam controls

---

## 1) UX + routes (match Reddit structure but don’t cosplay it)

### Primary pages
- `/forum`:
  - Default feed (new)
  - Sort dropdown: New, Top (last 24h, week, month, all-time)
- `/forum/c/:category_slug`:
  - Category landing (optional in MVP)
- `/forum/b/:board_slug`:
  - Board-level feed (like a subreddit)
- `/forum/t/:thread_id-:slug`:
  - Thread view (post + comment tree)
- `/forum/new`:
  - Create post (or modal)

### UI components (DaisyUI)
- Feed list items: vote column, title, meta row, snippet
- Thread header: title + content + meta + vote
- Comment tree:
  - Collapsible branches
  - Reply box per comment (toggle)
  - Depth limit (MVP: 6–8)

---

## 2) Data model (Postgres + Ecto)

Pick a stable hierarchy that fits your “forums by topic, lesson, class” idea. Use **Category → Board → Thread → Comment**. Then optionally attach threads to lessons.

### Tables (recommended)
1. `forum_categories`
   - `id` (uuid)
   - `name`, `slug`, `position`, `is_hidden`
   - timestamps

2. `forum_boards` (the “subreddit” equivalent)
   - `id` (uuid)
   - `category_id` (fk)
   - `name`, `slug`, `description`
   - `is_locked` (no new posts), `is_hidden`
   - timestamps

3. `forum_threads` (posts)
   - `id` (uuid)
   - `board_id` (fk)
   - `author_id` (fk users)
   - `title`, `slug`
   - `body` (markdown or plain text)
   - `score` (int, cached)
   - `comment_count` (int, cached)
   - `is_locked`, `is_removed`
   - `removed_by_id` (fk users, nullable)
   - timestamps

4. `forum_comments`
   - `id` (uuid)
   - `thread_id` (fk)
   - `author_id` (fk users)
   - `parent_id` (self-fk, nullable)  // adjacency list for nesting
   - `body`
   - `score` (int, cached)
   - `is_removed`, `removed_by_id`
   - timestamps

5. `forum_votes` (single table for both targets)
   - `id` (uuid)
   - `user_id` (fk users)
   - `target_type` (`thread` | `comment`)
   - `target_id` (uuid)
   - `value` (smallint: -1, 0, 1)  // store 0 only if you want “unvote” history; otherwise delete row
   - timestamps
   - **unique index** on `(user_id, target_type, target_id)`

6. Optional: thread-to-lesson link (for your course site)
   - `forum_thread_links`
     - `thread_id`
     - `link_type` (`lesson` | `course` | `post`)
     - `link_id` (uuid or bigint, depending on your existing schema)
   - This avoids polymorphic junk inside `forum_threads` and keeps it flexible.

### Indexes (non-negotiable)
- `forum_threads(board_id, inserted_at desc)`
- `forum_threads(board_id, score desc)` (or partial, depending on how you sort)
- `forum_comments(thread_id, parent_id, inserted_at)`
- `forum_votes(user_id, target_type, target_id)` unique
- `forum_votes(target_type, target_id)` for score aggregation

### Soft-deletes
Use boolean flags (`is_removed`) plus `removed_by_id` instead of hard deletes. It simplifies moderation and avoids orphaning comment trees.

---

## 3) Domain layer (contexts) and core operations

Create a dedicated context: `UrielM.Forum` (or `MyApp.Forum`). Keep it boring and explicit.

### Core functions
- `list_threads(opts)`
  - filters: board/category
  - sorting: new, top(time_range)
  - pagination: keyset preferred (inserted_at + id), offset acceptable for MVP
- `get_thread!(id)` + preload author/board
- `create_thread(author, attrs)`
- `list_comments(thread_id)`
  - return as flat list and build tree in app code, or build tree with recursive CTE later
- `create_comment(author, thread_id, parent_id, attrs)`
- `cast_vote(user, target_type, target_id, value)`
  - enforce -1/1
  - update cached score atomically
- moderation:
  - `remove_thread(actor, thread_id)`
  - `remove_comment(actor, comment_id)`
  - `lock_thread(actor, thread_id)`

### Voting correctness (avoid “eventually consistent vibes”)
Do vote writes in a transaction (`Ecto.Multi`):
1. Upsert vote row (or insert/delete)
2. Compute delta vs previous vote
3. Apply delta to cached `score` on thread/comment
This prevents score drifting.

---

## 4) LiveView implementation (fast, SEO-friendly, no overengineering)

### LiveViews
- `ForumFeedLive`
  - params: board_slug, sort, time_range, page cursor
  - renders list of `ThreadCard` components
- `ForumThreadLive`
  - loads thread + comments
  - renders `CommentTree` component
  - supports “reply” actions and optimistic UI if you want

### Comment tree rendering
- Fetch all comments for thread in one query
- Build a tree in Elixir:
  - group by `parent_id`
  - recursively render children
- Enforce a max depth to avoid performance murder.

### Real-time updates (optional in MVP)
Use PubSub broadcasts on:
- new thread in board
- new comment in thread
Then update LV streams (`stream_insert`) for the feed and comment list. Ship without this first if time is tight.

---

## 5) Anti-spam and safety (minimum viable sanity)

### Rate limits (MVP)
- Limit thread creation and comment creation per user per minute
- Use your existing stack (Oban + DB, Redis if you already have it, or a simple DB-based throttle)

### Content rules
- Max lengths: title/body/comment
- Strip dangerous HTML if you allow markdown (use a sanitizer)
- Optional: require email verified for posting

---

## 6) Search (v1)
Postgres full-text search:
- Add `tsvector` generated column or materialized field for threads (title + body)
- GIN index
- Search endpoint: `/forum/search?q=...`

---

## 7) Migration plan (concrete steps)

1. Generate migrations for the forum tables above
2. Add all indexes and unique constraints
3. Seed default categories/boards (optional)
4. Deploy migrations
5. Add context + schemas
6. Build LiveViews + routes
7. Add vote + comment actions
8. Add basic moderation UI
9. Add tests
10. Performance pass (explain + add missing indexes)

---

## 8) Testing plan (don’t be brave)

### Unit tests
- Changesets validate lengths and required fields
- Voting multi correctly updates cached scores
- Comment tree builder (pure function) works with deep nesting

### Integration tests (LiveView)
- Feed loads and paginates
- Create thread, appears in feed
- Create comment, appears in thread
- Vote toggles and updates UI/state

---

## 9) Performance checklist (before you brag on TikTok)

- Use keyset pagination for feeds if you expect real volume
- Preload only what you render
- Cache `comment_count` and `score`
- Cap comment depth and optionally collapse old threads by default
- Add `EXPLAIN ANALYZE` checks for feed queries

---

## 10) “Lessons + forum” integration (fits your app)

### Recommended integration pattern
- A lesson page can show:
  - “Discuss this lesson” link to a dedicated thread (auto-create on first click)
  - Or “Related threads” list

Implementation:
- Create `forum_thread_links` that maps lesson_id -> thread_id
- On lesson page:
  - Look up linked thread; if none exists, create a thread in a “Lessons” board and link it

This keeps forum general-purpose while still supporting course content.

---

## 11) Deliverables checklist (what you will actually implement)

### Database
- [ ] 5 core tables + indexes
- [ ] Optional link table for lessons

### Backend
- [ ] Forum context
- [ ] Vote transactional logic
- [ ] Moderation actions

### Frontend (LiveView + DaisyUI)
- [ ] Feed view + thread view
- [ ] Create post + create comment UI
- [ ] Vote UI
- [ ] Basic moderation UI

### Quality
- [ ] Tests
- [ ] Rate limiting
- [ ] Sanitization for markdown

---

## Appendix: Recommended decisions (stop overthinking these)

- IDs: UUID everywhere
- Comments: adjacency list (`parent_id`) now; recursive CTE later if needed
- Votes: single polymorphic votes table with unique constraint
- Deletes: soft-delete with “removed” flags
- Sorting: New + Top first; Hot later

