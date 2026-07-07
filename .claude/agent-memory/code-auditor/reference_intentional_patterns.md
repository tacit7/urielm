---
name: reference-intentional-patterns
description: urielm patterns that look like bugs but are intentional — skip in future audits
metadata:
  type: reference
---

# Intentional Patterns — Do Not Reflag

## Vote behavior divergence
`Forum.cast_vote` (upsert — always sets value) vs `Engagement.toggle_vote` (toggle — removes on same value). Both exist intentionally:
- `thread_live.ex` uses `cast_vote` (forum-specific sticky voting)
- `LiveHelpers.handle_vote` uses `toggle_vote` (generic toggle for prompts, videos)
Documented with inline comment. Not a bug.

## Atomic comment counter
`Repo.update_all(inc: [comment_count: delta])` in `forum.ex` — intentional atomic increment/decrement. Not an N+1 or missing transaction.

## `Vote.target_id` is `:string` not `:binary_id`
The DB column is `text` (migration 20260307154029). Integer IDs (prompts, videos) are stored as strings. Correct. Do not change to `:binary_id`.

## Admin `try/rescue` in `moderation_queue_live.ex`
Lines 281, 292: `try do Forum.get_thread!(report.target_id) rescue` — intentional for admin context where target may be hard-deleted. Acceptable here; normal handlers use nil-returning variants.

## `serialize_thread_full/2` bulk path
`live_helpers.ex` uses `load_bulk_thread_state` + `serialize_thread_card_bulk` for thread lists. The non-bulk `serialize_thread_card/2` still exists for single-thread serialization. Both are correct — don't consolidate.
