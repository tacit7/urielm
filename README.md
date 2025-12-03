# urielm.dev

Personal website built with Phoenix LiveView and Svelte, powered by `live_svelte` for seamless component integration.

## What's Included

This project demonstrates:

- **Phoenix 1.8.1** with **Phoenix LiveView 1.1.0**
- **Svelte 5.18** components integrated via **live_svelte 0.16.0**
- Server-side rendering (SSR) of Svelte components
- Bidirectional communication between LiveView and Svelte
- Custom esbuild configuration for dual builds (client + server)

## Architecture

### How It Works

1. **Dual Build System**: The custom `build.js` script compiles Svelte components twice:
   - **Client bundle** → `priv/static/assets/` (runs in browser)
   - **Server bundle** → `priv/svelte/` (for SSR)

2. **Component Registration**: Svelte components are registered as LiveView hooks in `assets/js/app.js`

3. **LiveView Integration**: The `.svelte` component function renders Svelte components within LiveView templates

4. **State Management**: LiveView manages state on the server, Svelte handles UI reactivity

### Data Flow

```
User clicks button in Svelte
    ↓
Svelte calls live.pushEvent('increment', {})
    ↓
LiveView receives event in handle_event/3
    ↓
LiveView updates assigns (count: count + 1)
    ↓
LiveView re-renders with new props
    ↓
Svelte component receives new props
    ↓
Svelte reactively updates DOM
```

## Project Structure

```
urielm/
├── assets/
│   ├── build.js              # Custom esbuild config (dual build)
│   ├── package.json          # NPM dependencies
│   ├── js/
│   │   ├── app.js            # Client entry (registers components)
│   │   └── server.js         # Server entry (exports for SSR)
│   └── svelte/
│       └── Counter.svelte    # Example Svelte component
├── lib/
│   ├── urielm/               # Domain logic
│   └── urielm_web/           # Web interface
│       ├── live/
│       │   └── counter_live.ex
│       └── urielm_web.ex     # Imports LiveSvelte
└── config/                   # Configuration files
```

## Getting Started

### Prerequisites

- Elixir 1.15+
- Phoenix 1.8+
- Node.js (for npm)

### Setup

1. **Install dependencies**:
   ```bash
   cd urielm
   mix deps.get
   cd assets && npm install && cd ..
   ```

   Or use the shortcut:
   ```bash
   mix setup
   ```

2. **Build assets**:
   ```bash
   cd assets && node build.js && cd ..
   ```

3. **Start the Phoenix server**:
   ```bash
   mix phx.server
   ```

4. **Visit** [`localhost:4000`](http://localhost:4000)

You should see a counter with increment/decrement buttons. The counter state is managed by Phoenix LiveView, but the UI is rendered by a Svelte component.

## Development

### Watch Mode

When you run `mix phx.server`, the custom build script runs in watch mode automatically. Any changes to Svelte components will trigger a rebuild and browser refresh.

### Adding New Components

1. Create a new `.svelte` file in `assets/svelte/`
2. Import it in `assets/js/app.js`:
   ```javascript
   import MyComponent from "../svelte/MyComponent.svelte"

   let Hooks = getHooks({
     Counter,
     MyComponent  // Add here
   })
   ```

3. Use it in any LiveView:
   ```elixir
   def render(assigns) do
     ~H"""
     <.svelte
       name="MyComponent"
       props={%{someProp: @some_value}}
       socket={@socket}
     />
     """
   end
   ```

## Example: Counter Component

### Svelte Component (`assets/svelte/Counter.svelte`)

```svelte
<script>
  export let count = 0
  export let live

  function increment() {
    live.pushEvent('increment', {})
  }

  function decrement() {
    live.pushEvent('decrement', {})
  }
</script>

<div>
  <h2>Counter: {count}</h2>
  <button on:click={decrement}>Decrement</button>
  <button on:click={increment}>Increment</button>
</div>
```

### LiveView (`lib/urielm_web/live/counter_live.ex`)

```elixir
defmodule UrielmWeb.CounterLive do
  use UrielmWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

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

## Key Features

### 1. Server-Side Rendering

Svelte components are rendered on the server first for fast initial page load:

```javascript
// assets/js/server.js
import * as Components from "../svelte/**/*.svelte"
import {getRender} from "live_svelte"

export const render = getRender(Components)
```

### 2. Reactive Props

LiveView assigns automatically flow to Svelte props:

```elixir
# LiveView
assign(socket, :count, 42)

# Becomes available in Svelte as:
export let count  // value: 42
```

### 3. Event Handling

Svelte can push events back to LiveView:

```javascript
// In Svelte
live.pushEvent('my_event', {data: 'value'})
```

```elixir
# In LiveView
def handle_event("my_event", %{"data" => data}, socket) do
  # Handle event
  {:noreply, socket}
end
```

## Configuration Files

### `mix.exs`

Added `live_svelte` dependency and custom build aliases:

```elixir
{:live_svelte, "~> 0.16.0"}

# ...

"assets.build": ["compile", "cmd --cd assets node build.js"]
```

### `config/dev.exs`

Configured custom build script watcher:

```elixir
watchers: [
  node: ["build.js", "--watch", cd: Path.expand("../assets", __DIR__)]
]
```

### `lib/urielm_web.ex`

Imported LiveSvelte for use in templates:

```elixir
defp html_helpers do
  quote do
    import LiveSvelte
    # ...
  end
end
```

## Troubleshooting

### Components not updating

Make sure you've registered the component in `assets/js/app.js`:

```javascript
let Hooks = getHooks({
  MyComponent  // Must match the name used in .svelte template
})
```

### Build errors

Run the build manually to see detailed errors:

```bash
cd assets && node build.js
```

### Props not passing correctly

Ensure you're passing the socket:

```elixir
<.svelte
  name="Counter"
  props={%{count: @count}}
  socket={@socket}  ← Required
/>
```

## Resources

- [live_svelte GitHub](https://github.com/woutdp/live_svelte)
- [Phoenix LiveView Docs](https://hexdocs.pm/phoenix_live_view)
- [Svelte Docs](https://svelte.dev/docs)
- [esbuild Docs](https://esbuild.github.io/)

## Learn More About Phoenix

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
