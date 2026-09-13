# SEO implementation

## Objective

Make public learning content discoverable and understandable from its initial HTTP response. Preserve current layouts, interactive behavior, and authorization. The `pre-seo` tag records the starting commit; the existing generated Svelte bundle modification is outside this work.

## Design

- Load public content during disconnected LiveView mount. Keep writes and subscriptions behind connection checks. Render body text and ordinary links without requiring JavaScript.
- Resolve shell page metadata at the parent level. Produce unique titles, descriptions, canonical URLs, social metadata, and accurate structured data in the initial document. Keep head metadata consistent after live navigation.
- Return HTTP 404 for missing public content rather than a successful empty shell. Do not disclose protected content through metadata or structured data.
- Serve a dynamic XML sitemap of eligible public content, with accurate modification dates and XML escaping. Reference it from robots.txt and exclude utility routes through indexing directives rather than crawler blocking.

## Ownership

EITS team `urielm-seo` (748), with GPT-5.5 workers:

- Task 9627: disconnected content rendering and crawlable listing links.
- Task 9628: parent metadata, structured data, missing content responses, and live head updates.
- Task 9629: sitemap and indexing controls.
- Task 9626: orchestration, lesson rendering, integration, and final validation.

Workers use separate worktrees. The orchestrator integrates local commits on `codex/seo-optimization`.

## Validation

Request-level tests parse initial HTML with LazyHTML. Verify visible article/lesson/video/prompt content, resource and collection links, page-specific metadata, escaped structured data, sitemap eligibility, indexing headers, missing content status codes, and authorization. Existing LiveView tests cover interactions after connection. Run `mix precommit` on the integrated branch and distinguish pre-existing failures from regressions.

Deployment and Search Console submission are subsequent actions; this implementation does not deploy to production.
