# Code Quality & Maintainability Audit (Phoenix 1.8 / LiveView / LiveSvelte)

This audit focuses on **high-impact improvements with minimal refactors**. It prioritizes issues that:
- Cause production bugs/crashes
- Increase security or data integrity risk
- Make day-to-day changes slower (high coupling, duplication, unclear boundaries)

---

## 1) Top 10 Findings (ranked)

### 1. Unsafe integer parsing from user input can crash LiveViews
- **Severity:** High
- **Effort:** S (≤1h)
- **Location:** `lib/urielm_web/live/user_profile_live.ex:handle_params/3`
- **Problem:** Multiple LiveViews call `String.to_integer/1` on query/path params (e.g. `"page"`, `"id"`). Any non-integer input raises `ArgumentError`, causing a LiveView crash (500/disconnect) instead of a graceful fallback.
- **Fix (steps):**
  1. Introduce a small helper (e.g. `UrielmWeb.Param.int/3`) that uses `Integer.parse/1` and falls back to a default.
  2. Replace `String.to_integer/1` usages across LiveViews (search `String.to_integer(`) with the helper.
  3. Treat invalid values as the default (`page=1`, etc) and keep UX stable.
- **Regression test idea:** Add a LiveView test that hits a page with `?page=lol` (and another with `?page=-1`) and asserts it renders (no crash) and behaves like `page=1`.

### 2. Not-found resources frequently become 500s (bang getters in LiveViews)
- **Severity:** High
- **Effort:** S (≤1h)
- **Location:** `lib/urielm_web/live/prompt_live.ex:mount/3`
- **Problem:** Several LiveViews call `get_*!` functions (or parse IDs) without handling not-found/invalid IDs. For example, `PromptLive.mount/3` calls `Content.get_prompt_with_comments(String.to_integer(id))` without guarding parse errors or `nil`/not-found. This turns normal “bad URL” cases into crashes.
- **Fix (steps):**
  1. Add non-bang context functions for the web layer (`get_prompt/1`, `get_thread/1`, etc) that return `nil` instead of raising (or wrap existing getters with `try/rescue` in the LiveView as a short-term fix).
  2. In `mount/3` / `handle_params/3`, redirect to a safe route with an error flash when the record is missing (or render a dedicated “not found” state).
  3. Combine with Finding #1 so invalid IDs never raise.
- **Regression test idea:** Add a test that visits `/prompts/not-an-int` (or `/prompts/999999`) and asserts a redirect + flash instead of a LiveView crash.

### 3. `serialize_thread_card/2` performs N+1 queries (saved/subscribed/unread/vote)
- **Severity:** High
- **Effort:** M (≤1d)
- **Location:** `lib/urielm_web/live_helpers.ex:serialize_thread_card/2`
- **Problem:** `serialize_thread_card/2` calls `Forum.is_thread_saved?/2`, `Forum.is_subscribed?/2`, `Forum.is_thread_unread?/2`, and `Forum.get_user_vote/3`. When used for thread lists (board feed, profile threads, etc) this becomes **O(N)** DB queries and will bottleneck the forum at modest traffic.
- **Fix (steps):**
  1. Add a bulk loader in `Urielm.Forum` (e.g. `thread_user_state(user_id, thread_ids)`) returning maps/sets for saved/subscribed/unread/votes.
  2. Update `serialize_thread_list/2` to call the bulk loader once and pass the per-thread state into serialization (or build a `serialize_thread_list/3` variant).
  3. Keep `serialize_thread_card/2` as a convenience for single-thread use, but avoid calling it in a loop without preloaded state.
- **Regression test idea:** Add a context test for `thread_user_state/2` to ensure correct flags/votes across multiple threads. (Optionally add a telemetry-based assertion to confirm query count is bounded.)

### 4. Generated SSR output (`priv/svelte/server.js`) is committed and churns heavily
- **Severity:** Medium
- **Effort:** M (≤1d)
- **Location:** `priv/svelte/server.js:generated artifact`
- **Problem:** `priv/svelte/server.js` is a build output that shows up as a top “most-changed” file. Committing generated artifacts increases merge conflicts, hides meaningful diffs, and makes it unclear whether source or build output is the canonical truth.
- **Fix (steps):**
  1. Decide the deployment model: either build SSR artifacts in CI/deploy, or explicitly document why they’re committed.
  2. If building in CI/deploy, add `priv/svelte/` to `.gitignore`, remove committed artifacts, and ensure `mix assets.deploy` (or deploy script) generates them.
  3. Add a short `docs/DEPLOYMENT.md` note describing the SSR build step and required Node version.
