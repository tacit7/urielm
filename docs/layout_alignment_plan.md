# Layout Alignment Plan (Non-Forum)

**STATUS: COMPLETED** (2025-12-25)

Goal: Unify blog, posts, videos, courses/lessons, prompts, search, and home on a single shared layout (`Layouts.app`), while keeping forum on its own layout track. This avoids duplicate nav/flash logic and aligns with the project guideline for non-forum pages.

## Changes Made

### Phase 1: Forum Routes Separated
- Moved `/forum`, `/forum/b/:board_slug`, `/forum/t/:thread_id`, `/forum/search` out of `:default` live_session
- Created new `:forum` live_session routing directly to LiveViews
- Removed forum-related child_module and page_name_for_action entries from ShellLive

### Phase 2: Layout Updates
- ForumLayout now accepts `flash` and `categories` attributes
- Added `<.flash_group>` to ForumLayout for flash message display
- Updated ForumLive, BoardLive to pass `flash={@flash}` to ForumLayout
- Added `<Layouts.flash_group>` to ThreadLive and SearchLive (they use simpler layouts)

### Phase 3: Cleanup
- Forum LiveViews (BoardLive, ThreadLive, SearchLive) now use params directly instead of child_params pattern
- Fixed outdated "load_more" test to use page-based pagination

## Scope
- Included: `home_live`, `blog_live` (index/show), `prompts_live`, `prompt_live`, `courses_live`, `course_live`, `lesson_live`, `video_live`, `themes_live`, `user_profile_live` - all routed through ShellLive which wraps with `Layouts.app`
- Forum pages: `forum_live`, `board_live`, `thread_live`, `search_live` - now use ForumLayout directly (no ShellLive wrapper)

## Testing
- Forum context tests: 95 tests, 0 failures
- Forum LiveView tests: 37 tests, 0 failures

## Notes
- Non-forum pages continue using ShellLive with Layouts.app (navbar at top)
- Forum pages now use ForumLayout directly (sidebar navigation, no top navbar)
- Authenticated pages (settings, chat, notifications) wrap themselves with Layouts.app
