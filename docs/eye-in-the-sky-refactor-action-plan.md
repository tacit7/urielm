# Eye in the Sky Web: Refactor Action Plan

This document is your step-by-step guide for refactoring parts of the Eye in the Sky web app.
Follow the tasks in order. Do not skip steps, and commit in small chunks.

---

## High-Level Goals

1. Make session data consistent between database sessions and filesystem sessions.
2. Provide a dedicated “view model” for sessions instead of mixing raw structs and maps.
3. Use a real “updated at / last activity” timestamp instead of pretending `started_at` is updated.
4. Move filesystem discovery and merge logic out of the LiveView and into a context module.
5. Clean up the navbar theme-toggle JavaScript so it lives in assets instead of inline script.
6. Add basic tests around the new code.

You will mostly be working in:

- `lib/eye_in_the_sky_web_web/live/agent_live/index.ex`
- `lib/eye_in_the_sky_web/sessions.ex`
- `lib/eye_in_the_sky_web/agents/agent.ex` (or wherever the Agent schema lives)
- `lib/eye_in_the_sky_web_web/components/navbar.ex`
- `assets/js/app.js` (and a new JS file)
- Test files under `test/`

---

## Task 0: Setup & Safety

**Goal:** Make sure you are working safely on a separate branch.

1. Create a new git branch:

   ```bash
   git checkout -b refactor-session-overview
   ```

2. Ensure tests pass before you touch anything:

   ```bash
   mix test
   ```

3. Run the formatter so later diffs are clean:

   ```bash
   mix format
   ```

If tests do not pass here, stop and fix that first or ask for help.

---

## Task 1: Introduce a Proper “Last Activity” Timestamp

Right now the UI label says “Updated:” but uses `started_at`. We want a real timestamp that represents the latest activity on the session.

### 1.1 Add a new column to `sessions`

1. Generate a migration:

   ```bash
   mix ecto.gen.migration add_last_activity_to_sessions
   ```

2. In the generated migration file (under `priv/repo/migrations/`), add:

   ```elixir
   def change do
     alter table(:sessions) do
       add :last_activity_at, :utc_datetime_usec
     end

     # Optional: backfill existing rows so they are not NULL
     execute """
     UPDATE sessions
     SET last_activity_at = COALESCE(ended_at, started_at)
     WHERE last_activity_at IS NULL
     """
   end
   ```

3. Run the migration:

   ```bash
   mix ecto.migrate
   ```

### 1.2 Update the Session schema

1. Open the `Session` schema (likely in `lib/eye_in_the_sky_web/sessions/session.ex`).
2. Add the new field:

   ```elixir
   schema "sessions" do
     # existing fields...
     field :last_activity_at, :utc_datetime_usec
     # ...
   end
   ```

3. Ensure the changeset allows the field to be set:

   ```elixir
   def changeset(session, attrs) do
     session
     |> cast(attrs, [..., :last_activity_at])
     |> validate_required([...])
   end
   ```

   Keep required fields list unchanged unless specifically requested.

### 1.3 Make last_activity_at default to started_at on create

In the `Sessions.create_session/1` function (in `lib/eye_in_the_sky_web/sessions.ex`):

1. Before building the changeset, ensure `:last_activity_at` is present.

   Example pattern:

   ```elixir
   def create_session(attrs \ %{}) do
     now = DateTime.utc_now() |> DateTime.truncate(:second)
     attrs = Map.put_new(attrs, "started_at", now)
     attrs = Map.put_new(attrs, "last_activity_at", attrs["started_at"] || now)

     %Session{}
     |> Session.changeset(attrs)
     |> Repo.insert()
   end
   ```

Adjust this logic if `started_at` is already set somewhere else. The goal is: if no explicit `last_activity_at` is provided, it should default to `started_at`.

### 1.4 Update activity when something happens

We want `last_activity_at` to bump when there is new activity (logs, messages, tasks, etc.). For this first pass, keep it conservative:

1. In `Sessions.end_session/1`, set both `ended_at` and `last_activity_at`:

   ```elixir
   def end_session(%Session{} = session) do
     now = DateTime.utc_now() |> DateTime.truncate(:second)
     update_session(session, %{ended_at: now, last_activity_at: now})
   end
   ```

