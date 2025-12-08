# Blog Rendering Process

Complete walkthrough of how a blog post gets rendered from HTTP request to final HTML.

## 1. Request Routing

**File**: `lib/urielm_web/router.ex:47-48`

```elixir
get "/blog", PostController, :index
get "/blog/:slug", PostController, :show
```

- **GET /blog** → `PostController.index/2`
- **GET /blog/:slug** → `PostController.show/2`

Both routes pass through the `:browser` pipeline:
- Accept HTML requests
- Fetch session and live flash
- Set root layout to `{UrielmWeb.Layouts, :root}`
- Protect from CSRF
- Fetch current user via `UrielmWeb.Plugs.Auth` plug

## 2. Controller Dispatch

**File**: `lib/urielm_web/controllers/post_controller.ex`

### For `/blog/:slug` (single post):

```elixir
def show(conn, %{"slug" => slug}) do
  post = Content.get_post_by_slug!(slug)
  render(conn, :show, post: post, page_title: post.title, layout: {UrielmWeb.Layouts, :app}, current_page: "blog")
rescue
  Ecto.NoResultsError ->
    conn
    |> put_flash(:error, "Post not found")
    |> redirect(to: ~p"/blog")
end
```

**Steps:**
1. Extract slug from URL params: `%{"slug" => "my-post"}`
2. Query database via `Content.get_post_by_slug!(slug)`
3. If found, pass to template with assigns:
   - `post`: The Post struct from DB
   - `page_title`: Used for `<title>` tag
   - `layout`: Use the app layout (with navbar, etc.)
   - `current_page`: "blog" (used by navbar for active link styling)
4. If not found, catch `Ecto.NoResultsError`, flash error message, redirect to `/blog`

## 3. Database Query

**File**: `lib/urielm/content.ex:299-303`

```elixir
def get_post_by_slug!(slug) do
  Post
  |> Post.published()
  |> Repo.get_by!(slug: slug)
end
```

**Process:**
1. Start with `Post` query
2. Apply `Post.published()` scope to filter only published posts:

**File**: `lib/urielm/content/post.ex:29-32`

```elixir
def published(query \\ __MODULE__) do
  from p in query,
    where: p.status == "published" and not is_nil(p.published_at) and p.published_at <= ^DateTime.utc_now()
end
```

This `published/1` scope applies filters:
- `status == "published"` (not draft)
- `published_at` is not null
- `published_at <= DateTime.utc_now()` (scheduled posts in future are hidden)

3. Query by slug: `Repo.get_by!(slug: slug)` finds exact match or raises `Ecto.NoResultsError`

**Result**: `Post` struct with fields:
- `id`: Database ID
- `title`: String (used as H1)
- `slug`: URL-friendly slug (used in URL)
- `body`: Markdown string (converted to HTML)
- `excerpt`: Optional short summary
- `status`: "published" or "draft"
- `published_at`: DateTime when published
- `author_id`: User ID (optional)
- `inserted_at`, `updated_at`: Timestamps

## 4. View Template Rendering

**File**: `lib/urielm_web/controllers/post_html.ex`

```elixir
defmodule UrielmWeb.PostHTML do
  use UrielmWeb, :html
  embed_templates "post_html/*"

  def markdown_to_html(markdown) do
    case Earmark.as_html(markdown || "") do
      {:ok, html, _warnings} ->
        Phoenix.HTML.raw(html)
      {:error, _html, _warnings} ->
        Phoenix.HTML.raw(markdown || "")
    end
  end
end
```

**What happens:**
- `embed_templates "post_html/*"` loads all `.html.heex` files from `post_html/` directory
- For `show` action, looks for `post_html/show.html.heex`
- Defines `markdown_to_html/1` helper function:
  1. Takes markdown string from `@post.body`
  2. Calls `Earmark.as_html/1` to convert markdown → HTML
  3. Wraps result in `Phoenix.HTML.raw()` to mark as safe HTML (prevents escaping)
  4. Falls back to raw markdown if conversion fails

## 5. HEEx Template Rendering

**File**: `lib/urielm_web/controllers/post_html/show.html.heex`

