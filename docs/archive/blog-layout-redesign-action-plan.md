# Blog Layout Redesign – Action Plan (Phoenix + Tailwind + daisyUI)

Goal: Turn the current “plain Markdown dump” blog into a focused reading experience that matches the rest of UrielM.dev, using your existing Tailwind + daisyUI setup.

---

## 0. Constraints & Context

- Stack: Phoenix 1.7+, HEEx templates, Tailwind, daisyUI themes defined in `assets/css/app.css`.
- Current blog page: single narrow column, minimal typography, no framing.
- You already have rich themes (`tokyo-night`, `catppuccin-*`) but are not leveraging them in the blog layout.

Focus: **post show page** first (single article). Blog index can be improved later.

---

## 1. Typography & Layout Decisions

### 1.1 Reading width & centering

- Use a **reading container** with:
  - max-width ≈ `70ch` for body text
  - full-width header, centered article
- Target class combo:
  - `max-w-[70ch] mx-auto px-4 sm:px-6 lg:px-0` for article
  - Wrap in an outer `max-w-5xl mx-auto` shell if you want sidebar later

### 1.2 Base typography rules

- Body text:
  - `text-base` or `text-[17px]`
  - `leading-relaxed` (or custom `1.7`)
- Paragraph spacing:
  - Tailwind `prose` utilities, or custom overrides
- Headings:
  - h1: `text-3xl sm:text-4xl font-bold tracking-tight`
  - h2: `text-2xl font-semibold mt-8 mb-3`
  - h3: `text-xl font-semibold mt-6 mb-2`

Plan:
- Enable Tailwind Typography plugin if not already.
- Use a custom `prose` style tuned for your dark/light themes.

---

## 2. Update Phoenix Blog Show Template

File: `lib/urielm_web/controllers/post_html/show.html.heex` (or equivalent)

### 2.1 Add structured header

Replace current minimal header with something like:

```heex
<div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10 lg:py-14">
  <p class="text-xs sm:text-[13px] text-base-content/60 mb-3">
    <.link navigate={~p"/blog"} class="inline-flex items-center gap-1 hover:text-primary">
      <!-- back arrow icon -->
      &larr; Back to blog
    </.link>
  </p>

  <header class="mb-8 lg:mb-10">
    <h1 class="text-3xl sm:text-4xl font-bold tracking-tight text-base-content mb-3">
      <%= @post.title %>
    </h1>

    <div class="flex flex-wrap items-center gap-3 text-xs sm:text-[13px] text-base-content/70">
      <span>
        <%= if @post.published_at do %>
          <%= Calendar.strftime(@post.published_at, "%b %d, %Y") %>
        <% else %>
          Draft
        <% end %>
      </span>

      <span class="hidden sm:inline text-base-content/40">•</span>

      <span class="inline-flex items-center gap-1">
        <span class="w-1.5 h-1.5 rounded-full bg-primary/70"></span>
        <span>Blog</span>
      </span>
    </div>
  </header>

  <article class="max-w-[70ch] text-base leading-relaxed">
    <!-- body goes here -->
  </article>
</div>
```

### 2.2 Wrap Markdown output in a `prose` container

Inside `article`, render markdown like:

```heex
<article class="prose prose-invert dark:prose-invert prose-neutral max-w-none text-base leading-relaxed">
  <%= markdown_to_html(@post.body) %>
</article>
```

Then tune prose colors via Tailwind config (see section 3).

---

## 3. Tailwind / Typography Styling

### 3.1 Enable typography plugin (if not already)

In `tailwind.config.js` (or PostCSS-based config):

```js
module.exports = {
  content: [
    "./js/**/*.{js,svelte}",
    "../lib/urielm_web/**/*.*ex"
  ],
  theme: {
    extend: {
      typography: (theme) => ({
        DEFAULT: {
          css: {
            maxWidth: "70ch",
            color: theme("colors.base-content / 0.9"),
            a: {
              color: theme("colors.primary"),
              textDecoration: "none",
              fontWeight: "500",
              "&:hover": {
                textDecoration: "underline",
              },
            },
            code: {
              fontSize: "0.9em",
              borderRadius: theme("borderRadius.md"),
              paddingInline: theme("spacing[1.5]"),
              paddingBlock: theme("spacing[0.5]"),
              backgroundColor: theme("colors.base-200"),
            },
            "h1,h2,h3,h4": {
              color: theme("colors.base-content"),
              fontWeight: "700",
            },
            pre: {
              backgroundColor: theme("colors.base-200"),
              borderRadius: theme("borderRadius.xl"),
              padding: theme("spacing.4"),
            },
          },
        },
        invert: {
          css: {
            color: theme("colors.base-content / 0.9"),
            a: { color: theme("colors.primary") },
            pre: { backgroundColor: theme("colors.base-300") },
            code: { backgroundColor: theme("colors.base-300") },
          },
        },
      }),
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    // existing daisyUI plugin etc.
  ]
};
```

