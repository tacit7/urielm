# PR 2 — Bulk Thread User State (Kill N+1 in Feeds)

This PR eliminates N+1 database queries when rendering thread lists by bulk-loading per-user state (saved/subscribed/unread/vote) in one pass.

It’s a high-impact maintainability + performance win: page rendering becomes predictable, and future features (more flags/badges) don’t silently add more per-thread queries.

---

## Why this PR exists (context for juniors)

`UrielmWeb.LiveHelpers.serialize_thread_list/2` maps threads into the shape used by `ThreadCard.svelte`.

Today, `serialize_thread_card/2` does *per-thread* lookups:
- `Forum.is_thread_saved?/2`
- `Forum.is_subscribed?/2`
- `Forum.is_thread_unread?/2`
- `Forum.get_user_vote/3`

If the page shows 20 threads, this can be **dozens of DB queries**.

We want to compute those flags in bulk:
- 1 query for saved thread IDs
- 1 query for subscription thread IDs
- 1 query for topic read IDs (or unread IDs)
- 1 query for votes

Then apply that data in memory while serializing.

---

## Goals
- Rendering a thread list does not perform per-thread state queries.
- All existing UI flags remain correct:
  - `is_saved`, `is_subscribed`, `is_unread`, `user_vote`
- Add regression tests for bulk state accuracy.

## Non-goals
- No change to the DB schema.
- No new caching layer.
- No redesign of thread list UI.

---

## Files you will likely touch
- `lib/urielm/forum.ex` (add bulk loader)
- `lib/urielm_web/live_helpers.ex` (use bulk loader in list serialization)
- Any LiveViews that serialize lists (if they don’t already go through `serialize_thread_list/2`)
- Tests:
  - Add: `test/urielm/forum_thread_user_state_test.exs` (or extend `forum_test.exs`)

---

## Step-by-step implementation plan

### Step 0 — Confirm where thread list serialization happens

Search:
- `rg "serialize_thread_list\\(" -n lib/urielm_web`
- `rg "serialize_thread_card\\(" -n lib/urielm_web`

The goal is: all list pages should go through one “bulk-aware” path.

---

### Step 1 — Add a bulk loader in the Forum context

Add a public function (name bikeshed is ok, keep it clear):

- `Forum.thread_user_state(user_id, thread_ids)`

Suggested return shape (easy to consume):

```elixir
%{
  saved: MapSet.t(binary_id()),
  subscribed: MapSet.t(binary_id()),
  read: MapSet.t(binary_id()),
  votes: %{binary_id() => -1 | 1}
}
```

Or a per-thread map:

```elixir
%{
  thread_id => %{is_saved: true, is_subscribed: false, is_unread: true, user_vote: 1}
}
```

Implementation notes:
- Only run the queries when `thread_ids != []`.
- `Vote.target_id` is `:binary_id`, so query votes with `target_type == "thread"` and `target_id in ^thread_ids`.
- For unread:
  - easiest: query `TopicRead` IDs and treat “not present” as unread
  - compute unread in-memory: `unread? = not MapSet.member?(read_ids, thread_id)`

---

### Step 2 — Update thread list serialization to use the bulk state

In `UrielmWeb.LiveHelpers`:

1) Keep `serialize_thread_card/2` for single-thread convenience.
2) Change `serialize_thread_list/2` so it:
   - preloads authors once (`Repo.preload(threads, :author)`)
   - bulk-loads state once (when `current_user`)
   - builds cards without DB calls

There are a few ways to do this without over-abstracting:

Option A (smallest change): add a new internal serializer:
- `serialize_thread_card(thread, current_user, state)`

Option B: build a “state map” and let the card read from it.

Avoid:
- Passing the socket into helpers.
- Creating “magic” global caches.

---

### Step 3 — Ensure correctness on key pages

Manually check at least:
- Board thread list
- Saved threads list
- User profile “threads” tab

Confirm for a logged-in user:
- Saved badge toggles correctly
- Subscribed badge toggles correctly
- Unread badge disappears after marking thread read (if implemented)
- Vote highlight reflects user vote

---

### Step 4 — Add tests for bulk state

Add an ExUnit test that:
1. Creates a user and 3 threads.
2. Saves thread A, subscribes to thread B, votes +1 on thread C, marks thread A read.
3. Calls `Forum.thread_user_state(user.id, [a.id, b.id, c.id])`.
4. Asserts:
   - only A in `saved`
   - only B in `subscribed`
   - votes map includes `c.id => 1`
   - unread logic is correct (A read means not unread)

This test is stable, fast, and protects the logic even if UI code changes later.

---

## How to verify locally
- Run the new test file (or updated `forum_test.exs`)
- Run relevant LiveView tests:
  - `mix test test/urielm_web/live/forum_live_test.exs`
  - `mix test test/urielm_web/live/saved_threads_live_test.exs` (if exists)
- Finish with: `mix precommit`

---

## Common pitfalls
- Don’t accidentally reintroduce per-thread queries by calling `Forum.is_thread_saved?/2` etc inside the map loop.
- Handle the `current_user == nil` case efficiently (skip DB state loading).
- Keep return types simple; junior devs should be able to debug this without opening 5 modules.

