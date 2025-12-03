# Svelte + Phoenix Integration Guide

## Overview

This document explains how to integrate Svelte components with Phoenix LiveView using the `live_svelte` library, based on the implementation in the eye-in-the-sky-web project.

## Architecture Stack

- **Phoenix**: 1.8.1
- **Phoenix LiveView**: 1.1.0
- **live_svelte**: 0.16.0
- **Svelte**: 5.43.6
- **esbuild**: Custom build configuration

## Core Concept

Phoenix LiveView manages application state and routing on the server. Svelte components handle rich client-side interactivity and UI rendering. The `live_svelte` library bridges the two, enabling:

1. Server-side rendering of Svelte components
2. Bidirectional communication between LiveView and Svelte
3. Real-time updates via Phoenix PubSub

## Project Structure

```
assets/
├── build.js                    # Custom esbuild configuration
├── package.json               # NPM dependencies
├── tsconfig.json              # TypeScript configuration
├── js/
│   ├── app.js                 # Client-side entry point
│   └── server.js              # Server-side entry point (SSR)
├── svelte/
│   ├── components/            # Svelte components
│   │   ├── SessionsSidebar.svelte
│   │   ├── MainWorkArea.svelte
│   │   └── tabs/
│   │       ├── TasksTab.svelte
│   │       └── ...
│   └── utils/                 # Shared utilities
└── css/
    └── app.css

lib/
└── your_app_web/
    ├── live/                  # LiveView modules
    │   └── agent_live/
    │       └── show.ex
    └── your_app_web.ex        # Import LiveSvelte

priv/
├── static/assets/             # Compiled client bundle
└── svelte/                    # Compiled server bundle
```

## Setup Steps

### 1. Add Dependencies (mix.exs)

```elixir
defp deps do
  [
    {:phoenix, "~> 1.8.1"},
    {:phoenix_live_view, "~> 1.1.0"},
    {:live_svelte, "~> 0.16.0"},
    # ... other deps
  ]
end
```

### 2. Configure Asset Build (mix.exs)

```elixir
defp aliases do
  [
    "assets.setup": ["cmd --cd assets npm install"],
    "assets.build": ["compile", "cmd --cd assets node build.js"],
    "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"]
  ]
end
```

### 3. NPM Dependencies (assets/package.json)

```json
{
  "devDependencies": {
    "esbuild": "^0.27.0",
    "esbuild-svelte": "^0.9.3",
    "esbuild-plugin-import-glob": "^0.1.1",
    "svelte": "^5.43.6",
    "svelte-preprocess": "^6.0.3"
  },
  "dependencies": {
    "live_svelte": "file:../deps/live_svelte",
    "phoenix": "file:../deps/phoenix",
    "phoenix_html": "file:../deps/phoenix_html",
    "phoenix_live_view": "file:../deps/phoenix_live_view"
  }
}
```

### 4. Custom Build Script (assets/build.js)

The key innovation: compile Svelte components twice for client and server.

```javascript
const esbuild = require("esbuild")
const sveltePlugin = require("esbuild-svelte")
const importGlobPlugin = require("esbuild-plugin-import-glob").default
const sveltePreprocess = require("svelte-preprocess")

const args = process.argv.slice(2)
const watch = args.includes("--watch")
const deploy = args.includes("--deploy")

// Client bundle configuration
let optsClient = {
    entryPoints: ["js/app.js"],
    bundle: true,
    minify: deploy,
    outdir: "../priv/static/assets",
    plugins: [
        importGlobPlugin(),
        sveltePlugin({
            preprocess: sveltePreprocess(),
            compilerOptions: {
                dev: !deploy,
                css: "injected",
                generate: "client"  // Client-side rendering
            },
        }),
    ],
}

// Server bundle configuration
let optsServer = {
    entryPoints: ["js/server.js"],
    platform: "node",
    bundle: true,
    outdir: "../priv/svelte",
    plugins: [
        importGlobPlugin(),
        sveltePlugin({
            preprocess: sveltePreprocess(),
            compilerOptions: {
                dev: !deploy,
                css: "injected",
                generate: "server"  // Server-side rendering
            },
        }),
    ],
}

if (watch) {
    esbuild.context(optsClient).then(ctx => ctx.watch())
    esbuild.context(optsServer).then(ctx => ctx.watch())
} else {
    esbuild.build(optsClient)
    esbuild.build(optsServer)
}
```

