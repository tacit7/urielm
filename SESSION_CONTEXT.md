# Session Context - urielm.dev

**Last Updated**: December 2, 2025
**Project**: Personal website for urielm.dev
**Stack**: Phoenix 1.8.1 + LiveView 1.1.0 + Svelte 5.18 + live_svelte 0.16.0

---

## Project Overview

This is a Phoenix LiveView application integrated with Svelte components for building the urielm.dev personal website. The project demonstrates a hybrid architecture where:

- **Phoenix LiveView** manages server-side state, routing, and business logic
- **Svelte** handles rich client-side UI and interactivity
- **live_svelte** bridges the two with server-side rendering and bidirectional communication

## Current State

### What Was Built This Session

1. **Complete Phoenix + Svelte Integration**
   - Custom dual build system (client + server bundles)
   - Svelte components registered as LiveView hooks
   - Example Counter component demonstrating state management

2. **Project Structure**
   - `lib/urielm/` - Domain logic (currently minimal)
   - `lib/urielm_web/` - Web interface with LiveView
   - `assets/svelte/` - Svelte components
   - `assets/js/` - Client and server entry points
   - `assets/build.js` - Custom esbuild configuration

3. **Documentation**
   - `README.md` - Project setup and usage
   - `../docs/svelte-phoenix-integration.md` - Comprehensive integration guide
   - This session context file

### Key Files

```
urielm/
├── mix.exs                           # App: :urielm, Module: Urielm
├── config/
│   └── dev.exs                       # Watchers for node build.js
├── lib/
│   ├── urielm.ex                     # Main application module
│   ├── urielm/application.ex         # OTP application
│   ├── urielm_web.ex                 # Web module (imports LiveSvelte)
│   └── urielm_web/
│       ├── endpoint.ex
│       ├── router.ex                 # Routes to CounterLive
│       └── live/
│           └── counter_live.ex       # Example LiveView
├── assets/
│   ├── build.js                      # Dual build (client + server)
│   ├── package.json                  # Svelte dependencies
│   ├── js/
│   │   ├── app.js                    # Registers Svelte hooks
│   │   └── server.js                 # Exports for SSR
│   └── svelte/
│       └── Counter.svelte            # Example component
└── priv/
    ├── static/assets/                # Client bundle
    └── svelte/                       # Server bundle (SSR)
```

## Architecture

### Data Flow

```
User Action (Svelte)
    ↓
live.pushEvent('increment', {})
    ↓
LiveView.handle_event/3
    ↓
Update socket assigns
    ↓
Re-render with new props
    ↓
Svelte receives new props
    ↓
Reactive DOM update
```

### Build System

The custom `assets/build.js` script runs **two esbuild processes**:

1. **Client Build**
   - Entry: `js/app.js`
   - Output: `priv/static/assets/app.js`
   - Target: Browser
   - Registers components as LiveView hooks

2. **Server Build**
   - Entry: `js/server.js`
   - Output: `priv/svelte/server.js`
   - Target: Node.js
   - Exports components for SSR

### Component Registration

```javascript
// assets/js/app.js
import Counter from "../svelte/Counter.svelte"
import {getHooks} from "live_svelte"

let Hooks = getHooks({
  Counter  // Creates hook for <.svelte name="Counter" />
})
```

### LiveView Integration

```elixir
# lib/urielm_web/live/counter_live.ex
def render(assigns) do
  ~H"""
  <.svelte
    name="Counter"
    props={%{count: @count}}
    socket={@socket}
  />
  """
end
```

## Dependencies

### Elixir (mix.exs)

- `phoenix ~> 1.8.1`
- `phoenix_live_view ~> 1.1.0`
- `live_svelte ~> 0.16.0`
- `bandit ~> 1.5` (HTTP server)
- `tailwind ~> 0.3` (CSS)

### JavaScript (package.json)

- `svelte ^5.18.0`
- `esbuild ^0.27.0`
- `esbuild-svelte ^0.9.3`
- `esbuild-plugin-import-glob ^0.1.1`
- `svelte-preprocess ^6.0.3`

## Development Workflow

### Starting the Server

```bash
cd urielm
mix phx.server
# Visit http://localhost:4000
```

