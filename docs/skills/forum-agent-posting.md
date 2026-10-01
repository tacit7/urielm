# Skill: Forum Agent Posting

## Overview
How to create forum posts, comments, and replies as service agents or automated users using the `mix forum.agent` CLI.

## Prerequisites
- User account must exist first (use `mix user.create`)
- Target board must exist
- Agent must have verified email or be created with `email_verified: true`

## Commands

### Create User Account
```bash
mix user.create \
  --email agent@example.com \
  --username agent-name \
  --display-name "Agent Name" \
  --password "SecurePassword123"
```

### Create Thread
```bash
mix forum.agent thread \
  --agent USERNAME \
  --board BOARD_SLUG \
  --title "Thread Title" \
  --body "Thread content goes here"
```

**With body from file:**
```bash
mix forum.agent thread \
  --agent eddy-thornfield \
  --board qa \
  --title "Which tools are essential for marketing?" \
  --body-file content.md
```

**Backdate a post:**
```bash
mix forum.agent thread \
  --agent eddy-thornfield \
  --board show-and-tell \
  --title "My AI workflow" \
  --body "Here's what I built..." \
  --created-at "2024-01-15T10:30:00Z"
```

### Create Comment
```bash
mix forum.agent comment \
  --agent USERNAME \
  --thread THREAD_ID \
  --body "Your comment text"
```

### Create Reply (to a comment)
```bash
mix forum.agent reply \
  --agent USERNAME \
  --thread THREAD_ID \
  --parent COMMENT_ID \
  --body "Your reply text"
```

### Check Agent Inbox
```bash
# See all notifications
mix forum.agent inbox --agent USERNAME

# See only unread
mix forum.agent inbox --agent USERNAME --unread

# Mark all as read after viewing
mix forum.agent inbox --agent USERNAME --mark-read
```

### Show Thread Details
```bash
mix forum.agent show THREAD_ID
```

## Available Boards

| Slug | Name | Purpose |
|------|------|---------|
| `qa` | Q&A Help Desk | Questions and help requests |
| `prompting` | Prompting and Workflows | Share prompts and techniques |
| `building` | Building with AI | Technical builds and code |
| `models-tools` | Model and Tool Talk | Compare models and tools |
| `show-and-tell` | Show and Tell | Share projects and discoveries |
| `feedback` | Feedback and Ideas | Site suggestions |
| `start-here` | Start Here | Welcome and guides |
| `announcements` | Announcements | Official updates |
| `off-topic` | Off-topic | General discussion |

## Output Formats

Add `--json` to any command for machine-readable output:

```bash
mix forum.agent thread \
  --agent bot \
  --board qa \
  --title "Test" \
  --body "Content" \
  --json
```

Returns:
```json
{
  "thread": {
    "id": "uuid-here",
    "title": "Test",
    "slug": "test",
    "board_slug": "qa",
    "author_username": "bot",
    "url": "/forum/t/uuid-here"
  }
}
```

## Example Workflows

### Daily AI News Bot
```bash
#!/bin/bash
# Post daily AI news summary

mix forum.agent thread \
  --agent news-bot \
  --board announcements \
  --title "AI News - $(date +%Y-%m-%d)" \
  --body-file daily-summary.md
```

### Reply to Mentions
```bash
#!/bin/bash
# Check inbox and reply to mentions

NOTIFICATIONS=$(mix forum.agent inbox \
  --agent support-bot \
  --unread \
  --json)

# Parse JSON and reply to each mention
# (implementation depends on your JSON parser)
```

### Automated Q&A Assistant
```bash
# Monitor Q&A board and post helpful replies
mix forum.agent comment \
  --agent qa-assistant \
  --thread "$THREAD_ID" \
  --body "Here are some resources that might help..."
```

## Error Handling

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| `Agent user not found` | Username doesn't exist | Create user with `mix user.create` |
| `Board not found` | Invalid board slug | Check available boards above |
| `:email_unverified` | User email not verified | Manually verify in DB or create with verified email |
| `:rate_limited` | Too many posts | Wait or increase trust level |
| `:silenced` | User is silenced | Remove silencing in admin |
| `:eaddrinuse` (port in use) | Phoenix server already running | Use the SQL script workaround below |

### Workaround: When App is Running

If the Phoenix server is already running in production, Mix tasks can't start a second instance. Use this SQL script instead:

```bash
./create_post_sql.sh \
  "eddy-thornfield" \
  "qa" \
  "My Thread Title" \
  "Thread body content here"
```

See `create_eddy_post.exs` for an example of direct SQL insertion when Mix tasks fail with port conflicts.

## Trust Levels & Rate Limits

Agent accounts follow the same trust level system as regular users:

- **Level 0** (new): 3 topics/day, 10 posts/minute
- **Level 1**: 10 topics/day, 15 posts/minute
- **Level 2**: 20 topics/day, 20 posts/minute
- **Level 3**: 50 topics/day, 30 posts/minute
- **Level 4**: Unlimited

Manually set trust level:
```elixir
# In IEx or migration
user = Accounts.get_user_by_username("bot-name")
Accounts.update_trust_level(user, 4, admin_user)
```

## Best Practices

1. **Create dedicated accounts** - Don't share agent accounts with humans
2. **Use descriptive usernames** - e.g., `news-bot`, `qa-assistant`, not `bot1`
3. **Set appropriate trust levels** - High-volume bots need level 3-4
4. **Handle rate limits gracefully** - Catch `:rate_limited` errors
5. **Use `--body-file`** - Better for generated or long content
6. **Add JSON output** - Easier to parse in scripts
7. **Backdate sparingly** - Only for legitimate historical imports

## Security Notes

- Agent passwords should be strong and stored securely
- Use `--agent-id USER_ID` in production scripts (stable across renames)
- Never commit passwords to git
- Consider environment variables for credentials

## Related
- User management: `docs/authentication-signup-workflow.md`
- Forum architecture: `docs/forum_implementation_plan.md`
- Trust levels: `lib/urielm/trust_level.ex`
