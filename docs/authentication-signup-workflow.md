# Authentication & Signup Workflow

**Last Updated:** 2025-12-20
**Status:** Implemented (Email verification backend pending)
**Recent Updates:** Added handle/display_name to email/password signup (2025-12-20)

---

## Overview

This document describes the signup, authentication, and user onboarding flow for urielm.dev.

**System has two different signup flows:**
1. **Email/Password**: Requires username + display_name upfront (NEW 2025-12-20)
2. **OAuth**: Uses lazy username collection (collects only when needed)

---

## Recent Changes (2025-12-20)

### Email/Password Signup Updated
- **Before:** Signup form only had email/password
- **After:** Now requires 4 fields: email, password, username, display_name
- **Endpoint:** `POST /auth/signup` (same endpoint, updated to accept new fields)
- **Frontend:** `AuthModal.svelte` updated with handle availability checking
- **Validation:** Real-time username availability via `/api/check-handle` (debounced 300ms)

### Two-Field User Identity
- **Handle (username):** 3-20 chars, lowercase alphanumeric + dashes/underscores, unique, URL-safe
  - Regex: `^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$`
  - Case-insensitive lookup (e.g., "JohnDoe" finds "johndoe")
  - Auto-normalized: lowercase + trim whitespace

- **Display Name:** Flexible human-friendly name shown on posts
  - Allows spaces, special characters, emojis
  - Not unique (multiple users can have same name)
  - Auto-normalized: trim whitespace only

### Database
- Added `display_name` column to users table
- Migration: `priv/repo/migrations/20251217200853_add_display_name_to_users.exs`

### Test Coverage
- **155+ new tests** added covering:
  - 30 accounts tests
  - 34 auth controller tests
  - 40 content sanitizer tests
  - 39 chat tests
  - 42 learning tests

---

## Signup Flow

### Entry Point: `/signup`

Clean, focused page with two options:
- **Continue with Google** (primary) → OAuth flow
- **Continue with email** (secondary) → Email/password flow

**Files:**
- `lib/urielm_web/live/signup_live.ex`
- Uses `Layouts.auth` (minimal layout, no navbar)

---

## Google OAuth Flow

### Step 1: User clicks "Continue with Google"
- Redirects to `/auth/google`
- Ueberauth handles OAuth with Google

### Step 2: OAuth Callback (`/auth/google/callback`)
**File:** `lib/urielm_web/controllers/auth_controller.ex:17-43`

**Process:**
1. Receives Google auth data (email, name, avatar)
2. Calls `Accounts.find_or_create_user(auth)`
3. Checks if `OAuthIdentity` exists for this Google account
4. **If new user:**
   - Creates `User` record with:
     - `email` from Google
     - `name` from Google profile
     - `avatar_url` from Google
     - `email_verified: true` (Google already verified)
     - `username: nil` (collected later if needed)
   - Creates `OAuthIdentity` linking user to Google provider
5. **If returning user:** retrieves existing user
6. Sets `user_id` in session

### Step 3: Smart Redirect Logic
**Function:** `auth_controller.ex:needs_handle_for_action?/1`

- Gets `return_to` from session (where user came from) or defaults to "/"
- Checks if destination path requires username:
  - Paths containing `/new`, `/post`, or `/comment` require username
- **If needs username AND user.username is nil:**
  - Stores `pending_redirect` in session
  - Redirects to `/signup/set-handle`
- **Otherwise:** redirects to intended destination

**Key behavior:**
- Email already verified (Google verified it)
- No extra verification step
- Username collected only when needed
- Browsing/consuming works immediately

---

## Email/Password Flow

### Step 1: Email Signup (`/auth/signup`)
**File:** `lib/urielm_web/controllers/auth_controller.ex:63-92`

**Form fields (collected immediately):**
- Email (required) - validated email format
- Password (required, min 8 chars)
- Username/Handle (required) - 3-20 lowercase alphanumeric + dashes/underscores
- Display Name (required) - flexible name field for posts/comments

**New two-field user identity approach:**
Users provide both fields during initial signup, unlike OAuth flow which collects them lazily.

### Step 2: Account Creation
**Function:** `Accounts.register_user/1`
**Changeset:** `User.registration_changeset/2`
**Controller normalization:** `auth_controller.ex:69-74`

**Process:**
1. Normalizes username: lowercase + trim whitespace
2. Normalizes display_name: trim whitespace
3. Validates email format and uniqueness
4. Validates password length (min 8 chars)
5. Validates handle format: `^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$`
6. Validates handle uniqueness
7. Hashes password with Bcrypt
8. **Sets `email_verified: true`** (unlike OAuth which requires verification)
9. Creates user record with username and display_name populated
10. Sets `user_id` in session
11. Returns JSON response: `{success: true}`