2. Later we can add “bump” logic in other contexts (e.g. when messages or logs are appended) but that is out of scope for this refactor. Just keep in mind the field exists for future use.

### 1.5 Use last_activity_at in the UI

In `AgentLive.Index` (`lib/eye_in_the_sky_web_web/live/agent_live/index.ex`):

1. Find where the “Updated:” label is rendered. It currently uses `session.started_at`.

2. Replace that usage with `session.last_activity_at` if available, otherwise fall back:

   ```elixir
   <span title={format_datetime_full(session.last_activity_at || session.started_at)}>
     {relative_time(session.last_activity_at || session.started_at)}
   </span>
   ```

3. Do **not** change the label text; it should still say `Updated:` but now it will be honest.

---

## Task 2: Introduce a Session View Model Struct

Right now the LiveView mixes DB `Session` structs and “virtual session” maps created from filesystem data. We want a single unified struct for rendering.

### 2.1 Create a new module for the view model

Create a new file:

- `lib/eye_in_the_sky_web/sessions/session_view.ex`

Add a struct and helper functions:

```elixir
defmodule EyeInTheSkyWeb.Sessions.SessionView do
  @moduledoc """
  Presentation-layer struct for session cards in the Agents overview.

  This unifies DB-backed sessions and filesystem-only sessions into a
  single shape that the LiveView can render without conditionals.
  """

  alias EyeInTheSkyWeb.Sessions.Session
  alias EyeInTheSkyWeb.Agents.Agent

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t() | nil,
          started_at: NaiveDateTime.t() | DateTime.t() | nil,
          last_activity_at: NaiveDateTime.t() | DateTime.t() | nil,
          ended_at: NaiveDateTime.t() | DateTime.t() | nil,
          archived_at: NaiveDateTime.t() | DateTime.t() | nil,
          agent_id: integer() | nil,
          agent_status: String.t() | nil,
          agent_description: String.t() | nil,
          project_name: String.t() | nil,
          git_worktree_path: String.t() | nil,
          source: :db | :filesystem
        }

  defstruct [
    :id,
    :name,
    :started_at,
    :last_activity_at,
    :ended_at,
    :archived_at,
    :agent_id,
    :agent_status,
    :agent_description,
    :project_name,
    :git_worktree_path,
    :source
  ]

  @spec from_db(Session.t(), Agent.t()) :: t()
  def from_db(%Session{} = session, %Agent{} = agent) do
    %__MODULE__{
      id: session.id,
      name: session.name,
      started_at: session.started_at,
      last_activity_at: session.last_activity_at || session.started_at,
      ended_at: session.ended_at,
      archived_at: session.archived_at,
      agent_id: agent.id,
      agent_status: agent.status,
      agent_description: agent.description,
      project_name: agent.project_name,
      git_worktree_path: agent.git_worktree_path,
      source: :db
    }
  end

  @spec from_filesystem(map()) :: t()
  def from_filesystem(fs_session) do
    %__MODULE__{
      id: fs_session.session_id,
      name: "Discovered session",
      started_at: NaiveDateTime.from_erl!(fs_session.last_modified),
      last_activity_at: NaiveDateTime.from_erl!(fs_session.last_modified),
      ended_at: nil,
      archived_at: nil,
      agent_id: nil,
      agent_status: "discovered",
      agent_description: "Session from #{Path.basename(fs_session.project_path)}",
      project_name: Path.basename(fs_session.project_path),
      git_worktree_path: fs_session.project_path,
      source: :filesystem
    }
  end
end
```

Adjust types and imports as necessary to match your actual `Session` and `Agent` modules.

### 2.2 Switch merging logic to use SessionView

In `AgentLive.Index`, instead of returning raw `Session` structs or maps, return the `SessionView` struct.

1. Replace the existing `create_virtual_session/1` to delegate to `SessionView.from_filesystem/1`.

2. When you have a DB session with preloaded agent, transform them via `SessionView.from_db/2` before inserting into the list.

By the end of this task, the LiveView should work only with `%SessionView{}` values for `@sessions`.

### 2.3 Update the template to match SessionView fields

In `AgentLive.Index` render function:

