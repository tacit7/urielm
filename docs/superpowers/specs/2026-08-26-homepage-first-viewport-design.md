# Homepage First Viewport Design

## Goal

Make Urielm's public homepage immediately prove its practical AI-learning value. A signed-out visitor should understand what the product helps them do and reach a useful resource without creating an account.

## Approved direction

- Replace the decorative hero treatment, metrics, and featured-course card with direct product copy and an interactive prompt-improvement artifact.
- Keep one primary action, “Start learning,” with “Browse prompts” as the quieter secondary action.
- Follow the hero with outcome-led routes for learning a concept, improving a prompt, building a workflow, and watching a quick demo.
- Keep the prompt artifact visible on mobile and support both Tokyo Night and Tokyo Day through existing daisyUI theme tokens.
- Use the existing system sans-serif hierarchy and functional monospace only inside prompt content and metadata.
- Move the Google profile-data explanation from the homepage catalog flow to the Google sign-in context.

## Data and behavior

- Use the approved, clearly labeled illustrative prompt so the before-and-after comparison remains coherent.
- Switch prompt variants through a LiveView event with clear tab semantics and selected state.
- Reuse existing routes: courses, prompts, blog, and videos.
- Leave downstream homepage content sections unchanged during this pass.

## Quality constraints

- No gradient text, decorative grid background, violet-led palette, hover-only essential action, or thick one-sided border.
- Preserve keyboard focus, reduced-motion behavior, public browsing, and touch-safe controls.
- Verify with focused LiveView tests, project precommit checks, the Impeccable detector, and one desktop/mobile browser review pass.
