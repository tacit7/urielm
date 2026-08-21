# Notifications experience design

## Goal

Complete the community participation loop with a notification inbox that makes unread activity, its source, and the next action immediately clear on desktop and mobile.

## Design

- Keep the page in the authenticated application shell.
- Use a compact header with unread summary and a conditional mark-all-read action.
- Preserve URL-backed All and Unread filters and expose active state accessibly.
- Group streamed items as Today, Yesterday, and Earlier while keeping notification rows independently actionable.
- Show notification type, actor identity, relative time, related discussion title, and a clear destination link.
- Use a subtle blue surface wash and status dot for unread items. Do not use decorative left borders or purple/violet accents.
- Provide distinct empty states for an empty inbox and an empty unread filter.
- Keep infinite pagination and show a compact loading affordance.

## Behavior

- Marking one notification read updates the unread count and row state; in the Unread filter it disappears.
- Mark all read clears the count and returns to the All filter.
- Per-item mutations must be scoped to the signed-in user.
- Existing notification types remain supported: comment, reply, and thread update.

## Verification

- LiveView tests assert stable IDs, active filters, grouped items, empty states, and read actions.
- Context tests cover user-scoped read mutations.
- Run focused notification tests, asset compilation, and `mix precommit`.