1. Anywhere you reference `session.agent.*`, change to the corresponding flattened fields;

   - `session.agent.id` → `session.agent_id`
   - `session.agent.status` → `session.agent_status`
   - `session.agent.description` → `session.agent_description`
   - `session.agent.project_name` → `session.project_name`
   - `session.agent.git_worktree_path` → `session.git_worktree_path` (if used)

2. Update any conditionals that depend on agent status or source.

   Example:

   ```elixir
   status_color =
     cond do
       session.agent_status == "discovered" -> "border-l-info"
       is_nil(session.ended_at) -> "border-l-success"
       true -> "border-l-ghost"
     end
   ```

   And:

   ```elixir
   if session.agent_id do
     phx-click={JS.navigate(~p"/agents/#{session.agent_id}")}
   end
   ```

3. Make sure the badge rendering uses `session.agent_status` instead of `session.agent.status`.

---

## Task 3: Move Filesystem Discovery & Merge Logic into a Context Module

We do not want LiveView directly doing IO discovery and reconciliation.

### 3.1 Create a dedicated module

Create a new file:

- `lib/eye_in_the_sky_web/sessions/discovery.ex`

Add something like:

```elixir
defmodule EyeInTheSkyWeb.Sessions.Discovery do
  @moduledoc """
  Functions for merging DB sessions with Claude filesystem sessions.
  """

  alias EyeInTheSkyWeb.Sessions
  alias EyeInTheSkyWeb.Sessions.SessionView

  def list_session_views(opts \ []) do
    db_sessions = Sessions.list_sessions_with_agent(opts)

    db_views =
      Enum.map(db_sessions, fn session ->
        # assuming session.agent is preloaded
        SessionView.from_db(session, session.agent)
      end)

    fs_sessions = EyeInTheSkyWeb.Claude.SessionReader.discover_all_sessions()

    merge_db_and_fs(db_views, fs_sessions)
  end

  defp merge_db_and_fs(db_views, fs_sessions) do
    db_ids = MapSet.new(db_views, & &1.id)

    fs_views =
      Enum.map(fs_sessions, fn fs_session ->
        if MapSet.member?(db_ids, fs_session.session_id) do
          nil
        else
          SessionView.from_filesystem(fs_session)
        end
      end)
      |> Enum.reject(&is_nil/1)

    db_views ++ fs_views
  end
end
```

Adjust function names as needed. The idea is: the LiveView will just ask this module for session views.

### 3.2 Update AgentLive.Index to use the new context

In `AgentLive.Index`:

1. Add an alias:

   ```elixir
   alias EyeInTheSkyWeb.Sessions.Discovery, as: SessionDiscovery
   ```

2. Replace `Sessions.list_sessions_with_agent()` + `discover_and_merge_sessions` with a call to the new function:

   ```elixir
   defp load_sessions(socket) do
     views = SessionDiscovery.list_session_views()

     sessions =
       views
       |> filter_sessions_by_status(socket.assigns.session_filter)
       |> filter_sessions_by_search(socket.assigns.search_query)
       |> sort_sessions(socket.assigns.sort_by)

     assign(socket, :sessions, sessions)
   end
   ```

3. Remove unused helpers that are now redundant (old `discover_and_merge_sessions/1`, `create_virtual_session/1` if they are no longer used).

---

## Task 4: Fix Navbar Theme Toggle JavaScript

The navbar currently has inline `<script>` in the LiveComponent. We want that JS to live in `assets/js` and be attached via a hook or imported logic.

### 4.1 Create a new JS module for theme handling

Create a new file:

- `assets/js/theme_toggle.js`

Add:

```js
const darkThemes = new Set([
  "abyss", "black", "business", "cyberpunk", "dark", "dim", "dracula",
  "forest", "halloween", "luxury", "night", "nord", "synthwave"
])

export function isDarkTheme(theme) {
  return darkThemes.has(theme)
}

export function setTheme(theme) {
  if (theme === "system") {
    const systemTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
    document.documentElement.setAttribute("data-theme", systemTheme)
    localStorage.setItem("theme", "system")
  } else {
    document.documentElement.setAttribute("data-theme", theme)
    localStorage.setItem("theme", theme)
  }
  updateThemeIcon()
}

export function updateThemeIcon() {
  const currentTheme = document.documentElement.getAttribute("data-theme")
  const icon = document.getElementById("theme-toggle-icon")
  if (!icon) return
  icon.textContent = isDarkTheme(currentTheme) ? "🌙" : "☀️"
}

export function toggleDarkMode() {
  const html = document.documentElement
  const currentTheme = html.getAttribute("data-theme")
  const dark = isDarkTheme(currentTheme)
  const newTheme = dark ? "light" : "dark"

  html.setAttribute("data-theme", newTheme)
  localStorage.setItem("theme", newTheme)
  updateThemeIcon()
}

export function initThemeObserver() {
  updateThemeIcon()

  const observer = new MutationObserver(function () {
    updateThemeIcon()
  })

  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ["data-theme"]
  })
}
```

### 4.2 Wire it up in `app.js`

In `assets/js/app.js`:

1. Import the functions at the top:

   ```js
   import { toggleDarkMode, initThemeObserver } from "./theme_toggle"
   ```

2. After `liveSocket.connect()` (or near the bottom), initialize the observer:

   ```js
   window.addEventListener("load", () => {
     initThemeObserver()
   })

   window.toggleDarkMode = toggleDarkMode
   ```

   This exposes `toggleDarkMode` globally so the navbar button can still call it.

### 4.3 Simplify the navbar component

In `lib/eye_in_the_sky_web_web/components/navbar.ex`:

1. Remove the entire `<script> ... </script>` block from the template.

2. Keep the button markup that calls `toggleDarkMode()`; it will now call the global function provided by `app.js`:

   ```heex
   <button class="flex items-center justify-between" onclick="toggleDarkMode()">
     <span>Dark Mode</span>
     <span id="theme-toggle-icon" class="text-lg">🌙</span>
   </button>
   ```

3. Ensure there are no unused assigns or functions related to theme in this component.

---

## Task 5: Add Tests

We need basic tests to ensure the new behavior is stable.

### 5.1 Tests for SessionView

Create or update a test file:

- `test/eye_in_the_sky_web/sessions/session_view_test.exs`

Add tests for:

1. `SessionView.from_db/2`
   - Given a `Session` and `Agent`, it should build a struct with correct `id`, `agent_id`, `project_name`, etc.
   - `last_activity_at` should default to `session.last_activity_at || session.started_at`.

2. `SessionView.from_filesystem/1`
   - Given a map with `session_id`, `last_modified`, `project_path`, it should set `source: :filesystem`, `agent_status: "discovered"`, and correct `project_name`.

### 5.2 Tests for Discovery module

Create or update:

- `test/eye_in_the_sky_web/sessions/discovery_test.exs`

Write tests for:

1. `list_session_views/1` returns `SessionView` structs.
2. When a filesystem session has the same `session_id` as a DB session, the filesystem one is not duplicated.
3. When a filesystem session does not exist in DB, you get a filesystem `SessionView` for it.

Use factories or fixtures if they exist. Otherwise, build simple structs manually.

### 5.3 Basic check on last_activity_at migration behavior

Add a small test in the `Sessions` context tests to ensure that:

- `create_session/1` sets `last_activity_at` when creating a new session.
- `end_session/1` updates both `ended_at` and `last_activity_at`.

---

## Task 6: Cleanup & Review

1. Run formatter and tests:

   ```bash
   mix format
   mix test
   ```

2. Manually test in the browser:

   - Open the Agents overview page.
   - Verify sessions render without errors.
   - Check that:
     - Discovered filesystem sessions still show up correctly.
     - Clicking on a session with `agent_id` navigates to the agent page.
     - “Updated” timestamps look reasonable and change when sessions end.

3. Check the browser console for JS errors related to theme toggle.

4. Once everything passes, create a clean commit:

   ```bash
   git status
   git add .
   git commit -m "Refactor session overview view model and theme toggle"
   ```

5. Push the branch and open a pull request:

   ```bash
   git push origin refactor-session-overview
   ```

   In the PR description, summarize:
   - New `last_activity_at` field.
   - SessionView view model.
   - Discovery module extraction.
   - Navbar theme toggle JS move.
   - New tests.
