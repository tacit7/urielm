# Discourse Feature Set - Complete Reference

Comprehensive list of Discourse features for comparison and implementation tracking.

**Legend**
- ✅ Implemented
- ⚠️ Partial / backend-only / needs UI or coverage verification
- ❌ Not implemented

## Core Forum Features

### Content Management
- ✅ **Categories** - Top-level organization
- ✅ **Subcategories** - Nested organization (boards in our impl)
- ✅ **Topics/Threads** - Discussion posts
- ✅ **Posts/Comments** - Replies with nesting
- ⚠️ **Tags** - Backend/thread tagging exists; browse/management UI and tag UI tests need coverage
- ❌ **Tag groups** - Grouped tag management
- ✅ **Search** - Full-text search
- ⚠️ **Advanced search** - Full-text and some filters exist; Discourse-level user/date/category filters are incomplete
- ❌ **Saved searches** - Persistent search queries

### Content Creation
- ⚠️ **Rich text editor** - Tiptap pieces exist; forum composer integration and coverage need verification
- ✅ **Markdown support** - Full markdown syntax
- ❌ **BBCode support** - Alternative markup
- ⚠️ **Composer** - Composer/editor flow exists, but Discourse-style bottom anchoring/resizing is partial
- ⚠️ **Grippie** - Resize behavior appears partial and lacks UI coverage
- ⚠️ **Draft system** - LocalStorage drafts only; no server-side draft system
- ❌ **Draft sequences** - Multiple drafts per user
- ⚠️ **Preview** - Preview/renderer pieces exist; composer preview flow lacks end-to-end coverage
- ⚠️ **Side-by-side** - Preview-side styling exists, but split editor/preview UI is not fully verified
- ⚠️ **Uploads** - Generic upload library with R2 is backend complete; composer UI remains pending
- ❌ **Drag-drop** - Drag files into composer
- ⚠️ **Keyboard shortcuts** - Some shortcuts exist; composer shortcut coverage is incomplete

### Formatting & Embeds
- ✅ **Bold, italic, strike** - Text formatting
- ✅ **Headings** - H1-H6
- ✅ **Lists** - Bullet, numbered
- ✅ **Quotes** - Blockquotes
- ✅ **Code** - Inline and blocks
- ⚠️ **Tables** - Markdown/table styling support appears present; integration coverage needs verification
- ✅ **Links** - Hyperlinks
- ⚠️ **YouTube embeds** - Embed helper and tests exist; integration coverage is incomplete
- ⚠️ **Image embeds** - Embed helper and tests exist; integration coverage is incomplete
- ⚠️ **Twitter embeds** - Embed helper and tests exist; integration coverage is incomplete
- ❌ **Instagram embeds** - Instagram posts
- ❌ **GitHub gists** - Code snippet embeds
- ❌ **PDF viewer** - Inline PDF rendering
- ❌ **Audio player** - MP3, OGG playback
- ❌ **Video player** - MP4 playback
- ❌ **Giphy integration** - GIF search
- ❌ **Emoji picker** - Unicode emoji

### User Interactions
- ✅ **Voting** - Upvote/downvote (we do upvote only)
- ⚠️ **Likes** - Like/vote-style engagement exists; distinct Discourse-style heart reactions are not fully represented
- ❌ **Multiple reactions** - Different emoji reactions
- ✅ **Bookmarks** - Save posts and comments
- ❌ **Bookmark notes** - Add private notes to bookmarks
- ❌ **Bookmark reminders** - Timed reminders
- ✅ **Following users** - Subscribe to user activity
- ❌ **Muting users** - Hide specific users
- ❌ **Ignoring users** - Complete user block
- ⚠️ **Mentions** - Mention parsing/notification backend exists; UI wiring and end-to-end coverage are incomplete
- ❌ **Quoting** - Quote previous posts
- ❌ **Multi-quote** - Quote multiple posts at once
- ❌ **Whispers** - Mod-only visible posts

### Topic Features
- ✅ **Pinning** - Sticky topics
- ❌ **Global pins** - Pin across all categories
- ❌ **Banner** - Site-wide announcement
- ✅ **Locking** - Close topic to replies
- ❌ **Archiving** - Separate read-only archived topic state was not found in audit
- ✅ **Solved status** - Mark topic as solved
- ⚠️ **Auto-close timer** - Backend/worker support exists; UI and live tests are incomplete
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
- ✅ **Flag queue** - Dedicated admin moderation queue exists
- ❌ **Auto-flagging** - Rules-based automatic flags
- ✅ **Hide/remove posts** - Soft delete
- ❌ **Delete posts** - Hard delete
- ✅ **Edit history** - Post revisions
- ❌ **Edit reasons** - Required edit explanations
- ❌ **Post approval** - Pre-moderate new users
- ✅ **User suspension** - Temporary bans supported through admin/user management
- ✅ **User silencing** - Restrict posting supported through admin/user management
- ❌ **IP banning** - Block IP addresses
- ❌ **Email banning** - Block email domains
- ❌ **Watched words** - Auto-flag/block specific terms
- ❌ **Akismet** - Spam filtering
- ❌ **Staff notes** - Private mod notes on users