- **Regression test idea:** Add a CI/deploy check that runs `mix assets.deploy` and asserts `priv/svelte/server.js` is produced (and that git stays clean afterward).

### 5. `Urielm.Forum` is a god context with many responsibilities
- **Severity:** Medium
- **Effort:** M (≤1d)
- **Location:** `lib/urielm/forum.ex:Urielm.Forum`
- **Problem:** At ~1300 LOC, `Urielm.Forum` mixes categories/boards/threads/comments/votes/saves/subscriptions/notifications/reads/moderation. This increases coupling, makes navigation harder for juniors, and raises the cost of safe change.
- **Fix (steps):**
  1. Extract **internal** modules without changing the public API (e.g. `Urielm.Forum.Threads`, `Urielm.Forum.Comments`, `Urielm.Forum.Notifications`) and delegate from `Urielm.Forum`.
  2. Start with low-risk moves: query builders and pagination helpers.
  3. Keep public function signatures stable so call sites and tests don’t churn.
- **Regression test idea:** Existing `test/urielm/forum_test.exs` should remain green; add a small test ensuring extracted modules are not used directly from the web layer (enforce boundary).

### 6. `ThreadLive` is very large; behavior changes are high-risk
- **Severity:** Medium
- **Effort:** M (≤1d)
- **Location:** `lib/urielm_web/live/thread_live.ex:UrielmWeb.ThreadLive`
- **Problem:** `ThreadLive` (~950 LOC) contains many unrelated concerns: loading, voting, moderation actions, reporting, subscriptions, comment editing, notification settings, etc. Large LiveViews tend to accumulate “just one more event” until they become fragile.
- **Fix (steps):**
  1. Extract pure, testable helpers for repeated state refresh and authorization error mapping (keep LiveView as the orchestrator).
  2. Group related handlers into private functions (`handle_comment_*`, `handle_thread_*`) to reduce cognitive load.
  3. Prefer context functions for domain operations; keep LiveView focused on assigns/redirects/streams.
- **Regression test idea:** Expand `test/urielm_web/live/thread_live_test.exs` to cover one “golden path” per capability (vote, report, subscribe) using element IDs/data-testid, not raw HTML string matching.

### 7. Auth behavior is split and inconsistent between Plug and LiveView layers
- **Severity:** Medium
- **Effort:** S (≤1h)
- **Location:** `lib/urielm_web/plugs/auth.ex:require_authenticated_user/1`
- **Problem:** Controllers use `UrielmWeb.Plugs.Auth` (redirect to `/` with flash), while LiveViews use `UrielmWeb.UserAuth` (redirect to `/signup` without flash). This leads to inconsistent UX and makes it easy for engineers to implement auth checks differently depending on entry point.
- **Fix (steps):**
  1. Decide a canonical behavior (recommended: redirect to `/signup` with a clear flash + optional `return_to`).
  2. Align `Plugs.Auth` and `UserAuth` to the same redirect target and message.
  3. Document the rule in `docs/CODE_GUIDELINES.md` (controllers vs LiveView).
- **Regression test idea:** Add/extend an auth controller test and a LiveView test verifying unauthenticated access redirects consistently (same destination + flash).

### 8. OAuth user creation uses exceptions inside transactions (hard to recover/test)
- **Severity:** Medium
- **Effort:** M (≤1d)
- **Location:** `lib/urielm/accounts.ex:create_user_from_oauth/4`
- **Problem:** `create_user_from_oauth/4` uses `Repo.transaction/1` with `{:ok, user} = Repo.insert(...)` and `Repo.insert!()` for identity creation. Any unexpected validation or DB error raises, making failures harder to handle cleanly and harder to test.
- **Fix (steps):**
  1. Convert the flow to `Ecto.Multi` returning `{:ok, user}` or `{:error, failed_step, changeset, _changes}`.
  2. Make the controller handle the error tuple and show a user-friendly failure.
  3. Add logging/telemetry for failures to support debugging.
- **Regression test idea:** Add an `Accounts` test that forces a constraint violation (e.g., duplicate OAuth identity) and asserts you get a structured error tuple rather than an exception.

### 9. `Urielm.HTTP.ReqClient` exists but is unused and `:req` is not a direct dependency
- **Severity:** Low
- **Effort:** S (≤1h)
- **Location:** `lib/urielm/http/req_client.ex:Urielm.HTTP.ReqClient`
- **Problem:** The repo has an opinionated Req wrapper but does not include `:req` in `mix.exs`, and nothing calls it. This is confusing to juniors and creates “dead code” paths that may break at runtime if adopted later.
- **Fix (steps):**
  1. Either add `{:req, "~> 0.5"}` to `mix.exs` and adopt `ReqClient` for real callers, **or** remove the module until needed.
  2. If keeping it, add a tiny usage example to `docs/CODE_GUIDELINES.md`.
  3. Add a smoke test for `ReqClient.new/1` so compilation/runtime expectations stay aligned.
