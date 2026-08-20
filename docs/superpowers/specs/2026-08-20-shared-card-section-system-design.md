# Shared Card and Section System

## Goal

Make courses, articles, prompts, comments, and supporting content feel like parts of one product while reducing repeated visual decisions in templates.

## Visual system

- Use one theme-aware card surface: softly translucent `base-200`, a quiet `base-300` border, a 20px default radius, and a restrained shadow.
- Interactive cards use the same 200ms hover behavior: a three-pixel lift, primary-tinted border, and slightly deeper shadow.
- Compact row cards keep the same surface language with a 16px radius and tighter spacing.
- Section headings use a consistent eyebrow, tightly tracked title, muted supporting copy, and predictable bottom spacing.
- Gradients remain reserved for the hero; content cards use solid theme surfaces.

## Scope

Add reusable CSS component classes and adopt them on the homepage course, article, and prompt surfaces; the blog index; and prompt comments. Preserve page-specific layout, color semantics, and data behavior.

## Responsive behavior

Cards retain their existing grids at larger sizes and stack naturally on mobile. Section headers allow actions to wrap below their copy without introducing horizontal overflow.

## Accessibility

Focus-visible behavior remains provided by links and controls. Motion is subtle and disabled for users requesting reduced motion.
