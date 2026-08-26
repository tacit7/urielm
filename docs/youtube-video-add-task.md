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
```

Videos are public and published by default. `--draft` stores `published_at: nil`.
Re-running the same URL is idempotent and prints the existing video path.

## Production

Production runs with `MIX_ENV=prod`, so run the task with the same environment
used by the systemd service:

```bash
MIX_ENV=prod mix videos.add "https://www.youtube.com/watch?v=g5oEAoKdrdw"
```

Do not print or hardcode production secrets. If invoking manually over SSH, use
the service environment rather than copying secret values into shell history.