### 3.2 Map to your daisyUI themes

Your `app.css` already defines:

- `--color-base-100`, `--color-base-200`, `--color-base-300`, `--color-base-content`, etc.

Ensure Tailwind uses those via DaisyUI’s generated palette so `prose` colors align automatically.

If needed, add small overrides in `app.css`:

```css
.prose {
  color: hsl(var(--bc) / 0.9);
}

.prose code {
  background-color: hsl(var(--b2));
}
```

---

## 4. Code Block & Inline Code Styling

### 4.1 Global code styles in `app.css`

Append near the bottom of `app.css`:

```css
.prose pre {
  border-radius: 1rem;
  border: 1px solid hsl(var(--b3) / 0.7);
  background: linear-gradient(
    135deg,
    hsl(var(--b2)),
    hsl(var(--b3))
  );
  padding: 1rem 1.25rem;
  overflow-x: auto;
}

.prose code {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
}

.prose :not(pre) > code {
  background-color: hsl(var(--b2));
  border-radius: 0.375rem;
  padding: 0.15rem 0.4rem;
  font-size: 0.9em;
}
```

This makes code blocks feel deliberate and inline code feel like a highlight, not noise.

---

## 5. Improve Blog Index Page (after show page is good)

Once the article view feels solid, update `/blog` listing.

### 5.1 Card list with clear hierarchy

- Use a simple vertical list (`space-y-6`)
- Each item:
  - Title (link)
  - Date
  - Optional excerpt
  - Subtle border or background

Example (in `index.html.heex`):

```heex
<div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10 lg:py-14">
  <header class="mb-8 lg:mb-10">
    <h1 class="text-3xl sm:text-4xl font-bold tracking-tight mb-2">
      Blog
    </h1>
    <p class="text-sm text-base-content/70 max-w-[60ch]">
      Essays, notes, and deep dives on Elixir, Phoenix, AI workflows, and whatever else you are obsessing over this week.
    </p>
  </header>

  <div class="space-y-6">
    <%= for post <- @posts do %>
      <article class="border border-base-300/70 bg-base-200/40 rounded-xl p-4 sm:p-5 hover:border-primary/60 transition-colors">
        <h2 class="text-lg sm:text-xl font-semibold mb-1">
          <.link navigate={~p"/blog/#{post.slug}"} class="hover:text-primary">
            <%= post.title %>
          </.link>
        </h2>

        <p class="text-xs text-base-content/60 mb-2">
          <%= Calendar.strftime(post.published_at, "%b %d, %Y") %>
        </p>

        <p class="text-sm text-base-content/80 line-clamp-3">
          <%= post.excerpt || String.slice(post.body, 0, 200) <> "…" %>
        </p>
      </article>
    <% end %>
  </div>
</div>
```

---

## 6. Theming & Consistency Checks

After implementation, validate:

- **Dark mode**: toggle between your daisyUI themes and confirm:
  - Body text remains readable
  - Code blocks have enough contrast
  - Links are visible but not screaming
- **Mobile**:
  - Padding feels right on small screens (`px-4` or `px-5`)
  - Headlines wrap gracefully
  - No horizontal scroll on code blocks
- **Desktop**:
  - Reading width feels comfortable
  - Outer whitespace feels intentional, not empty

---

## 7. Implementation Checklist

1. Update post show template with:
   - Strong header block
   - Centered article container (`max-w-[70ch]`)
   - Prose wrapper around Markdown body.
2. Add / enable Tailwind Typography plugin and configure prose styles.
3. Add `.prose` overrides for colors, code, and pre blocks in `app.css`.
4. Refine blog index `/blog` layout to match new article style.
5. Test across:
   - `tokyo-night`, `catppuccin-mocha`, `catppuccin-latte`
   - Mobile vs desktop
6. Write one **real** essay and read it end-to-end in the browser to judge pacing, not just markup.
