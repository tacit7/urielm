# Components Documentation

Component architecture patterns, implementations, and debugging guides.

---

## ShellLive - Persistent Layout Container

**File:** `lib/urielm_web/live/shell_live.ex`
**First Introduced:** Commit `69be99e` - "Implement persistent navbar with ShellLive pattern"
**Created:** 2025-12-21

### Purpose

ShellLive implements the **persistent shell pattern** to eliminate navbar flickering during navigation. It acts as a permanent container that never unmounts, rendering child pages inside it via `live_render/3`.

### Problem It Solves

**Before ShellLive:**
```
User clicks /prompts → /forum
  ↓
LiveView unmounts entire page (including navbar)
  ↓
Navbar disappears
  ↓
New page mounts (including navbar)
  ↓
Navbar reappears
  ↓
Result: Visible flicker
```

**After ShellLive:**
```
User clicks /prompts → /forum
  ↓
ShellLive stays mounted (navbar persists)
  ↓
Only @live_action changes (:prompts → :forum)
  ↓
Child LiveView swaps (PromptsLive → ForumLive)
  ↓
Result: Smooth transition, navbar never disappears
```

### How It Works

#### 1. Router Configuration

All main app pages route through ShellLive with different `live_action` atoms:

```elixir
# router.ex
live_session :default do
  live "/", ShellLive, :home
  live "/blog", ShellLive, :blog_index
  live "/blog/:slug", ShellLive, :blog_show
  live "/prompts", ShellLive, :prompts
  live "/forum", ShellLive, :forum
  live "/forum/t/:thread_id", ShellLive, :thread
  # etc.
end
```

#### 2. ShellLive Responsibilities

**Render the persistent chrome:**
```elixir
def render(assigns) do
  ~H"""
  <div class="min-h-screen bg-base-100">
    <div id="navbar-container" phx-update="ignore" phx-hook="NavbarActiveLinks">
      <.Navbar currentPage={@current_page} currentUser={...} />
    </div>

    <main class="pt-16">
      <%= live_render(@socket, child_module(@live_action),
        id: "page-#{@live_action}",
        session: %{
          "current_user_id" => current_user_id(@current_user),
          "child_params" => @child_params
        }
      ) %>
    </main>
  </div>
  """
end
```

**Map live_action to child modules:**
```elixir
defp child_module(:home), do: UrielmWeb.HomeLive
defp child_module(:forum), do: UrielmWeb.ForumLive
defp child_module(:blog_index), do: UrielmWeb.BlogLive
# etc.
```

**Pass route params to children:**
```elixir
def handle_params(params, _url, socket) do
  socket
  |> assign(:live_action, socket.assigns.live_action)
  |> assign(:current_page, page_name_for_action(socket.assigns.live_action))
  |> assign(:child_params, params)  # ← Passed to children via session
end
```

#### 3. Child LiveView Requirements

Child LiveViews must:

**a) Handle params from session (not router):**
```elixir
def mount(params, session, socket) do
  # Handle both direct mount and child mount
  child_params = case params do
    :not_mounted_at_router -> session["child_params"] || %{}
    params -> params
  end

  slug = child_params["slug"]
  # ... use params
end
```

**b) NOT use `handle_params/3`:**
```elixir
# ❌ This will crash in child LiveViews
def handle_params(params, _url, socket) do
  # Error: "handle_params/3 is not allowed on child LiveViews"
end
```

**c) Render content only (no Layouts.app wrapper):**
```elixir
def render(assigns) do
  ~H"""
  <div class="container">
    <!-- Page content only -->
  </div>
  """
end
```

#### 4. Navigation Links

**All in-app links use patch navigation:**
```heex
<!-- Navbar links (Svelte) -->
<a href="/forum" data-phx-link="patch" data-phx-link-state="push">
  Forum
</a>

<!-- Phoenix templates -->
<.link patch={~p"/prompts"}>Prompts</.link>
```

**Rule:**
- Use `patch` for in-shell pages
- Use `navigate` only for auth pages (outside shell)

### Key Implementation Details

#### phx-update="ignore"

The navbar container uses `phx-update="ignore"` to prevent LiveView from touching it:

```heex
<div id="navbar-container" phx-update="ignore" phx-hook="NavbarActiveLinks">
  <.Navbar ... />
</div>
```

This keeps the navbar in the DOM across navigations, but **prevents props from updating**.

#### NavbarActiveLinks Hook

Since the navbar is ignored by LiveView, we use a JavaScript hook to update active link styling:

```javascript
const NavbarActiveLinks = {
  mounted() {
    // Update on initial mount
    this.updateActiveLinks()

    // Update on every navigation
    window.addEventListener('phx:page-loading-stop', () => {
      this.updateActiveLinks()
    })
  },

  updateActiveLinks() {
    const path = window.location.pathname
    // Detect active page from URL
    // Add/remove CSS classes to highlight active link
  }
}
```

