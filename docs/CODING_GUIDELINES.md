# Coding Guidelines: Svelte 5 + Phoenix LiveView + daisyUI

This document is **Svelte-focused**. For repo-wide conventions (routing, LiveView, streams, testing, deployment), start with `docs/CODE_GUIDELINES.md`.

## Table of Contents
1. [Tech Stack Overview](#tech-stack-overview)
2. [Svelte 5 Guidelines](#svelte-5-guidelines)
3. [Phoenix LiveView Integration](#phoenix-liveview-integration)
4. [daisyUI Theming](#daisyui-theming)
5. [State Management](#state-management)
6. [File Organization](#file-organization)
7. [Styling Conventions](#styling-conventions)
8. [Common Patterns](#common-patterns)
9. [Performance Best Practices](#performance-best-practices)
10. [Testing Guidelines](#testing-guidelines)

---

## Tech Stack Overview

### Versions
- **Phoenix**: 1.8.1
- **Phoenix LiveView**: 1.1.x (currently 1.1.18 in `mix.lock`)
- **Svelte**: 5.18.0
- **live_svelte**: 0.16.0
- **daisyUI**: 5.5.8
- **Tailwind CSS**: v4 (via Phoenix Tailwind integration)

### House Style (Project Conventions)
- Prefer minimal diffs: match the existing file’s formatting and patterns; don’t reformat unrelated code.
- Avoid inline JS in HEEx and in generated HTML strings; put behavior in hooks/components and wire it through `assets/js/app.js`.
- LiveView `mount/3` runs twice (disconnected + connected). Only perform DB writes / side effects when `connected?(socket)` is true.
- If you render raw HTML via Svelte `{@html ...}`, the content must be sanitized and any interpolated attributes must be escaped (never emit `onclick=` or other inline handlers).

### Architecture
```
┌─────────────────────────────────────────────────┐
│           Browser (Client)                      │
│  ┌──────────────────────────────────────────┐  │
│  │  Svelte 5 Components                     │  │
│  │  - Reactive UI                           │  │
│  │  - Client-side interactions              │  │
│  │  - LiveView hooks                        │  │
│  └────────────┬─────────────────────────────┘  │
└───────────────┼─────────────────────────────────┘
                │ WebSocket
┌───────────────┼─────────────────────────────────┐
│               ▼                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  Phoenix LiveView (Server)               │  │
│  │  - Server-side rendering                 │  │
│  │  - State management                      │  │
│  │  - Business logic                        │  │
│  │  - Database queries                      │  │
│  └──────────────────────────────────────────┘  │
│           Phoenix Server                         │
└─────────────────────────────────────────────────┘
```

---

## Svelte 5 Guidelines

### Component Structure

#### Use Runes for Reactivity
Svelte 5 uses runes (`$state`, `$derived`, `$effect`) instead of reactive statements.

```svelte
<script>
  // ✅ GOOD - Use runes
  let count = $state(0);
  let doubled = $derived(count * 2);

  $effect(() => {
    console.log(`Count is: ${count}`);
  });

  // ❌ BAD - Don't use old reactive syntax
  let count = 0;
  $: doubled = count * 2;
  $: console.log(`Count is: ${count}`);
</script>
```

#### Props and Live Integration
```svelte
<script>
  // Always export 'live' prop for LiveView integration
  export let live;

  // Export other props with defaults
  export let title = "Default Title";
  export let items = [];
  export let isActive = false;

  // Use $state for internal component state
  let isOpen = $state(false);
  let selectedItem = $state(null);
</script>
```

#### Component Communication

**From Svelte to Phoenix:**
```svelte
<script>
  export let live;

  function handleClick(itemId) {
    // Send events to LiveView
    live.pushEvent('item_clicked', {
      item_id: itemId,
      timestamp: Date.now()
    });
  }
</script>

<button onclick={() => handleClick(item.id)}>
  Click me
</button>
```

**From Phoenix to Svelte:**
```elixir
# In LiveView mount/3 or handle_event/3
socket = assign(socket, :items, get_items())

# In template
<.svelte
  name="ItemList"
  props={%{
    items: serialize_items(@items),
    activeId: to_string(@active_id)
  }}
  socket={@socket}
/>
```

### Effect Management

#### Use $effect for Side Effects
```svelte
<script>
  export let live;
  let currentTheme = $state('dark');

  // ✅ GOOD - Use $effect for side effects
  $effect(() => {
    document.documentElement.setAttribute('data-theme', currentTheme);
    localStorage.setItem('phx:theme', currentTheme);
  });

  // Setup/cleanup pattern
  $effect(() => {
    const handler = (e) => handleClickOutside(e);
    document.addEventListener('click', handler);

    // Cleanup function
    return () => {
      document.removeEventListener('click', handler);
    };
  });
</script>
```

#### Avoid Multiple $effect Blocks for Same Logic
```svelte
<script>
  // ❌ BAD - Multiple effects doing related work
  $effect(() => {
    const theme = localStorage.getItem('theme');
    currentTheme = theme;
  });

  $effect(() => {
    document.addEventListener('click', handleClick);
    return () => document.removeEventListener('click', handleClick);
  });

  // ✅ GOOD - Combined into single effect
  $effect(() => {
    const theme = localStorage.getItem('theme') || 'dark';
    currentTheme = theme;

    document.addEventListener('click', handleClick);
    return () => document.removeEventListener('click', handleClick);
  });
</script>
```

---

## Phoenix LiveView Integration

### Component Registration

**Register components in `assets/js/app.js`:**
```javascript
import { getHooks } from "live_svelte"

// Import Svelte components
import Counter from "../svelte/Counter.svelte"
import Navbar from "../svelte/Navbar.svelte"
import ThemeSelector from "../svelte/ThemeSelector.svelte"

// Register hooks
let Hooks = getHooks({
  Counter,
  Navbar,
  ThemeSelector
})

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken }
})
```

### LiveView Template Usage

**Use the `.svelte` component function:**
```elixir
defmodule UrielmWeb.PageLive do
  use UrielmWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.svelte
        name="Counter"
        props={%{count: @count}}
        socket={@socket}
      />
    </div>
    """
  end

  def handle_event("increment", _params, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1)}
  end
end
```

### Data Serialization

**Always serialize complex data before passing to Svelte:**
```elixir
# ❌ BAD - Don't pass raw Ecto structs
<.svelte
  name="TaskList"
  props={%{tasks: @tasks}}
  socket={@socket}
/>

# ✅ GOOD - Serialize data
<.svelte
  name="TaskList"
  props={%{tasks: serialize_tasks(@tasks)}}
  socket={@socket}
/>

defp serialize_tasks(tasks) do
  Enum.map(tasks, fn task ->
    %{
      id: to_string(task.id),           # Convert IDs to strings
      title: task.title,
      completed: task.completed,
      createdAt: task.inserted_at,      # Use camelCase for JS
      updatedAt: task.updated_at
    }
  end)
end
```

### State Ownership

**Server state lives in LiveView, UI state in Svelte:**

```elixir
# ✅ GOOD - Server owns business data
def mount(_params, _session, socket) do
  socket = assign(socket,
    tasks: get_tasks(),           # Server state
    filter: "all",                # Server state
    current_user: get_user()      # Server state
  )
  {:ok, socket}
end
```

```svelte
<script>
  // ✅ GOOD - Svelte owns UI-only state
  export let tasks = [];           // From server
  export let filter = "all";       // From server

  let isDropdownOpen = $state(false);   // UI state only
  let animating = $state(false);        // UI state only
  let hoveredId = $state(null);         // UI state only
</script>
```

---

## daisyUI Theming

### Theme Configuration

**In `assets/css/app.css`:**
```css
/* ✅ GOOD - Use 'themes: all' for all built-in themes */
@plugin "../vendor/daisyui" {
  themes: all;
}

/* ❌ BAD - Array syntax doesn't work in Tailwind v4 */
@plugin "../vendor/daisyui" {
  themes: ["light", "dark", "dracula"];
}
```

### Semantic Color Classes

**ALWAYS use semantic classes for theming:**

```svelte
<!-- ✅ GOOD - Semantic classes that respond to themes -->
<div class="bg-base-100 text-base-content">
  <div class="bg-base-200 border border-base-300">
    <h1 class="text-base-content">Title</h1>
    <button class="btn btn-primary">Click me</button>
  </div>
</div>

<!-- ❌ BAD - Hardcoded colors that never change with themes -->
<div class="bg-[#0f0f0f] text-white">
  <div class="bg-[#212121] border border-white/10">
    <h1 class="text-white">Title</h1>
    <button class="bg-purple-600 text-white">Click me</button>
  </div>
</div>
```

### Semantic Class Reference

| Purpose | Semantic Class | Never Use |
|---------|---------------|-----------|
| Main background | `bg-base-100` | `bg-black`, `bg-[#0f0f0f]` |
| Secondary background | `bg-base-200` | `bg-gray-900`, `bg-[#212121]` |
| Tertiary background | `bg-base-300` | `bg-gray-800`, `bg-[#2a2a2a]` |
| Primary text | `text-base-content` | `text-white`, `text-black` |
| Muted text | `text-base-content/60` | `text-gray-600`, `text-white/60` |
| Borders | `border-base-300` | `border-white/10`, `border-gray-700` |
| Primary accent | `bg-primary`, `text-primary` | `bg-purple-600`, `text-purple-400` |
| Primary button | `btn btn-primary` | `bg-purple-600 text-white` |
| Secondary button | `btn btn-secondary` | `bg-gray-600 text-white` |
| Accent | `bg-accent`, `text-accent` | `bg-pink-500` |
| Success | `text-success`, `bg-success` | `text-green-400`, `bg-green-600` |
| Error | `text-error`, `bg-error` | `text-red-400`, `bg-red-600` |
| Warning | `text-warning`, `bg-warning` | `text-yellow-400`, `bg-yellow-600` |
| Info | `text-info`, `bg-info` | `text-blue-400`, `bg-blue-600` |

### Theme Switching Implementation

```svelte
<script>
  export let live;

  const themes = [
    { value: 'light', label: 'Light', icon: '☀️' },
    { value: 'dark', label: 'Dark', icon: '🌙' },
    { value: 'dracula', label: 'Dracula', icon: '🧛' },
    { value: 'synthwave', label: 'Synthwave', icon: '🌆' }
  ];

  let currentTheme = $state('dark');

  function applyTheme(theme) {
    currentTheme = theme;
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('phx:theme', theme);

    // Notify other components
    window.dispatchEvent(new CustomEvent('phx:set-theme', {
      detail: { theme }
    }));
  }

  $effect(() => {
    // Initialize from localStorage
    const saved = localStorage.getItem('phx:theme') || 'dark';
    applyTheme(saved);
  });
</script>

<select onchange={(e) => applyTheme(e.target.value)}>
  {#each themes as theme}
    <option value={theme.value} selected={currentTheme === theme.value}>
      {theme.icon} {theme.label}
    </option>
  {/each}
</select>
```

---

## State Management

### State Ownership Rules

1. **Business data = LiveView** (tasks, users, posts, etc.)
2. **UI state = Svelte** (dropdowns, modals, animations, etc.)
3. **User preferences = localStorage + LiveView** (theme, layout, etc.)

### State Flow Pattern

```
User Action (Svelte)
  ↓
live.pushEvent()
  ↓
LiveView handle_event/3
  ↓
Update assigns + DB
  ↓
Re-render template
  ↓
New props → Svelte
  ↓
Reactive update (Svelte)
```

### Example: Todo List

**LiveView (server state):**
```elixir
def mount(_params, _session, socket) do
  {:ok, assign(socket,
    todos: get_todos(),
    filter: "all"
  )}
end

def handle_event("toggle_todo", %{"id" => id}, socket) do
  todo = get_todo!(id)
  update_todo(todo, %{completed: !todo.completed})
  {:noreply, assign(socket, todos: get_todos())}
end

def handle_event("filter_changed", %{"filter" => filter}, socket) do
  {:noreply, assign(socket, filter: filter)}
end
```

**Svelte (UI state + interaction):**
```svelte
<script>
  export let live;
  export let todos = [];
  export let filter = "all";

  // UI-only state
  let editingId = $state(null);
  let hoveredId = $state(null);

  // Filter todos (derived from props)
  let filteredTodos = $derived(
    filter === "all"
      ? todos
      : todos.filter(t => filter === "completed" ? t.completed : !t.completed)
  );

  function toggleTodo(id) {
    live.pushEvent('toggle_todo', { id });
  }

  function changeFilter(newFilter) {
    live.pushEvent('filter_changed', { filter: newFilter });
  }
</script>
```

---

## File Organization

### Project Structure
```
lib/
├── urielm_web/
│   ├── live/
│   │   ├── home_live.ex          # LiveView modules
│   │   └── references_live.ex
│   ├── components/
│   │   └── layouts/              # Phoenix components
│   └── router.ex

assets/
├── js/
│   ├── app.js                    # Main entry, register Svelte components
│   └── server.js                 # SSR entry
├── svelte/
│   ├── Navbar.svelte             # Svelte components
│   ├── ThemeSelector.svelte
│   └── TaskList.svelte
└── css/
    └── app.css                   # Tailwind + daisyUI config
```

### Naming Conventions

**Svelte Components:**
- PascalCase: `ThemeSelector.svelte`, `TaskList.svelte`
- Descriptive names: `UserProfileCard.svelte` not `Card.svelte`

**LiveView Modules:**
- Suffix with `Live`: `PageLive`, `DashboardLive`
- Snake_case files: `page_live.ex`, `dashboard_live.ex`

**Props:**
- camelCase in Svelte: `activeFilter`, `itemCount`
- snake_case in Elixir: `active_filter`, `item_count`

---

## Styling Conventions

### Component Styling Priority

1. **daisyUI components** (buttons, cards, forms)
2. **daisyUI semantic classes** (colors, spacing)
3. **Tailwind utilities** (layout, typography)
4. **Custom CSS** (animations, special effects) - use sparingly

### Example Component Styling

```svelte
<script>
  export let title = "";
  export let isActive = false;
</script>

<!-- 1. Use daisyUI components -->
<div class="card bg-base-200 shadow-xl">
  <div class="card-body">
    <!-- 2. Use semantic color classes -->
    <h2 class="card-title text-base-content">
      {title}
    </h2>

    <!-- 3. Use Tailwind utilities for layout -->
    <div class="flex items-center justify-between mt-4">
      <!-- 4. daisyUI button component with semantic colors -->
      <button class="btn btn-primary">
        Action
      </button>

      <!-- State-dependent styling -->
      <span class={isActive ? "badge badge-success" : "badge badge-ghost"}>
        {isActive ? "Active" : "Inactive"}
      </span>
    </div>
  </div>
</div>
```

### Never Use @apply

```css
/* ❌ BAD - Don't use @apply in Tailwind v4 */
.custom-button {
  @apply btn btn-primary rounded-full;
}

/* ✅ GOOD - Use classes directly in markup */
<button class="btn btn-primary rounded-full">Click me</button>

/* ✅ GOOD - Or create a Svelte component */
<!-- Button.svelte -->
<button class="btn btn-primary rounded-full">
  <slot />
</button>
```

---

## Common Patterns

### Modal Pattern

```svelte
<script>
  export let live;
  export let isOpen = false;

  function close() {
    live.pushEvent('close_modal', {});
  }

  function handleBackdropClick(e) {
    if (e.target === e.currentTarget) {
      close();
    }
  }
</script>

{#if isOpen}
  <div
    class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
    onclick={handleBackdropClick}
  >
    <div class="modal-box bg-base-200">
      <h3 class="font-bold text-lg text-base-content">Modal Title</h3>
      <p class="py-4 text-base-content/70">Modal content goes here</p>
      <div class="modal-action">
        <button class="btn btn-primary" onclick={close}>Close</button>
      </div>
    </div>
  </div>
{/if}
```

### Dropdown Pattern

```svelte
<script>
  let isOpen = $state(false);

  function handleClickOutside(e) {
    if (!e.target.closest('.dropdown-container')) {
      isOpen = false;
    }
  }

  $effect(() => {
    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
  });
</script>

<div class="dropdown dropdown-container">
  <button
    class="btn btn-ghost"
    onclick={() => isOpen = !isOpen}
  >
    Menu
  </button>

  {#if isOpen}
    <ul class="dropdown-content menu bg-base-200 rounded-box z-[1] w-52 p-2 shadow">
      <li><a>Item 1</a></li>
      <li><a>Item 2</a></li>
    </ul>
  {/if}
</div>
```

### Form Pattern

```svelte
<script>
  export let live;

  let formData = $state({
    email: '',
    password: ''
  });

  function handleSubmit(e) {
    e.preventDefault();
    live.pushEvent('form_submit', formData);
  }
</script>

<form onsubmit={handleSubmit} class="space-y-4">
  <div class="form-control">
    <label class="label">
      <span class="label-text">Email</span>
    </label>
    <input
      type="email"
      bind:value={formData.email}
      class="input input-bordered bg-base-200"
      placeholder="email@example.com"
    />
  </div>

  <div class="form-control">
    <label class="label">
      <span class="label-text">Password</span>
    </label>
    <input
      type="password"
      bind:value={formData.password}
      class="input input-bordered bg-base-200"
    />
  </div>

  <button type="submit" class="btn btn-primary w-full">
    Submit
  </button>
</form>
```

---

## Performance Best Practices

### 1. Minimize LiveView Re-renders

```elixir
# ❌ BAD - Updates entire list on every change
def handle_event("update_item", %{"id" => id}, socket) do
  items = update_item_in_list(socket.assigns.items, id)
  {:noreply, assign(socket, items: items)}
end

# ✅ GOOD - Use streams for large lists
def mount(_params, _session, socket) do
  {:ok, stream(socket, :items, get_items())}
end

def handle_event("update_item", %{"id" => id}, socket) do
  item = get_item!(id) |> update_item()
  {:noreply, stream_insert(socket, :items, item)}
end
```

### 2. Debounce Expensive Operations

```svelte
<script>
  export let live;

  let searchQuery = $state('');
  let debounceTimer = null;

  function handleSearch(query) {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      live.pushEvent('search', { query });
    }, 300);
  }

  $effect(() => {
    if (searchQuery) {
      handleSearch(searchQuery);
    }
  });
</script>

<input
  bind:value={searchQuery}
  class="input input-bordered"
  placeholder="Search..."
/>
```

### 3. Lazy Load Components

```svelte
<script>
  let showExpensiveComponent = $state(false);
</script>

<button onclick={() => showExpensiveComponent = true}>
  Load Component
</button>

{#if showExpensiveComponent}
  {#await import('./ExpensiveComponent.svelte')}
    <div class="loading loading-spinner"></div>
  {:then module}
    <svelte:component this={module.default} />
  {/await}
{/if}
```

### 4. Optimize Data Serialization

```elixir
# ✅ GOOD - Only serialize what's needed
defp serialize_task(task) do
  %{
    id: to_string(task.id),
    title: task.title,
    completed: task.completed
    # Don't include: timestamps, associations, etc. unless needed
  }
end
```

---

## Testing Guidelines

### Svelte Component Tests

```javascript
// TaskList.test.js
import { render, fireEvent } from '@testing-library/svelte';
import { expect, test } from 'vitest';
import TaskList from './TaskList.svelte';

test('renders tasks correctly', () => {
  const tasks = [
    { id: '1', title: 'Task 1', completed: false },
    { id: '2', title: 'Task 2', completed: true }
  ];

  const { getByText } = render(TaskList, { props: { tasks } });

  expect(getByText('Task 1')).toBeInTheDocument();
  expect(getByText('Task 2')).toBeInTheDocument();
});

test('calls live.pushEvent when task clicked', async () => {
  const mockLive = {
    pushEvent: vi.fn()
  };

  const tasks = [{ id: '1', title: 'Task 1', completed: false }];
  const { getByText } = render(TaskList, {
    props: { tasks, live: mockLive }
  });

  await fireEvent.click(getByText('Task 1'));

  expect(mockLive.pushEvent).toHaveBeenCalledWith('task_clicked', {
    id: '1'
  });
});
```

### LiveView Tests

```elixir
defmodule UrielmWeb.TaskLiveTest do
  use UrielmWeb.ConnCase
  import Phoenix.LiveViewTest

  test "displays tasks", %{conn: conn} do
    task = insert(:task, title: "Test Task")

    {:ok, view, html} = live(conn, "/tasks")

    assert html =~ "Test Task"
    assert has_element?(view, "[data-test-id=task-#{task.id}]")
  end

  test "toggles task completion", %{conn: conn} do
    task = insert(:task, completed: false)

    {:ok, view, _html} = live(conn, "/tasks")

    view
    |> element("[data-test-id=toggle-#{task.id}]")
    |> render_click()

    assert Repo.reload!(task).completed == true
  end
end
```

---

## Common Pitfalls & Solutions

### ❌ Using Hardcoded Colors
**Problem:** Theme switching doesn't work
**Solution:** Always use daisyUI semantic classes

### ❌ Multiple $effect Blocks
**Problem:** Code duplication, hard to maintain
**Solution:** Combine related effects into single block

### ❌ Large IDs in Props
**Problem:** JavaScript precision loss for integers > 2^53
**Solution:** Always convert to strings: `to_string(task.id)`

### ❌ Forgetting socket={@socket}
**Problem:** Svelte component doesn't render
**Solution:** Always pass socket to `.svelte` component

### ❌ Using @apply in Tailwind v4
**Problem:** Build errors or unexpected styling
**Solution:** Use classes directly in markup

### ❌ Not Serializing Ecto Structs
**Problem:** JSON encoding errors, large payloads
**Solution:** Create serialization functions

---

## Quick Reference

### Essential Commands
```bash
# Development
mix phx.server                    # Start dev server
PORT=4001 mix phx.server          # Custom port
mix tailwind urielm               # Rebuild CSS
mix assets.build                  # Build all assets

# Testing
mix test                          # Run all tests
mix test test/path_test.exs       # Specific test

# Pre-commit
mix precommit                     # Format + test
```

### File Templates

**New Svelte Component:**
```svelte
<script>
  export let live;
  export let title = "";

  let localState = $state(null);

  function handleAction() {
    live.pushEvent('action_name', { data: 'value' });
  }
</script>

<div class="card bg-base-200">
  <div class="card-body">
    <h2 class="card-title text-base-content">{title}</h2>
    <button class="btn btn-primary" onclick={handleAction}>
      Action
    </button>
  </div>
</div>
```

**New LiveView:**
```elixir
defmodule UrielmWeb.PageLive do
  use UrielmWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, data: [])}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto">
      <.svelte
        name="Component"
        props={%{data: serialize_data(@data)}}
        socket={@socket}
      />
    </div>
    """
  end

  def handle_event("event_name", params, socket) do
    {:noreply, socket}
  end

  defp serialize_data(data) do
    Enum.map(data, &serialize_item/1)
  end

  defp serialize_item(item) do
    %{
      id: to_string(item.id),
      # ... other fields
    }
  end
end
```

---

## Resources

- [Svelte 5 Runes Documentation](https://svelte-5-preview.vercel.app/docs/runes)
- [Phoenix LiveView Guides](https://hexdocs.pm/phoenix_live_view)
- [daisyUI Components](https://daisyui.com/components/)
- [Tailwind CSS v4 Docs](https://tailwindcss.com/docs)
- [live_svelte GitHub](https://github.com/woutdp/live_svelte)
- Project: `docs/THEME_SWITCHING_FIX.md`
- Project: `CLAUDE.md`
- Project: `AGENTS.md`
