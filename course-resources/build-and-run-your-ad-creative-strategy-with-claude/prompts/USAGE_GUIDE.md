# How to Use the Creative Strategy Prompts

These prompts are a workflow, not a collection of interchangeable copywriting commands. Use them in order to give Claude reliable business context, buyer evidence, and a consistent system for turning ad tests into decisions.

The operating principle throughout is simple: Claude accelerates research, organization, and structured ideation; you supply the business judgment. Do not ask it to make the final strategic choice, invent missing evidence, or write a finished ad before the audience and angle are agreed.

## The workflow at a glance

1. Create the brand and company context file.
2. Set up a Claude Project and add the enduring project files.
3. Research raw buyer language.
4. Choose and build one core avatar, then save it in the project.
5. Find advertiser libraries worth studying and review the ads yourself.
6. Turn a selected reference ad into distinct concepts and hooks.
7. Name every launched ad consistently.
8. Pull performance data into a flowchart and decide what to scale, iterate, or stop.

Each later step depends on the output of earlier ones. Skipping the context or research steps makes later copy generic; skipping naming makes later performance analysis unreliable.

## Before you begin

Create one Claude Project for the brand and keep its source-of-truth files there. The project should contain:

- The completed brand and company context file.
- The core avatar training document.
- One or more completed core avatar files.
- The project instructions, customized for the brand.

If available, connect the Meta Ads MCP to the project for ad-library research and performance analysis. The library-research and data-flowchart prompts require that connection.

Customize every bracketed placeholder before sending a prompt. Provide the real product, offer, market, source material, dates, and metric. Never leave Claude to infer a fact that determines the strategy, especially the offer, target metric, or launch date.

## Step 1 Build the brand and company context

Use `01-brand-and-company-context-prompt.md` in a fresh Claude chat. It is an interview and document-building prompt, not a one-shot form.

Give Claude only the company name and website when it asks. Let it research public pages first, then correct its short research summary before the interview begins. Answer the eight interview questions one at a time with concrete detail. Include active offers, actual prices, landing-page promises, substantiated proof, objections, claims you cannot make, language that has worked, language to avoid, and production constraints.

Review the completed file before uploading it to the project. The file is the source of truth for what the business sells, its voice, conversion path, usable proof, and prohibited claims. Correct weak or inaccurate sections rather than accepting plausible prose. If information is unavailable, leave it as `Not provided`; that is safer and more useful than an invented answer.

## Step 2 Set the project instructions and train Claude on avatars

Upload `03-core-avatar-training.md` once. Do not paste it into every conversation or treat it as a request for an avatar. It teaches Claude the framework it must follow whenever it builds, narrows, or evaluates an avatar.

Then customize and upload `09-project-instructions-template.md`. Fill in the brand, product, producible formats, optimization metric, and destination page. This tells Claude to read the project files before creative work, ask for a missing avatar or offer, follow brand voice and claim limits, and give a small number of distinct options rather than a flood of variations.

The project instructions do not replace the context or avatar files. They tell Claude how to use those files together.

## Step 3 Collect buyer evidence before defining an avatar

Use `02-core-avatar-research-prompt.md` outside or inside the project after adding a concise description of the product and the buyer you expect to serve. Its output is research, not marketing copy.

Ask for the full output, including links. Preserve it unedited when you pass it to the avatar build prompt. The useful inputs are buyers' exact words, situations, failed attempts, emotions with triggers, repeated behaviors, objections, and disagreements—not a polished market summary.

Judge the research before using it:

- Check that quotes are verbatim, linked, and drawn from public buyer conversations.
- Prioritize repeated language across communities and useful comments, not only top-level posts.
- Keep opposing views; they may point to separate avatars or objections.
- Treat sections marked thin or unsupported as gaps to research, not facts to fill in.

If you already have surveys, reviews, sales-call notes, support tickets, or customer interviews, include them with the raw research. First-party buyer language is valuable evidence.

## Step 4 Choose and build a core avatar

Use `04-core-avatar-build-prompt.md` only after the training document and brand context are in the project. Paste the complete research output, unchanged, into its research section.

Phase 1 is deliberately a decision point. Claude should propose three materially different foundations, drawn from desires, situations, or behaviors, and recommend one. Read the evidence, commercial fit, and production feasibility; then choose the foundation yourself. Do not ask Claude to silently choose and build an avatar in the same turn.

After you choose, allow Phase 2 to build the complete avatar. Save that output as a separate project file. A sound avatar has one defining boundary, buyer language quoted verbatim, evidence-backed first-order insights, labeled second-order inference, and a few sub-avatars that would result in different ads.

Use these checks when reviewing it:

- One desire, situation, behavior, emotion, or genuinely relevant demographic defines the avatar. Do not merge several desires into one persona.
- Demographics come last and may be unnecessary. They should increase relevance, not merely shrink reach.
- Experiences state what happened; emotions state the reaction and its trigger; behaviors state what people repeatedly do.
- Second-order benefits and pains are informed interpretations, not buyer quotes. They must trace back to the research and be labeled as a read.
- `Not researched` and a clear gap are better than a plausible assumption.

