# Locked video discussion

## Direction

Align video discussions with the established forum permission state. When a video's discussion thread is locked, replace the reply composer or sign-in prompt with a compact locked-state panel while keeping the existing comment tree visible and readable.

## Component system

- Use the existing Tailwind and daisyUI vocabulary already present in the video detail card.
- Reuse the forum's warning semantics: `border-warning/25`, `bg-warning/8`, and the shared lock icon.
- Preserve the Tokyo Day/Night theme tokens and the existing video discussion spacing.
- Do not add a modal, action button, decorative gradient, or one-sided accent border.

## Behavior

- Locked state takes precedence over authentication state.
- Authenticated viewers do not see `#video-comment-form` when the thread is locked.
- Anonymous viewers do not see the sign-in-to-comment prompt when the thread is locked.
- Existing comments remain rendered below the state panel.
- The server-side `:thread_locked` guard remains in place as defense in depth.

## Copy

- Title: “This discussion is locked”
- Description: “New comments are closed, but the existing conversation remains available to read.”

## Verification

- Add LiveView coverage for authenticated and anonymous locked discussions.
- Assert the locked panel is present, the composer/sign-in prompt is absent, and existing comments remain rendered.
- Run the focused video LiveView suite, the Impeccable detector once, and `mix precommit`.
