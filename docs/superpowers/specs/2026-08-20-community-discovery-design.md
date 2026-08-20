# Community discovery polish

## Goal

Make the forum immediately understandable and inviting while preserving its existing routes, data model, and discussion behavior.

## Shared forum shell

- Keep the desktop sidebar, but tighten its hierarchy and make active navigation unmistakable with a soft cyan surface.
- Give mobile users a sticky title bar and accessible drawer controls.
- Keep categories scannable while avoiding a long wall of repeated headings.
- Preserve saved, notifications, search, and account access.

## Discovery header

- Introduce the community with a short, useful statement rather than a generic page title.
- Make search the primary discovery action and route it to the existing forum search page.
- Add stable Latest and Categories tabs so users can switch mental models without returning to the sidebar.
- Keep content counts secondary and omit them when unavailable.

## Category and board presentation

- Group boards inside calm bordered surfaces with generous touch targets.
- Show board purpose first, then latest activity and topic count as supporting metadata.
- Collapse metadata cleanly on mobile instead of squeezing desktop columns.
- Use semantic daisyUI colors and the existing forum color helper.

## Visual direction

- Continue the Tokyo Night day/night themes through semantic tokens.
- Favor cyan, teal, blue, and neutral surfaces; avoid purple-heavy treatment.
- Do not add decorative left borders.
- Use subtle hover and focus transitions with reduced-motion compatibility.

## Verification

- Add LiveView tests for the shared navigation, discovery actions, and category structure using stable DOM IDs.
- Build application assets.
- Run the full Phoenix precommit suite and report any pre-existing strict compiler warnings separately.