Start with one core avatar and test its sub-avatars before adding more core avatars. Narrow, recognizable groups are usually easier to test than broad, generic audiences.

## Step 5 Find reference libraries without copying ads

Use `05-ad-library-research-prompt.md` with the Meta Ads MCP connected. Fill in the product, buyer, product type, and market.

This prompt only identifies advertiser pages to inspect manually. It should return direct competitors and same-product-type brands in unrelated niches, sorted by active-ad volume. Open the recommended libraries yourself and look for transferable structures: the format, hook pattern, tension, proof placement, offer sequence, and visual approach.

Do not use active-ad volume as proof that a particular ad is profitable. The prompt treats it only as a signal for where to look. Do not copy words, brand-specific claims, footage, or the competitor's exact idea. Adapt the structural lesson to your context and avatar.

## Step 6 Convert a reference ad into testable concepts

Use `06-script-creation-prompt.md` after you have selected a reference ad worth studying. Paste the script and let Claude ask which persona to target and which format and length to use. Confirm or correct its recommendations before it writes.

The output is a concept-development brief, not finished production copy. It should explain the reference ad's structural mechanism, then provide three distinct adaptation directions. Select one direction based on the target avatar, the offer, brand voice, evidence available, and what you can actually produce.

Use the direction's hooks as a starting point, then write and produce the final script with the project context open. A finished ad should speak to one avatar, make one central argument, keep the landing-page promise, use only authorized proof, and retain the buyer's language where it is stronger than polished advertising language.

## Step 7 Name the ad before it launches

Use `07-naming-convention-prompt.md` for every ad or concept variation before launch. Give Claude the script or copy, format, and launch date. If the offer is not explicit in the script, provide it when asked; it must not be guessed.

The required format is:

`ConceptName-Persona-Angle-Offer-Format-MMDDYY`

Use PascalCase-style field values with no spaces. The name records the variables needed to understand a test: what concept was tested, who it addressed, what argument it made, what it offered, how it was delivered, and when it launched.

Consistency is more important than the perfect label. Reuse an existing concept name for a variation of the same idea, and reuse the exact existing persona, angle, and offer labels. A new concept name means a materially new idea, not a new hook or edit. Maintain the running label list in the same Claude Project or a separate tracker so labels do not drift between chats.

## Step 8 Analyze the test portfolio, not a list of ads

After the ads have enough spend to be informative, use `08-data-flowchart-prompt.md` with the Meta Ads MCP connected. Set the ad account, date range, main metric, target, and minimum-spend threshold. The naming convention must already be in use for this prompt to work well.

First inspect the parsing report. If less than 80 percent of spend parses cleanly, fix or account for the malformed names before asking for the chart. Do not make a strategy decision from a chart that hides most of the account.

The flowchart should roll up `PERSONA → ANGLE → OFFER → FORMAT`, preserving the labels in your ad names. Metrics must be calculated as total spend divided by total results for each branch, never by averaging individual ad CPAs or CPLs. Keep thin-data and unparsed-spend nodes visible so a green result on a tiny sample is not mistaken for a scalable winner.

Use the chart to decide which combinations deserve more spend, which need a new hook or format, and which should stop. Then diagnose weak ads through the funnel: CPM, thumb-stop or hook rate, playthrough, click-through rate, and landing-page conversion. Fix the first weak link, rather than rewriting the whole ad without evidence.

## Working habits that keep the system reliable

- Keep the brand context, avatar research, completed avatars, scripts, ad names, and outcome data connected in one project or tracker.
- Treat raw buyer language and verified business facts as evidence. Treat Claude's recommendations as hypotheses to judge and test.
- Ask one high-impact clarification question when key information is missing instead of filling the gap with a safe-sounding assumption.
- Test manageable combinations. Start with an avatar and a few strong concepts, then vary hooks, formats, and angles within what the budget and production capacity can support.
- Wait for enough spend relative to the target CPA or CPL before drawing conclusions. The course guidance suggests roughly three to five times the target CPA as a practical initial threshold.
- Revisit the brand context and avatar files as new customer language, proof, constraints, or winning messages emerge. Update the source documents before relying on the new information in creative.

## Common failure modes

| Failure | What to do instead |
| --- | --- |
| Asking for final ads before context, research, avatar, and angle are settled | Build the inputs in order and use concept work to decide the angle first. |
| Treating a broad demographic as the avatar | Define the audience around one desire, situation, behavior, or evidenced emotion; add demographics only when relevant. |
| Cleaning up buyer language | Preserve the original phrasing in research and avatar files; use it deliberately in creative. |
| Filling gaps with assumptions | Mark the gap, state what evidence would fill it, and research it. |
| Copying a competitor ad | Reuse a structural mechanism, then rebuild it for your avatar, offer, proof, and voice. |
| Naming each variation as a new concept | Reuse the concept label unless the central creative idea has changed. |
| Comparing averaged CPAs across ads | Aggregate spend and results first, then calculate the branch metric. |
| Letting AI make the final strategy call | Have Claude show the evidence and tradeoffs; choose the avatar, concept, and production decision yourself. |

Used this way, the prompts form a learning loop: evidence creates an avatar, the avatar focuses concepts, consistent names preserve the test variables, and performance data tells you what to develop next.
