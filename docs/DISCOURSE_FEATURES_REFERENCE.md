# Discourse Feature Set - Complete Reference

Comprehensive list of Discourse features for comparison and implementation tracking.

## Core Forum Features

### Content Management
- ✅ **Categories** - Top-level organization
- ✅ **Subcategories** - Nested organization (boards in our impl)
- ✅ **Topics/Threads** - Discussion posts
- ✅ **Posts/Comments** - Replies with nesting
- ✅ **Tags** - Cross-category organization
- ❌ **Tag groups** - Grouped tag management
- ✅ **Search** - Full-text search
- ❌ **Advanced search** - Filters by user, date, category
- ❌ **Saved searches** - Persistent search queries

### Content Creation
- ✅ **Rich text editor** - Tiptap WYSIWYG
- ✅ **Markdown support** - Full markdown syntax
- ❌ **BBCode support** - Alternative markup
- ✅ **Composer** - Bottom-anchored, resizable
- ✅ **Grippie** - Drag to resize composer
- ❌ **Draft system** - Server-side drafts (we have localStorage)
- ❌ **Draft sequences** - Multiple drafts per user
- ✅ **Preview** - See rendered output
- ❌ **Side-by-side** - Editor + preview split view
- ✅ **Uploads** - Generic upload library with R2 (backend complete, UI pending)
- ❌ **Drag-drop** - Drag files into composer
- ✅ **Keyboard shortcuts** - Cmd+Enter, formatting shortcuts

### Formatting & Embeds
- ✅ **Bold, italic, strike** - Text formatting
- ✅ **Headings** - H1-H6
- ✅ **Lists** - Bullet, numbered
- ✅ **Quotes** - Blockquotes
- ✅ **Code** - Inline and blocks
- ❌ **Tables** - Markdown tables
- ✅ **Links** - Hyperlinks
- ✅ **YouTube embeds** - Auto-embed videos
- ✅ **Image embeds** - Inline images
- ✅ **Twitter embeds** - Tweet cards
- ❌ **Instagram embeds** - Instagram posts
- ❌ **GitHub gists** - Code snippet embeds
- ❌ **PDF viewer** - Inline PDF rendering
- ❌ **Audio player** - MP3, OGG playback
- ❌ **Video player** - MP4 playback
- ❌ **Giphy integration** - GIF search
- ❌ **Emoji picker** - Unicode emoji

### User Interactions
- ✅ **Voting** - Upvote/downvote (we do upvote only)
- ✅ **Likes** - Heart reactions
- ❌ **Multiple reactions** - Different emoji reactions
- ✅ **Bookmarks** - Save posts and comments
- ❌ **Bookmark notes** - Add private notes to bookmarks
- ❌ **Bookmark reminders** - Timed reminders
- ✅ **Following users** - Subscribe to user activity
- ❌ **Muting users** - Hide specific users
- ❌ **Ignoring users** - Complete user block
- ✅ **Mentions** - @username notifications
- ❌ **Quoting** - Quote previous posts
- ❌ **Multi-quote** - Quote multiple posts at once
- ❌ **Whispers** - Mod-only visible posts

### Topic Features
- ✅ **Pinning** - Sticky topics
- ❌ **Global pins** - Pin across all categories
- ❌ **Banner** - Site-wide announcement
- ✅ **Locking** - Close topic to replies
- ✅ **Archiving** - Read-only topics
- ✅ **Solved status** - Mark topic as solved
- ✅ **Auto-close timer** - Close after X days
- ❌ **Auto-delete timer** - Delete after X days
- ❌ **Slow mode** - Rate limit replies per topic
- ❌ **Unlisted** - Hidden from topic lists
- ❌ **Topic templates** - Pre-filled content
- ❌ **Required tags** - Enforce tag selection
- ❌ **Private topics** - Visible to specific users only