```heex
<div class="min-h-screen bg-base-100 flex flex-col">
  <div class="flex-1 mx-auto w-full px-4 sm:px-6 lg:px-8 py-10 lg:py-14 max-w-[70ch]">
    <!-- Back link -->
    <p class="text-xs sm:text-[13px] text-base-content/50 lg:text-base-content/40 mb-6">
      <.link navigate={~p"/blog"} class="inline-flex items-center gap-1 hover:text-primary transition-colors">
        &larr; Back to blog
      </.link>
    </p>

    <!-- Header with title and metadata -->
    <header class="mb-12 lg:mb-16">
      <h1 class="text-4xl sm:text-5xl font-bold tracking-tight text-base-content mb-4">
        <%= @post.title %>
      </h1>

      <div class="flex flex-wrap items-center gap-3 text-xs sm:text-sm text-base-content/50 lg:text-base-content/35">
        <span>
          <%= if @post.published_at do %>
            <%= Calendar.strftime(@post.published_at, "%b %d, %Y") %>
          <% else %>
            Draft
          <% end %>
        </span>

        <span class="hidden sm:inline text-base-content/30 lg:text-base-content/25">•</span>

        <span class="inline-flex items-center gap-1">
          <span class="w-1.5 h-1.5 rounded-full bg-primary/50 lg:bg-primary/30"></span>
          <span>Blog</span>
        </span>
      </div>
    </header>

    <!-- Article content (markdown converted to HTML) -->
    <article class="prose prose-invert" id="blog-article">
      <%= markdown_to_html(@post.body) %>
    </article>

    <!-- Syntax highlighting setup -->
    <script>
      document.addEventListener('DOMContentLoaded', () => {
        const article = document.getElementById('blog-article')
        if (article && window.hljs) {
          article.querySelectorAll('pre code').forEach((block) => {
            window.hljs.highlightElement(block)
          })
        }
      })
    </script>
  </div>
</div>
```

**Template breakdown:**

1. **Outer container**: `min-h-screen bg-base-100 flex flex-col`
   - Full viewport height
   - Base background color (theme-aware via daisyUI)
   - Flexbox column layout

2. **Content wrapper**: `flex-1 mx-auto w-full max-w-[70ch]`
   - Grows to fill available space (`flex-1`)
   - Centered on page (`mx-auto`)
   - Full width on mobile, max 70 characters wide on desktop (reading line length)

3. **Back link**: `<.link navigate={~p"/blog"}`
   - Navigates to `/blog` index
   - Styled as quiet metadata

4. **Header**: `<header>`
   - **Title (H1)**: From `@post.title`, sized as hero heading
   - **Metadata**: Date formatted via `Calendar.strftime()`, category badge
   - Metadata fades on desktop (`lg:text-base-content/35`)

5. **Article**: `<article class="prose prose-invert">`
   - `prose` class applies Tailwind Typography plugin styles
   - `prose-invert` adds dark mode variant (currently not used actively since we override)
   - **Content**: `markdown_to_html(@post.body)` converts markdown to HTML
   - Wrapped in `id="blog-article"` for JavaScript access

6. **Syntax highlighting script**:
   ```javascript
   document.addEventListener('DOMContentLoaded', () => {
     const article = document.getElementById('blog-article')
     if (article && window.hljs) {
       article.querySelectorAll('pre code').forEach((block) => {
         window.hljs.highlightElement(block)
       })
     }
   })
   ```
   - Runs after DOM loads
   - Finds all `<pre><code>` blocks in article
   - Calls `window.hljs.highlightElement()` to apply syntax highlighting
   - `window.hljs` exposed by `assets/js/app.js`

## 6. Layout Nesting

**Root layout**: `lib/urielm_web/components/layouts/root.html.heex`
- Sets up `<html>`, `<head>`, `<body>`
- Imports Tailwind CSS, JavaScript bundles
- Sets theme attribute via `data-theme`

**App layout**: `lib/urielm_web/components/layouts.ex` (loaded as `{UrielmWeb.Layouts, :app}`)
- Wraps content with navbar and footer
- Passes `current_page: "blog"` so navbar highlights "Blog" link
- Renders the view template (post_html/show.html.heex) in the middle

**Nesting order:**
```
root.html.heex
  └── app layout
       └── post_html/show.html.heex (the template above)
```

## 7. CSS Styling Pipeline

**File**: `assets/css/app.css` (lines 196-330)

### Approach: Custom CSS + daisyUI semantics

We write custom `.prose` rules that use daisyUI CSS variables for theme-aware colors:

```css
.prose {
  color: hsl(var(--bc) / 0.9);  /* base-content from daisyUI */
}

.prose h2 {
  font-size: 1.5em;
  margin-top: 3.5rem;  /* Strong section break via spacing, not decoration */
  margin-bottom: 1em;
}

.prose :not(pre) > code {
  background-color: hsl(var(--b3) / 0.6);  /* base-300 at 60% opacity */
  border: none;  /* Minimal visual noise */
  color: hsl(var(--p));  /* primary color from theme */
  font-weight: 500;
}

.prose pre {
  background-color: hsl(var(--b2) / 0.5);  /* base-200 at 50% opacity */
  border: none;
  padding: 1rem;
  margin: 1.5em 0;
  border-radius: 0.5rem;
}
```

