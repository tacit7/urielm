# Refactoring Guide

This guide documents current refactoring patterns and helpers used across the Phoenix + LiveView forum code, focused on reducing duplication and keeping behavior stable.

## Goals
- DRY common logic (serialization, preloads, authorization).
- Keep LiveViews small; delegate mapping/formatting to helpers.
- Ensure stable ordering in paginated/time‑sorted queries.
- Avoid UX changes unless explicitly requested.

## Shared Helpers

Module: `lib/urielm_web/live_helpers.ex`

- Thread serialization
  - `serialize_thread_card(thread, current_user)` → map for thread card components
  - `serialize_thread_full(thread, current_user)` → extended payload for Thread page
  - `serialize_thread_list(threads, current_user)` → preload authors and map list
- Comment helpers
  - `build_comment_tree(comments, current_user)` → nested tree for CommentTree
  - `serialize_comment(comment, current_user)` → flat comment serializer (profile lists)
- UI utilities
  - `update_thread_in_stream(socket, stream, thread_id, current_user)` → refresh one card
  - `format_relative/1`, `format_short/1` → humanized time labels

Usage example (LiveView):
```elixir
threads = Forum.list_threads(board.id)
|> LiveHelpers.serialize_thread_list(socket.assigns.current_user)
|> then(&stream(socket, :threads, &1))

# After a vote
{:noreply, LiveHelpers.update_thread_in_stream(socket, :threads, thread_id, socket.assigns.current_user)}
```

## Forum Context Patterns

Module: `lib/urielm/forum.ex`

- Query preloads
  - `thread_preloads(query)` → `preload([:author, :board])` used across thread queries
- Authorization
  - `authorized?(user, owner_id)` → owner‑or‑admin check used in edit/remove functions
- Stable ordering
  - Always add an `id` tiebreaker for timestamp sorts: `desc: inserted_at, desc: id`
- Convenience
  - `list_categories_with_boards/1` → `Repo.preload(:boards)` wrapper for category listings

## LiveView Patterns

- Start templates with `<Layouts.app ...>`.
- Use `<.link navigate/patch>` for navigation/filters; avoid deprecated `live_redirect/live_patch`.
- Use streams for lists; sibling empty states should have a stable single block.
- Handle search/filter/page via URL and `handle_params/3` to keep views testable and linkable.
- Keep event handlers small:
  - Perform action in context
  - Refresh affected item (`update_thread_in_stream/4`) or re‑fetch minimal data
  - Show concise flash messages for feedback

## Examples

Stable order with tie‑breaker:
```elixir
from(t in Thread,
  where: t.board_id == ^board_id and t.is_removed == false,
  order_by: [desc: t.updated_at, desc: t.id]
)
```

Owner‑or‑admin authorization:
```elixir
if authorized?(user, resource.author_id) do
  # proceed
else
  {:error, :unauthorized}
end
```

## What’s Been Refactored

- Centralized serialization and comment tree building under `LiveHelpers`.
- Added `thread_preloads/1` and applied across forum queries.
- Added `authorized?/2` and used in edit/remove operations for threads and comments.
- Added `id` tie‑breakers to time‑ordered queries to prevent jitter between pages.
- Replaced ad‑hoc category board preloads with `list_categories_with_boards/1`.
- Simplified `UserProfileLive` to use URL params + patch navigation instead of incremental loaders.

## Next Candidates

- ~~Extract shared event patterns~~ **DONE**
  - ~~Added `with_auth/3` helper to LiveHelpers for authentication checks.~~
  - ~~Refactored 6 event handlers in thread_live.ex and board_live.ex.~~
  - ~~Reduced auth check duplication from ~10 lines to single helper call.~~
- Add base query builders (e.g., `author_threads_base/1`) if multiple call sites continue to share shape.

## Immediate Refactor TODOs

- ~~Centralize notification preloads in Forum~~ **DONE**
  - ~~Move all preloading to `Forum.list_notifications/2` and return fully shaped structs/maps.~~
  - ~~Remove `Repo.preload` from `NotificationsLive` (presentation only).~~
  - ~~Files: `lib/urielm/forum.ex`, `lib/urielm_web/live/notifications_live.ex`.~~

- ~~Repo-in-View cleanup (general)~~ **DONE**
  - ~~LiveViews should not call `Repo` directly. Expose preloaded data via context functions.~~
  - ~~Fixed `references_live.ex` - moved tag preloads to `Content.get_prompt!/1` and `Content.search_prompts/2`.~~
  - ~~Fixed `user_profile_live.ex` - removed duplicate comment preloads (already in Forum context).~~
  - ~~Fixed `moderation_queue_live.ex` - use preloaded `report.user` instead of `Repo.get`.~~

- ~~Struct preload helper~~ **DONE**
  - ~~Added `preload_thread_meta/1` helper to replace ad-hoc `Repo.preload([:author, :board])` on thread structs.~~
  - ~~Updated `get_thread!/1` to use the helper at lib/urielm/forum.ex:126.~~
  - ~~Placed alongside existing `thread_preloads/1` query helper at lib/urielm/forum.ex:1019.~~

- ~~Changeset error formatter~~ **DONE**
  - ~~Added `format_changeset_errors/1` to `LiveHelpers` at lib/urielm_web/live_helpers.ex:195.~~
  - ~~Replaced local implementations in `signup_email_live.ex` and `set_handle_live.ex`.~~
  - ~~Note: `thread_live.ex` kept its custom `format_errors/1` for report-specific error handling.~~

- ~~@impl annotations audit~~ **DONE**
  - ~~Added `@impl true` to all LiveView callbacks across 24 LiveView files.~~
  - ~~Total: 127 @impl annotations added for `mount/3`, `handle_event/3`, `handle_params/3`, `render/1`, etc.~~
  - ~~Provides compile-time verification that callbacks match behavior contracts.~~
