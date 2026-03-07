# Engagement System

Unified voting and discussion system for all content types in urielm.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Urielm.Engagement                           │
│  (Context module - single entry point for all engagement ops)   │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   Engagement.Vote       │     │  Engagement.Discussion  │
│   ─────────────────     │     │  ────────────────────   │
│   Thumbs up/down for    │     │  Maps content to forum  │
│   any content type      │     │  threads for comments   │
└─────────────────────────┘     └─────────────────────────┘
              │                               │
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│      votes table        │     │   discussions table     │
│   (polymorphic via      │     │   + forum_threads       │
│    target_type/id)      │     │   + forum_comments      │
└─────────────────────────┘     └─────────────────────────┘
```

## Design Principles

1. **One table for all votes** - No separate `likes`, `forum_votes`, etc.
2. **One comment system** - Reuse forum threads/comments everywhere
3. **Polymorphic targeting** - `target_type` + `target_id` pattern
4. **Predictable toggle logic** - Same behavior everywhere
5. **Lazy creation** - Discussion threads created on first use

## Database Schema

### votes

```sql
CREATE TABLE votes (
  id            UUID PRIMARY KEY,
  user_id       BIGINT NOT NULL REFERENCES users(id),
  target_type   VARCHAR(255) NOT NULL,  -- "thread", "comment", "video", "lesson", "prompt", "post"
  target_id     UUID NOT NULL,          -- ID of the target (as binary_id)
  value         SMALLINT NOT NULL,      -- -1 (downvote) or +1 (upvote)
  inserted_at   TIMESTAMP NOT NULL,
  updated_at    TIMESTAMP NOT NULL
);

-- Constraints
UNIQUE INDEX (user_id, target_type, target_id)  -- One vote per user per target
CHECK (value IN (-1, 1))                         -- Only -1 or +1 allowed
INDEX (target_type, target_id)                   -- Fast lookups by target
```

### discussions

```sql
CREATE TABLE discussions (
  id          UUID PRIMARY KEY,
  target_type VARCHAR(255) NOT NULL,  -- "video", "lesson", "prompt", "post", "course"
  target_id   BIGINT NOT NULL,        -- ID of the content item
  thread_id   UUID NOT NULL REFERENCES forum_threads(id),
  inserted_at TIMESTAMP NOT NULL,
  updated_at  TIMESTAMP NOT NULL
);

-- Constraints
UNIQUE INDEX (target_type, target_id)  -- One discussion per content item
UNIQUE INDEX (thread_id)               -- One-to-one with thread
```

## Vote System

### Valid Target Types

```elixir
# Engagement.Vote
@valid_targets ~w(thread comment video lesson prompt post)
```

### Valid Values

| Value | Meaning  | UI Representation |
|-------|----------|-------------------|
| `1`   | Upvote   | Thumbs up, Like   |
| `-1`  | Downvote | Thumbs down       |

### Toggle Logic

The `toggle_vote/4` function implements predictable behavior:

```
Current State  +  Action  =  Result
─────────────────────────────────────
none           +  up      =  +1 (create)
+1             +  up      =  none (remove)
-1             +  up      =  +1 (switch)

none           +  down    =  -1 (create)
-1             +  down    =  none (remove)
+1             +  down    =  -1 (switch)
```

### API Reference

```elixir
# Toggle a vote (recommended for UI interactions)
Engagement.toggle_vote(user_id, "thread", thread_id, 1)   # Upvote
Engagement.toggle_vote(user_id, "comment", comment_id, -1) # Downvote

# Cast a vote (upsert - always sets to value)
Engagement.cast_vote(user_id, "prompt", prompt_id, 1)

# Remove a vote
Engagement.unvote(user_id, "video", video_id)

# Get user's vote on a target
Engagement.get_vote(user_id, "lesson", lesson_id)
# => %Vote{value: 1} or nil

# Bulk fetch votes (for list views - avoids N+1)
Engagement.bulk_get_votes(user_id, "thread", thread_ids)
# => %{"uuid1" => 1, "uuid2" => -1}

# Get vote counts for a target
Engagement.get_vote_counts("thread", thread_id)
# => {upvotes, downvotes, score}
```

### Score Updates

For forum content, votes automatically update the `score` field:

```elixir
# In Engagement context - happens automatically
defp apply_score_delta("thread", target_id, delta) do
  from(t in Thread, where: t.id == ^target_id)
  |> Repo.update_all(inc: [score: delta])
end

defp apply_score_delta("comment", target_id, delta) do
  from(c in Comment, where: c.id == ^target_id)
  |> Repo.update_all(inc: [score: delta])
end

# Other content types don't have score fields (yet)
defp apply_score_delta(_target_type, _target_id, _delta), do: :ok
```

## Discussion System

Maps any content item to a forum thread for comments.

### How It Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│   Video     │────▶│ Discussion  │────▶│  Forum Thread   │
│  id: 123    │     │ target_type │     │  (hidden board) │
│             │     │ target_id   │     │                 │
└─────────────┘     │ thread_id   │     │  ┌───────────┐  │
                    └─────────────┘     │  │ Comments  │  │
                                        │  └───────────┘  │
                                        └─────────────────┘
```

### Lazy Creation

Threads are created when first needed (not when content is created):

```elixir
# Get existing or create new discussion thread
{:ok, discussion} = Engagement.get_or_create_discussion("video", video_id,
  board_id: comments_board_id,
  author_id: system_user_id,
  title: "Comments on #{video.title}"
)

# Access the thread
thread = discussion.thread
comments = Forum.list_comments(thread.id)
```

