# PR 1 — Param Safety + Not-Found Handling (Crash‑proof URLs)

This PR removes a class of easy-to-trigger LiveView crashes caused by unsafe parsing and bang-style getters on user-controlled params.

The goal is **not** to redesign routing or error pages — it’s to make “bad URLs” behave predictably (redirect/flash or not-found state) instead of crashing.

---

## Why this PR exists (context for juniors)

Today, multiple LiveViews do some version of:

- `page = Map.get(params, "page", "1") |> String.to_integer()`
- `Content.get_prompt_with_comments(String.to_integer(id))`

Problems:
- `String.to_integer/1` **raises** on invalid input (ex: `?page=lol`).
- Many context calls use `Repo.get!/2` internally, which **raises** when the record is missing or the ID is invalid.
- LiveViews don’t automatically turn these into nice 404s — you get a crash/disconnect.

We want:
- Invalid params → **safe defaults** (`page=1`)
- Missing records → **redirect + flash** (or a small not-found state)

---

## Goals
- No LiveView crashes from invalid `page`/`id` params.
- No direct `String.to_integer/1` on user input inside LiveViews.
- Prompt/Thread “not found” behaves consistently (no exceptions).
- Add regression tests that cover invalid params and missing resources.

## Non-goals
- No new 404 page design.
- No refactor of every context API (keep diffs small).
- No behavior changes to valid URLs.

---

## Files you will likely touch

### New helper
- Add: `lib/urielm_web/param.ex` (or similar name)

### LiveViews with unsafe parsing
- `lib/urielm_web/live/board_live.ex:handle_params/3`
- `lib/urielm_web/live/search_live.ex:handle_params/3`
- `lib/urielm_web/live/saved_threads_live.ex:handle_params/3`
- `lib/urielm_web/live/user_profile_live.ex:handle_params/3`
- `lib/urielm_web/live/references_live.ex:handle_params/3`
- `lib/urielm_web/live/prompt_live.ex:mount/3` (and comment delete)
- `lib/urielm_web/live/admin/trust_level_settings_live.ex:handle_event/3`

### Contexts where “get with comments” raises
- `lib/urielm/content.ex:get_prompt_with_comments/1`

### Tests to add/update
- Update: `test/urielm_web/live/forum_live_test.exs` (BoardLive invalid page)
- Add: `test/urielm_web/live/prompt_live_test.exs` (invalid prompt id / not found)
- Add/Update: `test/urielm_web/live/user_profile_live_test.exs` (invalid page param)

---

## Step-by-step implementation plan

### Step 0 — Inventory the crashy call sites

Run:
- `rg "String\\.to_integer\\(" lib/urielm_web/live`
- `rg "Repo\\.get!|Repo\\.get_by!" -n lib/urielm_web/live lib/urielm/content.ex lib/urielm/forum.ex`

Write down every LiveView that:
- parses `page` from query params
- parses numeric IDs from route params (`/prompts/:id`)

---

### Step 1 — Add a tiny safe param helper

Create `lib/urielm_web/param.ex`:

Recommended API (keep it boring):
- `int(params, key, default)` → safe integer parse with fallback
- `pos_int(params, key, default)` → same, but clamps to ≥ 1

Implementation sketch:

```elixir
defmodule UrielmWeb.Param do
  @spec int(map(), String.t(), integer()) :: integer()
  def int(params, key, default) do
    case Map.get(params, key) do
      nil -> default
      value when is_integer(value) -> value
      value when is_binary(value) ->
        case Integer.parse(value) do
          {i, ""} -> i
          _ -> default
        end
      _ -> default
    end
  end

  def pos_int(params, key, default) do
    int = int(params, key, default)
    if int < 1, do: default, else: int
  end
end
```

Why a helper? We have 3+ call sites and it prevents production crashes.

---

### Step 2 — Replace `String.to_integer/1` usages in LiveViews

Example conversions:

1) Query param page:

- Before:
  - `page = Map.get(params, "page", "1") |> String.to_integer()`
- After:
  - `page = UrielmWeb.Param.pos_int(params, "page", 1)`

2) Vote values from UI:

- If the value is always `"1"` or `"-1"` you can keep `String.to_integer/1`.
- If it can be manipulated, prefer the helper to avoid crashes.

---

### Step 3 — Stop crashing on missing prompts (fix `get_prompt_with_comments`)

Right now, `Content.get_prompt_with_comments/1` uses `Repo.get!/2`.

Minimal, safe change:

1) Update the function to support `raise?: false`:

```elixir
def get_prompt_with_comments(prompt_id, opts \\ []) do
  raise? = Keyword.get(opts, :raise?, true)
  prompt = if raise?, do: Repo.get!(Prompt, prompt_id), else: Repo.get(Prompt, prompt_id)
  case prompt do
    nil -> nil
    prompt -> ...
  end
end
```

2) In `PromptLive.mount/3`, parse the ID safely:
- If parsing fails → redirect with flash (e.g., “Prompt not found”).
- If parsing succeeds but prompt is `nil` → redirect with flash.

Avoid `try/rescue` in LiveViews if you can; handling “not found” as data is easier to test.

---

### Step 4 — Add regression tests

Add tests that prove we fixed the crash class:

1) **BoardLive invalid `page` doesn’t crash**
- Update `test/urielm_web/live/forum_live_test.exs`
- Add a test:
  - `live(conn, ~p"/forum/b/#{board.slug}?page=lol")` renders successfully

2) **PromptLive invalid ID redirects (no crash)**
- Add `test/urielm_web/live/prompt_live_test.exs`
- Cases:
  - `/prompts/not-an-int`
  - `/prompts/999999` (not found)
- Assert:
  - redirect happened (or rendered not-found state)
  - flash exists

3) **UserProfile invalid `page` doesn’t crash**
- Update/add `test/urielm_web/live/user_profile_live_test.exs`
- Use `?page=lol` and assert render succeeds.

---

## How to verify locally
- Run `mix test test/urielm_web/live/forum_live_test.exs`
- Run `mix test test/urielm_web/live/prompt_live_test.exs`
- Run `mix test test/urielm_web/live/user_profile_live_test.exs`
- Finish with: `mix precommit`

---

## Common pitfalls
- Don’t rebind variables inside `if`/`case` blocks (Elixir immutability rule).
- Don’t “fix” crashes by swallowing exceptions everywhere; prefer safe parsing + non-bang getters.
- Keep redirects consistent (same “not found” message/destination across similar pages).

