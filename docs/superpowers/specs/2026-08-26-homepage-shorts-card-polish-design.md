# Homepage Shorts Card Polish

## Job and audience

Help homepage visitors—especially mobile visitors—recognize Shorts as playable, practical learning content without relying on hover or guessing that the horizontal row continues.

## Approved direction

- Preserve the existing homepage section order, `/videos/:slug` routes, and horizontal browsing model.
- Replace decorative rainbow placeholders with real YouTube thumbnails when available and a restrained Signal Blue tonal fallback when they are not.
- Keep the play control and `Short` label visible at rest on pointer and touch devices.
- Show only metadata already supplied by the product: up to two tags, author, and publish date. Do not invent a runtime because videos do not currently store duration.
- Use a themed thin scrollbar on larger screens and deliberate next-card exposure on mobile so overflow is discoverable.

## Interaction and layout

- Cards use a vertical media composition, a strong bottom scrim for legibility, and a compact metadata stack.
- The entire card remains the link target and retains visible keyboard focus.
- Hover may lift the card and scale the thumbnail slightly, but it must not reveal essential information.
- Empty content keeps the existing plain-language state.

## Boundaries

- Scope is limited to the homepage Shorts section and its focused tests.
- The videos index, video detail page, schema, and database remain unchanged.
- Tokyo Night and Tokyo Day themes use existing daisyUI/Tailwind tokens; violet, rose, cyan, and orange decoration are removed from this section.

## Reference

Approved mockup: `priv/static/mockups/homepage-shorts-card-polish.html`.
