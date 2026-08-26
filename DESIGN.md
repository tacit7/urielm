---
name: Urielm
description: A calm, practical learning workspace for developers and creators building with AI.
colors:
  midnight-canvas: "#1a1b26"
  workshop-surface: "#24283b"
  midnight-border: "#3b4261"
  night-text: "#c0caf5"
  signal-blue: "#7aa2f7"
  deep-blue: "#6b82bd"
  cool-teal: "#73daca"
  midnight-neutral: "#414868"
  success-green: "#9ece6a"
  warning-amber: "#e0af68"
  error-rose: "#f7768e"
  day-canvas: "#e6e7ed"
  day-surface: "#dcdde3"
  day-border: "#c4c8da"
  day-text: "#2e3c64"
  daylight-blue: "#2e7de9"
  day-deep-blue: "#304b80"
  day-teal: "#007c79"
typography:
  display:
    fontFamily: "ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2rem, 4vw, 3rem)"
    fontWeight: 750
    lineHeight: 1.08
    letterSpacing: "-0.035em"
  title:
    fontFamily: "ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 750
    lineHeight: 1.5
    letterSpacing: "-0.02em"
  body:
    fontFamily: "ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.7
  label:
    fontFamily: "ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 700
    lineHeight: 1.333
    letterSpacing: "0.14em"
rounded:
  code: "0.375rem"
  control: "0.75rem"
  compact: "1rem"
  surface: "1.25rem"
  pill: "9999px"
spacing:
  xs: "0.5rem"
  sm: "0.75rem"
  md: "1rem"
  lg: "1.5rem"
  xl: "2rem"
  section-gap: "2.5rem"
components:
  button-primary:
    backgroundColor: "{colors.signal-blue}"
    textColor: "{colors.midnight-canvas}"
    rounded: "{rounded.pill}"
    padding: "0.625rem 1.25rem"
    height: "2.75rem"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.night-text}"
    rounded: "{rounded.control}"
    padding: "0.625rem"
    height: "2.75rem"
  card:
    backgroundColor: "{colors.workshop-surface}"
    textColor: "{colors.night-text}"
    rounded: "{rounded.surface}"
    padding: "1.5rem"
  input:
    backgroundColor: "{colors.midnight-canvas}"
    textColor: "{colors.night-text}"
    rounded: "{rounded.control}"
    padding: "0.625rem 0.875rem"
    height: "2.75rem"
---

# Design System: Urielm

## Overview

**Creative North Star: "The Midnight Workshop"**

Urielm should feel like a focused workspace that happens to be open late: calm enough for sustained learning, technical without becoming sterile, and confident without visual bravado. Cool layered surfaces organize the interface while clear typography and restrained blue signals keep attention on the next useful action.

The system is practical rather than theatrical. Familiar daisyUI controls provide predictable behavior, while deliberate spacing, rounded geometry, clear focus treatment, and small responsive transitions add craft. Avoid neon cyberpunk styling, excessive violet, decorative noise, and effects that compete with instructional content.

**Key Characteristics:**

- Cool Tokyo Night and Tokyo Day surfaces with strong text contrast.
- Signal blue as the dominant interactive color and teal as a supporting accent.
- Rounded, comfortably sized controls with compact developer-oriented information density.
- Tonal layering first, soft elevation only where interaction or floating context warrants it.
- Direct hierarchy, semantic structure, and visible keyboard focus throughout.

## Colors

The palette pairs ink-like navy surfaces with clear blue interaction cues; the light companion retains the same cool character without becoming stark white.

### Primary

- **Signal Blue** (`#7aa2f7`): Primary dark-theme actions, active navigation, links, focus outlines, and selected states.
- **Daylight Blue** (`#2e7de9`): Light-theme counterpart for the same primary roles.

### Secondary

- **Deep Blue** (`#6b82bd`): Secondary emphasis and informational states in Tokyo Night.
- **Day Deep Blue** (`#304b80`): Secondary emphasis and informational states in Tokyo Day.

