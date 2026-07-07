---
name: audit-2026-07-07-round3
description: Round 3 audit (2026-07-07) — connected? guards sweep, get_comment! crash, theme_colors complexity, dead code
metadata:
  type: project
---

Audit round 3 run 2026-07-07. Team: audit-round3-fixes (team 616), 3 agents.

## Fixed in Round 3

| Finding | Group | Commits |
|---|---|---|
| `connected?` guard missing in `notifications_live`, `latest_live` | A | dd7bb64 |
| `Content.get_comment!` crash in `prompt_live:delete_comment` — added `Content.get_comment/1` | B | e000e26 |
| `connected?` guard missing in `prompt_live`, `lesson_live` | B | e000e26 |
| `connected?` guard missing in `blog_live` | C | 1c58f3e |
| `theme_colors/1` complexity 37 (37-arm case) → `@theme_colors` module attr map + `Map.get` | C | 1c58f3e |
| `can_access_file?/2` dead public function in `files.ex` — made `defp` | C | 1c58f3e |

## Spawn behavior note (2026-07-07)
Groups B and C committed directly to the main worktree instead of their assigned worktrees. The merge step still worked (commits already on main). Root cause: agents used `project-path` as CWD for editing, not the worktree path. This is a spawn instruction issue — future agents need explicit CWD instructions or the worktree path set as project root.

## Credo baseline after round 3
- 9 refactoring opportunities (down from 48 in baseline — most fixed in sprint 1)
- Remaining: board_live mount complexity 27, user_profile_live mount complexity 17, themes_live 37→fixed, video_live nesting 5, prompts_live nesting 5, prompt_live nesting 4, forum.ex:create_comment nesting 4, room_channel nesting 4, mention_parser nesting 4

## Still Open After Round 3

| File | Issue | Why deferred |
|---|---|---|
| `thread_live.ex` 9x `get_thread!/get_comment!` in handle_event | H1 crash risk | IDs from socket.assigns; deferred 2 rounds — address in round 4 |
| `board_live.ex` mount complexity 27 | M3 | 115L mount, risky |
| `user_profile_live.ex` 1094L / complexity 17 | M1/M3 | God LiveView |
| `video_live.ex` nesting depth 5 | M3 | Inside connected? block; needs extraction |
| `prompts_live.ex` nesting depth 5 | M3 | toggle_save handler |
| `forum.ex:create_comment` nesting depth 4 | M3 | Complex validation chain |
| `room_channel.ex` nesting depth 4 | M3 | Channel join flow |
| `mention_parser.ex` nesting depth 4 | M3 | Recursive parsing |
