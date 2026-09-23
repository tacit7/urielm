# Blog Publish Mix Task Design

## Goal

Add an idempotent `mix blog.publish` task that imports a Markdown draft into the existing `posts` table without publishing directly from an interactive shell.

## Interface

```bash
mix blog.publish PATH --author USERNAME [--draft] [--hero-image URL]
```

The file must begin with an HTML comment containing `Title`, `Slug`, and `Excerpt` publishing metadata. `Author` may be present for editorial reference, but `--author` is required and resolves an existing user by username.

## Behavior

- Read and validate the Markdown file before starting a write.
- Strip the publishing metadata comment from the stored body.
- Strip a leading H1 matching the title and a following `By ...` line because the blog layout renders both.
- Publish immediately by default; `--draft` stores a draft with no publication time.
- Update an existing post with the same slug instead of inserting a duplicate.
- Preserve an existing publication timestamp when updating an already-published post.
- Accept an optional hero image URL.
- Fail with actionable messages for missing files, metadata, authors, or invalid changesets.

## Verification

Mix task tests cover creation, body cleanup, draft mode, validation failures, and idempotent updates. Final verification runs the focused test file, compilation with warnings as errors, and `mix precommit`.
