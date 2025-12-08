# Blog Index Redesign – Action Plan (Svelte + Tailwind + daisyUI)

Audience: Junior dev. Follow this step by step. When in doubt, keep it simple and consistent with the rest of the app.

Goal: Redesign the `/blog` index page using Svelte, Tailwind, and daisyUI so that it feels like a focused, modern reading hub instead of a plain list.

---

## 1. Requirements & UX Goals

### 1.1 Functional requirements

- Display a list of blog posts.
- Each post item must show:
  - Title
  - Published date
  - Short excerpt (or truncated body)
- Clicking a post navigates to `/blog/:slug`.
- Layout must be responsive:
  - Mobile: full-width stacked cards
  - Desktop: centered column with comfortable reading width

### 1.2 Visual / UX goals

- Strong header at the top: `Blog` + short description.
- Content column centered on larger screens.
- Cards with subtle hierarchy (light borders, hover feedback).
- The latest post should feel slightly more prominent than the rest (but not loud).
- Works across daisyUI themes (dark and light).

---

## 2. File / Component Structure

Assumption: You already have a Svelte setup under `assets/svelte` (or similar). Adjust paths to match the real project.

### 2.1 Create a dedicated BlogIndex component

Create a new file:

```text
assets/svelte/blog/BlogIndex.svelte
```

This component will:
- Accept a list of posts as a prop.
- Render the header and the card list.
- Handle navigation to post pages (via standard `<a>` links or your router).

### 2.2 Expected `posts` data shape

The Svelte component should expect something like this:

```ts
type BlogPostSummary = {
  id: number | string
  title: string
  slug: string
  published_at: string  // ISO date string
  excerpt?: string
  body?: string         // optional, for fallback snippet
}
```

Backend / Phoenix will pass this data into the Svelte component (via LiveSvelte or whatever integration is already in use).

---

## 3. Layout & Markup in Svelte

### 3.1 Base layout wrapper

In `BlogIndex.svelte`, start with the outer layout:

```svelte
<script lang="ts">
  export let posts: BlogPostSummary[] = []
</script>

<section class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10 lg:py-14">
  <header class="mb-8 lg:mb-10">
    <h1 class="text-3xl sm:text-4xl font-bold tracking-tight mb-2 text-base-content">
      Blog
    </h1>
    <p class="text-sm sm:text-base text-base-content/70 max-w-[60ch]">
      Essays, notes, and deep dives on Elixir, Phoenix, AI workflows, and whatever else I am currently obsessing over.
    </p>
  </header>

  <!-- Cards list goes here -->
</section>
```

Key points:

- `max-w-5xl mx-auto` centers the whole block.
- `px-*` and `py-*` add responsive padding.
- The intro text is constrained with `max-w-[60ch]` for readability.

### 3.2 Card list markup

Add the list below the header:

```svelte
{#if posts.length === 0}
  <p class="text-sm text-base-content/60">
    No posts yet. Check back soon.
  </p>
{:else}
  <div class="space-y-4 sm:space-y-5">
    {#each posts as post, index}
      <article
        class={`card bg-base-100 border ${
          index === 0
            ? "border-primary/40 shadow-sm"
            : "border-base-300/70 hover:border-primary/40"
        } transition-colors`}
      >
        <a
          href={`/blog/${post.slug}`}
          class="card-body py-4 sm:py-5 gap-2 sm:gap-3"
        >
          <h2 class="card-title text-lg sm:text-xl leading-snug text-base-content">
            {post.title}
          </h2>

          <p class="text-xs text-base-content/60">
            {formatDate(post.published_at)}
          </p>

          <p class="text-sm text-base-content/80 line-clamp-2 sm:line-clamp-3">
            {getExcerpt(post)}
          </p>
        </a>
      </article>
    {/each}
  </div>
{/if}
```

Notes:

- Uses daisyUI `card` component plus Tailwind classes.
- First post (`index === 0`) gets a slightly stronger border to imply “latest”.

### 3.3 Add helper functions in `<script>`

At the top of `BlogIndex.svelte`:

```svelte
<script lang="ts">
  export type BlogPostSummary = {
    id: number | string
    title: string
    slug: string
    published_at: string
    excerpt?: string
    body?: string
  }

  export let posts: BlogPostSummary[] = []

  function formatDate(dateString: string): string {
    if (!dateString) return ""
    const date = new Date(dateString)
    return date.toLocaleDateString(undefined, {
      year: "numeric",
      month: "short",
      day: "2-digit"
    })
  }

  function getExcerpt(post: BlogPostSummary): string {
    if (post.excerpt && post.excerpt.trim().length > 0) {
      return post.excerpt
    }

    if (post.body && post.body.trim().length > 0) {
      const text = post.body.replace(/[#*_`>]/g, "").trim()
      return text.length > 180 ? text.slice(0, 180) + "…" : text
    }

    return "No summary available yet."
  }
