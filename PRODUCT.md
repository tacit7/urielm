# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Urielm serves developers and creators who are learning to build useful projects with AI. They use the site to find practical guidance, reusable materials, and peer discussion while moving from an idea toward a working result.

## Product Purpose

Urielm is a public learning platform for practical AI development. It brings together tutorials, structured courses, videos, production-ready prompts, and community discussions. Success means people can learn from useful public resources, apply them to real projects, and optionally participate in the community.

## Positioning

Urielm combines guided learning, reusable prompts, concise video walkthroughs, and developer discussion in one personally curated platform focused on practical application rather than AI news or abstract theory.

## Operating Context

Visitors can browse public learning content without an account. Signing in enables personal and community workflows such as saving resources and participating in discussions. Content spans blog posts, prompts, courses and lessons, videos, and forum conversations.

## Capabilities and Constraints

- Public routes include the home page, blog, prompts, courses, videos, user profiles, forum content, privacy policy, and terms.
- Accounts support saved content, notifications, chat, profiles, settings, and community participation.
- Google OAuth and email/password authentication are supported.
- The product is a responsive web application built with Phoenix LiveView and Svelte.
- Public learning content must remain understandable and useful without requiring authentication.

## Brand Commitments

- Preserve the Urielm name.
- Keep the voice practical, direct, and useful to builders.
- Preserve the existing Tokyo Night-inspired light and dark themes, favoring midnight blue over cyan or violet-heavy treatments.
- Preserve the existing Urielm logo at `priv/static/images/logo.svg`.

## Evidence on Hand

- Existing published and database-backed content across tutorials, prompts, courses, videos, and forum discussions.
- Privacy policy: `smpl-labs-privacy-policy.pdf`.
- Terms and conditions: `smpl-labs-terms-and-conditions.pdf`.
- Product purpose and public-access claims are represented in `lib/urielm_web/live/home_live.ex` and `lib/urielm_web/live/shell_live.ex`.
- No testimonials, customer logos, performance benchmarks, pricing claims, or press evidence are currently confirmed; future work must not fabricate them.

## Product Principles

1. Make practical learning useful before asking someone to sign in.
2. Help builders move from explanation to application with reusable resources.
3. Keep learning paths clear across tutorials, courses, prompts, videos, and discussion.
4. Make community features additive to the public learning experience.
5. Prefer trustworthy, concrete claims over invented proof or hype.

## Accessibility & Inclusion

Maintain an accessible, responsive experience across desktop and mobile web, including keyboard navigation, visible focus states, semantic structure, and sufficient color contrast in both themes.
