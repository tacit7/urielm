# Code Auditor Memory — urielm

## Audits
- [audit_2026_07_06_baseline.md](audit_2026_07_06_baseline.md) — Baseline audit 2026-07-06: 5.5/10 → 6.5/10 after sprint; 4 HIGH fixed (String.to_integer, rescue, notify N+1, live_helpers N+1); god modules deferred
- [audit_2026_07_07_round2.md](audit_2026_07_07_round2.md) — Round 2 (2026-07-07): get! crashes fixed in board/new_thread/chat/prompts/video live; connected? guards added to user_profile + video; ssr=false sweep; 5-agent team
- [audit_2026_07_07_round3.md](audit_2026_07_07_round3.md) — Round 3 (2026-07-07): connected? guards in notifications/latest/blog/prompt/lesson; get_comment! crash fixed; theme_colors complexity; dead code privatized

## Intentional Patterns (do not reflag)
- [reference_intentional_patterns.md](reference_intentional_patterns.md) — Vote divergence, atomic counters, Vote.target_id :string, admin try/rescue, bulk vs single serialize

## Workflow Patterns
- [feedback_codex_review.md](feedback_codex_review.md) — All fix branches require Codex LGTM before merge; Codex caught 3 regressions in round 1

- [audit_2026_07_07_round4.md](audit_2026_07_07_round4.md) — Round 4 (2026-07-07): thread_live 9x get_thread!/get_comment! fixed; nesting depth reduced in prompts_live, room_channel, mention_parser
- [audit_2026_07_07_round5.md](audit_2026_07_07_round5.md) — Round 5 (2026-07-07): XSS markdown fix, UrielmWeb.Markdown module, admin try/rescue replaced, admin connected? guards. Score ~8/10.
- [audit_2026_07_07_antipattern_round2.md](audit_2026_07_07_antipattern_round2.md) — Anti-pattern audit round 2 (2026-07-07, note 6255 on project 11): 0/13 round-1 anti-pattern findings fixed; video_live get_thread! and moderation_queue_live get_report! still crash despite looking fixed by round-5 commit 9e6e199 (which touched a different lookup in the same files). 18 new findings.

## Top Remaining Issues (as of round 5)
- `lib/urielm/forum.ex` — 1574L god context (12 concerns); solo pass needed
- `lib/urielm_web/live/user_profile_live.ex` — 1094L god LiveView, complexity 17
- `lib/urielm_web/live/board_live.ex` — mount complexity 27
- `lib/urielm/content.ex` — 828L mixed context
- XSS: `UrielmWeb.Markdown.sanitize_and_wrap` uses fragile regex; correct fix is HtmlSanitizeEx