### User Management
- ✅ **User profiles** - Bio, location, website
- ✅ **Avatars** - Profile pictures
- ❌ **Profile backgrounds** - Header images
- ❌ **User cards** - Hover cards with quick info
- ✅ **Trust levels** - 0-4 progression
- ❌ **Automatic promotion** - Based on activity
- ✅ **Display names** - Separate from username
- ✅ **Email/password auth** - Native auth
- ✅ **OAuth** - Google OAuth
- ❌ **SSO** - Single sign-on
- ❌ **2FA** - Two-factor authentication

### Moderation
- ✅ **Moderator role** - Between user and admin
- ❌ **Category moderators** - Per-category mods
- ✅ **Flag/report system** - User reports
- ❌ **Flag queue** - Dedicated moderation queue
- ❌ **Auto-flagging** - Rules-based automatic flags
- ✅ **Hide/remove posts** - Soft delete
- ❌ **Delete posts** - Hard delete
- ✅ **Edit history** - Post revisions
- ❌ **Edit reasons** - Required edit explanations
- ❌ **Post approval** - Pre-moderate new users
- ❌ **User suspension** - Temporary bans
- ❌ **User silencing** - Restrict posting
- ❌ **IP banning** - Block IP addresses
- ❌ **Email banning** - Block email domains
- ❌ **Watched words** - Auto-flag/block specific terms
- ❌ **Akismet** - Spam filtering
- ❌ **Staff notes** - Private mod notes on users

### Notifications
- ✅ **In-app notifications** - Real-time alerts
- ❌ **Email notifications** - Digest emails
- ❌ **Push notifications** - Browser push
- ✅ **Thread watching** - Subscribe to topics
- ❌ **Category watching** - Subscribe to categories (have watch/mute but no auto-subscribe)
- ✅ **Mention notifications** - @username alerts (backend ready, UI not wired)
- ❌ **Reply notifications** - Notified when replied to
- ❌ **Quote notifications** - Notified when quoted
- ❌ **Like notifications** - Notified when liked
- ✅ **Notification preferences** - Per-topic settings
- ❌ **Muted topics** - Silence specific topics
- ❌ **Notification schedules** - Quiet hours

### Discovery & Navigation
- ✅ **Latest topics** - Recently active
- ✅ **New topics** - Recently created
- ✅ **Top topics** - Sorted by score
- ✅ **Unread** - Unread for current user
- ❌ **Categories page** - Category overview
- ❌ **Tags page** - Browse by tags
- ❌ **Top contributors** - User leaderboard
- ❌ **Similar topics** - Related content suggestions
- ❌ **Suggested topics** - Personalized recommendations
- ✅ **Read tracking** - Mark topics as read
- ✅ **Last read position** - Resume where you left off
- ❌ **Topic excerpts** - Previews in lists
- ✅ **View count** - Track topic views

### Social Features
- ✅ **User following** - Follow other users
- ❌ **Activity feed** - Posts from followed users
- ❌ **User directory** - Browse all users
- ❌ **User groups** - Custom user groups
- ❌ **Group messages** - PM groups
- ❌ **Presence** - Show who's online
- ❌ **Typing indicators** - Show who's typing
- ❌ **User status** - Custom status messages
- ❌ **User flair** - Title/badge under username

### Gamification
- ❌ **Badges** - Achievement system
- ❌ **Badge progress** - Track progress to badges
- ❌ **Leaderboards** - Top users by metric
- ❌ **Ranks** - User ranking system
- ✅ **Like counts** - Social proof
- ❌ **Streaks** - Visit/post streaks
- ❌ **Invites** - User invitation system
- ❌ **Referrals** - Track who invited who

### Content Discovery
- ❌ **Topic lists** - Multiple views (latest, top, categories)
- ❌ **Digest emails** - Weekly/monthly summaries
- ❌ **RSS feeds** - Per-category/tag feeds
- ❌ **Webhooks** - External integrations
- ❌ **Related topics** - Sidebar suggestions
- ❌ **Popular links** - Most shared URLs
- ❌ **Hot algorithm** - Trending calculation
- ❌ **New user of the month** - Highlight newcomers