### Step 3: Post-Signup Redirect
**Route:** `GET /auth/post-signup/:user_id`
**Function:** `auth_controller.ex:post_signup/2`

**Logic:**
1. Sets `user_id` in session
2. Gets `return_to` from session or defaults to "/"
3. **If email not verified:**
   - Stores `pending_redirect` in session
   - Redirects to `/signup/verify-email`
4. **Else if needs username for action AND username is nil:**
   - Stores `pending_redirect` in session
   - Redirects to `/signup/set-handle`
5. **Otherwise:** redirects to intended destination

---

## Email Verification

### Current State: UI Complete, Backend TODO

**Page:** `/signup/verify-email`
**File:** `lib/urielm_web/live/verify_email_live.ex`

**UI Features:**
- Shows user's email address
- Warning: "You can browse the site, but you'll need to verify your email before posting or commenting"
- Resend button with 60-second cooldown
- "Continue browsing" link (returns to `pending_redirect`)

**TODO - Backend Implementation:**
- [ ] Generate verification tokens (UUID or signed token)
- [ ] Store tokens in database with expiration
- [ ] Send verification emails (need Swoosh/mailer setup)
- [ ] Create verification endpoint: `GET /auth/verify/:token`
- [ ] Update user.email_verified on successful verification
- [ ] Handle expired tokens

**Blocking behavior:**
- Users can browse immediately
- Posting/commenting blocked until verified (checked in handle_event)

---

## Username & Display Name Collection

### When Collected: Lazy (Just-in-Time)

**Triggers:**
- User tries to post a new thread (checked in `NewThreadLive.mount/3`)
- User tries to comment (checked in `ThreadLive.handle_event/3` for "create_comment")
- User navigates to action requiring username after OAuth signup

**Page:** `/signup/set-handle`
**File:** `lib/urielm_web/live/set_handle_live.ex`

### Form Fields

#### 1. Username (Required)
- **Label:** "Username"
- **Prefix:** @ symbol
- **Validation:**
  - 3-20 characters
  - Lowercase only
  - Letters, numbers, dashes, underscores
  - No leading/trailing dashes
  - Pattern: `^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$`
- **Real-time availability check (NEW - now in email signup too):**
  - API: `GET /api/check-handle?username=:username`
  - Debounced 300ms
  - Frontend normalization: auto-lowercase, trim, remove invalid chars
  - Shows ✓ (available), ✗ (taken), or format error
  - Case-insensitive lookup (handles "JohnDoe" lookup as "johndoe")
- **Prefill logic:**
  - Extracts from email: `john.doe@gmail.com` → `johndoe`
  - Removes invalid characters
  - Truncates to 20 chars

#### 2. Display Name (Required - NEW)
- **Label:** "Display name"
- **Validation:** Flexible, allows letters, numbers, spaces, special characters (emojis, dashes, apostrophes, etc.)
- **No length restrictions** (uses content sanitization for safety)
- **Uniqueness:** Not unique (multiple users can have same display name)
- **Normalization:** Trim whitespace only (no lowercasing or other transforms)

**In email/password signup:**
- Required field during initial signup
- User explicitly provides their display name
- Examples: "John O'Brien-Smith 🚀", "Alice Smith", "Developer", etc.

**In OAuth signup (set-handle page):**
- Google users: prefill with `user.name` from OAuth profile
- Email users: humanizes username (`john_doe` → `John Doe`)
- If blank: defaults to username

### Submit Behavior

**For email/password signup:**
- Both fields already validated and submitted together in single `/auth/signup` POST
- If validation fails, returns 422 Unprocessable Entity with error details
- On success: Sets session `user_id` and returns `{success: true}`
- No post-submit redirect needed (frontend handles navigation)

**For OAuth set-handle page:**
**Function:** `set_handle_live.ex:handle_event("submit")`

```elixir
# If display_name is blank, set it to username
final_display_name = if display_name == "", do: username, else: display_name

Accounts.update_user(user, %{username: username, display_name: final_display_name})
```

After successful update:
- Redirects to `pending_redirect` (stored in session)
- Or defaults to "/"

---

## Blocking Logic

### Posting Threads
**File:** `lib/urielm_web/live/new_thread_live.ex:10-27`

