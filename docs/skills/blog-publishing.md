# Skill: Blog Publishing

## Overview
How to create and update blog posts using the `mix blog.publish` CLI task.

## Prerequisites
- Author user account must exist
- Markdown file with proper metadata format
- Author must have appropriate permissions

## Command

### Publish Blog Post

```bash
mix blog.publish path/to/article.md --author USERNAME
```

**Options:**
- `--author USERNAME` (required): Username of the post author
- `--draft`: Publish as draft instead of live
- `--hero-image URL`: Set hero/featured image for the post

## Markdown File Format

Blog posts must be in Markdown format with metadata in an HTML comment at the top:

```markdown
<!--
Title: Your Blog Post Title
Slug: url-friendly-slug
Excerpt: A short excerpt that appears in listings and meta tags
-->

# Your Blog Post Title

Your content here...
```

### Required Metadata Fields
- **Title**: The display title of the blog post
- **Slug**: URL-friendly identifier (e.g., `my-first-post`)
- **Excerpt**: Short summary for previews and SEO

### Content Processing
The task automatically:
- Removes the leading H1 if it matches the title
- Removes bylines (e.g., "By Author Name")
- Strips the metadata comment from the stored body
- Sets published timestamp on first publish (preserved on updates)

## Examples

### Basic Publication
```bash
mix blog.publish content/my-article.md --author urielm
```

### Save as Draft
```bash
mix blog.publish content/work-in-progress.md --author urielm --draft
```

### With Hero Image
```bash
mix blog.publish content/feature-post.md \
  --author urielm \
  --hero-image /images/hero-blog-post.jpg
```

### Update Existing Post
```bash
# Updates post with same slug, preserves original published_at
mix blog.publish content/updated-article.md --author urielm
```

## Production Usage

Use `./bin/prod-mix` to run with production database credentials:

```bash
./bin/prod-mix blog.publish tmp/article.md --author urielm
```

## Complete Workflow Example

### 1. Create the Markdown File

```bash
cat > tmp/my-blog-post.md <<'EOF'
<!--
Title: Getting Started with Phoenix LiveView
Slug: getting-started-phoenix-liveview
Excerpt: Learn the basics of building real-time applications with Phoenix LiveView in this beginner-friendly guide.
-->

# Getting Started with Phoenix LiveView

Phoenix LiveView lets you build rich, real-time user experiences without writing JavaScript...

## What is LiveView?

LiveView provides server-rendered HTML that updates over WebSockets...

## Your First LiveView

Here's how to create a simple counter...
EOF
```

### 2. Publish to Production

```bash
./bin/prod-mix blog.publish tmp/my-blog-post.md --author urielm
```

### 3. Verify

Output should confirm:
```
Published blog post:
Title: Getting Started with Phoenix LiveView
Slug: getting-started-phoenix-liveview
URL: /blog/getting-started-phoenix-liveview
```

Visit `https://urielm.dev/blog/getting-started-phoenix-liveview` to see it live.

## Common Patterns

### Publishing Multiple Posts

```bash
#!/bin/bash
# Publish all markdown files in a directory

for file in content/posts/*.md; do
  ./bin/prod-mix blog.publish "$file" --author urielm
done
```

### Converting Content from Other Formats

```python
#!/usr/bin/env python3
# Convert article to blog post format

import sys

def create_blog_post(title, slug, excerpt, body):
    """Create properly formatted blog post markdown"""
    return f"""<!--
Title: {title}
Slug: {slug}
Excerpt: {excerpt}
-->

{body}
"""

# Usage
article = create_blog_post(
    "My Article Title",
    "my-article-title",
    "A brief description...",
    "# My Article Title\n\nContent here..."
)

with open("tmp/article.md", "w") as f:
    f.write(article)
```

### AI-Generated Blog Post Script

```bash
#!/bin/bash
# Generate and publish AI-assisted blog posts

# 1. Create markdown file (via AI, manual editing, etc.)
cat > tmp/generated-post.md <<'EOF'
<!--
Title: AI in Software Development
Slug: ai-in-software-development
Excerpt: Exploring how AI tools are transforming the software development workflow in 2026.
-->

# AI in Software Development

Modern development increasingly relies on AI assistance...
EOF

# 2. Review (optional manual step)
# ${EDITOR} tmp/generated-post.md

# 3. Publish
./bin/prod-mix blog.publish tmp/generated-post.md --author urielm
```

## Error Handling

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| `Author not found: USERNAME` | Username doesn't exist | Verify username with: `psql $DATABASE_URL -c "SELECT username FROM users"` |
| `Missing publishing metadata: title, slug, excerpt` | Incomplete metadata | Ensure HTML comment has all required fields |
| `Could not read FILE: no such file or directory` | Invalid file path | Check file path is correct |
| `slug has already been taken` | Slug conflict | This will update the existing post (not create duplicate) |
| `:eaddrinuse` (port in use) | Phoenix server running | Use `./bin/prod-mix` instead of `mix` |

## Database Schema

Posts are stored in the `posts` table with:
- `title`: Display title
- `slug`: Unique URL identifier
- `body`: Markdown content (without metadata)
- `excerpt`: Short description
- `status`: "published" or "draft"
- `published_at`: Timestamp (null for drafts)
- `hero_image`: Optional featured image URL
- `author_id`: Foreign key to users table

## Best Practices

1. **Use descriptive slugs** - Keep them readable and SEO-friendly
2. **Write clear excerpts** - These appear in listings and social shares
3. **Test in draft first** - Use `--draft` to preview before publishing
4. **Preserve original timestamps** - Updates keep the original `published_at`
5. **Use consistent author** - Most posts should use the main site owner
6. **Store source files** - Keep markdown files in version control
7. **Validate links** - Check all links work before publishing
8. **Use hero images** - Featured images improve engagement

## Integration Examples

### Automated News Digest

```bash
#!/bin/bash
# Daily AI news digest as blog post

DATE=$(date +%Y-%m-%d)
SLUG="ai-news-digest-$DATE"

cat > tmp/news-digest.md <<EOF
<!--
Title: AI News Digest - $DATE
Slug: $SLUG
Excerpt: Today's top AI and tech news, curated and summarized.
-->

# AI News Digest - $DATE

$(./bin/fetch-and-summarize-news.sh)
EOF

./bin/prod-mix blog.publish tmp/news-digest.md --author news-bot
```

### Migration from External CMS

```python
#!/usr/bin/env python3
# Migrate posts from Ghost/WordPress export

import json

with open("ghost-export.json") as f:
    data = json.load(f)

for post in data["posts"]:
    slug = post["slug"]
    markdown = f"""<!--
Title: {post["title"]}
Slug: {slug}
Excerpt: {post["excerpt"]}
-->

{post["markdown"]}
"""

    with open(f"tmp/{slug}.md", "w") as f:
        f.write(markdown)

    # Publish with original date
    import subprocess
    subprocess.run([
        "./bin/prod-mix", "blog.publish",
        f"tmp/{slug}.md",
        "--author", "urielm"
    ])
```

## Related
- Blog content model: `docs/blog-content-model.md`
- Blog rendering: `docs/blog-rendering-process.md`
- Task implementation: `lib/mix/tasks/blog.publish.ex`
- User creation: `lib/mix/tasks/user.create.ex`
