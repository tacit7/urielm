# Video SQL Template

Quick reference for manually creating video records until admin UI is built.

## Basic Video Insert

```sql
INSERT INTO videos (
  id,
  title,
  slug,
  youtube_url,
  description_md,
  visibility,
  published_at,
  inserted_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'Introduction to Phoenix LiveView',
  'intro-phoenix-liveview',
  'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  '# Introduction\n\nLearn the basics of Phoenix LiveView...',
  'public',
  NOW(),
  NOW(),
  NOW()
);
```

## Visibility Options

```sql
-- Public (anyone can view)
visibility = 'public'

-- Signed-in users only
visibility = 'signed_in'

-- Subscribers only (requires active subscription)
visibility = 'subscriber'
```

## With All Optional Fields

```sql
INSERT INTO videos (
  id,
  title,
  slug,
  youtube_url,
  description_md,
  resources_md,
  author_name,
  author_url,
  author_bio_md,
  visibility,
  published_at,
  thread_id,
  inserted_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'Advanced Ecto Patterns',
  'advanced-ecto-patterns',
  'https://www.youtube.com/watch?v=VIDEO_ID',
  '# Advanced Patterns\n\nDeep dive into Ecto query composition...',
  '## Resources\n- [Ecto Docs](https://hexdocs.pm/ecto)\n- [Source Code](https://github.com/example)',
  'Jose Valim',
  'https://twitter.com/josevalim',
  'Creator of Elixir and Ecto. Core team member.',
  'signed_in',
  NOW(),
  NULL,  -- Set after creating forum thread
  NOW(),
  NOW()
);
```

## Attaching Forum Thread for Comments

### Step 1: Create a thread in the Videos board

```sql
-- First, get the Videos board ID
SELECT id FROM forum_boards WHERE slug = 'videos';

-- Create thread with kind='video' to keep it separate from forum threads
INSERT INTO forum_threads (
  id,
  board_id,
  author_id,
  title,
  slug,
  body,
  kind,
  inserted_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'VIDEOS_BOARD_ID_HERE',  -- From query above
  1,  -- Admin user ID
  'Comments: Introduction to Phoenix LiveView',
  'comments-intro-phoenix-liveview',
  'Discussion thread for the video "Introduction to Phoenix LiveView"',
  'video',  -- Mark as video thread (won't show in forum listings)
  NOW(),
  NOW()
) RETURNING id;
```

### Step 2: Update video with thread_id

```sql
UPDATE videos
SET thread_id = 'THREAD_ID_FROM_ABOVE'
WHERE slug = 'intro-phoenix-liveview';
```

## Unpublished Draft

```sql
INSERT INTO videos (
  id,
  title,
  slug,
  youtube_url,
  visibility,
  published_at,  -- NULL = unpublished
  inserted_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'Work in Progress Video',
  'wip-video',
  'https://www.youtube.com/watch?v=VIDEO_ID',
  'public',
  NULL,  -- Not published yet
  NOW(),
  NOW()
);
```

## Supported YouTube URL Formats

All of these work:
```
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://youtu.be/dQw4w9WgXcQ
https://www.youtube.com/shorts/dQw4w9WgXcQ
https://www.youtube.com/embed/dQw4w9WgXcQ
```

## Quick Queries

### List all videos
```sql
SELECT id, title, slug, visibility, published_at
FROM videos
ORDER BY published_at DESC NULLS LAST;
```

### Find unpublished videos
```sql
SELECT title, slug FROM videos WHERE published_at IS NULL;
```

### Check if video has comments enabled
```sql
SELECT v.title, v.thread_id IS NOT NULL as has_comments
FROM videos v
WHERE slug = 'your-slug';
```

### Create test subscription for a user
```sql
INSERT INTO subscriptions (
  id,
  user_id,
  status,
  current_period_end,
  inserted_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  123,  -- Your user ID
  'active',
  NOW() + INTERVAL '1 month',
  NOW(),
  NOW()
);
```

## Common Mistakes

❌ **Wrong visibility value**
```sql
visibility = 'premium'  -- Invalid! Must be: public, signed_in, or subscriber
```

❌ **Missing required fields**
```sql
-- title, slug, youtube_url, visibility are all required
INSERT INTO videos (id) VALUES (gen_random_uuid());  -- Will fail
```

❌ **Duplicate slug**
```sql
-- Slug must be unique
INSERT INTO videos (..., slug = 'intro') ...;
INSERT INTO videos (..., slug = 'intro') ...;  -- Will fail
```

❌ **Invalid thread_id**
```sql
thread_id = 'some-uuid'  -- Must reference existing forum_threads.id
```