```elixir
def mount(%{"board_slug" => slug}, _session, socket) do
  user = socket.assigns.current_user

  if is_nil(user.username) do
    {:ok, socket
     |> put_flash(:info, "Please set a username before creating a thread")
     |> redirect(to: ~p"/signup/set-handle")}
  else
    # Allow posting
  end
end
```

### Commenting
**File:** `lib/urielm_web/live/thread_live.ex:44-75`

```elixir
def handle_event("create_comment", %{"body" => body}, socket) do
  cond do
    is_nil(user) ->
      {:noreply, put_flash(socket, :error, "Sign in to comment")}

    is_nil(user.username) ->
      {:noreply, socket
       |> put_flash(:info, "Please set a username before commenting")
       |> redirect(to: ~p"/signup/set-handle")}

    true ->
      # Allow commenting
  end
end
```

**Username is the only hard gate** - email verification and display_name are handled separately.

---

## Session Management

### Redirect Preservation

**How it works:**
1. Unauthenticated user visits protected route (e.g., `/forum/b/general/new`)
2. `UserAuth.on_mount(:ensure_authenticated)` catches it
3. Redirects to `/signup`
4. OAuth/email signup completes
5. `post_signup` or OAuth callback checks `return_to` from session
6. If action needs username → show handle modal first
7. Finally redirects to original destination

**Session keys used:**
- `user_id` - authenticated user ID
- `return_to` - path user was trying to access
- `pending_redirect` - stored during verification/handle collection flows

---

## Database Schema

### Users Table

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  name VARCHAR,                    -- From OAuth, may be null
  username VARCHAR UNIQUE,         -- Required for email/password, null for OAuth initially
  display_name VARCHAR NOT NULL,   -- Required for both email and OAuth (set during signup/handle collection)
  avatar_url VARCHAR,
  email_verified BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  is_admin BOOLEAN DEFAULT false,
  password_hash VARCHAR,           -- Only for email/password signups
  trust_level INTEGER DEFAULT 0,
  trust_level_locked BOOLEAN DEFAULT false,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**Schema changes (2025-12-20):**
- Added `display_name` column as NOT NULL
- Updated migration: `priv/repo/migrations/20251217200853_add_display_name_to_users.exs`

### OAuth Identities Table

```sql
CREATE TABLE oauth_identities (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  provider VARCHAR NOT NULL,       -- 'google', 'twitter', 'facebook'
  provider_uid VARCHAR NOT NULL,   -- Provider's user ID
  provider_token TEXT,             -- OAuth access token
  raw_info JSONB,                  -- Raw provider user info
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE(provider, provider_uid)
);
```

---

## Routes

### LiveView Routes

```elixir
# Public (no auth)
live "/signup", SignupLive
live "/signup/email", SignupEmailLive

# Authenticated (requires login)
live "/signup/verify-email", VerifyEmailLive
live "/signup/set-handle", SetHandleLive
```

### Controller Routes

```elixir
# OAuth
get "/:provider", AuthController, :request
get "/:provider/callback", AuthController, :callback
post "/:provider/callback", AuthController, :callback

# Email/Password (NEW - now accepts username and display_name in signup)
post "/signup", AuthController, :signup              # Now requires email, password, username, display_name
post "/signin", AuthController, :signin

# Post-signup helper
get "/post-signup/:user_id", AuthController, :post_signup

# Utility
get "/api/check-handle", AuthController, :check_handle   # Real-time handle availability check
delete "/logout", AuthController, :delete
```

---

## Key Functions

### Accounts Context (`lib/urielm/accounts.ex`)

```elixir
# New: Email/password registration (NEW - now requires username + display_name upfront)
register_user(attrs) -> {:ok, user} | {:error, changeset}
# attrs: %{email, password, username, display_name}

# OAuth user lookup/creation
find_or_create_user(ueberauth_auth) -> {:ok, user} | {:error, reason}

# Authentication
authenticate_user(email, password) -> {:ok, user} | {:error, :invalid_credentials}

# Profile updates
update_user(user, attrs) -> {:ok, user} | {:error, changeset}

# Lookups
get_user_by_username(username) -> user | nil  # Case-insensitive lookup
get_user_by_email(email) -> user | nil
get_user(id) -> user | nil
```

### User Changesets (`lib/urielm/accounts/user.ex`)

```elixir
# Standard changeset (used for profile updates, optional fields)
changeset(user, attrs)

# Email/password registration (NEW - requires email, password, username, display_name)
registration_changeset(user, attrs)
# Validates:
# - email format and uniqueness
# - password length (min 8 chars)
# - username format: ^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$
# - username uniqueness
# - display_name presence

# Validation helper
validate_handle(changeset)  # Validates username format with regex
```

