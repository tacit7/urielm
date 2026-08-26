---
name: audit-2026-07-07-round5
description: Round 5 audit (2026-07-07) — admin try/rescue, XSS markdown, connected? guards in admin LiveViews
metadata:
  type: project
---

Audit round 5 run 2026-07-07. Team: audit-round5-fixes (team 618), 3 agents.

## Fixed in Round 5

| Finding | Group | Commits |
|---|---|---|
| `try/rescue Ecto.NoResultsError` anti-pattern in `moderation_queue_live` — replaced with `Forum.get_thread/1` + `Forum.get_comment/1` nil-safe | A | 9e6e199 + 095e870 (merge) |
| XSS risk in markdown rendering: `Phoenix.HTML.raw(Earmark.as_html(user_input))` — created `UrielmWeb.Markdown` with script-tag stripping | B | fbd4e6e |
| `markdown_to_html/1` duplicated in 3 places — consolidated; `post_html.ex` now delegates to `UrielmWeb.Markdown.to_html/1` | B | fbd4e6e |
| `connected?` guard missing in `admin/user_management_live` and `admin/user_detail_live` | C | 22df787 |

## UrielmWeb.Markdown — new module

`lib/urielm_web/markdown.ex` created. Public API:
- `to_html/2` — strips `<script>` tags, returns `Phoenix.HTML.safe`
- `to_html!/2` — strict variant (Earmark raises on error)

`post_html.ex:markdown_to_html/1` now delegates to `UrielmWeb.Markdown.to_html/1`.

## Intentional pattern update

`Admin try/rescue` in `reference_intentional_patterns.md` entry is now **obsolete** — `moderation_queue_live` was fixed to use nil-safe variants. The entry should be removed or updated if anyone reviews the reference.

## Updated intentional patterns reference
- Removed: "Admin try/rescue in moderation_queue_live" — this was fixed in round 5

## Credo / quality baseline after round 5
- `connected?` guard now present in: user_profile, video, notifications, latest, blog, prompt, lesson, admin/user_management, admin/user_detail
- Remaining credo issues: board_live mount complexity 27, user_profile_live mount complexity 17

## Still Open After Round 5

| File | Issue | Why deferred |
|---|---|---|
| `lib/urielm/forum.ex` | 1574L god context (12 concerns) | Too large; needs dedicated solo pass |
| `lib/urielm_web/live/user_profile_live.ex` | 1094L god LiveView | Same; needs Action extraction |
| `lib/urielm_web/live/board_live.ex` | mount complexity 27 | 115L mount, risky |
| `lib/urielm/content.ex` | 828L mixed context | Same pattern as forum.ex |
| `XSS: sanitize_and_wrap` | `String.replace` script-strip is fragile vs nested tags | Full HTML sanitizer lib (e.g. HtmlSanitizeEx) is the correct fix |

## Score estimate after round 5
~8/10 (up from 7.5/10 at round 4 assessment). Remaining gap: god modules + fragile XSS sanitization.
