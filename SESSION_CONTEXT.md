# Session Context - urielm.dev

**Last Updated**: December 10, 2025
**Project**: Personal website for urielm.dev
**Stack**: Phoenix 1.8.1 + LiveView 1.1.0 + Svelte 5.18 + live_svelte 0.16.0

---

## Session Updates - December 10, 2025

### Database Setup
- Created new `urielm` database on DigitalOcean managed PostgreSQL
- Updated `.env` to use `urielm` database instead of `defaultdb`
- Ran all 24 migrations fresh
- User: `urielm_app`

### Migrations Added This Session
1. `20251210150400_unique_prompts_url.exs` - Unique index on prompts.url (partial, where url IS NOT NULL)
2. `20251210151400_remove_prompts_tags_array.exs` - Removed `tags` array column from prompts

### Prompt Schema Changes
- Changed `process_status` (string) to `processed` (boolean) to match database
- Updated `lib/urielm/content/prompt.ex`
- Updated `lib/mix/tasks/process_prompts.ex`

### New Files Created
- `lib/urielm_web/live/courses_live.ex` - Courses index page for `/courses` route
- `lib/mix/tasks/prompts.import_vendor_ramonov.ex` - Import prompts from vendor/prompts

### Vendor Prompts
- Cloned `SabrinaRamonov/prompts` to `vendor/prompts/`
- Added README.md with source attribution
- Imported 865 prompts into database

### UI Updates (PR #1 merged)
- Navigation: Home, Blogs, Courses, Prompts
- Home badge links to new blog post
- Dark theme as default
- Fixed duplicate migration versions (20251208 → 20251208120000/1)

### Infrastructure
- SSH key created at `~/.ssh/id_ed25519` for GitHub
- GitHub CLI installed at `~/bin/gh`
- Authenticated as `tacit7`
- Git remote switched from HTTPS to SSH

### PRs
- PR #1: UI updates, dark theme, nav (merged)
- PR #2: Add courses index page and vendor prompts collection

### Running Server
```bash
set -a && source .env && set +a && MIX_ENV=prod mix phx.server
```
Server runs on port 4000, proxied via Caddy to https://urielm.dev

---

## Project Overview

This is a Phoenix LiveView application integrated with Svelte components for building the urielm.dev personal website. The project demonstrates a hybrid architecture where:

- **Phoenix LiveView** manages server-side state, routing, and business logic
- **Svelte** handles rich client-side UI and interactivity
- **live_svelte** bridges the two with server-side rendering and bidirectional communication

## Current State

### Key Files

```
urielm/
├── mix.exs                           # App: :urielm, Module: Urielm
├── .env                              # DATABASE_URL points to urielm db
├── config/
│   └── runtime.exs                   # CA cert path fallback for local/Docker
├── lib/
│   ├── urielm/
│   │   └── content/prompt.ex         # Prompt schema (uses `processed` boolean)
│   ├── urielm_web/
│   │   ├── router.ex                 # Routes including /courses
│   │   └── live/
│   │       ├── courses_live.ex       # Courses index page
│   │       ├── course_live.ex        # Individual course
│   │       └── references_live.ex    # Prompts listing
│   └── mix/tasks/
│       ├── process_prompts.ex        # AI prompt processing
│       └── prompts.import_vendor_ramonov.ex  # Vendor import
├── assets/
│   └── svelte/
│       └── Navbar.svelte             # Nav with Home, Blogs, Courses, Prompts
├── vendor/
│   └── prompts/                      # 865 SabrinaRamonov prompts
└── priv/
    └── repo/migrations/              # 24 migrations total
```

## Database

- **Host**: db-postgresql-sfo2-18861-do-user-4084462-0.l.db.ondigitalocean.com:25060
- **Database**: `urielm` (not defaultdb)
- **User**: `urielm_app`
- **Tables**: prompts (865 rows), courses, lessons, users, posts, etc.

### Connect to DB
```bash
# Use credentials from .env file
psql "postgresql://urielm_app:<PASSWORD>@db-postgresql-sfo2-18861-do-user-4084462-0.l.db.ondigitalocean.com:25060/urielm?sslmode=require"
```

## Development Workflow

### Starting the Server
```bash
cd /home/claude-watch/claude-home-base/urielm
set -a && source .env && set +a && MIX_ENV=prod mix phx.server
```

### Run Migrations
```bash
set -a && source .env && set +a && MIX_ENV=prod mix ecto.migrate
```

### Import Prompts from Vendor
```bash
set -a && source .env && set +a && MIX_ENV=prod mix prompts.import_vendor_ramonov
```

## Next Steps / TODO

### Immediate
- [x] Update prompt schema to remove tags field (migration done, schema updated)
- [ ] Add seed data for blog posts and courses
- [ ] Commit and push remaining changes

### Features
- [ ] Process prompts with AI categorization
- [ ] Add search to prompts page
- [ ] Course content and lessons

---

**Server Status**: Running on port 4000
**Database**: urielm on DO managed PostgreSQL