### Tertiary

- **Cool Teal** (`#73daca`): Supporting dark-theme accent used sparingly for tertiary emphasis.
- **Day Teal** (`#007c79`): Accessible light-theme counterpart.

### Neutral

- **Midnight Canvas** (`#1a1b26`): Primary Tokyo Night page background.
- **Workshop Surface** (`#24283b`): Raised or grouped dark-theme surface.
- **Midnight Border** (`#3b4261`): Dark-theme dividers, outlines, and stronger surface separation.
- **Night Text** (`#c0caf5`): Primary content on dark surfaces; opacity variants create secondary text.
- **Day Canvas** (`#e6e7ed`): Primary Tokyo Day page background.
- **Day Surface** (`#dcdde3`): Raised or grouped light-theme surface.
- **Day Border** (`#c4c8da`): Light-theme dividers and outlines.
- **Day Text** (`#2e3c64`): Primary content on light surfaces; opacity variants create secondary text.

### Named Rules

**The Blue Leads Rule.** Blue leads; teal supports. Violet never dominates.

**The Semantic Color Rule.** Reserve green, amber, and rose for success, warning, and error meaning instead of decoration.

## Typography

**Display Font:** system sans (`ui-sans-serif, system-ui, sans-serif`)
**Body Font:** system sans (`ui-sans-serif, system-ui, sans-serif`)
**Label/Mono Font:** native monospace stack for code, counts, timestamps, and compact technical metadata

**Character:** The typography is direct and highly legible, using weight, compact tracking, and measured scale rather than decorative typefaces. Monospace appears as a functional signal for code and technical metadata, never as a blanket aesthetic.

### Hierarchy

- **Display** (750, `clamp(2rem, 4vw, 3rem)`, 1.08): Section-leading statements with tight `-0.035em` tracking.
- **Headline** (700, `1.75rem`, 1.25): Long-form and major content headings.
- **Title** (750, `1.125rem`, 1.5): Card, state, and compact page titles with `-0.02em` tracking.
- **Body** (400, `1rem`, 1.7): General interface copy; long-form blog content increases to `1.0625rem`–`1.125rem` with 1.82 line-height.
- **Label** (700, `0.75rem`, `0.14em`, uppercase): Sparse eyebrow and grouping labels.

### Named Rules

**The Useful Type Rule.** Use hierarchy to clarify reading order; do not introduce ornamental fonts or uppercase labels where plain language reads faster.

## Layout

Primary content sits inside a fluid shell capped at `80rem`, with `1.5rem` side padding and section spacing of `clamp(4rem, 8vw, 6rem)`. Section headers pair a title block with an optional action, then collapse into a vertical stack below `640px`. A `44rem` centered header width and `42rem` copy width keep explanatory text readable.

The global navigation uses a `4.25rem` fixed header, a persistent mobile bottom dock, and responsive ownership of actions so controls are not duplicated unnecessarily. Content grids should collapse cleanly on narrow screens; touch targets should remain at least `2.75rem` high, with primary navigation targets reaching `2.75rem`–`3rem`.

Spacing follows a practical `0.5rem`, `0.75rem`, `1rem`, `1.5rem`, `2rem`, and `2.5rem` rhythm. Dense forum and metadata views may tighten the rhythm while preserving clear grouping and touch-safe actions.

## Elevation & Depth

The system is layered and restrained. Tonal shifts between Canvas, Surface, and Border establish most hierarchy. Soft ambient shadows identify floating menus and interactive cards; elevation is not a default decoration for every container.

### Shadow Vocabulary

- **Card Rest** (`0 12px 32px color-mix(in oklch, var(--color-base-content) 8%, transparent)`): Quiet depth for substantial content cards.
- **Card Hover** (`0 18px 42px color-mix(in oklch, var(--color-base-content) 13%, transparent)`): Pairs with a `-3px` lift for clearly interactive cards.
- **Floating Menu** (`shadow-xl`): Reserved for dropdowns and temporary overlays above the application shell.
- **Navigation Rest** (`shadow-sm` at scroll): Separates the fixed header from content only after scrolling.

