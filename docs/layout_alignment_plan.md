# Layout Alignment Plan (Non-Forum)

Goal: Unify blog, posts, videos, courses/lessons, prompts, search, and home on a single shared layout (`Layouts.app`), while keeping forum on its own layout track. This avoids duplicate nav/flash logic and aligns with the project guideline for non-forum pages.

## Scope
- Included: `home_live`, `blog_live` (index/show), `prompts_live`, `prompt_live`, `courses_live`, `course_live`, `lesson_live`, `video_live`, `themes_live`, `search_live`, `user_profile_live`, and the `ShellLive` wrapper they currently sit under.
- Excluded: Forum pages (`forum_live`, `board_live`, `thread_live`, `new_thread_live`, `search_live` when forum-specific) will migrate separately to their dedicated layout later.

## Plan (ordered)
1) Establish the base: confirm `Layouts.app` is the canonical non-forum wrapper (navbar, flash, current_page). Keep forum layout separate.
2) Phase 1 – Shell migration:
   - Update `lib/urielm_web/live/shell_live.ex` to wrap its child content with `<Layouts.app flash={@flash} current_user={@current_user} current_page={...}>` instead of its custom container/navbar/flash.
   - Ensure `current_page` is passed through for navbar highlighting.
3) Phase 2 – Child LiveViews:
   - For each non-forum LiveView in scope, wrap the template body in `<Layouts.app ...>` and remove any duplicate nav/flash markup. Use meaningful `current_page` values (`"home"`, `"blog"`, `"prompts"`, `"videos"`, `"search"`, etc.).
   - Verify assigns: `@flash`, `@current_user`, and `@socket` are available; add when missing.
4) Phase 3 – Routing cleanup (optional):
   - Once children render with `Layouts.app`, you may remove the `ShellLive` indirection for non-forum routes and point routes directly at the LiveViews. Keep forum routes on their own shell/layout until its new design is ready.
5) Testing & QA:
   - Manually verify navbar/flash and active state on key routes: `/`, `/blog`, `/blog/:slug`, `/prompts`, `/prompts/:id`, `/courses`, `/courses/:course_slug/lessons/:lesson_slug`, `/videos/:slug`, `/search`, `/u/:username`.
   - Run existing LiveView tests covering these pages; add a smoke test if needed to assert navbar presence and no missing assigns.
   - Run `mix precommit` before merge.

## Notes
- Forum will retain its own layout (ForumLayout/Shell) until the new menu/page views are delivered.
- Keep `Layouts.app` as the single source for navbar/flash on non-forum pages to avoid drift.
