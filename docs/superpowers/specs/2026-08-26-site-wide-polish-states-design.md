# Site-wide polish states

## Goal

Give loading, empty, and recoverable-error moments one recognizable visual and accessibility language across Urielm without changing the existing Tokyo Night-inspired identity.

## Design direction

- Add reusable HEEx components for empty, error, and skeleton states instead of copying page-specific markup.
- Use calm centered cards, blue semantic accents, Heroicons, concise guidance, and optional action slots.
- Preserve existing page hierarchy and copy where it is already strong; this is refinement, not a redesign.
- Provide stable DOM IDs, appropriate ARIA roles, `aria-busy`, live-region support, keyboard-visible focus, and reduced-motion-safe shimmer.
- Keep mobile actions at least 44px tall and retain the existing global mobile dock as the only bottom navigation.
- Do not add decorative left borders.

## First adoption set

Apply the shared empty-state component to Blog, Courses, Forum categories, Forum Search, and Saved Threads. Video files are deliberately excluded from this pass because tag work is active there.

## Validation

Add component-level rendering tests and page-level selector assertions, build assets, run the relevant LiveView suites, run the Impeccable detector once, then run `mix precommit`.
