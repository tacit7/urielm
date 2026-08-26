---
target: /
total_score: 15
max_score: 24
na_heuristics: 5,7,9,10
p0_count: 0
p1_count: 3
timestamp: 2026-08-26T09-49-35Z
slug: lib-urielm-web-live-home-live-ex
---
## Design Health Score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of System Status | 2/4 | Disconnected data can appear as factual zero or empty content. |
| 2 | Match System / Real World | 3/4 | Language is clear, but generic claims are weakly proven. |
| 3 | User Control and Freedom | 3/4 | Routes are available, but visitors receive little starting guidance. |
| 4 | Consistency and Standards | 2/4 | Components are consistent, but some homepage effects drift from the design system. |
| 5 | Error Prevention | n/a | No meaningful error-prone form or destructive workflow exists here. |
| 6 | Recognition Rather Than Recall | 3/4 | Labels are visible, but users must infer which content format fits their goal. |
| 7 | Flexibility and Efficiency | n/a | Not applicable to this public landing surface. |
| 8 | Aesthetic and Minimalist Design | 2/4 | Repeated grids, parallel CTAs, and decoration flatten the hierarchy. |
| 9 | Error Recovery | n/a | No substantive recovery workflow is present. |
| 10 | Help and Documentation | n/a | Not applicable to this public landing surface. |
| **Total** | | **15/24** | **Acceptable — significant focus and specificity work remains.** |

## Design Specificity Verdict

The homepage is coherent but only partly authored for Urielm. Its large AI headline, glow treatment, statistics, content grids, and generic calls to action could belong to many AI-learning products. Urielm's practical learning model is explained in copy but not convincingly demonstrated in the first viewport.

The deterministic scan found four source issues: `gradient-text` at `home_live.ex:85`, `ai-color-palette` at `home_live.ex:733`, and `codex-grid-background` plus `design-system-color` at `home_live.ex:61`. The raw grid color is likely a low-impact token concern, while the other findings reinforce the category-interchangeable visual language and violet drift. No reliable visual overlay was available because no browser backend was connected.

## Overall Impression

The homepage feels polished, trustworthy, and accessible, but behaves more like a catalog of content formats than a guided entrance into practical AI building. The largest opportunity is replacing abstract promise and category choice with one concrete builder outcome in the first viewport.

## What's Working

- Public browsing is explicit, reducing forced-auth friction.
- Semantic sections, responsive navigation, visible focus, and reduced-motion support provide a strong accessibility foundation.
- Content is database-backed rather than supported by invented proof.

## Priority Issues

### P1 — The first viewport promises practical building without proving it

Show one real prompt, lesson artifact, workflow output, or demonstrable result beside one outcome-led primary CTA. Suggested command: `/impeccable shape /`.

### P1 — Content formats create choice overload

Replace early format choice with three or four outcome-led paths and reduce repeated lower-page grids. Suggested command: `/impeccable distill /`.

### P1 — Google account disclosure creates an early emotional valley

Keep public-access reassurance concise and move detailed profile disclosure beside the actual sign-in action. Suggested command: `/impeccable clarify /`.

### P2 — Familiar AI visual tropes dilute the Midnight Workshop identity

Replace gradient text, the familiar grid treatment, and violet emphasis with tonal layering, artifact-led detail, and controlled Signal Blue. Suggested command: `/impeccable quieter /`.

### P2 — Loading and media states undersell the content

Use explicit skeletons until connected and persistent thumbnail, duration, and play affordances for video content. Suggested command: `/impeccable harden /`.

## Persona Red Flags

**Jordan, first-time learner:** Does not receive a clear starting path and may find broad AI-mastery language intimidating.

**Riley, skeptical evaluator:** Sees insufficient artifact proof for practical and battle-tested claims; disconnected empty states would damage trust.

**Casey, distracted mobile visitor:** Encounters a long succession of similar grids and may miss hover-dependent media cues or hidden overflow.

**Morgan, practical builder:** Needs earlier visibility into difficulty, time, prerequisites, expected output, and copy/use affordances.

## Minor Observations

- Verify accessible names on social links and icons.
- Consolidate raw SVG usage through the established icon system where practical.
- Validate low-opacity text and glow contrast once browser inspection is available.
- Confirm external footer links use appropriate target and rel behavior.
- Avoid a hardcoded footer year if one remains.

## Questions to Consider

- What single builder outcome can the homepage prove in the first viewport?
- Are prompts, courses, and videos the visitor's mental model, or the site's content model?
- Which three sections would survive if every section had to build trust or begin a learning session?