- **Regression test idea:** Add a unit test asserting `ReqClient.new/1` returns a `%Req.Request{}` (skipped if Req is not present).

### 10. Test coverage is thin for high-churn LiveViews (and some assertions are brittle)
- **Severity:** Medium
- **Effort:** M (≤1d)
- **Location:** `lib/urielm_web/live/references_live.ex:render/1`
- **Problem:** Key surfaces like References/Prompts/Lessons have little or no LiveView test coverage. Some tests assert on raw HTML substrings, which are brittle during UI iteration.
- **Fix (steps):**
  1. Add LiveView smoke tests for `ReferencesLive`, `PromptLive`, and `LessonLive` that assert presence of stable IDs/forms (not strings).
  2. Add stable DOM IDs (or `data-testid`) on key elements to make tests resilient.
  3. Prefer `has_element?/2` and `element/2` interactions over `html =~ "text"`.
- **Regression test idea:** For each LiveView above, add a basic “renders + key controls exist” test, then one interaction test (e.g., open prompt modal, submit comment, change dock tab).

---

## 2) Duplication Map

### Repeated patterns (and where)

1. **Unsafe integer parsing (`String.to_integer/1`)**
   - Occurs in: `board_live.ex`, `search_live.ex`, `saved_threads_live.ex`, `user_profile_live.ex`, `references_live.ex`, `prompt_live.ex`, `thread_live.ex`, `admin/trust_level_settings_live.ex`
   - Recommendation: extract a shared safe parser (`UrielmWeb.Param.int/3`) because it’s used 3+ times and prevents crashes.

2. **Auth checks in event handlers**
   - Pattern: `case socket.assigns.current_user do nil -> ...; user -> ... end`
   - Occurs across many LiveViews; partially addressed via `UrielmWeb.LiveHelpers.with_auth/3` (used in `thread_live.ex`, `board_live.ex`)
   - Recommendation: expand `with_auth/3` usage where it keeps handlers smaller; avoid making it too “magical”.

3. **“Refresh after mutation” pattern**
   - Pattern: perform action → re-fetch resource → reassign (e.g., comments on prompts/lessons)
   - Occurs in: `prompt_live.ex`, `lesson_live.ex`, `thread_live.ex`
   - Recommendation: only extract if a third near-identical use appears; otherwise keep local but standardize naming (`refresh_*` helpers).

4. **Thread query shapes (`preload [:author, :board]` + stable ordering)**
   - Repeated across multiple Forum queries (threads, saved threads, subscriptions, unread threads)
   - Recommendation: extraction pays off if you add more feeds; otherwise keep `thread_preloads/1` + `preload_thread_meta/1` as the canonical helpers.

5. **UI test selectors**
   - Pattern: mixing `data-testid`, IDs, and raw HTML string assertions
   - Recommendation: standardize on stable IDs for key elements and `has_element?/2` for tests; only add `data-testid` when IDs are not appropriate.

---

## 3) Refactor Plan (3 PRs max)

### PR 1 — Param Safety + Not-Found Handling (Crash-proof URLs)
- **Scope:** Replace unsafe parsing, add graceful handling for invalid/missing IDs across LiveViews.
- **Acceptance criteria:**
  - No LiveView uses `String.to_integer/1` directly on params.
  - Visiting pages with invalid `?page=` or invalid IDs does not crash; user sees redirect/flash or a not-found state.
  - New tests cover at least 2 invalid-param cases.

### PR 2 — Bulk Thread User State (Kill N+1 in feeds)
- **Scope:** Bulk-load saved/subscribed/unread/votes for thread lists and update serialization paths.
- **Acceptance criteria:**
  - `serialize_thread_list/2` does not perform per-thread DB checks for user state.
  - New context test verifies bulk state accuracy across multiple threads.
  - Board and profile pages still show correct saved/subscribed/unread/vote UI states.

### PR 3 — Deployment Hygiene: Stop Committing Generated SSR Bundles
- **Scope:** Treat `priv/svelte/*` as build output and generate during deploy (or document why it’s committed).
- **Acceptance criteria:**
  - Clear documented policy in `docs/DEPLOYMENT.md` (or an existing deploy doc).
  - If uncommitted: `priv/svelte/` is git-ignored and generated by `mix assets.deploy` or deploy script.
  - Deploy process produces working SSR assets without manual steps.

