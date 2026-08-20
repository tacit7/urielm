# Global navigation polish

## Goal

Create a calmer, more dependable site-wide navigation experience across desktop and mobile without changing the app's route structure.

## Desktop

- Center content inside a shared maximum-width shell instead of stretching controls edge to edge.
- Use compact rounded navigation targets with a cyan active surface and clear hover feedback.
- Retain theme, authentication, and account actions on the right.
- Add a labeled-on-hover search action that routes to the existing community search.
- Apply translucent surface and border treatment once the page scrolls.

## Mobile

- Keep the brand on the left and theme/menu controls on the right.
- Replace the narrow dropdown with a nearly full-width anchored panel.
- Use large touch targets, a clear active route, a dedicated search row, and authentication actions.
- Close the panel after navigation, outside click, or Escape.

## State and accessibility

- Derive active navigation state from `window.location.pathname` after LiveView navigation so persistent shell links do not become stale.
- Expose menu state through `aria-expanded` and `aria-controls`.
- Use the existing `UMIcon` component for all navigation icons.
- Preserve visible focus styles and reduced-motion compatibility.

## Visual direction

- Continue the Tokyo Night day/night themes through semantic daisyUI colors.
- Favor cyan, teal, and neutral surfaces; avoid purple-heavy accents.
- Do not add decorative left borders.

## Verification

- Unit test path-to-navigation mapping.
- Build both Svelte bundles.
- Run the full Phoenix precommit suite.
