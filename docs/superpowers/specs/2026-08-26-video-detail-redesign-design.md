# Video Detail Redesign

## Scope

Redesign the standard-format `/videos/:slug` experience to match the approved Tokyo Night mockup. Short-format videos keep their existing full-screen viewer. Existing authorization, publishing rules, voting, completion tracking, comments, Markdown rendering, and embeds remain unchanged.

## Layout

- Use a theater-first player inside a centered `max-w-7xl` page rather than an almost full-window embed.
- Add a clear “All videos” return link above the player.
- Put the video title, author/date metadata, completion control, votes, and share action into one balanced header below the player.
- Use one responsive content grid: tabbed content on the left and contextual cards on the right.
- Show creator information, resources, and the next accessible standard video in the sidebar when those records exist.

## Navigation and responsive behavior

- Replace the Svelte underline navigation and the video-specific mobile dock with native LiveView tab buttons.
- Tabs use stable IDs, `aria-current`, and horizontally scroll on small screens.
- The same active section drives desktop and mobile rendering.
- The global application mobile dock remains the only fixed bottom navigation.

## Visual language

- Use daisyUI cards, buttons, badges, and Tokyo theme variables.
- Favor midnight surfaces and primary blue accents; do not introduce purple/violet accents.
- Use subtle borders, radial blue player ambience, rounded surfaces, and restrained hover transitions.
- Keep light-theme compatibility by using semantic theme colors instead of fixed dark text colors outside the player.

## Data and behavior

- Load one next published standard video, excluding the current video and anything the viewer cannot access.
- Derive its thumbnail from its YouTube ID when available.
- Keep the current share hook, vote component, completion events, comment form/tree, and report modal.
- Empty resources, author, comments, and next-video states should disappear cleanly rather than leaving blank cards.

## Verification

LiveView tests cover the redesigned structure, active tabs, responsive single-navigation contract, contextual sidebar cards, related-video access rules, and existing content visibility. Run focused video tests, asset compilation, `mix compile --warnings-as-errors`, `git diff --check`, and `mix precommit` before commit.
