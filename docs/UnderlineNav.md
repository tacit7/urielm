# UnderlineNav Component

A reusable GitHub-style underline navigation component for tab-based interfaces.

## Features

- GitHub-style underline active state
- Optional SVG icons
- Optional count badges
- Responsive with horizontal scroll on mobile
- Three size variants (sm, md, lg)
- Accessibility support (ARIA roles)
- LiveView or callback-based event handling

## Usage

### In LiveView (Elixir)

```elixir
defmodule MyAppWeb.MyLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte
      name="UnderlineNav"
      props={%{
        items: [
          %{
            key: "overview",
            label: "Overview",
            icon: "M0 1.75C0 .784.784 0 1.75 0h12.5C15.216 0 16 .784...",
            count: 5
          },
          %{
            key: "files",
            label: "Files",
            icon: "M3.75 1.5a.25.25 0 0 0-.25.25v11.5c0 .138...",
            count: 23
          },
          %{
            key: "settings",
            label: "Settings"
          }
        ],
        activeKey: @active_tab,
        showCounts: true,
        size: "md"
      }}
      socket={@socket}
    />
    """
  end

  def handle_event("tab_change", %{"key" => key}, socket) do
    {:noreply, assign(socket, :active_tab, key)}
  end
end
```

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `items` | `Array<TabItem>` | `[]` | Array of tab configuration objects |
| `activeKey` | `string` | `''` | Currently active tab key |
| `onTabChange` | `Function` | `() => {}` | Callback when tab clicked (non-LiveView) |
| `showCounts` | `boolean` | `true` | Whether to show count badges |
| `size` | `'sm' \| 'md' \| 'lg'` | `'md'` | Size variant |
| `live` | `LiveSocket` | - | LiveView socket (auto-injected) |

### TabItem Object

```javascript
{
  key: string,        // Unique identifier (required)
  label: string,      // Display text (required)
  icon?: string,      // SVG path data (optional)
  count?: number      // Count badge number (optional)
}
```

## Icon Sources

Icons use 16x16 viewBox SVG paths. Compatible sources:

- [GitHub Octicons](https://primer.style/foundations/icons) - Free, MIT licensed
- [Heroicons](https://heroicons.com/) - Free, MIT licensed
- Custom SVG paths

### Example Icon Extraction

From Octicons:
```html
<!-- GitHub shows this -->
<svg viewBox="0 0 16 16">
  <path d="M0 1.75C0 .784.784 0 1.75 0h12.5..."/>
</svg>

<!-- Extract just the path d attribute -->
icon: "M0 1.75C0 .784.784 0 1.75 0h12.5..."
```

## Examples

### Basic Tabs (No Icons)

```elixir
items: [
  %{key: "all", label: "All"},
  %{key: "active", label: "Active"},
  %{key: "completed", label: "Completed"}
]
```

### Tabs with Counts

```elixir
items: [
  %{key: "inbox", label: "Inbox", count: 12},
  %{key: "archive", label: "Archive", count: 156},
  %{key: "spam", label: "Spam", count: 3}
]
```

### Full Featured

```elixir
items: [
  %{
    key: "code",
    label: "Code",
    icon: "m11.28 3.22 4.25 4.25a.75.75 0 0 1 0 1.06l-4.25...",
    count: nil
  },
  %{
    key: "issues",
    label: "Issues",
    icon: "M8 9.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Z...",
    count: 8
  },
  %{
    key: "pulls",
    label: "Pull requests",
    icon: "M1.5 3.25a2.25 2.25 0 1 1 3 2.122v5.256...",
    count: 3
  }
]
```

## Size Variants

```elixir
# Small (mobile-friendly)
size: "sm"  # px-3 py-1.5 text-xs

# Medium (default)
size: "md"  # px-4 py-2 text-sm

# Large
size: "lg"  # px-5 py-3 text-base
```

## Styling

The component uses Tailwind/DaisyUI classes:

- `border-primary` - Active tab underline color
- `text-base-content` - Active text color
- `text-base-content/60` - Inactive text color
- `badge-ghost` - Count badge style

Customize via DaisyUI theme or Tailwind config.

## Accessibility

- Proper ARIA roles (`tablist`, `tab`)
- `aria-selected` state management
- `aria-controls` linking to panels
- Keyboard navigation support (via browser defaults)

## Related Components

- `SubNav.svelte` - Original DaisyUI tabs-based navigation (deprecated)
- Use `UnderlineNav` for all new implementations
