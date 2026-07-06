---
name: audit-2026-07-06-baseline
description: First audit of urielm (2026-07-06) — baseline findings, what was fixed, what was deferred
metadata:
  type: project
---

Baseline audit run 2026-07-06. Score: 5.5/10 → 6.5/10 after sprint.

**Why:** First-ever audit of this codebase; no prior quality tooling installed.
**How to apply:** Use as the starting point for all future audit rounds. Open items below are the next priorities.

## Fixed in Sprint 1

| Finding | Branch | Commits |
|---|---|---|
| `String.to_integer` crash risk (12 files) — no guard on integer parse | fix/parse-int | 65a219d, 10c754d |
| `try/rescue` anti-pattern in thread_live/video_live/blog_live | fix/rescue-helpers | 469802d, 4d80374 |
| `notify_thread_subscribers` N+1 → `Repo.insert_all` | fix/forum-notify | 8fc8b72, 396ef7b |
| `serialize_thread_card` N+1 (3 DB calls/thread) → bulk load | fix/rescue-helpers | 469802d |

**Regressions caught by Codex review (round 1):**
1. `{n, _}` loose parse accepted trailing junk (`"5abc"` → 5) — tightened to `{n, ""}` 
2. `get_thread/2` dropped `include_comments?` — broke ThreadLive comment rendering
3. `DateTime.truncate(:second)` broke `:utc_datetime_usec` column precision

## Still Open (deferred)

| File | Size | Issue | Why deferred |
|---|---|---|---|
| `lib/urielm/forum.ex` | ~1505L | God context: 12 concerns | Too large for parallel agents; needs solo dedicated pass |
| `lib/urielm_web/live/user_profile_live.ex` | ~1056L | God LiveView: 22+ handle_event | Needs Action module extraction; high surface area |
| `lib/urielm_web/live/video_live.ex` | ~992L | Large LiveView | Same pattern as user_profile |
| `lib/urielm_web/live/thread_live.ex` | ~897L | Large LiveView | Partially improved (nil-checks); still large |
| `lib/urielm/content.ex` | ~828L | Mixed context | Same pattern as forum.ex |
| `lib/urielm_web/live_helpers.ex` | ~412L | Grab-bag module | N+1 partially fixed; still a mixed-concern module |

## Quality Tools — First Run Baseline (2026-07-06)
- credo: 48 issues
- sobelow: 7 findings (not triaged yet)
- dialyxir: not yet run (slow)
- ex_dna: not yet run (slow)
