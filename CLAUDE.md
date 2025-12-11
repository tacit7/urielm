# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal website for urielm.dev built with Phoenix 1.8.1, LiveView 1.1.0, and Svelte 5.18, integrated via live_svelte 0.16.0. This is a hybrid architecture where Phoenix LiveView manages server-side state and routing, while Svelte handles rich client-side UI.

**App Name**: `:urielm`
**Module Prefix**: `Urielm`, `UrielmWeb`

## Development Commands

### Setup
```bash
mix setup                    # Install all dependencies (Elixir + NPM)
mix deps.get                 # Install Elixir dependencies only
cd assets && npm install     # Install NPM dependencies only
```

### Running the App
```bash
mix phx.server               # Start server with live reload on localhost:4000
PORT=8080 mix phx.server     # Run on custom port
```

### Building Assets
```bash
cd assets && node build.js              # Build once (client + server bundles)
cd assets && node build.js --watch      # Watch mode (auto-runs via mix phx.server)
cd assets && node build.js --deploy     # Production build (minified)
```

### Testing & Quality
```bash
mix test                     # Run all tests
mix test test/path_test.exs  # Run specific test file
mix test --failed            # Re-run only failed tests
mix format                   # Format Elixir code
mix precommit               # Run full pre-commit checks (compile, format, test)
```

### Asset Management
```bash
mix assets.setup            # Install Tailwind + NPM packages
mix assets.build            # Compile Tailwind + run build.js
mix assets.deploy           # Production asset build + digest
```

### Database
```bash
mix ecto.create             # Create development database
mix ecto.drop               # Drop development database
mix ecto.migrate            # Run all pending migrations
mix ecto.gen.migration name # Generate new migration file
mix ecto.reset              # Drop + create + migrate
```

## Architecture

### Dual Build System

The custom `assets/build.js` script compiles Svelte components **twice**:

1. **Client Bundle**: `js/app.js` → `priv/static/assets/app.js` (browser target)
   - Svelte components generate client-side code
   - Registered as LiveView hooks via `getHooks()`

2. **Server Bundle**: `js/server.js` → `priv/svelte/server.js` (Node target)
   - Svelte components generate SSR code
   - Exported via `getRender()` for server-side rendering

Both bundles are built simultaneously when running `mix phx.server` (watch mode) or `node build.js`.

### Data Flow

```
User interaction (Svelte)
  → live.pushEvent('event_name', payload)
  → LiveView.handle_event/3
  → Update socket assigns
  → Re-render with new props
  → Svelte receives updated props
  → Reactive DOM update
```

**Server → Client**: LiveView assigns become Svelte props
**Client → Server**: Svelte events via `live.pushEvent()` handled in `handle_event/3`

### Directory Structure

```
lib/
├── urielm/                      # Domain logic
│   └── application.ex
├── urielm_web/                  # Web interface
│   ├── components/              # Phoenix function components
│   ├── controllers/             # Traditional controllers
│   ├── live/                    # LiveView modules
│   ├── endpoint.ex
│   ├── router.ex
│   └── telemetry.ex
├── urielm.ex                    # Main app module
└── urielm_web.ex                # Web module (imports LiveSvelte)

assets/
├── build.js                     # Custom esbuild dual-build config
├── package.json
├── tsconfig.json
├── js/
│   ├── app.js                   # Client entry: registers Svelte as hooks
│   └── server.js                # Server entry: exports for SSR
├── svelte/                      # Svelte components (*.svelte)
└── css/
    └── app.css                  # Tailwind CSS

priv/
├── static/assets/               # Compiled client bundle
└── svelte/                      # Compiled server bundle (SSR)
```

## Working with Svelte Components

### Adding New Components

1. Create `assets/svelte/MyComponent.svelte`

2. Register in `assets/js/app.js`:
```javascript
import MyComponent from "../svelte/MyComponent.svelte"

let Hooks = getHooks({
  Counter,
  MyComponent  // Add here
})
```

3. Use in LiveView templates:
```elixir
<.svelte
  name="MyComponent"
  props={%{someProp: @value}}
  socket={@socket}
/>
```

### Component Requirements

- **Always** pass `socket={@socket}` to `.svelte` component
- Component names must match exactly between registration and usage
- Use camelCase for prop names (JavaScript convention)
- Convert large IDs to strings: `id: to_string(task.id)` to prevent precision loss
- The `live` prop is automatically injected for LiveView communication

