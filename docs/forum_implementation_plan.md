# Forum Routes & LiveView Implementation Plan

## Overview
Implement Reddit-style forum UI with feed views, thread detail pages, and nested comments. Follow existing Phoenix LiveView + Svelte hybrid patterns from the codebase.

## Critical Files to Modify

### Routes
- `lib/urielm_web/router.ex` - Add forum routes

### LiveView Modules (new files)
- `lib/urielm_web/live/forum_live.ex` - Board list view
- `lib/urielm_web/live/board_live.ex` - Thread feed for a board
- `lib/urielm_web/live/thread_live.ex` - Thread detail with comments
- `lib/urielm_web/live/new_thread_live.ex` - Thread creation form (separate page)

### Svelte Components (new files)
- `assets/svelte/ThreadCard.svelte` - Thread preview in feed
- `assets/svelte/CommentTree.svelte` - Nested comment display
- `assets/svelte/VoteButtons.svelte` - Upvote/downvote UI

### Integration
- `assets/js/app.js` - Register new Svelte components

## Implementation Steps

### 1. Router Setup

Add to `:default` live_session (public viewing):
```elixir
live_session :default, layout: {UrielmWeb.Layouts, :app} do
  # ... existing routes
  live "/forum", ForumLive
  live "/forum/b/:board_slug", BoardLive
  live "/forum/t/:thread_id", ThreadLive
end
```

Add to `:authenticated` live_session (posting):
```elixir
live_session :authenticated,
  on_mount: [{UrielmWeb.UserAuth, :ensure_authenticated}],
  layout: {UrielmWeb.Layouts, :app} do
  # ... existing routes
  live "/forum/b/:board_slug/new", NewThreadLive
end
```

Voting uses same routes as viewing but with `handle_event` guards checking `@current_user`

### 2. ForumLive - Board List

**Purpose**: Display all categories and boards

**mount/3**:
- Load categories with boards: `Forum.list_categories() |> Repo.preload(:boards)`
- Assign to socket

**Template**:
- Simple Phoenix template (no Svelte needed)
- Group boards by category
- Links to `/forum/b/:board_slug`
- Show board stats (thread count, last activity)

**Pattern**: Similar to simple list pages, no streams needed (small dataset)

### 3. BoardLive - Thread Feed

**Purpose**: Display threads for a board with sorting

**mount/3**:
- Get board by slug: `Forum.get_board!(slug)`
- Set default sort: `:new`

**handle_params/3**:
- Parse `?sort=top` query param
- Load threads with `Forum.list_threads(board_id, sort: sort, limit: 20)`
- Use LiveView streams: `stream(:threads, threads, reset: true)`

**handle_event/3**:
- `"vote"` - call `Forum.cast_vote`, update thread score in stream
- `"load_more"` - infinite scroll pagination (append to stream)

**Template**:
- Sort tabs (New | Top)
- Stream container with `phx-update="stream"` + InfiniteScroll hook
- Each thread rendered with `<.svelte name="ThreadCard" .../>`
- "New Thread" button → links to `/forum/b/:board_slug/new` (visible only if authenticated)

**Svelte: ThreadCard**:
- Props: `{id, title, body, author, score, commentCount, createdAt, userVote}`
- Display title, snippet, metadata
- Vote buttons component
- Link to thread detail

### 4. NewThreadLive - Thread Creation Form

**Purpose**: Separate page for creating new threads (authenticated only)

**mount/3**:
- Get board by slug from params
- Create empty changeset: `Forum.Thread.changeset(%Thread{}, %{})`
- Assign board and changeset to socket

**handle_event/3**:
- `"validate"` - validate form on input change, update changeset errors
- `"save"` - insert thread via `Forum.create_thread`, redirect to thread detail on success

**Template**:
- Form with title, body (markdown textarea)
- Live validation errors
- Cancel button → back to board
- Submit button

**Pattern**: Follow form patterns from existing LiveViews (PromptLive comment form)

### 5. ThreadLive - Thread Detail with Comments

**Purpose**: Show full thread and nested comments

**mount/3**:
- Load thread with comments: `Forum.get_thread!(id) |> Repo.preload(comments: [:author, :replies])`
- Build comment tree structure in memory (adjacency list → nested map)
- Serialize for Svelte

**handle_event/3**:
- `"create_comment"` - validate user, insert, rebuild comment tree, update assigns
- `"vote"` - similar to BoardLive
- `"delete_thread"` - admin or author only, call `Forum.remove_thread`
- `"delete_comment"` - admin or author only, call `Forum.remove_comment`

**Template**:
- Thread header (title, body, author, vote buttons)
- Comment form (auth-gated)
- `<.svelte name="CommentTree" props={%{comments: @comment_tree}} .../>`