### 5. Client Entry Point (assets/js/app.js)

Register Svelte components as LiveView hooks:

```javascript
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {getHooks} from "live_svelte"

// Import your Svelte components
import SessionsSidebar from "../svelte/components/SessionsSidebar.svelte"
import MainWorkArea from "../svelte/components/MainWorkArea.svelte"
import ContextPanel from "../svelte/components/ContextPanel.svelte"

// Register components with LiveSvelte
let Hooks = getHooks({
  SessionsSidebar,
  MainWorkArea,
  ContextPanel
})

// Add custom hooks if needed
Hooks.CustomHook = {
  mounted() { /* ... */ },
  updated() { /* ... */ }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
})

liveSocket.connect()
```

### 6. Server Entry Point (assets/js/server.js)

Export all components for SSR:

```javascript
import * as Components from "../svelte/**/*.svelte"
import {getRender} from "live_svelte"

export const render = getRender(Components)
```

The glob import (`../svelte/**/*.svelte`) automatically includes all Svelte components.

### 7. Import LiveSvelte in Phoenix (lib/your_app_web.ex)

```elixir
defmodule YourAppWeb do
  defp html_helpers do
    quote do
      use Gettext, backend: YourAppWeb.Gettext
      import Phoenix.HTML
      import YourAppWeb.CoreComponents
      import LiveSvelte  # Add this line

      alias Phoenix.LiveView.JS
      unquote(verified_routes())
    end
  end
end
```

### 8. Development Watcher (config/dev.exs)

```elixir
config :your_app, YourAppWeb.Endpoint,
  watchers: [
    node: ["build.js", "--watch", cd: Path.expand("../assets", __DIR__)],
    tailwind: {Tailwind, :install_and_run, [:your_app, ~w(--watch)]}
  ]
```

## Usage in LiveView

### Basic Component Rendering

```elixir
defmodule YourAppWeb.PageLive do
  use YourAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.svelte
      name="Counter"
      props={%{count: @count}}
      socket={@socket}
    />
    """
  end
end
```

### Passing Complex Data

```elixir
def render(assigns) do
  ~H"""
  <.svelte
    name="AgentDetail"
    props={%{
      header: @header,
      sessionId: @session_id,
      activeTab: Atom.to_string(@active_tab),
      counts: @counts,
      tasks: serialize_tasks(@tasks),
      commits: serialize_commits(@commits)
    }}
    socket={@socket}
  />
  """
end

defp serialize_tasks(tasks) do
  Enum.map(tasks, fn task ->
    %{
      id: to_string(task.id),
      title: task.title,
      priority: task.priority,
      state: task.state.name
    }
  end)
end
```

## Svelte Component Structure

### Basic Component with LiveView Integration

```svelte
<script>
  // Props passed from LiveView
  export let sessions = []
  export let activeSessionId = null
  export let live  // Special prop for LiveView communication

  // Event handler that pushes to LiveView
  function selectSession(sessionId) {
    live.pushEvent('select_session', { session_id: sessionId })
  }
</script>

<div class="sidebar">
  <h3>Sessions</h3>
  {#each sessions as session}
    <button
      class:active={session.id === activeSessionId}
      on:click={() => selectSession(session.id)}
    >
      {session.name}
    </button>
  {/each}
</div>
```

### Component with Child Components

