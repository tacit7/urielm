# Automatic discussion notifications

## Goal

Create notifications as part of normal discussion activity and keep the signed-in user's navigation badge current without a reload.

## Recipient rules

- A new top-level comment notifies the thread author.
- A nested reply notifies the parent comment author and the thread author.
- Explicit thread subscribers are notified.
- The actor is always excluded.
- A muted topic setting excludes the user even when they are an author or subscriber.
- Recipient IDs are deduplicated before insertion, so a thread author who is also subscribed receives one notification.
- Nested activity uses the `reply` subject type; top-level activity uses `comment`.

## Delivery and live state

Notification rows are inserted after the comment succeeds. Each successful notification mutation broadcasts the recipient's new unread count on a user-specific PubSub topic. The global LiveView auth hook subscribes connected signed-in views and owns an `unread_notification_count` assign.

The forum navigation renders a compact cyan/blue badge beside Notifications. It is hidden at zero and displays `99+` above 99. No purple accents or decorative left borders are introduced.

## Failure behavior

Notification delivery is a secondary effect: an already-persisted comment remains successful if a notification insert cannot be produced. Validation and database constraints remain the source of truth for notification records.

## Tests

- Top-level comments notify the thread author and subscribers.
- Replies notify the parent author.
- Actor exclusion, muted preferences, and recipient deduplication are enforced.
- Notification creation/read actions broadcast updated unread counts.
- The shared forum navigation badge renders the count, caps it, and hides at zero.
