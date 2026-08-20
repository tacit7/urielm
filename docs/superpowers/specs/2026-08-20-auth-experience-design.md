# Authentication experience polish

## Goal

Make signing in and creating an account feel trustworthy, focused, and consistent with the Tokyo Night product experience without changing authentication behavior.

## Shared shell

- Add a lightweight brand link and Tokyo Day/Night toggle to the authentication layout.
- Use an editorial value proposition beside the form on large screens.
- Collapse to the focused form card on phones and smaller tablets.
- Keep semantic theme colors, cyan/teal accents, and neutral surfaces without decorative left borders.

## Forms

- Keep Google authentication first and email/password as the alternative.
- Use project `<.input>` components backed by the existing `to_form` assigns.
- Provide explicit labels, autocomplete attributes, concise constraints, and large touch targets.
- Keep hook-managed fields inside their existing ignored containers so values survive LiveView loading/error updates.
- Present server and network errors in an accessible alert with recovery-oriented language.
- Disable submission and show a spinner while a request is active.

## Sign up

- Retain username, display name, email, and password fields.
- Explain username format and password length adjacent to the relevant field.
- Add concise benefit and privacy copy without adding new legal claims.

## Verification

- LiveView tests assert stable shell, form, field, provider, error, and loading-state IDs.
- Existing authentication controller behavior remains unchanged.
- Build frontend bundles and run the complete Phoenix precommit suite.
