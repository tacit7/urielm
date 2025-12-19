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

Implemented:
- Board listing: Flop pagination for all filters (all/latest/top/unread/new)
- Saved threads: Flop pagination
- Search results: Flop pagination
- User profile: Flop pagination for threads and comments

Removed:
- Infinite scroll hooks/handlers in these views

## Next Steps

- Add tie-breakers (`id DESC`) explicitly to all Flop orderings for perfect stability
- Add DB migration for indexes listed above
- (Optional) Replace any remaining manual pagers with `<.pagination />` (done for current scope)
- (Optional) Apply Flop to notifications and moderation queue for consistency

## Testing Plan

- LiveView tests: pager render, navigation updates, params retained, empty states, clamped pages
- Context tests: Flop queries return expected order/meta and honor filters