The watchers automatically:
- Rebuild Svelte when `.svelte` files change
- Recompile Elixir when `.ex` files change
- Reload browser when assets change

### Adding New Components

1. Create `assets/svelte/MyComponent.svelte`
2. Import in `assets/js/app.js`:
   ```javascript
   import MyComponent from "../svelte/MyComponent.svelte"

   let Hooks = getHooks({
     Counter,
     MyComponent
   })
   ```
3. Use in any LiveView:
   ```elixir
   <.svelte name="MyComponent" props={%{}} socket={@socket} />
   ```

## Next Steps / TODO

### Immediate

- [ ] Remove example Counter component (or keep as reference)
- [ ] Design actual page structure for urielm.dev
- [ ] Set up routing for main sections (home, about, projects, etc.)
- [ ] Create layout components

### Content Pages

- [ ] Home/landing page
- [ ] About page
- [ ] Projects showcase
- [ ] Blog (if desired)
- [ ] Contact/links

### Svelte Components to Build

- [ ] Navigation component
- [ ] Project card component
- [ ] Skills/tech stack display
- [ ] Animated hero section
- [ ] Footer component

### Infrastructure

- [ ] Add Ecto if database needed (currently no-ecto)
- [ ] Set up deployment pipeline
- [ ] Configure production secrets
- [ ] Add analytics (if desired)
- [ ] SEO optimization (meta tags, etc.)

### Styling

- [ ] Design system / color palette
- [ ] Typography choices
- [ ] Responsive design breakpoints
- [ ] Dark mode support
- [ ] Animation/transition strategy

## Important Notes

### Hooks vs Components

- **Hooks** in Phoenix LiveView are JavaScript lifecycle callbacks
- `live_svelte` uses hooks to mount/update/destroy Svelte components
- Each Svelte component registered in `getHooks()` becomes a hook
- The hook manages the Svelte component lifecycle

### State Management

- **Server state** lives in LiveView assigns (`@count`, etc.)
- **UI state** can live in Svelte (animations, transitions, etc.)
- Events flow from Svelte → LiveView via `live.pushEvent()`
- Props flow from LiveView → Svelte via assigns

### Build Artifacts

Generated files (can be ignored in git):
- `_build/` - Compiled Elixir
- `deps/` - Elixir dependencies
- `assets/node_modules/` - NPM packages
- `priv/static/assets/` - Compiled JS/CSS
- `priv/svelte/` - SSR bundle

### Configuration

- Development port: 4000 (configurable in `config/dev.exs`)
- Build watchers run automatically with `mix phx.server`
- Live reload enabled for `.ex`, `.heex`, and `.svelte` files

## Reference Documentation

- **Integration Guide**: `../docs/svelte-phoenix-integration.md`
- **Phoenix LiveView**: https://hexdocs.pm/phoenix_live_view
- **live_svelte**: https://github.com/woutdp/live_svelte
- **Svelte**: https://svelte.dev/docs

## Common Tasks

### Rebuild Assets
```bash
cd assets && node build.js && cd ..
```

### Reset Dependencies
```bash
mix deps.clean --all
mix deps.get
cd assets && rm -rf node_modules && npm install && cd ..
```

### Format Code
```bash
mix format
```

### Run Tests
```bash
mix test
```

## Known Issues / Gotchas

1. **Tailwind Download**: Initial setup may fail downloading Tailwind binary
   - Workaround: Build JS assets first with `cd assets && node build.js`

2. **Component Names**: Must match exactly between registration and usage
   - Registration: `getHooks({Counter})`
   - Usage: `<.svelte name="Counter" />`

3. **Props Serialization**: Large integers should be converted to strings
   - IDs from database should use `to_string(id)`

4. **Socket Required**: Always pass `socket={@socket}` to `.svelte` component

## Session Summary

Created a production-ready Phoenix + Svelte foundation for urielm.dev. The architecture is solid and scalable. Next session should focus on designing and building the actual content pages and components for the personal website.

The dual build system provides excellent DX with hot reload, while SSR ensures fast initial page loads. The state management split (server for data, client for UI) keeps the codebase clean and maintainable.

---

**Ready for development**: The project is set up and can be extended with real content and features.