</script>
```

This makes the component robust even if excerpt is missing.

---

## 4. Styling Details Using Tailwind + daisyUI

### 4.1 Card spacing and hover behavior

- `space-y-4 sm:space-y-5` controls vertical rhythm between cards.
- `border-base-300/70` keeps borders subtle.
- `hover:border-primary/40` gives light interactivity on hover.
- `card-body py-4 sm:py-5` aligns paddings with the rest of the design.

You can adjust these numbers, but keep them consistent across other sections (lessons, docs, etc.).

### 4.2 Handling dark and light themes

daisyUI manages the base colors through CSS variables:

- `bg-base-100`
- `border-base-300`
- `text-base-content`
- `primary`

By relying on these classes instead of hard-coded hex values, the blog index will automatically adapt to `tokyo-night`, `catppuccin-mocha`, and `catppuccin-latte` themes that are already defined in `app.css`.

No extra code is needed for theme support, as long as you stick to those semantic classes.

---

## 5. Integration with Phoenix / LiveView

This part depends on how LiveSvelte (or your integration) is set up. General pattern:

### 5.1 Controller or LiveView prepares data

In your Phoenix controller or LiveView for `/blog`, build a list of posts in the expected shape:

```elixir
posts =
  Content.list_published_posts()
  |> Enum.map(fn post ->
    %{
      id: post.id,
      title: post.title,
      slug: post.slug,
      published_at: post.published_at,
      excerpt: post.excerpt,
      body: post.body
    }
  end)
```

### 5.2 Pass posts into the Svelte component

In your HEEx template where you embed Svelte, do something like:

```heex
<.svelte
  name="blog/BlogIndex"
  props={%{posts: @posts}}
  socket={@socket}
/>
```

Adjust `name` and `props` to match your LiveSvelte configuration.

### 5.3 Ensure JSON encoding works

- If you are passing `@posts` as a list of maps, LiveSvelte should handle encoding.
- If not, ensure you convert `DateTime` to ISO strings before passing (as shown above).

---

## 6. Responsive Checks

After implementation, verify in the browser:

### 6.1 Mobile (iPhone-sized viewport)

- Header should not feel cramped (check `px-4` padding).
- Cards should fill width; there should be no horizontal scroll.
- Title wraps nicely at 2–3 lines max.
- Excerpt truncated at 2 lines (`line-clamp-2`).

### 6.2 Tablet

- Text still readable, not overly wide.
- Card spacing still feels balanced.

### 6.3 Desktop

- Content column feels centered and intentional.
- No giant empty gaps between header and first card.
- Hover states are visible but subtle.

---

## 7. Optional Enhancements (Phase 2)

These are not required for the initial implementation but good candidates for later:

1. **Tag chips**  
   - Add optional tags under the title using daisyUI `badge` components.

2. **“Latest” tag on first post**  
   - Add a small `badge` that says `Latest` when `index === 0`.

3. **Pagination / “More posts” link**  
   - Add a footer section with a placeholder for pagination if you expect many posts.

4. **Skeleton loading state**  
   - If posts are loaded asynchronously, add daisyUI `skeleton` classes to show loading placeholders.

---

## 8. Task Checklist for Junior Dev

Use this as a step-by-step todo list:

1. Create `assets/svelte/blog/BlogIndex.svelte` with:
   - Props (`posts`)
   - Helpers `formatDate` and `getExcerpt`
   - Layout wrapper (`section` + `header`)
   - Cards list using daisyUI `card` classes.
2. Wire up the blog controller / LiveView to:
   - Query published posts.
   - Map them into the `BlogPostSummary` shape.
   - Pass them as `props` to the Svelte component.
3. Test `/blog` in the browser with:
   - At least 2 posts.
   - One post missing `excerpt` to verify fallback.
4. Check UI in both dark and light themes.
5. Verify responsiveness:
   - Mobile (narrow)
   - Desktop (wide)
6. Clean up:
   - Remove any old, unused blog index markup.
   - Keep the Svelte component small and focused (no business logic).
7. Once everything looks correct, push the branch and open a PR with screenshots for review.

This is the complete implementation plan for the blog index redesign using Svelte + Tailwind + daisyUI.
