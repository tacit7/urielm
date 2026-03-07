# Forum Layout (Discourse-style) Action Plan for Jr Devs

## Goal
Implement a Discourse-like forum shell using **Tailwind CSS + DaisyUI** with:
- Persistent **left sidebar** (desktop) that becomes a **drawer** (mobile)
- **Topic list** main panel (cards now, table-like later)
- Top **navbar** with search, quick filters, and “New Topic”
- Categories we already defined:
  - Start Here
  - Announcements
  - Q&A Help Desk
  - Prompting and Workflows
  - Building with AI
  - Model and Tool Talk
  - Show and Tell
  - Feedback and Ideas
  - Off-topic

This is UI-first; wire to real API later, but structure it so wiring is trivial.

---

## Non-goals (v1)
- Auth flows, moderation tools, trust levels
- Real-time updates, notifications
- Full markdown editor, rich composer
- Full-text search (basic input only)

---

## Tech assumptions
- Tailwind + DaisyUI already installed and configured
- App has routing (React Router, LiveView routes, etc.)
- You can serve mock data from a local module or a simple endpoint

If your stack differs, keep the same component boundaries and CSS classes.

---

## Deliverables
1. **ForumShell** layout component with navbar + sidebar + main content slot
2. **CategoriesSidebar** component
3. **TopicList** component
4. **TopicCard** component (mobile-first)
5. Responsive behavior:
   - `lg:` persistent sidebar
   - `<lg:` drawer sidebar
6. Simple state and routing:
   - `/forum/latest`
   - `/forum/top`
   - `/forum/unread`
   - `/forum/category/:slug`
7. Mock data module + types/interfaces
8. Basic accessibility pass (keyboard, labels, focus)

---

## Milestones

### Milestone 1 (Day 1): Skeleton layout
**Tasks**
- Create `ForumShell` with DaisyUI drawer pattern.
- Add sticky top navbar.
- Add main content wrapper and placeholder.
- Add sidebar placeholder and open/close behavior on mobile.

**Acceptance criteria**
- Sidebar visible by default on `lg+`.
- Sidebar accessible via hamburger button on mobile.
- Main content scrolls; navbar stays sticky.

---

### Milestone 2 (Day 1–2): Categories sidebar
**Tasks**
- Build `CategoriesSidebar` rendering category list from a config object.
- Visual treatment:
  - Active category highlighted
  - Colored dot/badge per category
- Add “Quick actions” buttons in sidebar: Latest, Top, Unread, Bookmarks (Bookmarks can be noop).

**Acceptance criteria**
- Clicking category navigates to `/forum/category/:slug`.
- Active state updates based on current route.
- Sidebar remains usable on mobile drawer and desktop.

---

### Milestone 3 (Day 2): Topic list (mocked)
**Tasks**
- Define topic type:
  - `id, title, excerpt, author, authorAvatarUrl, categorySlug, tags[], repliesCount, viewsCount, lastActivityAt, isSolved`
- Create mock topics array (10–20) with variety (solved/unsolved, different tags).
- Build `TopicList`:
  - Shows list of `TopicCard`s
  - Includes filters row: Latest/Top/Solved/My topics tabs (UI only)
  - Includes toggles: “Only unanswered” + “Show solved” (local filtering)

**Acceptance criteria**
- Topic list renders consistently.
- Filtering works with local state (no API).
- Solved badge appears only when `isSolved`.

---

### Milestone 4 (Day 3): Thread view stub + routing
**Tasks**
- Add `/forum/t/:id` route that renders a placeholder “Thread view (coming soon)” page.
- Make topic titles link to the thread route.
- Keep breadcrumb visible.

**Acceptance criteria**
- Clicking a topic navigates to thread stub.
- Back navigation works.
- Layout stays the same (ForumShell persists).

---

### Milestone 5 (Day 3–4): UX polish and correctness
**Tasks**
- Replace any hard-coded spacing with consistent classes.
- Ensure truncation for long titles (`truncate`, `line-clamp`).
- Improve scannability:
  - Title (primary)
  - Category badge + tags
  - Replies/views (desktop-only)
  - Last activity timestamp
- Add empty states:
  - No topics match filter
  - Category has zero topics

**Acceptance criteria**
- Looks clean at `sm`, `md`, `lg`, `xl`.
- No horizontal scroll.
- Empty states don’t look broken.

---

### Milestone 6 (Day 4–5): A11y baseline
**Tasks**
- Buttons have `aria-label` when icon-only.
- Drawer open/close is keyboard reachable.
- Focus styles visible; no “focus trap” bugs.
- Semantic structure:
  - `header`, `aside`, `main`, `article`

**Acceptance criteria**
- Can navigate sidebar and topic list using keyboard only.
- Screen reader labels exist for icon buttons.

---

## Suggested file structure
Adapt to your framework; this is the shape we want.

```
src/
  forum/
    data/
      categories.ts
      topics.mock.ts
      types.ts
    components/
      ForumShell.tsx
      CategoriesSidebar.tsx
      ForumNavbar.tsx
      TopicList.tsx
      TopicCard.tsx
      FiltersBar.tsx
    pages/
      ForumLatestPage.tsx
      ForumCategoryPage.tsx
      ForumThreadPage.tsx
```

---

## Category config (example)
Use a single source of truth.

```ts
export const categories = [
  { slug: "start-here", name: "Start Here", badge: "badge-primary" },
  { slug: "announcements", name: "Announcements", badge: "badge-secondary" },
  { slug: "qa", name: "Q&A Help Desk", badge: "badge-accent" },
  { slug: "prompting", name: "Prompting and Workflows", badge: "badge-info" },
  { slug: "building", name: "Building with AI", badge: "badge-success" },
  { slug: "models-tools", name: "Model and Tool Talk", badge: "badge-warning" },
  { slug: "show-and-tell", name: "Show and Tell", badge: "badge-neutral" },
  { slug: "feedback", name: "Feedback and Ideas", badge: "badge-error" },
  { slug: "off-topic", name: "Off-topic", badge: "badge-ghost" },
] as const;
```

---

## Code quality expectations
- No inline styles; Tailwind + DaisyUI only
- Components should be dumb; pass props in, don’t fetch inside
- Use `className` utilities only if necessary (avoid heavy abstractions)
- Keep state minimal; filters can be local state for now

---

## Testing (minimum)
- 1–2 component tests for:
  - Sidebar active state for a route
  - Filtering “Only unanswered” removes solved topics
- If no test framework is set up, add a lightweight manual test checklist in the PR.

---

## PR checklist
- [ ] Mobile drawer works
- [ ] Sidebar persistent on desktop
- [ ] Routes exist and don’t 404
- [ ] Topic list renders with mocks
- [ ] Filters toggle works locally
- [ ] No console errors
- [ ] A11y labels on icon buttons
- [ ] Clean spacing, no layout jump

---

## Stretch (v2, after UI lands)
- Table-like topic list on desktop (cards on mobile)
- Real API wiring for topics + categories
- Composer modal (New Topic)
- Full search + results page
- Notifications + user dropdown actions
