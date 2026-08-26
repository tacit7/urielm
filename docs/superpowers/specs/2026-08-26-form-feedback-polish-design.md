# Button and form feedback polish

## Goal

Make form interactions across Urielm feel immediate, predictable, and accessible while preserving the existing Tokyo Night-inspired interface.

## Shared behavior

- Extend the shared button component with an explicit loading label and automatic LiveView double-submit protection.
- Standardize inputs at a 44px minimum target, with persistent labels, readable hints, `aria-invalid`, and linked error/help descriptions.
- Add a compact form-feedback component for accessible success, error, and informational messages.
- Use semantic theme colors, Heroicons, stable geometry, visible focus, and reduced-motion-safe loading indicators.
- Keep field contents readable while a form submits; disable repeated actions without causing layout shift.
- Do not add decorative left borders or introduce additional purple accents.

## First adoption set

Apply the shared interaction behavior to sign-in, signup, account settings, forum search, new-thread publishing, and the shared report modal. Video-related files are excluded because tag work remains active there.

## Validation

Add component tests for button loading behavior and input accessibility, plus selector coverage for the adopted forms. Run the focused LiveView suites, asset build, one Impeccable detector pass, `mix compile --warnings-as-errors`, and `mix precommit`.
