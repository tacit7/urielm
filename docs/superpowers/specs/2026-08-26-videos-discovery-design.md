# Videos Discovery Design

## Goal

Add a public `/videos` library that makes published long-form videos and shorts easy to discover without requiring sign-in. The page should match the approved blue-forward Tokyo Night mockup and begin directly with discovery controls rather than a marketing header.

## Information architecture

- `/videos` is the collection page.
- `/videos/:slug` remains the existing detail page.
- `/courses` remains a distinct collection and receives its own navigation state.
- The primary navigation exposes both Videos and Courses.

## Content model

The first matching standard-format video is featured. Remaining standard videos appear in a responsive 16:9 grid. Videos where `format == "short"` appear in a portrait rail. Only records with `published_at` are listed.

The UI uses fields that already exist on `Content.Video`: title, slug, YouTube or TikTok URL, format, author, visibility, description, and publication date. YouTube thumbnails are derived from the provider ID; other or invalid URLs use a branded fallback surface.

Published gated videos remain discoverable. Their cards display Public, Sign in, or Subscriber access labels, while the existing detail-page authorization continues to enforce access.

## Discovery behavior

- `q` performs a case-insensitive title and author search.
- `format` accepts `all`, `standard`, or `short` and defaults safely to `all`.
- Search uses a GET form and filters use ordinary URL links so states are shareable and work without client JavaScript.
- A filtered empty state explains that nothing matched and provides a clear reset.
- A separate zero-content empty state explains that videos are coming soon.

## Responsive design

Desktop uses a split featured card, three-column standard video grid, and five-column shorts rail. Mobile stacks the featured card and turns both collections into horizontal, snap-aligned rails. Cards use the existing daisyUI and `ui-card` surface system, subtle hover motion, and no left-border accents.

## Accessibility and metadata

- Search has a visible icon and accessible label.
- Filter links expose `aria-current`.
- Each collection and card has a stable DOM ID.
- Decorative thumbnails use empty alt text because the linked title supplies the accessible name.
- The page sets title, description, and canonical URL metadata through `ShellLive`.

## Verification

LiveView tests cover public routing, published-only visibility, standard/short grouping, query and format filtering, gated labels, and both empty states. The production asset bundle and `mix precommit` are run before commit.
