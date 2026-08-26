# Public Terms of Use Page Design

## Goal

Publish the SMPL LABS LLC terms at the stable, unauthenticated URL `/terms` as readable HTML that visually matches the existing privacy policy.

## Source and normalization

- Legal source: `smpl-labs-terms-and-conditions.pdf`, generated August 25, 2026.
- Replace the PDF generator's blank company, service, date, and contact placeholders with values already published by the application and privacy policy.
- Correct the generic statement that the service does not accept user content because Urielm provides forum posts, comments, messages, and prompts.
- Do not publish incomplete arbitration blanks. Use Texas law and courts for the governing-law section based on the company's published Austin address; flag this substantive choice for legal review.
- Preserve all 19 numbered subject areas while rewriting malformed generator fragments into clear language.

## Route and rendering

- Add a standalone public `UrielmWeb.TermsLive` at `/terms` in the default LiveView session.
- Begin the template with `<Layouts.app>` and require no authenticated account.
- Set the page title, meta description, and canonical URL `https://urielm.dev/terms`.

## Layout

- Reuse the responsive structure and Tokyo Day/Night daisyUI treatment of `/privacy`.
- Show the company, title, and effective date in a compact hero.
- Use a sticky table of contents and 19 stable section IDs on desktop; stack content on mobile.
- Use cards, readable typography, and subtle hover/focus states without a decorative left border.

## Discovery and verification

- Add an exact `/terms` link next to Privacy Policy in the homepage footer.
- Test public access, canonical structure, all 19 anchors, contact information, privacy cross-link, and footer discovery.
- Run focused tests and `mix precommit`, separating external-service failures from feature failures.

## Mockup

Implementation reference: `priv/static/mockups/terms-page.html`, with desktop and mobile states.
