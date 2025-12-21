# PR 2 — Make Forum Thread Reads Pure (Stop Inflating `view_count`)

This PR removes hidden side effects from “read” functions (especially `Forum.get_thread!/…`) and makes view tracking explicit and correct in LiveView.

It is a **high-impact** change because it fixes:

- Incorrect `view_count` (currently inflated by normal interactions and by LiveView lifecycle)
- Unnecessary heavy DB work during “refresh” flows (vote/save/subscribe)

---

## Why this PR exists (context for juniors)

### LiveView mounts twice in real life

Phoenix LiveView typically runs:

1. **Disconnected mount** (server renders initial HTML over HTTP)
2. **Connected mount** (client connects over WebSocket and LiveView mounts again)

Any side effects inside `mount/3` (or inside functions called by `mount/3`) can happen **twice** per page view.

### Current bug: `Forum.get_thread!/1` increments view count as a side effect

In `lib/urielm/forum.ex`, `Urielm.Forum.get_thread!/1` currently:

- loads the thread
- loads all comments
- increments `view_count` (DB write!)
- returns the thread + comments

That means:

- A single visit can increment `view_count` **2 times** (disconnected + connected mount).
- Any later action that re-fetches the thread (vote/save/report/etc) also increments views.
- Admin moderation tooling may also increment views just by loading thread metadata.

That’s incorrect and makes `view_count` useless.

---

## Goals

- Make thread fetching **pure** (no view increment and no other side effects).
- Increment views **exactly once** per real page view (connected session only).
- Reduce wasted DB work by:
  - not loading comments when you only need the “thread card” data
  - avoiding “full thread” loads when updating a single card in a list stream
- Add tests that protect:
  - purity of `get_thread!/…`
  - correct view counting in `ThreadLive`
  - no view increments from vote/save actions

## Non-goals

- No major `Urielm.Forum` decomposition into multiple contexts (that’s a later PR).
- No UI changes.
- No changes to ranking, sorting, or pagination behavior.

---

## Files you will likely touch

- `lib/urielm/forum.ex`
- `lib/urielm_web/live/thread_live.ex`
- `lib/urielm_web/live_helpers.ex`
- `lib/urielm_web/live/admin/moderation_queue_live.ex` (and any other place loading a thread just for metadata)
- Tests:
  - `test/urielm/forum_test.exs`
  - `test/urielm_web/live/thread_live_test.exs`

---

## Step-by-step implementation plan

### Step 1 — Make “get thread” a pure read

In `lib/urielm/forum.ex`, refactor `get_thread!/1`.

#### Recommended API shape (minimal + safe)

Add options so callers can request only what they need:

- `include_comments?: boolean` (default `false`)

And remove view tracking entirely from the function.

Example shape (pseudocode):

```elixir
def get_thread!(id, opts \\ []) do
  include_comments? = Keyword.get(opts, :include_comments?, false)

  thread =
    Repo.get!(Thread, id)
    |> preload_thread_meta() # author + board

  if include_comments? do
    comments = list_comments_with_authors(id)
    Map.put(thread, :comments, comments)
  else
    thread
  end
end
```

Notes for juniors:

- Keep it boring: no `Repo.update_all` inside a read function.
- The thread returned should be stable and predictable.
- The `opts \\ []` default keeps existing call sites compiling, but you MUST update places that expect comments (see Step 2).

#### Add an explicit view counter function

Add a command-style function that does only one thing:

- `increment_thread_view_count(thread_id)`

Example:

```elixir
def increment_thread_view_count(thread_id) do
  from(t in Thread, where: t.id == ^thread_id)
  |> Repo.update_all(inc: [view_count: 1])
end
```

You can keep the existing private helper if you want, but make it public and clearly named.

---

### Step 2 — Update `ThreadLive` to fetch comments explicitly and track views correctly

In `lib/urielm_web/live/thread_live.ex`:

#### 2.1 Fetch comments explicitly

`ThreadLive.mount/3` uses `thread.comments` to build the comment tree.

After Step 1, you MUST change:

- `Forum.get_thread!(id)` → `Forum.get_thread!(id, include_comments?: true)`

Do the same in `refresh_thread/2`.

#### 2.2 Track views only when connected

Inside `mount/3`, after you’ve loaded the thread:

