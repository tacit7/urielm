# Public Privacy Policy Page Design

## Goal

Publish the SMPL LABS LLC privacy policy at the stable, unauthenticated URL `/privacy` in a format Google OAuth verification can read and users can navigate on desktop or mobile.

## Source of truth

- Legal source: `smpl-labs-privacy-policy.pdf`, dated August 25, 2026.
- Product-specific OAuth behavior: Google OAuth requests the `email profile` scopes and persists the provider identifier, email, name, profile image, provider token, and returned profile information for account creation and authentication.
- The HTML page preserves the PDF's numbered legal sections while adding an explicit Google OAuth disclosure to correct the PDF's generic Facebook/X social-login wording.

## Route and rendering

- Add a public standalone `UrielmWeb.PrivacyLive` route at `/privacy` in the browser pipeline.
- The LiveView begins with `<Layouts.app>` and requires no authenticated session.
- Add a canonical URL and a descriptive page title for verification and search engines.
- Do not embed the PDF as the policy body; Google requires a readable dedicated HTML page.

## Layout

- Reuse the Tokyo Day/Night daisyUI theme and the global navbar.
- Use a centered hero with company name, policy title, and effective date.
- Use a two-column reading layout on desktop: sticky table of contents plus a readable policy column.
- Collapse to one column on mobile with an accessible contents panel.
- Use cards, conventional dividers, and generous paragraph spacing. Do not add a decorative left border.
- Add stable section IDs so every table-of-contents link works without JavaScript.

## Google OAuth disclosure

The social-login section must explicitly disclose:

- scopes requested: `email` and `profile`;
- data received: Google account identifier, name, email, and profile image;
- purposes: account creation, sign-in, identity linking, security, and profile display;
- storage: account and OAuth identity records, including the provider token and returned profile information;
- sharing: no sale of Google user data and no use for advertising;
- retention/deletion: retained while the account is active or legally required, with deletion requests available through account settings or `uriel@smpllabs.io`.

## Discovery

- Add an exact `/privacy` link to the homepage footer.
- The route must return HTTP 200 without login.

## Verification

- LiveView test asserts `#privacy-policy-page`, title/date, all 15 section anchors, Google OAuth disclosure, contact email, and no sign-in redirect.
- Homepage test asserts an exact footer link to `/privacy`.
- Run `mix precommit`; report environment-only failures separately.

## Mockup

The approved implementation reference is `priv/static/mockups/privacy-page.html`, containing desktop and mobile states plus implementation annotations.
