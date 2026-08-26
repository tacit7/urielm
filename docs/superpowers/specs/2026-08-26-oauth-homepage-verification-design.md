# Google OAuth Homepage Verification Design

## Problem

Google rejected the submitted application homepage because it appeared to be behind login and did not explain the application's purpose. Google's current official guidance requires a production OAuth homepage to be public, identify the app, describe its functionality, explain why requested Google data is used, and link its privacy policy and terms.

## Diagnosis

- Local and production `/` are in a public LiveView session and return HTTP 200 without a user session.
- The current production checkout is stale and does not include `/privacy` or `/terms`; both return 404.
- The existing hero briefly describes AI learning, but does not explicitly explain Google sign-in data use.
- The strongest remaining causes are an old verification snapshot/deployment or an OAuth homepage URL configured as an authentication path instead of the exact root URL.

## UI changes

- Preserve the current hero while making its lead sentence explicitly identify Urielm as a public learning platform.
- Add a public `#app-purpose` section with three concrete capabilities: tutorials/courses, reusable prompts, and community discussion.
- Add `#google-signin-purpose` explaining that Google sign-in is optional for browsing and that name, email, profile image, and Google account identifier are used to create and authenticate an account.
- Show direct `/privacy` and `/terms` links inside this disclosure in addition to the footer.
- Preserve the Tokyo Day/Night theme and avoid a decorative left border.

## Metadata and routing

- Keep `/` in the unauthenticated default LiveView session.
- Give the Shell home action a descriptive page title, meta description, and canonical `https://urielm.dev/` URL.

## Verification

- A logged-out request to `/` must return 200 with no redirect.
- LiveView tests assert the hero, explicit app-purpose section, Google sign-in data-purpose section, and exact privacy/terms links.
- The production deployment and Google Cloud Branding page must use the exact same public URLs.

## Mockup

Implementation reference: `priv/static/mockups/oauth-verification-homepage.html` with desktop and mobile states.
