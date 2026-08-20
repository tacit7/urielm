# Courses Index and Detail Experience

## Goal

Bring Courses into the shared page, card, and Tokyo theme system while preserving its image-led learning identity.

## Courses index

- Use the standard centered page shell, eyebrow/title/copy hierarchy, and mobile gutters.
- Replace oversized decorative course numbers with compact outlined badges.
- Keep the first course featured, but reduce its height and use a stronger neutral overlay for reliable text contrast.
- Present lesson counts as readable metadata and keep primary actions visible without requiring hover.
- Use the shared full-outline empty surface when no courses exist. No left-border accents.

## Course detail

- Reduce the cinematic hero height, constrain its content to the shared shell, and retain the thumbnail as atmosphere rather than letting it dominate navigation.
- Use imported icon components for back, play, external-link, and arrow icons.
- Place the description and lesson collection inside the same centered shell.
- Render lessons as compact interactive cards with stable IDs, explicit lesson numbering, readable notes, and an always-visible navigation arrow.
- Keep description expansion and existing routes/data behavior unchanged.

## Responsive behavior

- Stack the page header and course count on narrow screens.
- Keep featured/index cards useful at shorter mobile heights.
- Allow lesson thumbnails to shrink without squeezing titles or creating horizontal overflow.