---

## Theme Updates

### Renamed: tokyo-night → midnight

**Files changed:**
- `assets/css/app.css` - theme definition
- `lib/urielm_web/components/layouts/root.html.heex` - default theme
- `lib/urielm_web/components/layouts.ex` - theme_toggle button
- `assets/svelte/ThemeSelector.svelte` - dropdown selector
- `lib/urielm_web/live/themes_live.ex` - settings page
- `assets/js/app.js` - migration code

**Color correction:**
- Changed base-100: `#1A1B27` → `#111827` (Tailwind gray-900)
- Fixes color drift issue (green channel was +8 units off)

**Migration:**
- Automatically converts `dark` and `tokyo-night` to `midnight` on page load
- Stored in localStorage as `phx:theme`

### GitHub Light Theme
Updated with official GitHub Primer colors:
- Background: `#ffffff`
- Muted surfaces: `#f6f8fa`
- Primary: `#0969da` (blue)
- Success: `#1f883d` (green)
- Error: `#d1242f` (red)
- Warning: `#9a6700` (orange)
- Alert text: `#ffffff` (white for all alerts)

---

## Pending Implementation

### Email Verification Backend
**Status:** UI complete, backend TODO

**Needs:**
1. **Token system:**
   - Generate verification tokens (UUID or Phoenix.Token)
   - Store in database with expiration (24-48 hours)
   - Migration: `create table(:email_verification_tokens)`
2. **Email sending:**
   - Configure Swoosh mailer
   - Create email template with verification link
   - Send on signup and resend request
3. **Verification endpoint:**
   - `GET /auth/verify/:token`
   - Validate token, check expiration
   - Update `user.email_verified = true`
   - Redirect to intended destination
4. **Wire up resend:**
   - `VerifyEmailLive.handle_event("resend")` currently just shows cooldown
   - Should generate new token and send email

### Account Linking/Merging
**Status:** Not implemented

**Scenario:** User signs up with Google, later tries email/password with same email (or vice versa).

**Desired behavior:**
- Detect same email across providers
- Offer to link accounts or show helpful error
- Allow users to link Google account to existing password account in settings
- Prevent duplicate accounts for same email

**Implementation approach:**
1. On email signup, check if email exists with OAuth identity
2. On OAuth callback, check if email exists with password_hash
3. Offer account linking or merge flow
4. Settings page: "Link Google Account" / "Set Password" options

---

## Design Decisions

### Why Lazy Username Collection?

**Rationale:**
- Reduces signup friction
- Many users just want to browse/consume
- Only active participants (posters/commenters) need handles
- Follows "progressive disclosure" UX pattern

**Trade-offs:**
- More complex flow (multiple gates)
- Users might not understand why handle is asked for later
- Needs clear messaging ("Please set a username before posting")

### Why Email NOT Auto-Verified?

**Old behavior:** Email/password signups auto-verified email (insecure)
**New behavior:** Requires verification before posting/commenting

**Rationale:**
- Prevents spam accounts
- Ensures valid email for notifications
- Consistent with Google OAuth (already verified by provider)

**Implementation:**
- `User.email_only_changeset` sets `email_verified: false`
- `User.registration_changeset` sets `email_verified: true` (legacy behavior, still requires username upfront)

### Display Name Strategy

**Optional field with smart defaults:**
- Google users: use `name` from OAuth profile
- Email users: humanize username (`john_doe` → `John Doe`)
- If blank: defaults to username

**Validation:**
- 2-50 characters
- Letters, numbers, spaces, basic punctuation allowed
- Not unique (multiple users can have same display name)

---

## Files Modified/Created

### New Files
- `lib/urielm_web/live/signup_live.ex` - Entry page
- `lib/urielm_web/live/signup_email_live.ex` - Email signup
- `lib/urielm_web/live/verify_email_live.ex` - Verification reminder
- `lib/urielm_web/live/set_handle_live.ex` - Username collection modal

### Modified Files
- `lib/urielm_web/router.ex` - Added signup routes
- `lib/urielm_web/controllers/auth_controller.ex` - Updated OAuth callback, added post_signup
- `lib/urielm/accounts.ex` - Added register_user_email_only
- `lib/urielm/accounts/user.ex` - Added email_only_changeset, validate_display_name
- `lib/urielm_web/components/layouts.ex` - Added Layouts.auth
- `lib/urielm_web/user_auth.ex` - Redirect to /signup instead of /signin
- `lib/urielm_web/live/new_thread_live.ex` - Check username before posting
- `lib/urielm_web/live/thread_live.ex` - Check username before commenting
- `assets/svelte/Navbar.svelte` - Removed AuthModal, link to /signup