**Svelte: CommentTree**:
- Props: `{comments: [], currentUserId, currentUserIsAdmin}`
- Recursive component rendering replies
- Collapse/expand branches
- Reply button (shows inline form)
- Vote buttons per comment
- Delete button (conditional on ownership/admin)
- Max depth limit (6-8 levels)

**Comment Tree Structure**:
```elixir
defp build_comment_tree(comments) do
  # Group by parent_id
  grouped = Enum.group_by(comments, & &1.parent_id)

  # Build tree recursively
  root_comments = grouped[nil] || []
  Enum.map(root_comments, fn comment ->
    build_node(comment, grouped)
  end)
end

defp build_node(comment, grouped) do
  children = grouped[comment.id] || []
  %{
    id: to_string(comment.id),
    body: comment.body,
    author: %{id: comment.author.id, username: comment.author.username},
    score: comment.score,
    insertedAt: comment.inserted_at,
    replies: Enum.map(children, &build_node(&1, grouped))
  }
end
```

### 6. VoteButtons Svelte Component

**Reusable component for threads and comments**

**Props**: `{targetType, targetId, score, userVote, live}`

**Behavior**:
- Display ▲ score ▼
- Highlight active vote
- Click triggers: `live.pushEvent('vote', {targetType, targetId, value: 1 or -1})`
- Optimistic UI update (revert on error)

### 7. Serialization Helpers

Add to each LiveView:
```elixir
defp serialize_thread(thread) do
  %{
    id: to_string(thread.id),
    title: thread.title,
    body: thread.body,
    slug: thread.slug,
    score: thread.score,
    commentCount: thread.comment_count,
    author: %{
      id: thread.author.id,
      username: thread.author.username
    },
    createdAt: thread.inserted_at,
    userVote: get_user_vote(@current_user, "thread", thread.id)
  }
end

defp get_user_vote(nil, _, _), do: nil
defp get_user_vote(user, target_type, target_id) do
  case Forum.get_user_vote(user.id, target_type, target_id) do
    nil -> nil
    vote -> vote.value
  end
end
```

### 8. Authorization Checks

**Pattern from PromptLive**:
```elixir
def handle_event("delete_thread", %{"id" => id}, socket) do
  thread = Forum.get_thread!(id)
  user = socket.assigns.current_user

  cond do
    is_nil(user) ->
      {:noreply, put_flash(socket, :error, "You must be logged in")}

    user.is_admin or thread.author_id == user.id ->
      Forum.remove_thread(thread, user.id)
      {:noreply, redirect(socket, to: ~p"/forum/b/#{thread.board.slug}")}

    true ->
      {:noreply, put_flash(socket, :error, "Not authorized")}
  end
end
```

### 9. Markdown Rendering

**Reuse existing MarkdownRenderer Svelte component** (already registered):
```elixir
<.svelte
  name="MarkdownRenderer"
  props={%{content: @thread.body}}
  socket={@socket}
/>
```

## Testing Strategy

**LiveView Tests** (new file: `test/urielm_web/live/forum_live_test.exs`):
- Mount forum index, assert boards listed
- Mount board with threads, assert stream rendered
- Mount thread, assert comments rendered
- Test voting with auth
- Test thread creation with auth
- Test comment creation with auth
- Test moderation (delete as admin)

**Follow existing test patterns from** `test/urielm_web/live/chat_live_test.exs`:
- Use `conn_case` with authenticated sessions
- Use `live/2` and `render_*/1` helpers
- Test event handling with `render_click/2`

## Decisions (User Confirmed)

1. **Thread creation form**: Separate page at `/forum/b/:board_slug/new`
2. **Pagination**: Infinite scroll (matches ReferencesLive pattern)
3. **Real-time updates**: Defer to v1 (manual refresh for MVP)
4. **Hot sorting**: Defer to v1 (New/Top only for MVP)

## Non-Goals (Defer to v1)

- Search (full-text)
- User profiles with post history
- Notifications
- Flair/tags
- Rate limiting (implement later)
- Admin moderation panel (use inline for MVP)

## Summary

This plan follows established patterns:
- Two-tier route protection (public viewing + authenticated posting)
- LiveView streams for feed efficiency with infinite scroll
- Svelte for complex interactive UI (voting, comment tree)
- Phoenix templates for structure
- Separate page for thread creation (not modal)
- Proper auth checks in event handlers
- Data serialization with camelCase + string IDs
- No real-time updates (manual refresh for MVP)

Estimated scope: 4 LiveView modules, 3 Svelte components, serialization helpers, route updates, tests.

## Implementation Order

1. Routes setup
2. ForumLive (board list) - simplest, no auth needed
3. BoardLive (thread feed) - streams + infinite scroll
4. NewThreadLive (thread form) - authenticated route
5. ThreadLive (thread detail) - most complex (comments)
6. Svelte components (ThreadCard, VoteButtons, CommentTree)
7. Tests