- Wrap view-count increment in:
  - `if connected?(socket) do ... end`

Example:

```elixir
if connected?(socket) do
  Forum.increment_thread_view_count(thread.id)
end
```

Why:

- Disconnected mount is just pre-rendering HTML.
- Connected mount is the “real” interactive session, so that’s where we count a view.

#### 2.3 Consider moving other “write” side effects behind `connected?/1` too

Currently, `ThreadLive.mount/3` also marks threads as read:

- `Forum.mark_thread_read/2`

This is idempotent (`on_conflict` replace), so correctness is fine, but it’s still a DB write.

Optional improvement (recommended):

- Only mark as read when connected:

```elixir
if connected?(socket) && socket.assigns.current_user do
  Forum.mark_thread_read(...)
end
```

---

### Step 3 — Make list/stream refreshes use lightweight thread fetches

Right now, `lib/urielm_web/live_helpers.ex` has:

- `update_thread_in_stream/4` which calls `Forum.get_thread!/1`

Once `Forum.get_thread!/…` is pure and defaults to **no comments**, this becomes safer automatically.

But you should also remove any unnecessary extra preloads (the helper currently does a `Repo.preload(:author)` on the returned thread).

Recommended update:

- Ensure the thread fetch used by stream updates returns:
  - `author` + `board` (needed for `serialize_thread_card/2`)
  - no comments

After Step 1, this likely means:

```elixir
thread = Forum.get_thread!(thread_id)
serialized = serialize_thread_card(thread, current_user)
stream_insert(...)
```

Why:

- Voting on a thread card shouldn’t fetch all comments.
- Saving/subscribing shouldn’t increment views or do extra work.

---

### Step 4 — Update “metadata-only” callers (moderation queue, etc.)

Search for `Forum.get_thread!(` usages:

```bash
rg -n "Forum\\.get_thread!\\(" lib
```

Audit each call site:

- If it only needs title/slug/author/board, use `Forum.get_thread!(id)` (no comments).
- If it needs comments (likely only Thread page), use `include_comments?: true`.

In particular:

- `lib/urielm_web/live/admin/moderation_queue_live.ex` should NOT load all comments for a thread.

This PR is a good time to ensure moderation tooling doesn’t accidentally mutate view counts.

---

## Tests to add/update

### 1) Unit test: `Forum.get_thread!/…` does not increment views

Add a test in `test/urielm/forum_test.exs` (or a new describe block):

1. Create a thread with `view_count = 0` (fixtures already exist).
2. Call `Forum.get_thread!(thread.id)` (and `include_comments?: true` if needed).
3. Reload from DB.
4. Assert `view_count` is unchanged.

Also add a small unit test for:

- `Forum.increment_thread_view_count/1` increments by 1

This is the easiest “guardrail” against future regressions.

### 2) LiveView test: viewing a thread increments views once

In `test/urielm_web/live/thread_live_test.exs`:

- Create a thread
- Assert starting `view_count`
- Call `live(conn, "/forum/t/:id")`
- Reload thread and assert `view_count` increased by 1

Important note:

- `Phoenix.LiveViewTest.live/2` may involve both initial HTTP render and WebSocket connect.
- Your final expectation should still be **+1** after the change (because we only increment when connected).

### 3) LiveView test: vote/save/subscribe do not increment views

Add a test:

1. Visit thread page (increment once)
2. Trigger an action that refreshes the thread (e.g. vote, save thread)
3. Reload thread and assert `view_count` did NOT change due to the action

This catches the “interaction inflation” bug.

---

## Manual QA checklist

1. Open a thread page in a browser:
   - Confirm `view_count` increases by 1 (not 2) per page refresh.
2. Click vote/save/subscribe buttons:
   - Confirm the UI updates
   - Confirm `view_count` does not change due to actions (check DB or admin panel if available)
3. Open moderation queue:
   - Confirm it does not change thread view counts

---

## Definition of Done (acceptance criteria)

- `Urielm.Forum.get_thread!/…` is a pure read and can optionally include comments.
- View counting is explicit and happens only in connected `ThreadLive` mount.
- Stream/list refreshes do not load comments and do not change view counts.
- Tests exist to prove:
  - thread fetches don’t mutate view_count
  - thread page view increments by 1
  - vote/save actions do not increment view_count
- `mix precommit` passes.

