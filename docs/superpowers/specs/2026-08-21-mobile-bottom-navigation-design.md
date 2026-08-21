# Mobile bottom navigation

## Goal

Make the most-used destinations consistently reachable with one thumb on mobile without changing the desktop navigation.

## Design

- Render a fixed bottom dock below the `lg` breakpoint on main application and forum layouts.
- Signed-in destinations are Home, Forum, Search, Alerts, and Profile.
- Signed-out destinations are Home, Forum, Search, and Sign in; private actions remain hidden.
- Use Tokyo Night cyan/blue semantic colors, a translucent surface, a subtle top border, and no purple or decorative left border.
- Show the existing unread count on Alerts, hide it at zero, and cap it at `99+`.
- Keep notifications out of the top mobile header; retain the account menu for settings and sign-out actions.

## Responsive behavior

- Hide the dock at `lg` and above.
- Include safe-area bottom padding for devices with a home indicator.
- Add matching mobile page padding so the dock does not cover page content.
- Hide the dock alongside the top navbar during fullscreen composition.

## Data and active state

- Reuse `current_user` and `unread_notification_count` assigns already loaded by `UserAuth`.
- Main application routes derive active state from `current_page`.
- Forum routes derive active state from `current_path`, with search distinct from the general Forum destination.

## Tests

- Signed-in main pages render all five dock destinations and the initial unread badge.
- Signed-out pages render Sign in and omit private destinations.
- Forum pages render the shared dock with the correct active destination.
- The asset bundle compiles after simplifying duplicate mobile header actions.