### Named Rules

**The Layer First Rule.** Establish hierarchy with surface tone and borders before adding shadow; shadow must communicate interaction or floating context.

## Shapes

Rounded geometry makes technical content approachable without becoming playful. Form fields and navigation actions use `0.75rem` corners, compact panels use `1rem`, and substantial cards use `1.25rem`. Pills are reserved for primary calls to action, badges, avatars, and compact toggles. Borders are generally one pixel and theme-aware; dashed borders identify empty or loading states rather than ordinary content.

## Components

Components are tactile but disciplined: comfortable targets, obvious states, and small transitions with no ornamental motion.

### Buttons

- **Shape:** Controls use `0.75rem` corners by default; primary marketing or account actions may use pill geometry.
- **Primary:** Signal Blue background with matching high-contrast primary content and a minimum height of `2.75rem`.
- **Hover / Focus:** Subtle color or surface shift, optional restrained lift, and a two-pixel Signal Blue focus outline with a three-pixel offset.
- **Ghost:** Transparent at rest; gains a low-chroma blue or Surface background on hover.

### Chips

- **Style:** Compact daisyUI badges use semantic colors or a quiet neutral treatment; labels remain short and scannable.
- **State:** Selected or meaningful status chips may use semantic fill. Do not use decorative badges as filler.

### Cards / Containers

- **Corner Style:** `1.25rem` for primary cards and `1rem` for compact cards.
- **Background:** Theme Surface mixed with transparency over the Canvas.
- **Shadow Strategy:** Ambient at rest only for substantial cards; hover lift is limited to interactive cards.
- **Border:** One-pixel Border at reduced opacity, shifting toward Signal Blue on hover.
- **Internal Padding:** Usually `1rem`–`1.5rem`, increasing only for spacious landing-page sections.

### Inputs / Fields

- **Style:** One-pixel Border, translucent Canvas background, `0.75rem` radius, and a minimum height of `2.75rem`.
- **Focus:** Global Signal Blue focus outline; field components may also shift their border through daisyUI state classes.
- **Error / Disabled:** Error Rose carries validation meaning; disabled submission controls communicate waiting or unavailability and use an inline loading indicator when appropriate.

### Navigation

Desktop navigation uses compact semibold labels with rounded hover surfaces and a restrained blue active treatment. The fixed header gains blur, border, and a light shadow on scroll. Mobile navigation moves primary destinations into a bottom dock and secondary destinations into a contrasting Surface dropdown. Active items use a low-opacity blue fill rather than a heavy block of color.

### Empty, Error, and Loading States

State containers use quiet tonal backgrounds, dashed borders, compact icon tiles, plain-language titles, and one contextual recovery action at most. Loading skeletons use a low-contrast blue shimmer and honor reduced-motion preferences.

## Do's and Don'ts

### Do:

- **Do** use Signal Blue for the highest-priority interaction and visible keyboard focus.
- **Do** use Canvas, Surface, and Border tones to establish hierarchy before introducing shadow.
- **Do** keep controls comfortably sized and preserve responsive navigation ownership.
- **Do** use subtle 150–200ms state transitions and disable nonessential movement for reduced-motion users.
- **Do** keep instructional copy readable, direct, and visually dominant over decoration.

### Don't:

- **Don't** let violet or neon cyberpunk effects dominate the Tokyo palette.
- **Don't** use teal as a competing primary action color; it is a supporting accent.
- **Don't** add thick one-sided accent borders to cards or prose callouts.
- **Don't** stack shadows, gradients, badges, and decorative labels on the same surface.
- **Don't** hide essential actions behind hover-only behavior on touch layouts.
- **Don't** invent testimonials, performance claims, or other visual proof absent from the product record.
