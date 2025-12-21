# Theme Switching Fix - daisyUI + Tailwind v4

## Problem Statement

Theme switching was not working despite:
- Converting all hardcoded colors to semantic daisyUI classes (`bg-base-100`, `text-base-content`, etc.)
- Implementing a functional ThemeSelector component
- JavaScript correctly setting `data-theme` attribute on document root

The symptoms were that clicking different themes in the selector would change the `data-theme` attribute, but the colors remained the same across all themes.

## Root Cause Analysis

### The Core Issue
**daisyUI theme CSS was not being generated at all.** The configuration syntax in `assets/css/app.css` was incorrect for Tailwind v4's plugin system, resulting in:
- No `[data-theme=...]` selectors in the compiled CSS
- No CSS variable definitions for different themes
- Only default `:root` variables being applied

### Investigation Process

1. **Checked HTML Output**
   ```bash
   curl -s http://localhost:4001/ | grep -o 'bg-base-[0-9]*'
   ```
   Result: Semantic classes were present in HTML ✓

2. **Checked Compiled CSS**
   ```bash
   grep '\[data-theme=' priv/static/assets/css/app.css
   ```
   Result: No theme selectors found ✗

3. **Checked CSS Variable Definitions**
   ```bash
   grep -E '\-\-color-(base-100|primary):' priv/static/assets/css/app.css
   ```
   Result: No variable definitions ✗

4. **Examined daisyUI Plugin**
   - Found default config: `themes: ["light --default", "dark --prefersdark"]`
   - Discovered plugin generates selectors like `[data-theme=${themeName}]`

### What Was Wrong

#### 1. Initial Configuration Had Custom Theme Definitions
```css
/* This prevented built-in themes from generating */
@plugin "../vendor/daisyui-theme" {
  name: "dark";
  default: false;
  prefersdark: true;
  --color-base-100: oklch(15% 0.016 252.42);
  /* ... */
}
```

#### 2. Array Syntax Didn't Work
```css
/* This was ignored by the plugin */
@plugin "../vendor/daisyui" {
  themes: ["light", "dark", "dracula", "synthwave", "business", "dim"];
}
```

#### 3. No Theme-Specific CSS Generated
The plugin wasn't outputting the required structure:
```css
/* What we needed but wasn't being generated */
[data-theme="dark"] {
  --color-base-100: oklch(...);
  --color-primary: oklch(...);
  /* ... */
}

[data-theme="dracula"] {
  --color-base-100: oklch(...);
  --color-primary: oklch(...);
  /* ... */
}
```

## The Solution

### Configuration Change
Changed `assets/css/app.css` from this:
```css
@plugin "../vendor/daisyui" {
  themes: ["light", "dark", "dracula", "synthwave", "business", "dim"];
}

@plugin "../vendor/daisyui-theme" {
  name: "dark";
  /* custom theme definition */
}

@plugin "../vendor/daisyui-theme" {
  name: "light";
  /* custom theme definition */
}
```

To this:
```css
@plugin "../vendor/daisyui" {
  themes: all;
}
```

### Why This Works
- `themes: all` is the correct syntax for Tailwind v4
- Generates all 35 built-in daisyUI themes
- Each theme gets proper `[data-theme=...]` selectors
- All CSS variables are defined for each theme

### Verification
After the fix:
```bash
$ grep -oE '\[data-theme=[a-z]+\]' priv/static/assets/css/app.css | sort | uniq
[data-theme=abyss]
[data-theme=acid]
[data-theme=aqua]
[data-theme=autumn]
[data-theme=black]
[data-theme=bumblebee]
[data-theme=business]
[data-theme=caramellatte]
[data-theme=cmyk]
[data-theme=coffee]
[data-theme=corporate]
[data-theme=cupcake]
[data-theme=cyberpunk]
[data-theme=dark]
[data-theme=dim]
[data-theme=dracula]
[data-theme=emerald]
[data-theme=fantasy]
[data-theme=forest]
[data-theme=garden]
[data-theme=halloween]
[data-theme=lemonade]
[data-theme=light]
[data-theme=lofi]
[data-theme=luxury]
[data-theme=night]
[data-theme=nord]
[data-theme=pastel]
[data-theme=retro]
[data-theme=silk]
[data-theme=sunset]
[data-theme=synthwave]
[data-theme=valentine]
[data-theme=winter]
[data-theme=wireframe]
```

## Files Modified

