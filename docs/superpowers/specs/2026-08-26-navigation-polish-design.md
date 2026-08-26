# Responsive navigation polish

## Direction

Refine the existing Tokyo Night navigation rather than replacing it. Desktop keeps the full primary destination set, while mobile separates frequent destinations into the bottom dock and secondary destinations into the top-right menu. Active states use `aria-current`, semantic blue, a contained surface, and a subtle bottom marker.

## Component system

- Build with Tailwind utilities and existing daisyUI `navbar`, `btn`, `dropdown`, `menu`, `badge`, and `dock` components.
- Keep a 68px global header and 44px minimum interactive targets.
- Use the existing `UMIcon`/Heroicon system throughout; remove the account menu's separate Lucide icon implementation.
- Preserve Tokyo Day/Night tokens and avoid one-off colors, decorative blur, purple accents, or side borders.

## Responsive behavior

- Desktop: brand, primary links, search, notifications, theme, and account controls remain visible in a stable single row.
- Mobile: the bottom dock owns Home, Videos, Forum, Alerts, and Profile/Sign in. The top menu contains only Courses, Blog, Prompts, and authenticated Settings.
- Menus close on navigation, outside click, and Escape. Account and mobile menu triggers expose expanded state and controlled menu IDs.
- Notification badges remain capped at `99+`, labelled for assistive technology, and tied to the existing pushed unread count.

## Account menu

Show identity first, followed by Profile, Saved items, and Settings, then Log out. Remove Dashboard and Courses because they duplicate primary navigation. Logout keeps its existing guarded submission and loading state.

## Verification

Cover active-route mapping, mobile dock semantics for signed-in and signed-out users, accessible menu source contracts, asset compilation, desktop/mobile visual inspection where browser tooling is available, and `mix precommit` with known R2 failures documented separately.
