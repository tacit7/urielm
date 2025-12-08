# Blog Content Model

This document formalizes the content structure, template responsibilities, and content rules for the blog system.

## Content Model

A blog post in the database contains:

```elixir
%Post{
  id: integer,
  title: string,              # Required. Single H1 concept. Published prominently.
  slug: string,               # Generated from title. Used in URL.
  body: markdown,             # Required. Markdown content (see rules below).
  excerpt: string,            # Optional. Short summary for index listing.
  published_at: datetime,     # Required. ISO 8601 timestamp.
  status: atom,               # :draft or :published
  inserted_at: datetime,
  updated_at: datetime
}
```

## Template Responsibilities

The template (`post_html/show.html.heex`) owns:

1. **Navigation**: Back link to blog index
2. **Page Container**: Single source of width constraint via `max-w-[70ch]` on outer div
3. **Title (H1)**: Rendered from `@post.title`, styled at text-4xl/5xl
4. **Metadata**: Date and category badge (quiet, subordinate to content)
5. **Page Rhythm**: Vertical spacing, margins, padding
6. **Article Container**: Prose styling via `.prose` class
7. **Syntax Highlighting**: Client-side highlight.js integration

## Markdown Content Responsibilities

Content in `@post.body` must follow these rules:

### 1. No H1 Headings Allowed

- The page title is the single H1
- Markdown must start with ## (H2) for sections
- No # headings in markdown

**Why**: One H1 per page is semantic and intentional. It makes the visual hierarchy unambiguous.

### 2. First Section Must be Overview

Pattern:
```markdown
## Overview

[1-2 paragraph summary of the post]

## [Section Name]

[Content...]

## [Section Name]

[Content...]
```

**Why**: Readers should immediately understand the post's scope. Overview comes before detail.

### 3. Sections Use H2 or H3 Only

- H2 for major sections (big spacing break)
- H3 for subsections (medium spacing break)
- No H4 headings unless absolutely necessary

**Why**: Restraint. Three levels of hierarchy is sufficient. Avoids visual fragmentation.

### 4. Code Blocks Must Have Language Specified

```markdown
# ✗ Bad
```
code here
```

# ✓ Good
```ruby
code here
```
```

**Why**: Enables syntax highlighting. Client-side hljs.highlightElement() requires a language class.

### 5. No Markdown-Based Layout

- No tables for layout (only data tables)
- No nested lists > 2 levels
- No HTML tags; use semantic markdown only
- No images without captions as alt text

**Why**: Markdown should express structure, not fight CSS. The template controls layout. Separation of concerns.

### 6. Inline Code for Identifiers, Functions, Types

```markdown
# ✓ Good
Use the `User.changeset/2` function to validate data.

# ✗ Bad
Use the "User.changeset/2" function to validate data.
```

**Why**: Semantic. Tells readers these are code-level concepts. Styled distinctly from prose.

### 7. Keep Paragraphs Readable

- Max ~10 sentences per paragraph
- Single idea per paragraph
- Blank line between paragraphs (standard markdown)

**Why**: Long walls of text read poorly on screen. Breathing room improves comprehension.

## CSS Styling Philosophy

The CSS (`app.css`) defines prose typography with these principles:

### Hierarchy Through Spacing, Not Decoration

```css
.prose h2 {
  margin-top: 3.5rem;   /* Major section break */
  margin-bottom: 1em;
  /* No border, no background, no gradient */
}

.prose h3 {
  margin-top: 2rem;     /* Subsection break */
  margin-bottom: 0.5em;
}
```

### Minimal Visual Noise

- No borders on code blocks (only subtle background)
- No borders on blockquotes (thin border, low opacity)
- No cards, boxes, or gradients in prose
- Metadata fades into background on desktop

### Readability Constraints

```css
/* Article width is constrained to 70ch (reading line length) */
max-w-[70ch]

/* Heading sizes and weights support hierarchy */
.prose h2 { font-size: 1.5em; font-weight: 700; }
.prose h3 { font-size: 1.25em; font-weight: 700; }
```

## Example: Well-Formed Blog Post

```markdown
# (Don't put this in markdown; use @post.title in template)

## Overview

This post explains how to build scalable Elixir applications using Phoenix.
We'll cover pattern matching, message passing, and OTP principles.

## Getting Started

Before we dive in, make sure you have Elixir 1.14+ installed.

### Installation

```bash
brew install elixir
```

## Pattern Matching

Pattern matching is the foundation of Elixir.

Use the `case` statement to match on different shapes:

```elixir
case response do
  {:ok, data} -> handle_success(data)
  {:error, reason} -> handle_error(reason)
end
```

## Advanced Patterns

### Pipe Operator

The pipe operator chains function calls:

```elixir
data
|> Enum.filter(&valid?/1)
|> Enum.map(&transform/1)
|> Enum.into(%{})
```

## Conclusion

Pattern matching and pipes make Elixir code expressive and composable.
```

## Security Note

**HTML Sanitization**: Blog posts use `Phoenix.HTML.raw()` to bypass escaping on Earmark's HTML output. This is safe because:
- Posts are author-only content (created by you)
- Markdown is not user-generated from untrusted sources
- If user-generated markdown ever becomes an input, you must sanitize HTML before rendering

Do **not** apply `raw()` to user-submitted markdown without proper sanitization.

## Enforcement

When adding new blog posts:

1. Database validation ensures `title` and `body` are present
2. No automated enforcement of markdown rules yet (manual review)
3. Future: Consider a linter or validation function that checks markdown structure

## Why This Matters

These rules enforce a single opinion across all blog posts:

- Readers know what to expect
- All posts share the same visual and structural language
- The template is unambiguous about its job
- Content creators know the constraints
- The page feels intentional, not generated