### Configuration
- `assets/css/app.css` - Fixed daisyUI plugin configuration

### Svelte Components (Semantic Class Conversion)
- `assets/svelte/Navbar.svelte` - Converted "Get in Touch" button to `btn-primary`
- `assets/svelte/SubNav.svelte` - Replaced hardcoded colors with semantic classes
- `assets/svelte/CodeSnippetCard.svelte` - Converted backgrounds to `bg-base-*`

### LiveView Templates (Semantic Class Conversion)
- `lib/urielm_web/live/home_live.ex` - All sections converted to semantic classes
- `lib/urielm_web/live/references_live.ex` - Entire page converted to semantic classes

## Semantic Class Mapping

For consistent theming, use these daisyUI semantic classes:

| Old Hardcoded Class | New Semantic Class | Purpose |
|-------------------|-------------------|---------|
| `bg-[#0f0f0f]` | `bg-base-100` | Main background |
| `bg-[#212121]` | `bg-base-200` | Secondary background |
| `bg-[#2a2a2a]` | `bg-base-300` | Tertiary background |
| `text-white` | `text-base-content` | Primary text color |
| `border-white/10` | `border-base-300` | Borders |
| `bg-purple-600` | `bg-primary` or `btn-primary` | Primary accent |
| `text-purple-400` | `text-primary` | Primary text accent |
| `bg-black dark:bg-white` | `btn-primary` | Buttons |
| `text-gray-600` | `text-base-content/60` | Muted text |

## Key Learnings

### 1. Tailwind v4 Plugin Configuration
- **Different syntax** from Tailwind v3
- **Use `themes: all`** instead of array of theme names
- **Simpler is better** - don't override with custom themes unless necessary

### 2. Debugging CSS Generation
When themes aren't working:
1. Check if semantic classes are in HTML
2. Check if `[data-theme=...]` selectors exist in CSS
3. Check if CSS variables are defined for each theme
4. Verify Tailwind watcher is running and rebuilding

### 3. Development Environment Issues
- Multiple Phoenix servers cause port conflicts
- Multiple Tailwind watchers cause build issues
- Always kill old processes: `pkill -f 'mix phx.server' && pkill -f 'tailwind.*urielm'`

### 4. Semantic Classes Are Essential
Theme switching **only works** with semantic classes. Hardcoded colors like:
- `bg-[#0f0f0f]`
- `text-white`
- `bg-gray-900`

Will **never respond** to theme changes because they don't use CSS variables.

## Testing Theme Switching

1. **Start dev server**
   ```bash
   PORT=4001 mix phx.server
   ```

2. **Open browser**
   ```
   http://localhost:4001
   ```

3. **Test theme selector**
   - Click theme selector in navbar
   - Select different themes (Dark, Dracula, Synthwave, etc.)
   - Verify colors change across entire page
   - Check that navigation, cards, buttons, borders all update

4. **Verify localStorage**
   ```javascript
   // In browser console
   localStorage.getItem('phx:theme') // Should show selected theme
   ```

5. **Verify data-theme attribute**
   ```javascript
   // In browser console
   document.documentElement.getAttribute('data-theme') // Should match selected theme
   ```

## Deployment Notes

### Production Deployment Checklist
1. Commit CSS configuration changes
2. Push to GitHub
3. Pull on production server
4. Rebuild Docker container with `--build` flag
5. Verify themes work in production

### Common Production Issues
- **Old Docker image cached**: Use `docker-compose up -d --build`
- **DATABASE_URL conflicts**: Remove from shell profile (`.bashrc`)
- **Static assets not rebuilt**: Ensure Tailwind runs in Docker build

## Related Commits

- `a082d9b` - Convert Svelte components to semantic daisyUI classes
- `4eb247b` - Convert all hardcoded colors to daisyUI semantic classes (LiveView pages)
- `29a3545` - Fix ThemeSelector component (onMount bug)
- `e23c409` - Add multi-theme switcher with 5 curated themes
- `19722ad` - Remove all light theme variants from references page

## References

- [daisyUI Themes Documentation](https://daisyui.com/docs/themes/)
- [Tailwind CSS v4 Documentation](https://tailwindcss.com/docs)
- [daisyUI GitHub](https://github.com/saadeghi/daisyui)
- Project: `assets/css/app.css` - Theme configuration
- Project: `assets/svelte/ThemeSelector.svelte` - Theme switcher component