---

## Testing Checklist

### Email/Password Signup (NEW)
- [x] Email signup requires all 4 fields: email, password, username, display_name
- [x] Username must be 3-20 chars, lowercase, alphanumeric + dash/underscore
- [x] Real-time availability check works (debounced 300ms)
- [x] Display name accepts spaces, special characters, emojis
- [x] Normalization: username → lowercase + trim, display_name → trim only
- [x] Case-insensitive username lookup (JohnDoe → johndoe)
- [x] Errors return 422 with descriptive error messages
- [x] Success sets session user_id and returns {success: true}
- [x] Test coverage: 155+ new tests added

### OAuth Signup (existing flow)
- [ ] Google OAuth signup → browse without username → try to post → prompted for username
- [ ] Google OAuth signup → going to /new → prompted for username → redirected back
- [ ] Display name prefills correctly (Google name vs humanized username)
- [ ] Display name defaults to username if left blank

### Other Existing Tests
- [ ] Email verification reminder → can browse → blocked from posting until verified (TODO backend)
- [ ] Redirect preservation works across flows
- [ ] Theme migration: dark/tokyo-night → midnight
- [ ] GitHub Light theme displays correctly

---

## Future Enhancements

### Phase 1 (Critical)
- [ ] Email verification backend
- [ ] Account linking for same email across providers
- [ ] Password reset flow (currently only available in settings)

### Phase 2 (Nice to Have)
- [ ] Social login: Twitter, Facebook, GitHub
- [ ] Two-factor authentication (TOTP/SMS)
- [ ] Magic link signin (passwordless)
- [ ] Username change with alias/redirect support
- [ ] Profile picture upload (currently OAuth only)
- [ ] Email notification preferences

### Phase 3 (Advanced)
- [ ] SSO/SAML for enterprise
- [ ] Rate limiting on auth endpoints
- [ ] Suspicious login detection
- [ ] Account recovery flows
- [ ] Security audit logs

---

## Common Gotchas

### 1. Account Duplication
**Problem:** User signs up with Google, later tries email+password with same email.
**Current behavior:** Creates second account (bug).
**Fix needed:** Account linking/merging logic.

### 2. Missing Display Name
**Problem:** Email users don't get display_name on initial signup.
**Solution:** Auto-set to username in `set_handle_live.ex:179`.

### 3. Email Verification Loop
**Problem:** User verifies email but still sees verification page.
**Check:** Ensure `mount/3` in `verify_email_live.ex` redirects if `email_verified: true`.

### 4. Username Conflicts
**Problem:** Suggested username already taken.
**Solution:** Real-time availability check with visual feedback. No auto-generated alternatives yet.

### 5. Redirect Loss
**Problem:** User's intended destination lost during multi-step flow.
**Solution:** `pending_redirect` stored in session, passed through verification/handle gates.

---

## API Reference

### Email/Password Signup (NEW)
```
POST /auth/signup
Content-Type: application/json
```

**Request body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "username": "john_doe",
  "displayName": "John Doe"
}
```

**Validation notes:**
- Controller normalizes: username → lowercase + trim, displayName → trim
- Server validates: email format, password length, username format/uniqueness

**Success response (200):**
```json
{
  "success": true
}
```

**Error response (422):**
```json
{
  "error": "email: has already been taken; username: must be 3-20 characters"
}
```

### Check Username Availability
```
GET /api/check-handle?username=:username
```

**Query params:**
- `username` - username to check (normalization handled by server)

**Response:**
```json
{
  "available": true
}
```

**Notes:**
- Server normalizes input: lowercase + trim
- Case-insensitive lookup (handles "JohnDoe" as "johndoe")
- Returns 200 regardless of result

### Verification Endpoint (TODO)
```
GET /auth/verify/:token
```

**Behavior:**
- Validates token
- Updates user.email_verified
- Redirects to home or pending_redirect

---

## Environment Variables

**TODO:** Add when email verification is implemented

```env
# Email configuration (Swoosh)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=noreply@urielm.dev
```

---

## Related Documentation

- `AGENTS.md` - Phoenix development guidelines
- `CLAUDE.md` - Project-specific instructions
- `docs/svelte-phoenix-integration.md` - Svelte/LiveView integration
- `README.md` - General setup instructions