### Event Handling

**In Svelte**:
```javascript
export let live

function handleClick() {
  live.pushEvent('button_clicked', {data: 'value'})
}
```

**In LiveView**:
```elixir
def handle_event("button_clicked", %{"data" => data}, socket) do
  {:noreply, assign(socket, :data, data)}
end
```

## Phoenix-Specific Guidelines

### LiveView Integration

- LiveSvelte is imported in `lib/urielm_web.ex` via `import LiveSvelte` in the `html_helpers/0` function
- Use `.svelte` component function in any LiveView template
- State lives in LiveView assigns, UI reactivity in Svelte
- For collections, consider LiveView streams if the list is large

### File Watchers

Development watchers (configured in `config/dev.exs`):
- `node build.js --watch` - Auto-rebuild Svelte on changes
- `tailwind --watch` - Auto-rebuild CSS
- Live reload triggers on:
  - `lib/urielm_web/**/*.{ex,heex}`
  - `assets/svelte/**/*.svelte`
  - `priv/static/**/*.{js,css}`

### Module Naming

- LiveViews: `UrielmWeb.PageLive`, `UrielmWeb.CounterLive`
- Routes in `:browser` scope are aliased with `UrielmWeb`, so use `live "/path", PageLive`

### Database & Ecto

- PostgreSQL is configured with Ecto in `lib/urielm/repo.ex`
- Development database: `urielm_dev` (configured in `config/dev.exs`)
- Run `mix ecto.create` to create the database
- Run `mix ecto.migrate` to run pending migrations
- Migrations are stored in `priv/repo/migrations/`

## Important Notes

### State Management

- **Server state**: Lives in LiveView assigns (`@count`, `@tasks`, etc.)
- **UI state**: Can live in Svelte (animations, local toggles, etc.)
- Keep business logic in Elixir, not Svelte
- Validate and persist data server-side

### Data Serialization

Always serialize complex data before passing to Svelte:

```elixir
defp serialize_items(items) do
  Enum.map(items, fn item ->
    %{
      id: to_string(item.id),        # Convert to string
      name: item.name,
      createdAt: item.inserted_at    # camelCase for JS
    }
  end)
end
```

### Build Artifacts

Generated/ignored files:
- `_build/` - Compiled Elixir
- `deps/` - Elixir dependencies
- `assets/node_modules/` - NPM packages
- `priv/static/assets/` - Compiled client JS/CSS
- `priv/svelte/` - SSR bundle

### Tailwind CSS v4

This project uses Tailwind v4 which:
- No longer needs `tailwind.config.js`
- Uses new import syntax in `app.css`:
  ```css
  @import "tailwindcss" source(none);
  @source "../css";
  @source "../js";
  @source "../../lib/urielm_web";
  ```
- **Never** use `@apply` in custom CSS

## Common Patterns

### Component with Props and Events

```svelte
<script>
  export let items = []
  export let activeId = null
  export let live

  function selectItem(id) {
    live.pushEvent('select_item', {item_id: id})
  }
</script>

<ul>
  {#each items as item}
    <li
      class:active={item.id === activeId}
      on:click={() => selectItem(item.id)}
    >
      {item.name}
    </li>
  {/each}
</ul>
```

```elixir
def render(assigns) do
  ~H"""
  <.svelte
    name="ItemList"
    props={%{
      items: serialize_items(@items),
      activeId: to_string(@active_id)
    }}
    socket={@socket}
  />
  """
end

def handle_event("select_item", %{"item_id" => id}, socket) do
  {:noreply, assign(socket, :active_id, String.to_integer(id))}
end
```

## Project-Specific Rules

1. **Use `mix precommit`** before committing changes (compiles, formats, runs tests)
2. **Always prefer editing** existing files over creating new ones
3. **Use the Req library** for HTTP requests, not httpoison/tesla
4. **Follow Phoenix 1.8 guidelines** in AGENTS.md (proper scope aliasing, no deprecated functions)
5. **Avoid LiveComponents** unless there's a specific need
6. **Database migrations**: Always create migrations before adding new tables/columns (`mix ecto.gen.migration migration_name`)

## Additional Documentation

- `README.md` - Setup instructions and examples
- `AGENTS.md` - Phoenix usage rules and guidelines
- `SESSION_CONTEXT.md` - Current session state and TODO items
- `docs/svelte-phoenix-integration.md` - Comprehensive Svelte integration guide
