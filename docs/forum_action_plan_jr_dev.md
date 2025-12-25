# Forum Remediation Plan (JR Dev)

Detailed, ordered steps to address current forum issues. Tackle in sequence; keep changes small and test after each ticket.

## 1) Comment Parent Integrity
- Update `Forum.create_comment/3` to reject `parent_id` that doesn’t belong to the same thread (lookup parent, compare `thread_id`).
- Add unit test in `test/urielm/forum_test.exs` to assert cross-thread parent is rejected with `{:error, :invalid_parent}` (or similar).
- Ensure existing happy path remains (nested replies within thread).

## 2) Safe Board Pagination Params
- In `lib/urielm_web/live/board_live.ex`, replace `String.to_integer/1` parsing with a safe helper using `Integer.parse` (default to 1 on bad input or clamp to >=1).
- Add LiveView test (`forum_live_test.exs`) for `/forum/b/:slug?page=lol` to ensure the page renders and doesn’t crash.

## 3) Correct Forum Index Thread Counts
- Replace `thread_count` derived from `board.threads` length in `ForumLive` with a real count (aggregate query or preload counts).
- Add test: forum index shows non-zero count when threads exist; zero when none.

## 4) Block Thread Creation on Locked Boards
- In `Forum.create_thread/3` and `NewThreadLive` mount/submit, check `board.is_locked`; return friendly error/flash if locked.
- Add test that a locked board renders an error and does not insert a thread.

## 5) Eliminate N+1s for User State/Votes
- Add bulk loaders in `lib/urielm/forum.ex` (or helpers) to fetch, per set of thread IDs:
  - saved, subscribed, unread flags, and user votes.
  - comment saved state and votes.
- Refactor `LiveHelpers.serialize_thread_list/2`, `serialize_thread_full/2`, and `build_comment_tree/2` to use bulk results instead of per-item queries.
- Add perf/behavior tests:
  - Assert thread list serialization does not grow queries with item count (use `assert_queries` if available or refute multiple lookups).
  - Comment tree serialization returns correct saved/vote flags with bulk path.

## 6) Regression + Release Checklist
- Run targeted tests: `mix test test/urielm_web/live/forum_live_test.exs test/urielm/forum_test.exs`.
- Run `mix precommit` before merge.
- Update docs if user-facing behavior changes (errors on locked boards, counts).