**Why this approach:**
- Tailwind Typography (`@plugin "@tailwindcss/typography"`) is registered but not used directly
- We avoid hardcoding colors; instead use daisyUI's semantic variable system
- daisyUI variables update automatically when theme changes
- Custom rules give us control over restraint (no borders, subtle backgrounds)
- Result: editorial aesthetic that adapts to any theme

**Theme variables used:**
- `--bc` (base-content): Text color
- `--b2` (base-200): Code block background
- `--b3` (base-300): Inline code background
- `--p` (primary): Links and code color

## 8. JavaScript Bundle Integration

**File**: `assets/js/app.js:49-52`

```javascript
import hljs from "highlight.js"

// Expose hljs globally for syntax highlighting in templates
window.hljs = hljs
```

**Process:**
1. esbuild bundles Highlight.js as a module
2. Imports hljs library
3. Assigns to `window.hljs` to make globally accessible
4. Template script queries `window.hljs` and calls `highlightElement()`
5. Highlight.js CSS theme imported: `@import "highlight.js/styles/atom-one-dark"` in app.css

## 9. Markdown Processing Details

**What Earmark does:**

Input markdown:
```markdown
Welcome! This is a post.

## Overview

Some intro text.

## Section Name

Content with `inline code` and:

```elixir
def hello(name) do
  IO.puts("Hello, #{name}!")
end
```
```

Output HTML (simplified):
```html
<p>Welcome! This is a post.</p>

<h2>Overview</h2>

<p>Some intro text.</p>

<h2>Section Name</h2>

<p>Content with <code>inline code</code> and:</p>

<pre><code class="language-elixir">def hello(name) do
  IO.puts("Hello, #{name}!")
end
</code></pre>
```

**Key points:**
- `##` becomes `<h2>` (not `<h1>`)
- Inline code becomes `<code>` (styled by `.prose :not(pre) > code`)
- Code fences with language become `<pre><code class="language-elixir">`
- Language class enables syntax highlighting

## 10. Syntax Highlighting Flow

1. **Markdown rendering**: Earmark adds `class="language-elixir"` to `<code>` in `<pre>`

2. **Browser DOMContentLoaded**: JavaScript runs after HTML parsed
   - Query: `article.querySelectorAll('pre code')`
   - For each code block: `window.hljs.highlightElement(block)`

3. **Highlight.js**:
   - Detects language from `class="language-elixir"`
   - Applies syntax rules for that language
   - Adds color spans: `<span class="hljs-keyword">def</span>`

4. **CSS theme**:
   - `@import "highlight.js/styles/atom-one-dark"` provides color definitions
   - Classes like `.hljs-keyword` are styled with specific colors

5. **Result**: Code blocks appear with syntax highlighting

## 11. Theme System Integration

daisyUI exposes theme colors as CSS variables:

```css
/* Tokyo Night theme (when data-theme="tokyo-night") */
:root {
  --p: 240 100% 68%;  /* primary: #7aa2f7 in HSL */
  --b2: 230 40% 11%;  /* base-200: #16161e in HSL */
  --b3: 228 35% 15%;  /* base-300 (custom) */
  --bc: 256 89% 82%;  /* base-content: #c0caf5 in HSL */
}
```

**How blog uses themes:**
- `color: hsl(var(--bc))`: Text color (adapts to light/dark)
- `background-color: hsl(var(--b2) / 0.5)`: Code block background at 50% opacity
- `color: hsl(var(--p))`: Links and inline code (primary accent)
- All colors automatically update when user switches themes (tokyo-night, catppuccin-mocha, etc.)

## Summary: Complete Request Flow

```
1. GET /blog/my-first-post
   ↓
2. Router matches route to PostController.show
   ↓
3. Controller calls Content.get_post_by_slug!("my-first-post")
   ↓
4. Query database, filter by published status, fetch Post struct
   ↓
5. Controller renders with assigns: post, page_title, layout, current_page
   ↓
6. Phoenix invokes post_html/show.html.heex template
   ↓
7. Template calls markdown_to_html(@post.body)
   ↓
8. Earmark converts markdown → HTML
   ↓
9. HTML wrapped in <article class="prose"> with id="blog-article"
   ↓
10. Template layout nests in app layout which nests in root layout
   ↓
11. Combined HTML + CSS + JS sent to browser
   ↓
12. Browser renders HTML with Tailwind + daisyUI styles
   ↓
13. DOMContentLoaded fires, JavaScript highlights code blocks
   ↓
14. User sees fully-rendered blog post with syntax highlighting
```