### Notifications
- ⚠️ **In-app notifications** - Notification list and unread state exist; generation flows are partial
- ❌ **Email notifications** - Digest emails
- ❌ **Push notifications** - Browser push
- ⚠️ **Thread watching** - Subscribe/unsubscribe support exists; auto-generated subscriber notification coverage is missing
- ⚠️ **Category watching** - Backend watch/mute levels exist; UI/route/tests are missing
- ⚠️ **Mention notifications** - Backend ready; UI wiring and end-to-end coverage are incomplete
- ❌ **Reply notifications** - Notified when replied to
- ❌ **Quote notifications** - Notified when quoted
- ❌ **Like notifications** - Notified when liked
- ✅ **Notification preferences** - Per-topic settings
- ⚠️ **Muted topics** - Per-topic mute level exists; UI/tests are incomplete
- ❌ **Notification schedules** - Quiet hours

### Discovery & Navigation
- ✅ **Latest topics** - Recently active
- ✅ **New topics** - Recently created
- ✅ **Top topics** - Sorted by score
- ✅ **Unread** - Unread for current user
- ✅ **Categories page** - Category overview exists
- ❌ **Tags page** - Browse by tags
- ❌ **Top contributors** - User leaderboard
- ❌ **Similar topics** - Related content suggestions
- ❌ **Suggested topics** - Personalized recommendations
- ✅ **Read tracking** - Mark topics as read
- ⚠️ **Last read position** - Read tracking exists; resume-position behavior/tests are missing
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
- ✅ **Topic lists** - Latest/new/top/unread/category views are available in forum navigation
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
- ⚠️ **Solved plugin** - Solved status exists as built-in behavior, not as a full Discourse plugin equivalent
- ❌ **Question/Answer mode** - StackOverflow style
- ⚠️ **Chat** - Separate real-time chat exists; not integrated as Discourse-style topic chat
- ❌ **Private messages** - 1-on-1 DMs
- ❌ **Message threading** - Threaded PMs
- ❌ **Group PMs** - Multi-user messages

### Performance & Scale
- ❌ **CDN support** - Asset delivery
- ❌ **Image optimization** - Auto-resize images
- ⚠️ **Lazy loading** - Some embed/image lazy loading exists; broad content lazy loading is incomplete
- ⚠️ **Infinite scroll** - Hook/notification marker support exists; forum-wide infinite scroll is incomplete
- ✅ **Pagination** - Page-based navigation (Flop)
- ❌ **Caching** - Redis caching
- ❌ **Read replicas** - Database scaling
- ⚠️ **Background jobs** - ThreadCloser GenServer exists; no full durable job queue such as Oban

### Admin & Configuration
- ⚠️ **Admin dashboard** - Admin moderation/user/trust-level pages exist; no unified metrics dashboard
- ⚠️ **Site settings** - Settings and trust-level configuration exist; not a Discourse-scale settings system
- ❌ **Customization** - CSS/JavaScript injection
- ❌ **Theme creator** - Visual theme builder
- ❌ **Plugin system** - Extend with plugins
- ⚠️ **API** - Limited JSON/auth endpoints exist; no comprehensive REST API for forum integrations
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
- ⚠️ **Keyboard navigation** - Basic support exists; full keyboard audit/coverage is missing
- ⚠️ **Screen readers** - ARIA labels exist in places; full screen-reader audit/coverage is missing
- ⚠️ **Focus indicators** - Focus styling exists in places; full focus-state audit/coverage is missing
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

**Tracked Feature Rows**: 195
**Implemented**: 47 (24%)
**Partial / Needs Verification**: 34 (17%)
**Missing**: 114 (58%)
**Core Features Implemented or Partial**: ~80%
**Advanced Features Implemented or Partial**: ~10%

**Recent Addition**: Generic file upload library (Cloudflare R2, polymorphic, UUID v7)

## Audit Notes

**Audit source**: EITS team `discourse-feature-audit` on August 17, 2026.

The audit found several rows that were stale in either direction:

- Some rows marked ✅ are only partial, backend-only, or insufficiently covered by tests.
- Some rows marked ❌ are implemented or partially implemented now, especially moderation queue, suspension/silencing, categories page, topic lists, embeds, and admin pages.
- `mix compile --warnings-as-errors` was reported blocked by pre-existing HEEx/template warnings during the audit, outside the scope of this document update.

### Test Coverage Gaps

- Tag UI and tag browsing/management tests
- `SearchLive` and advanced-search filter tests
- Composer, preview, side-by-side, draft, upload, and shortcut UI tests
- Auto-close timer UI/live tests
- End-to-end mention notification and subscriber notification generation tests
- Category-watch UI/route/tests
- Resume-position tests for last read position
- Embed integration tests beyond helper coverage
- Mobile and accessibility regression coverage
- OAuth callback tests with meaningful provider/callback behavior
- Trust-level settings LiveView tests
- Public-profile suspend/silence interaction tests

## Feature Priority for Remaining Work

### High Priority (User-facing, high value)
1. **Fix compile warnings-as-errors** - Required for reliable verification
2. **Advanced search completion** - User/date/category filters and SearchLive coverage
3. **Email notifications** - Critical for retention
4. **Composer completion** - Preview, drafts, uploads, shortcuts, and UI coverage
5. **Mention/subscriber notification E2E** - Close notification correctness gaps

### Medium Priority (Nice to have)
6. Polls
7. Category watch/mute UI
8. Tag browsing and management UI
9. Activity feed
10. User badges

### Low Priority (Advanced/Enterprise)
11. SSO/SAML
12. Plugin system
13. Analytics dashboard
14. Import/export tools
15. Advanced moderation (IP bans, etc.)

---
**Last Updated**: August 17, 2026
**Purpose**: Feature comparison and roadmap planning
**Status**: Living document