#### Varying Child LiveView IDs

Each child gets a unique ID based on live_action:

```elixir
live_render(@socket, child_module(@live_action),
  id: "page-#{@live_action}"  # ← Forces remount when action changes
)
```

This ensures the child LiveView remounts when switching between pages (e.g., `:forum` → `:prompts`).

### Common Issues & Debugging

#### Issue: Navbar Still Flickering

**Symptom:** Navbar disappears and reappears on navigation

**Possible Causes:**
1. **Child LiveView still has `Layouts.app` wrapper**
   - Check: Search child LiveView for `<Layouts.app`
   - Fix: Remove wrapper, render content only

2. **Using `navigate` instead of `patch`**
   - Check: Links should have `data-phx-link="patch"` or use `<.link patch={...}>`
   - Fix: Change `navigate` to `patch` for in-shell routes

3. **Route not going through ShellLive**
   - Check: Verify route in `router.ex` uses `ShellLive, :action_name`
   - Fix: Update router to route through ShellLive

#### Issue: Active Link Not Highlighting

**Symptom:** Clicked link doesn't turn primary color

**Possible Causes:**
1. **NavbarActiveLinks hook not attached**
   - Check: Navbar container should have `phx-hook="NavbarActiveLinks"`
   - Fix: Add hook attribute to navbar container

2. **Hook not registered**
   - Check: `Hooks.NavbarActiveLinks = NavbarActiveLinks` in app.js
   - Fix: Register the hook

3. **URL path not matching**
   - Check: Browser console, inspect `window.location.pathname`
   - Fix: Update path matching logic in `updateActiveLinks()`

#### Issue: Child LiveView Crashes on Mount

**Symptom:** `FunctionClauseError` when mounting child LiveView

**Possible Causes:**
1. **Mount expects params map, gets `:not_mounted_at_router`**
   - Check: Child's mount signature: `def mount(params, session, socket)`
   - Fix: Handle both cases:
   ```elixir
   child_params = case params do
     :not_mounted_at_router -> session["child_params"] || %{}
     params -> params
   end
   ```

2. **Child uses `handle_params/3`**
   - Check: Search child for `def handle_params`
   - Fix: Remove it; only root LiveView (ShellLive) can have handle_params

#### Issue: Props Not Updating in Child

**Symptom:** Child LiveView doesn't receive updated data on navigation

**Possible Causes:**
1. **Params not passed through session**
   - Check: ShellLive's `live_render` includes `session: %{"child_params" => @child_params}`
   - Fix: Ensure params are assigned in ShellLive's `handle_params`

2. **Child LiveView ID not varying**
   - Check: `id: "page-#{@live_action}"` in live_render
   - Fix: Use dynamic ID to force remount on action change

#### Issue: Layout Shift on Navigation

**Symptom:** Content jumps horizontally when navigating

**Possible Causes:**
1. **Scrollbar appearing/disappearing**
   - Check: Short pages vs tall pages
   - Fix: Add `overflow-y-scroll` to root html element

2. **Inconsistent padding/margins**
   - Check: Child pages should NOT have top padding (ShellLive's main has `pt-16`)
   - Fix: Remove duplicate `pt-16` from child page containers

### Testing Checklist

When modifying ShellLive or adding new routes:

- [ ] Navbar stays visible when navigating between all pages
- [ ] Active link highlights correctly on all pages
- [ ] No horizontal layout shift on navigation
- [ ] Child LiveView mounts without errors
- [ ] Params (slug, id, etc.) passed correctly to children
- [ ] Auth pages (signin/signup) still work (they're outside shell)
- [ ] Flash messages display correctly
- [ ] Browser back/forward buttons work

### Files Involved

**Core Shell:**
- `lib/urielm_web/live/shell_live.ex` - Shell container
- `lib/urielm_web/router.ex` - Routes through shell
- `lib/urielm_web/components/layouts.ex` - Layouts.app (not used by shell children)
- `lib/urielm_web/components/layouts/root.html.heex` - Root HTML with scrollbar fix

**Frontend:**
- `assets/svelte/Navbar.svelte` - Navbar component with patch links
- `assets/js/app.js` - NavbarActiveLinks hook

**Child LiveViews:**
- All pages in `lib/urielm_web/live/*.ex` (except SigninLive, SignupLive)

### Related Documentation

- `docs/persistent-navbar-shell-action-plan.md` - Original implementation plan
- `docs/CODE_GUIDELINES.md` - Routing and LiveView guidelines
- `CLAUDE.md` - Project architecture overview

---

## Future Components

Additional component documentation will be added here as needed.
