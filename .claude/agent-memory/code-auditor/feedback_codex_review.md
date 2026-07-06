---
name: feedback-codex-review
description: All fix branches require Codex LGTM before merge; round 1 caught 3 real regressions
metadata:
  type: feedback
---

All fix branches must go through Codex review (`--provider codex --model gpt-5.4`) before merging to main. Do not merge on my own read alone.

**Why:** Round 1 Codex review caught 3 real issues that visual inspection missed:
1. `{n, _}` loose Integer.parse pattern — accepted `"5abc"` as 5 across 19 callsites
2. `get_thread/2` missing `include_comments?` handling — broke ThreadLive comment rendering (blocking regression)
3. `DateTime.truncate(:second)` with `:utc_datetime_usec` column — test failure on precision mismatch

**How to apply:** After fix agents complete, spawn Codex review agents (`--provider codex --model gpt-5.4`) per branch. Wait for LGTM DMs before merging. If CHANGES NEEDED, fix and re-review before merging.
