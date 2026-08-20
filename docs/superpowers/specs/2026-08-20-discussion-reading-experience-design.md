# Discussion reading and reply experience

## Goal

Make individual forum discussions easier to read, act on, and reply to across desktop and mobile without changing forum permissions or event behavior.

## Topic presentation

- Use one focused reading column inside the existing forum shell.
- Keep board context and status visible before the topic title.
- Present author, publication date, and view count as supporting metadata.
- Give the original post generous reading space and restrained Tokyo Night surfaces.

## Actions

- Group voting, reply, save, watch, notification, moderation, and reporting actions into a predictable toolbar.
- Show text labels where space permits and retain compact accessible controls on mobile.
- Use cyan and teal active states instead of purple or violet.
- Preserve all existing LiveView events and permission checks.

## Reply composer

- Place the primary reply form directly after the original post.
- Use a LiveView `to_form` assign and the shared input component.
- Give the form a stable ID, clear placeholder, Markdown hint, and explicit submission state.
- Replace the form with a locked status or sign-in prompt when replying is unavailable.

## Reply hierarchy

- Improve reply cards, identity, timestamps, and action grouping in the existing Svelte comment tree.
- Indicate nesting with indentation and progressively softer surfaces.
- Do not use decorative left borders.
- Keep contextual reply and edit composers intact.

## Accessibility and responsive behavior

- Add stable landmark IDs and meaningful labels for LiveView tests.
- Preserve visible keyboard focus states and adequate touch targets.
- Collapse action labels on narrow screens without removing accessible names.
- Keep locked and empty states calm and explicit.

## Verification

- Add LiveView tests for the reading landmarks, reply form, anonymous state, and locked state.
- Run the focused thread and forum suites.
- Build both application asset bundles.
- Run the full Phoenix precommit suite.
