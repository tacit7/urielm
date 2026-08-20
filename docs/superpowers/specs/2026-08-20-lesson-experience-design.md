# Lesson Viewing Experience

## Goal

Make the lesson page feel like the natural continuation of the polished Courses experience: focused video viewing, readable supporting material, clear progression, and a useful course outline.

## Layout

- Use a centered `max-w-7xl` shell with a primary lesson column and sticky desktop course outline.
- Keep the video as the strongest element without allowing it to span an excessively wide display.
- Place lesson identity, voting, section navigation, and content beneath the player in a consistent hierarchy.
- Move previous/next navigation beneath the lesson material so it reads as progression rather than player chrome.

## Course outline

- Keep the existing desktop sidebar and mobile drawer behavior.
- Replace the active lesson's left border with a full-card primary tint and outline.
- Use compact thumbnails, lesson numbers, and an explicit now-playing state.
- Use the project icon component instead of embedded SVGs.

## Supporting content

- Present overview, notes, resources, timestamps, and comments in shared outlined surfaces.
- Preserve the existing desktop tabs, mobile dock, voting, comments, and authentication behavior.
- Improve empty states and comment form styling without changing data behavior.

## Responsive behavior

- Let the player reach the mobile viewport edges while keeping text content on standard gutters.
- Keep lesson title, voting, and course-outline controls usable without horizontal squeezing.
- Stack previous/next cards on narrow screens and preserve the mobile content dock.

## Visual constraints

- Use Tokyo Night cyan, blue, and teal accents with restrained purple.
- Do not add left-border accents.
