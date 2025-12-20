# Pagination Plan

This document describes the design, scope, and rollout plan for numbered pagination across the forum, replacing infinite scroll and standardizing on Flop + FlopPhoenix.

## Goals

- Forum-standard, numbered pagination (no infinite scroll)
- Fast navigation via LiveView `patch`
- Shareable, SEO-friendly URLs (page, sort, filters retained)
- Deterministic ordering to avoid drift/duplicates
- Consistent UI using Tailwind + daisyUI and FlopPhoenix components

## Scope

Primary views (done):
- Board listing (all/latest/top, unread, new)
- Saved threads
- Search results
- User profile: threads and comments

Secondary (optional next):
- Notifications index
- Moderation queue

## URL & Params

- `page` (1-based). Optional `page_size`.
- Board: `sort` (`latest` | `top` | `new`) and `filter` (`all` | `unread` | `new`).
- Search: `q` and `page`.
- User profile: `tab` (`threads` | `comments`) and `page`.

Behavior:
- Clamp out-of-range pages to 1..total_pages; show empty state or redirect via patch.
- Retain sort/filter in pager links.

## Sorting Rules (stable)

- Latest: `updated_at DESC, id DESC`
- New: `inserted_at DESC, id DESC`
- Top: `score DESC, inserted_at DESC, id DESC`
- Unread: left join `topic_reads` = NULL, order `inserted_at DESC, id DESC`

Tie-breakers: Always include `id DESC` in the order chain to guarantee stability.

## Data Layer

- Library: `flop` + `flop_phoenix`
- Threads: `Urielm.Forum.Thread` derives `Flop.Schema` with sortable fields.
- Comments (profile): paginated via Flop with a dedicated context function.
- Queries preload author/board to match UI needs.

Context pagination APIs:
- `paginate_threads(board_id, params)`
- `paginate_unread_threads(user_id, board_id, params)`
- `paginate_new_threads(board_id, params, opts \\ [])`
- `paginate_saved_threads(user_id, params)`
- `paginate_search_threads(query, params, opts \\ [])`
- `paginate_threads_by_author(author_id, params)`
- `paginate_comments_by_author(author_id, params)`

Return shape: `{:ok, {results, meta}} | {:error, meta}` (Flop)

## UI/UX

- LiveView navigation via `<.link patch={...}>` for fast page updates
- FlopPhoenix `<.pagination />` component for numbered pager
- Compact pager (current ± 2 pages) with automatic ellipsis rendering
- daisyUI classes for consistent look & accessibility
- Empty states when no items or out-of-range

## Performance & Indexes (next)

Add composite indexes to support filters/sorts at scale:
- `forum_threads(board_id, is_removed, updated_at, id)`
- `forum_threads(board_id, is_removed, inserted_at, id)`
- `forum_threads(board_id, is_removed, score, inserted_at, id)`
- `saved_threads(user_id, inserted_at)`
- `topic_reads(user_id, thread_id)`

Counts:
- Flop computes total pages via count. For very large datasets, we can consider count tuning.

## Edge Cases

- Invalid page → clamp to 1 and patch
- Empty query (search) → no results + empty state
- Threads/comments removed via soft delete: always filter `is_removed = false`

## Rollout Status

### Completed (2025-12-20)

**Pagination UI:**
- ✅ Custom pagination component with daisyUI styling (join/btn classes)
- ✅ Compact layout (current ± 2 pages with ellipsis)
- ✅ Applied to all primary views: Board, Search, Saved, UserProfile

**Stability improvements:**
- ✅ Added `:id` to Thread and Comment Flop.Schema sortable fields
- ✅ Added `id DESC` tie-breakers to all 6 pagination functions:
  - paginate_threads (via BoardLive params)
  - paginate_search_threads
  - paginate_unread_threads
  - paginate_new_threads
  - paginate_threads_by_author
  - paginate_comments_by_author
- ✅ paginate_saved_threads (already had tie-breaker)

**Performance:**
- ✅ Created migration `20251220164543_add_pagination_indexes.exs` with 5 composite indexes
- ⚠️ Migration ready but not applied (requires database superuser permissions)

**Removed:**
- ✅ Infinite scroll hooks/handlers from all views
- ✅ Flop.Phoenix import (using custom component)

### In Progress

**Testing:**
- ⏳ LiveView tests: pager render, navigation, params, empty states, clamping
- ⏳ Context tests: Flop query ordering and filtering

### Optional Next Steps

- Apply Flop pagination to notifications
- Apply Flop pagination to moderation queue
- Run pagination indexes migration in production (requires elevated DB permissions)