### API Reference

```elixir
# Get or create discussion (lazy creation)
Engagement.get_or_create_discussion(target_type, target_id, opts)
# opts:
#   :board_id   - Required for creation
#   :author_id  - Required for creation
#   :title      - Optional, defaults to "Discussion"

# Get existing discussion (no creation)
Engagement.get_discussion("video", video_id)
# => %Discussion{} or nil

# Get discussion by thread ID
Engagement.get_discussion_by_thread(thread_id)

# Check if discussion exists
Engagement.has_discussion?("lesson", lesson_id)
# => true/false

# Bulk check (for list views)
Engagement.bulk_has_discussions("video", video_ids)
# => MapSet of video_ids that have discussions
```

## Usage Examples

### Forum Thread Voting (LiveView)

```elixir
# In thread_live.ex
def handle_event("vote", %{"value" => value}, socket) do
  user_id = socket.assigns.current_user.id
  thread_id = socket.assigns.thread.id

  case Engagement.toggle_vote(user_id, "thread", thread_id, String.to_integer(value)) do
    {:ok, _} ->
      # Refresh thread to get updated score
      thread = Forum.get_thread!(thread_id)
      user_vote = Engagement.get_vote(user_id, "thread", thread_id)

      {:noreply, assign(socket, thread: thread, user_vote: user_vote&.value)}

    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Could not vote")}
  end
end
```

### Prompt Likes (simplified API)

The Content context provides a simplified API for prompt likes:

```elixir
# Toggle like (uses Engagement.toggle_vote internally)
Content.toggle_like(user_id, prompt_id)

# Check if liked
Content.user_liked_prompt?(user_id, prompt_id)
# => true/false
```

### Video Comments

```elixir
# In video_live.ex mount
def mount(%{"id" => id}, _session, socket) do
  video = Content.get_video!(id)

  # Get or create discussion thread for comments
  {:ok, discussion} = Engagement.get_or_create_discussion("video", video.id,
    board_id: get_comments_board_id(),
    author_id: get_system_user_id(),
    title: "Comments: #{video.title}"
  )

  comments = Forum.list_comments(discussion.thread_id)

  {:ok, assign(socket, video: video, discussion: discussion, comments: comments)}
end
```

### Bulk Loading for Lists (N+1 Prevention)

```elixir
def list_threads_with_user_votes(user_id, board_id) do
  threads = Forum.list_threads(board_id)
  thread_ids = Enum.map(threads, & &1.id)

  # Single query for all votes
  user_votes = Engagement.bulk_get_votes(user_id, "thread", thread_ids)

  # Attach votes to threads
  Enum.map(threads, fn thread ->
    Map.put(thread, :user_vote, Map.get(user_votes, thread.id))
  end)
end
```

## Migration from Old System

### What Changed

| Old                          | New                              |
|------------------------------|----------------------------------|
| `forum_votes` table          | `votes` table                    |
| `likes` table                | Dropped (use votes with +1)      |
| `Urielm.Forum.Vote`          | `Urielm.Engagement.Vote`         |
| `Urielm.Content.Like`        | Deleted (use Engagement.Vote)    |
| `Forum.cast_vote/4`          | `Engagement.cast_vote/4`         |
| `Forum.get_user_vote/3`      | `Engagement.get_vote/3`          |
| `Content.toggle_like/2`      | Still works (uses Engagement)    |
| `Accounts.like_prompt/2`     | Still works (uses Engagement)    |

### Data Migration

- All 907 forum votes were preserved (table renamed)
- 2 likes were dropped (not migrated)
- No data loss for forum voting functionality

### Code Changes Required

If you have code using the old system:

```elixir
# Old
alias Urielm.Forum.Vote
Forum.cast_vote(user_id, "thread", thread_id, 1)
Forum.get_user_vote(user_id, "thread", thread_id)

# New
alias Urielm.Engagement
Engagement.cast_vote(user_id, "thread", thread_id, 1)
Engagement.get_vote(user_id, "thread", thread_id)
```

## File Locations

```
lib/urielm/
├── engagement.ex                 # Main context module
└── engagement/
    ├── vote.ex                   # Vote schema
    └── discussion.ex             # Discussion schema

priv/repo/migrations/
└── 20251229194023_unify_engagement_system.exs
```

## Testing

```elixir
# Test toggle logic
{:ok, _} = Engagement.toggle_vote(user_id, "thread", thread_id, 1)
assert Engagement.get_vote(user_id, "thread", thread_id).value == 1

{:ok, _} = Engagement.toggle_vote(user_id, "thread", thread_id, 1)
assert Engagement.get_vote(user_id, "thread", thread_id) == nil  # Removed

{:ok, _} = Engagement.toggle_vote(user_id, "thread", thread_id, -1)
assert Engagement.get_vote(user_id, "thread", thread_id).value == -1

{:ok, _} = Engagement.toggle_vote(user_id, "thread", thread_id, 1)
assert Engagement.get_vote(user_id, "thread", thread_id).value == 1  # Switched
```

## Common Patterns

### Adding Votes to a New Content Type

1. Add target type to `@valid_targets` in `Engagement.Vote`
2. Optionally add score field to schema and `apply_score_delta/3` clause
3. Use `Engagement.toggle_vote/4` in your LiveView

### Adding Comments to Content

1. Add target type to `@valid_targets` in `Engagement.Discussion`
2. Create/get board for embedded comments
3. Use `Engagement.get_or_create_discussion/3` in mount
4. Render comments using existing forum components
