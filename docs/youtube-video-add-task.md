# YouTube Video Add Mix Task

Add a standalone YouTube video by URL:

```bash
mix videos.add "https://www.youtube.com/watch?v=g5oEAoKdrdw"
```

The task fetches public YouTube oEmbed metadata, generates a slug, inserts through
`Urielm.Content.create_video/1`, and prints the resulting `/videos/:slug` path.

## Options

```bash
mix videos.add URL --draft
mix videos.add URL --visibility signed_in
mix videos.add URL --visibility subscriber
mix videos.add URL --title "Custom Title"
mix videos.add URL --slug "custom-slug"
mix videos.add URL --tags "Agents, Career"
```

Videos are public and published by default. `--draft` stores `published_at: nil`.
`--tags` accepts comma-separated tag names and creates the video and its tags in one
transaction. Re-running the same URL is idempotent: it prints the existing video path
without changing its tags or other metadata.

## Add a one-video course

Use `courses.add_video` when the YouTube video should live under `/courses`
instead of `/videos`:

```bash
mix courses.add_video "https://www.youtube.com/watch?v=DJZISqryDfw"
```

The task fetches public YouTube oEmbed metadata, creates a course, creates the
first lesson, stores the YouTube video ID on the lesson, and prints the resulting
`/courses/:course_slug/lessons/:lesson_slug` path. Re-running the same YouTube
URL is idempotent and prints the existing course/lesson path.

Useful options:

```bash
mix courses.add_video URL --title "Custom Course"
mix courses.add_video URL --slug "custom-course"
mix courses.add_video URL --lesson-title "Custom Lesson"
mix courses.add_video URL --lesson-slug "custom-lesson"
mix courses.add_video URL --description-file description.md
mix courses.add_video URL --notes-file notes.md
mix courses.add_video URL --resources-file resources.md
mix courses.add_video URL --timestamps-file timestamps.md
```

## Add a playlist course

Use `courses.add_playlist` when several YouTube videos should become lessons in
one course:

```bash
mix courses.add_playlist "PLcGFJNFn5qEB1Va8whwT5VGGQvggDBJ4U" \
  uv0p9dpLH2I \
  f3TO_dm5Agc \
  hoBKAH7ePBs
```

The task fetches public YouTube oEmbed metadata for the playlist and each video,
creates one course with `youtube_playlist_id`, and creates lessons in the order
provided. Re-running the same playlist is idempotent: existing lessons are reused
and only missing videos are appended.

The playlist argument may be either a playlist ID or playlist URL. Longer video
lists can come from a file:

```bash
mix courses.add_playlist "PLcGFJNFn5qEB1Va8whwT5VGGQvggDBJ4U" --videos-file videos.txt
```

Useful options:

```bash
mix courses.add_playlist PLAYLIST --title "Custom Course"
mix courses.add_playlist PLAYLIST --slug "custom-course"
mix courses.add_playlist PLAYLIST --description-file description.md
```

## Replace tags

Use the dedicated task to replace a video's complete tag set:

```bash
mix videos.tags video-slug --tags "Agents, Career"
mix videos.tags video-slug --tags ""
```

The second form clears all tags. Both replacement and clearing are atomic.

## Update fields

Use `videos.update` for content-only changes to an existing video:

```bash
mix videos.update video-slug --title "Updated title"
mix videos.update video-slug --description-file chapters.md
mix videos.update video-slug --resources-file resources.md
mix videos.update video-slug --visibility public
mix videos.update video-slug --publish
mix videos.update video-slug --unpublish
```

Supported fields include title, slug, YouTube URL, TikTok URL, format, description,
resources, author metadata, visibility, and published state.

## Update chapters

Use `videos.chapters` to replace the video overview with linked YouTube chapters.
Chapters can come from a file:

```bash
mix videos.chapters video-slug --file chapters.txt
```

or stdin:

```bash
cat chapters.txt | mix videos.chapters video-slug
```

The input format is one chapter per line:

```text
00:00 Intro
00:26 First topic
01:37:55 Wrap up
```

The task validates timestamp order and converts each timestamp into a local
`#t=` link that seeks the embedded player on the video page.

## Production

Use `bin/prod-mix` for production tasks. It runs Mix with `MIX_ENV=prod` and
loads the same environment configured on the `urielm` systemd service without
printing secret values:

```bash
bin/prod-mix videos.add "https://www.youtube.com/watch?v=g5oEAoKdrdw"
bin/prod-mix videos.chapters video-slug --file chapters.txt
bin/prod-mix courses.add_video "https://www.youtube.com/watch?v=DJZISqryDfw"
bin/prod-mix courses.add_playlist "PLcGFJNFn5qEB1Va8whwT5VGGQvggDBJ4U" --videos-file videos.txt
```

Do not print or hardcode production secrets.
