# Global notification navbar

## Goal

Make notifications discoverable from every page that uses the global application navbar, on both desktop and mobile.

## Design

- Show a compact bell action only for signed-in users.
- Link directly to `/notifications`.
- Hide the count badge at zero and cap values above 99 at `99+`.
- Use the existing Tokyo Night cyan/blue semantic colors without purple accents or a decorative left border.
- Keep the action visible in the mobile navbar rather than hiding it inside the menu.

## Live updates

The navbar is intentionally inside `phx-update="ignore"` so it persists during navigation. Its initial count is passed from the LiveView socket into the Svelte component. Subsequent PubSub count changes are pushed as a `phx:unread-notification-count` browser event, which updates local Svelte state without replacing the persistent navbar.

## Tests

- Signed-in users render a notification link with the initial unread count.
- Signed-out users do not render the notification action.
- PubSub notification changes push the new unread count to the browser.
- The Svelte asset bundle compiles with the event listener and responsive badge.
