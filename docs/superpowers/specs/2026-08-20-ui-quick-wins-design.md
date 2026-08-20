# UI Quick Wins Design

## Goal

Improve the perceived quality and usability of the public homepage and prompt library without changing their data contracts or navigation architecture.

## Homepage

- Reduce the hero height and decorative motion so the primary message appears sooner.
- Establish a small eyebrow, a more direct headline, and one dominant CTA.
- Retain prompt discovery as a secondary action.
- Replace the three overlapping decorative cards with one featured-learning card backed by the first available course, with a designed fallback when no course exists.
- Retain the existing statistics while reducing their visual weight.

## Prompt library

- Use the same eyebrow/title/description hierarchy as the homepage.
- Combine search and category selection into a responsive toolbar.
- Surface four frequently useful categories as quick-filter buttons and expose the full category list through a select input.
- Keep the existing `search` and `filter_changed` events, streams, and drawer behavior. Category changes update the nested LiveView in place; direct category query parameters remain supported on initial navigation.
- Give cards a consistent border, radius, spacing, category label, and subtle lift interaction.

## Accessibility and responsive behavior

- Give the hero and prompt toolbar stable DOM IDs for LiveView tests.
- Keep all filters keyboard accessible using native buttons/selects.
- Keep essential controls visible on touch devices.
- Respect reduced-motion preferences by using `motion-safe` animation variants.

## Non-goals

- No new dependencies, schemas, queries, routes, or JavaScript hooks.
- No global forum redesign in this pass.
- No changes to authentication or prompt drawer actions.

## Reference

The static reference is `priv/static/mockups/ui-quick-wins.html`.