### Advanced Features
- ❌ **Polls** - In-topic voting
- ❌ **Multi-poll** - Multiple poll questions
- ❌ **Wiki posts** - Community-editable
- ❌ **Version control** - Wiki history
- ❌ **Events** - Calendar events in topics
- ❌ **Voting** - Democratic decisions
- ❌ **Solved plugin** - Accepted answers
- ❌ **Question/Answer mode** - StackOverflow style
- ❌ **Chat** - Real-time chat (we have separate chat)
- ❌ **Private messages** - 1-on-1 DMs
- ❌ **Message threading** - Threaded PMs
- ❌ **Group PMs** - Multi-user messages

### Performance & Scale
- ❌ **CDN support** - Asset delivery
- ❌ **Image optimization** - Auto-resize images
- ❌ **Lazy loading** - Load content on scroll
- ❌ **Infinite scroll** - Continuous pagination
- ✅ **Pagination** - Page-based navigation (Flop)
- ❌ **Caching** - Redis caching
- ❌ **Read replicas** - Database scaling
- ❌ **Background jobs** - Sidekiq/Oban (we have GenServer)

### Admin & Configuration
- ❌ **Admin dashboard** - Metrics and controls
- ❌ **Site settings** - 500+ configuration options
- ❌ **Customization** - CSS/JavaScript injection
- ❌ **Theme creator** - Visual theme builder
- ❌ **Plugin system** - Extend with plugins
- ❌ **API** - RESTful API for integrations
- ❌ **Backup/restore** - Automated backups
- ❌ **Import tools** - Migrate from other platforms
- ❌ **Export tools** - Data portability
- ❌ **Analytics** - Built-in analytics
- ❌ **Reports** - Usage reports
- ❌ **Rate limiting** - Global rate limits (we have per-user)

### Mobile
- ✅ **Responsive design** - Mobile-first
- ✅ **Mobile composer** - Touch-optimized
- ❌ **PWA** - Progressive web app
- ❌ **Mobile app** - Native iOS/Android
- ❌ **Push notifications** - Mobile push
- ❌ **Offline mode** - Read offline

### Accessibility
- ✅ **Keyboard navigation** - Full keyboard support
- ✅ **Screen readers** - ARIA labels
- ✅ **Focus indicators** - Visible focus rings
- ❌ **High contrast mode** - Accessibility theme
- ❌ **Font size controls** - User font preferences
- ❌ **Reduce motion** - Animation toggles

### Security
- ❌ **Content Security Policy** - CSP headers
- ❌ **Rate limiting** - DDoS protection
- ❌ **IP tracking** - Security monitoring
- ❌ **Login security** - Failed attempt tracking
- ❌ **CORS** - Cross-origin config
- ❌ **Spam protection** - Akismet, reCAPTCHA
- ❌ **Onebox whitelist** - Allowed embed domains
- ✅ **Trust levels** - Permission progression
- ✅ **Rate limiting** - Per-user posting limits

## Implementation Status Summary

**Total Discourse Features**: ~150+
**Implemented**: ~41 (27%)
**Core Features Implemented**: ~90%
**Advanced Features**: ~10%

**Recent Addition**: Generic file upload library (Cloudflare R2, polymorphic, UUID v7)

## Feature Priority for Remaining Work

### High Priority (User-facing, high value)
1. **Polls** - Very popular feature
2. **Email notifications** - Critical for retention
3. **Activity feed** - User engagement
4. **User badges** - Gamification
5. **Advanced search** - Usability

### Medium Priority (Nice to have)
6. Wiki posts
7. Topic templates
8. Similar topics
9. User directory
10. Groups/teams

### Low Priority (Advanced/Enterprise)
11. SSO/SAML
12. Plugin system
13. Analytics dashboard
14. Import/export tools
15. Advanced moderation (IP bans, etc.)

---
**Last Updated**: December 20, 2025
**Purpose**: Feature comparison and roadmap planning
**Status**: Living document