```svelte
<script>
  import TasksTab from "./tabs/TasksTab.svelte"
  import CommitsTab from "./tabs/CommitsTab.svelte"

  export let activeTab
  export let tasks
  export let commits
  export let live
</script>

<div class="container">
  {#if activeTab === 'tasks'}
    <TasksTab {tasks} {live} />
  {:else if activeTab === 'commits'}
    <CommitsTab {commits} {live} />
  {/if}
</div>
```

## LiveView Event Handling

### Handle Events from Svelte

```elixir
defmodule YourAppWeb.AgentLive.Show do
  use YourAppWeb, :live_view

  @impl true
  def handle_event("select_session", %{"session_id" => session_id}, socket) do
    {:noreply,
      socket
      |> assign(:session_id, session_id)
      |> push_patch(to: ~p"/agents/#{socket.assigns.agent_id}?s=#{session_id}")
    }
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    # Load tab-specific data
    tab_data = load_tab_data(String.to_atom(tab), socket.assigns.session_id)

    {:noreply, assign(socket, tab_data)}
  end
end
```

### Real-time Updates via PubSub

```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "session:#{session_id}")
  end

  {:ok, socket}
end

def handle_info({:new_message, message}, socket) do
  messages = load_messages(socket.assigns.session_id)
  {:noreply, assign(socket, :messages, messages)}
end
```

## Data Flow

### LiveView → Svelte (Props)

```
LiveView assigns → render/1 → props parameter → Svelte export let
```

1. Update assigns in LiveView
2. LiveView re-renders
3. New props sent to Svelte
4. Svelte reactively updates DOM

### Svelte → LiveView (Events)

```
User interaction → Svelte event handler → live.pushEvent() → handle_event/3
```

1. User clicks button in Svelte
2. Event handler calls `live.pushEvent('event_name', payload)`
3. LiveView receives event in `handle_event/3`
4. Update state, return `{:noreply, socket}`
5. New props trigger Svelte update

## Advanced Patterns

### Lazy Loading Tabs

Only load data for the active tab to improve performance:

```elixir
defp load_tab_data(:tasks, session_id) do
  %{tasks: Tasks.list_for_session(session_id)}
end

defp load_tab_data(:commits, session_id) do
  %{commits: Commits.list_for_session(session_id)}
end

def handle_event("change_tab", %{"tab" => tab}, socket) do
  tab_atom = String.to_atom(tab)
  tab_data = load_tab_data(tab_atom, socket.assigns.session_id)

  {:noreply,
    socket
    |> assign(:active_tab, tab_atom)
    |> assign(tab_data)
  }
end
```

### Modal Management

Control modals from both sides:

```elixir
# LiveView
def handle_event("open_modal", %{"type" => "task"}, socket) do
  {:noreply, assign(socket, show_task_modal: true)}
end

def handle_event("close_modal", _, socket) do
  {:noreply, assign(socket, show_task_modal: false, show_note_modal: false)}
end
```

```svelte
<script>
  export let showTaskModal
  export let live

  function openModal() {
    live.pushEvent('open_modal', {type: 'task'})
  }

  function closeModal() {
    live.pushEvent('close_modal', {})
  }
</script>

{#if showTaskModal}
  <div class="modal">
    <button on:click={closeModal}>Close</button>
    <!-- Modal content -->
  </div>
{/if}
```

### Form Submission

```svelte
<script>
  export let live

  let title = ""
  let description = ""

  function handleSubmit() {
    live.pushEvent('save_task', {
      title: title,
      description: description
    })

    // Reset form
    title = ""
    description = ""
  }
</script>

<form on:submit|preventDefault={handleSubmit}>
  <input bind:value={title} placeholder="Title" />
  <textarea bind:value={description} placeholder="Description" />
  <button type="submit">Save</button>
</form>
```

## Best Practices

### 1. Keep Business Logic in Elixir

Svelte handles UI and user interactions. All business logic, validation, and data persistence should happen in Phoenix/Elixir.

### 2. Serialize Data Properly

Always convert IDs to strings to prevent JavaScript precision loss with large integers:

```elixir
defp serialize_tasks(tasks) do
  Enum.map(tasks, fn task ->
    %{
      id: to_string(task.id),  # Important!
      title: task.title
    }
  end)
end
```

### 3. Use TypeScript for Type Safety

```typescript
// assets/svelte/types.ts
export interface Task {
  id: string
  title: string
  priority: number
  state_name: string
}

export interface Session {
  id: string
  name: string
  started_at: string
}
```

```svelte
<script lang="ts">
  import type { Task } from '../types'

  export let tasks: Task[]
  export let live: any
</script>
```

### 4. Handle Loading States

```svelte
<script>
  export let tasks
  export let loading = false

  $: isEmpty = !loading && (!tasks || tasks.length === 0)
</script>

{#if loading}
  <div class="spinner">Loading...</div>
{:else if isEmpty}
  <div class="empty-state">No tasks yet</div>
{:else}
  {#each tasks as task}
    <!-- Render task -->
  {/each}
{/if}
```

### 5. Optimize Re-renders

Use Svelte's reactivity wisely:

```svelte
<script>
  export let tasks
  export let activeTaskId

  // Only recalculate when tasks change
  $: sortedTasks = tasks
    .slice()
    .sort((a, b) => b.priority - a.priority)

  // Only recalculate when activeTaskId or tasks change
  $: activeTask = tasks.find(t => t.id === activeTaskId)
</script>
```

## Debugging

### Enable Debug Mode

```javascript
// assets/js/app.js
window.liveSocket = liveSocket

// In browser console:
liveSocket.enableDebug()
liveSocket.enableLatencySim(1000)  // Simulate slow network
```

### Inspect Props

```svelte
<script>
  export let tasks

  // Debug in development
  $: if (import.meta.env.DEV) {
    console.log('Tasks updated:', tasks)
  }
</script>
```

### Check LiveView Events

```elixir
def handle_event(event, params, socket) do
  require Logger
  Logger.debug("Event: #{event}, Params: #{inspect(params)}")

  # ... rest of handler
end
```

## Common Pitfalls

### 1. Forgetting to Import LiveSvelte

Make sure `import LiveSvelte` is in your `html_helpers/0` function.

### 2. Not Registering Components

Components must be registered in `assets/js/app.js`:

```javascript
let Hooks = getHooks({
  MyComponent,  // Must match component name in .svelte
})
```

### 3. Props Naming Mismatch

LiveView uses snake_case, JavaScript uses camelCase:

```elixir
# LiveView - use camelCase for JS
props={%{activeTab: "tasks", userId: @user_id}}
```

```svelte
<!-- Svelte -->
<script>
  export let activeTab
  export let userId
</script>
```

### 4. Not Handling nil Values

Always handle potential nil values:

```elixir
props={%{
  tasks: @tasks || [],
  session: @session || %{}
}}
```

```svelte
<script>
  export let tasks = []
  export let session = null
</script>

{#if session}
  <h2>{session.name}</h2>
{/if}
```

## Performance Optimization

### 1. Code Splitting

Load components on demand:

```javascript
// Instead of importing all components upfront
const LazyComponent = () => import('./components/HeavyComponent.svelte')
```

### 2. Minimize Data Transfer

Only send necessary data to the client:

```elixir
# Bad - sends entire user struct
props={%{user: @user}}

# Good - send only needed fields
props={%{
  userName: @user.name,
  userRole: @user.role
}}
```

### 3. Use keyed each Blocks

Help Svelte optimize list updates:

```svelte
{#each tasks as task (task.id)}
  <TaskItem {task} />
{/each}
```

## Conclusion

The Svelte + Phoenix integration via `live_svelte` provides the best of both worlds:

- **Phoenix strengths**: Server-side state, real-time updates, robust backend
- **Svelte strengths**: Reactive UI, component composition, smooth animations

The dual build system (client + server) enables true SSR with hydration, making your app fast on initial load while maintaining rich interactivity.

This architecture scales well for complex applications where you need both server control and sophisticated client-side UIs.
