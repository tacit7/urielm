---
name: audit-2026-07-07-antipattern-round2
description: Elixir anti-pattern audit round 2 (2026-07-07) — 0/13 round-1 findings fixed, 18 new findings, note 6255
metadata:
  type: project
---

Anti-pattern audit round 2 run 2026-07-07 (separate track from the general code-quality audits above — follows the official Elixir anti-patterns guide categories: code/design/process/macro). Full report posted as note 6255 on project 11. Round 1 was note 6246.

## Key result: 0 of 13 round-1 findings were fixed

Notably, two of them look fixed but aren't:
- `video_live.ex:128` `Forum.get_thread!` still crashes on deleted thread — a nil-safe `Forum.get_thread/2` exists (added since round 1) but this call site was never switched to it.
- `moderation_queue_live.ex:43,63,83,103` `Forum.get_report!` still crashes on stale ids in approve/resolve/dismiss/add_notes — round-5 commit `9e6e199` fixed a *different* lookup in the same file (report target-title display) not these four action handlers. `Urielm.Forum` has no non-raising `get_report/1` at all, so this needs a new function added first.

**Do not assume these are fixed just because the file was touched in round 5** — verify the specific call sites.

## 18 new findings (not in round 1)

Code-related: missing `Forum.get_report/1`; `content.ex` triplicated count-update helpers (`update_prompt_likes_count/saves_count/comments_count`); `Repo.get!` inside those same side-effect updaters; N+1 in `forum.ex:536-543` `calculate_depth/2` (one query per ancestor, up to 8); dead-code XSS in `embed_parser.ex` (unescaped interpolation, not currently wired in); non-assertive `&&` truthiness in `board_live.ex`/`latest_live.ex` vote handlers; duplicated lock/unlock/pin/unpin scaffold in `thread_live.ex`; page-param parsing duplicated 6+ places; sign-in guard duplicated instead of using `LiveHelpers.with_auth/3`.

Design-related: non-atomic revision-number race in `forum.ex:1533-1557` `save_revision/7` (no transaction, no unique constraint); primitive-obsession target-type lists duplicated further (report/mention/thread_link/post_revision) vs the correct pattern already in `Engagement.Vote`/`Discussion`; `rate_limiter.ex` single-GenServer bottleneck for all forum writes; `live_helpers.ex` (429L) confirmed as genuine god-module (was "borderline" in round 1); blanket rescue in `seed_prompts.ex` mix task; inconsistent `{:error, ...}` value shape in `seed_vibecoding_post.ex`; missing `connected?()` guard in `notifications_live.ex` `handle_params`; boolean-obsession panel-state in `user_profile_live.ex` (5 booleans, should be one `:active_panel`); divergent duration-parsing between `user_profile_live.ex` and `admin/user_detail_live.ex` moderation actions.

No process or macro anti-patterns found (both GenServers correctly supervised; no custom macros beyond stock Phoenix `use` idioms).

## Confirmed correct (double-checked, not bugs)
- `user_socket.ex` Phoenix.Token auth (commit 36f562a) — fine.
- `Chat.list_room_messages/2` is actually bounded (limit 50) — round-1's "unbounded" note was inaccurate.
- `Accounts` prompt save/like functions (accounts.ex:203-299) reconfirmed dead — zero call sites outside tests.

## Method note
This round used 4 parallel sub-agent sweeps (content/context/schemas, channels/controllers/mix tasks, LiveViews, round-1 re-verification) plus a synthesis pass. Findings were cross-checked against actual file reads, not grep-only.
