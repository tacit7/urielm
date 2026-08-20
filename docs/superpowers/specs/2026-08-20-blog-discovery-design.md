# Blog discovery polish

## Goal

Make the blog index feel editorial and easy to scan while preserving the existing article-reading experience.

## Content hierarchy

1. A compact introduction establishes the blog's subject matter.
2. The newest published post receives a single featured treatment.
3. Remaining posts appear in a responsive two-column archive.
4. The empty state explains what will appear and offers a useful route back home.

## Visual direction

- Use the existing Tokyo Night theme tokens with restrained cyan and teal accents.
- Avoid purple-heavy treatments and all decorative left borders.
- Favor subtle surface contrast, soft borders, rounded corners, and small hover movement.
- Generate a visual treatment with CSS and the existing icon system when a post has no hero image; use uploaded hero imagery when present.

## Responsive behavior

- Featured content uses a text-and-image split on wide screens and stacks on mobile.
- Archive cards collapse from two columns to one.
- Touch targets cover the full card, while visible title links remain accessible.

## Verification

- Stable DOM IDs identify the index, featured post, archive, cards, and empty state.
- LiveView tests cover featured/archive separation and the single-post case.
- The article detail branch must retain its existing tests and behavior.
