# Moderation & Reporting Testing Guide

This guide explains how to test the moderation, reporting, and notification features in the forum.

## Setup

1. Start the server:
   ```bash
   mix phx.server
   ```

2. Navigate to http://localhost:4000

3. Create test users with different roles

## Test Scenarios

### Scenario 1: Create Multiple Users

1. Create 3-4 user accounts via signup or database:
   - **Regular User 1** (reporter) - for reporting content
   - **Regular User 2** (accused) - for creating problematic content
   - **Regular User 3** (moderator) - for reviewing reports
   - **Admin** - for accessing admin panels (set `is_admin: true`)

### Scenario 2: Test Reporting (Backend/API)

The report buttons are not yet added to the UI, but the backend is ready. You can test via database queries or unit tests.

**Unit Tests:**
```bash
mix test test/urielm/moderation_test.exs
```

**Direct Backend Test (iex):**
```bash
iex -S mix

# Create users
{:ok, reporter} = Urielm.Accounts.register_user(%{
  email: "reporter@test.com",
  username: "reporter",
  password: "password123",
  name: "Reporter"
})

{:ok, accused} = Urielm.Accounts.register_user(%{
  email: "accused@test.com",
  username: "accused",
  password: "password123",
  name: "Accused User"
})

# Create forum content
category = Urielm.Repo.get_by!(Urielm.Forum.Category, slug: "general")
board = Urielm.Repo.get_by!(Urielm.Forum.Board, category_id: category.id)
{:ok, thread} = Urielm.Forum.create_thread(board.id, accused.id, %{"title" => "Test", "body" => "Test content"})

# Report the thread
{:ok, report} = Urielm.Forum.create_report(reporter.id, "thread", thread.id, %{
  reason: "spam",
  description: "This is spam"
})

IO.inspect(report)
```

### Scenario 3: Admin Reviews Reports

1. Navigate to `/admin/moderation` while logged in as an admin

2. You should see:
   - Moderation queue title
   - Badge showing pending report count
   - List of pending reports with:
     - Reporter name
     - Target type (thread/comment)
     - Reason (spam/abuse/offensive/other)
     - Description (if provided)
     - Buttons: Approve, Resolve, Dismiss

3. Click buttons to take action:
   - **Approve**: Mark content as acceptable
   - **Resolve**: Mark report as resolved
   - **Dismiss**: Discard report

4. Reports disappear from queue after action

### Scenario 4: Notification Settings

The notification level buttons are not yet added to the thread UI, but the backend functions are ready.

**Test via iex:**
```bash
iex -S mix

user = Urielm.Accounts.get_user(user_id)
thread = Urielm.Forum.get_thread!(thread_id)

# Set different notification levels
Urielm.Forum.set_notification_level(user.id, thread.id, "watching")
Urielm.Forum.is_watching?(user.id, thread.id)  # => true

Urielm.Forum.set_notification_level(user.id, thread.id, "tracking")
Urielm.Forum.is_tracking?(user.id, thread.id)  # => true

Urielm.Forum.set_notification_level(user.id, thread.id, "muted")
Urielm.Forum.is_muted?(user.id, thread.id)  # => true
```

### Scenario 5: Trust Level Rate Limiting

1. Create a user at trust level 0 (new user):
```bash
# In iex
{:ok, new_user} = Urielm.Accounts.register_user(%{
  email: "newuser@test.com",
  username: "newuser",
  password: "password",
  name: "New User"
})
# User automatically gets trust_level: 0
```

2. Try to create 4 threads in quick succession:
   - Threads 1-3 should succeed (max 3 per day for level 0)
   - Thread 4 should fail with `:rate_limited` error

3. Try to create 2 comments quickly on same thread:
   - Comment 1 should succeed (max 1 per minute for level 0)
   - Comment 2 should fail with `:rate_limited` error

4. Log in as admin (level 4) and create many threads/comments:
   - All should succeed (unlimited for level 4)

### Scenario 6: Admin Panel - Trust Levels

1. Navigate to `/admin/trust-levels` as an admin

2. You should see all 5 trust levels:
   - Level 0: "New"
   - Level 1: "Basic"
   - Level 2: "Member"
   - Level 3: "Regular"
   - Level 4: "Leader"

3. Click "Edit" on any level to modify:
   - Thresholds (min_topics, min_posts, etc.)
   - Rate limits
   - Permissions (can_pin_topics, can_moderate, etc.)

4. Changes are saved immediately and affect rate limiting for all users

## Test Data Setup (Database)

To quickly set up test scenarios:

```bash
iex -S mix

# Create admin
{:ok, admin} = Urielm.Accounts.register_user(%{
  email: "admin@test.com",
  username: "admin",
  password: "password",
  name: "Admin User"
})
admin |> Ecto.Changeset.change(%{is_admin: true, trust_level: 4}) |> Urielm.Repo.update!()

# Create regular users
{:ok, user1} = Urielm.Accounts.register_user(%{
  email: "user1@test.com",
  username: "user1",
  password: "password",
  name: "User One"
})

{:ok, user2} = Urielm.Accounts.register_user(%{
  email: "user2@test.com",
  username: "user2",
  password: "password",
  name: "User Two"
})

# Create forum content
category = Urielm.Repo.get_by!(Urielm.Forum.Category, slug: "general")
board = Urielm.Repo.get_by!(Urielm.Forum.Board, category_id: category.id)

{:ok, thread1} = Urielm.Forum.create_thread(board.id, user2.id, %{
  "title" => "Test Thread",
  "body" => "This is test content for reporting"
})

# Create report
{:ok, report} = Urielm.Forum.create_report(user1.id, "thread", thread1.id, %{
  reason: "spam",
  description: "This is spam content"
})

IO.puts("Admin ID: #{admin.id}, Admin user: admin@test.com / password")
IO.puts("User 1 ID: #{user1.id}, User: user1@test.com / password")
IO.puts("User 2 ID: #{user2.id}, User: user2@test.com / password")
IO.puts("Report ID: #{report.id}")
```

## Current Limitations

1. **UI Components Not Yet Added**: Report buttons exist in code but not rendered in templates
   - Need to add Svelte components or HTML buttons for:
     - Report thread button
     - Report comment buttons
     - Notification level dropdown

2. **Notification Settings**: Backend ready, UI components pending

3. **Test Failures**: 3 fixtures tests failing due to database state issues (isolated to moderation tests)

## Next Steps

1. Add report button to thread template
2. Add report buttons to comment components
3. Add notification level dropdown to thread
4. Fix remaining fixture test issues
5. Add integration tests for LiveView interactions

