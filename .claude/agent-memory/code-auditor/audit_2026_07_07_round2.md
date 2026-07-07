---
name: audit-2026-07-07-round2
description: Round 2 audit (2026-07-07) — get! crash fixes, connected? guards, ssr=false sweep, bulk serialize N+1
metadata:
  type: project
---

Audit round 2 run 2026-07-07. Team: audit-round2-fixes (team 615), 5 agents.

**Why:** Follow-up to baseline sprint 1. Connected? guards and mount crash risks were the top open items.

## Fixed in Round 2

| Finding | Group | Commits |
|---|---|---|
| `Forum.get_board!` crash in `board_live`, `new_thread_live` mount — added `Forum.get_board/1` | A | f94f3cd |
| `Chat.get_room!` crash in `chat_live` handle_params — added `Chat.get_room/1` | A | f94f3cd |
| `Content.get_prompt!` crash in `prompts_live` (2 sites) — added `Content.get_prompt/1` | B | c2330da |
| `connected?` guard missing in `user_profile_live` — dead render now skips all DB calls | C | 52e1450 |
| `serialize_thread_card` N+1 in `user_profile_live` — replaced with `serialize_thread_list` bulk | C | 52e1450 |
| `connected?` guard missing in `video_live` — dead render now skips DB calls | D | b2b2bc2 |
| `Forum.get_thread!/get_comment!` crash in `video_live` handle_event — added nil-returning variants | D | b2b2bc2 |
| `ssr={false}` missing on 32 `.svelte` callsites | F | a44e92b |
| `ssr={false}` misapplied to `<.input>` in `prompt_live` — removed | post-merge | c7c975c |

## Intentional Patterns (do NOT reflag)

- `Forum.cast_vote` (upsert) vs `Engagement.toggle_vote` (toggle): divergent behaviors are intentional. `thread_live` uses upsert; `live_helpers.handle_vote` uses toggle. Documented with comment.
- `Repo.update_all(inc: [comment_count: delta])`: atomic counter — correct pattern, not a bug.

## Still Open After Round 2

| File | Issue | Why deferred |
|---|---|---|
| `thread_live.ex:147,172,197,265,286,339,365,391,417` | 9x `get_thread!/get_comment!` in handle_event | IDs come from socket.assigns (server-set), not raw user input — lower crash risk; large change surface |
| `board_live.ex` mount complexity 27 | High cyclomatic complexity | 115L mount, risky extraction |
| `user_profile_live.ex` 1094L / complexity 17 | God LiveView | Same as baseline deferred |
