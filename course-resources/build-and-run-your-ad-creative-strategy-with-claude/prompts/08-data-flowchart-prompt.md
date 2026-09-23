Data flowchart prompt
You have the Meta ads MCP connected. I want you to pull everything I have run, map it back to the concepts behind it, and build me a live flowchart artifact showing where my money went and what it returned.
I do not want a list of ads. I want a picture of which ideas I paid for and which ones paid me back.
CONTEXT
Ad account: [name or ID, or "ask me"]
Date range: [for example, last 90 days]
Main metric: [CPA, or CPL, or whatever I optimise to]
My target for that metric: [number, or "work out the account average and use that"]
Minimum spend for something to appear on the chart: [for example $500]
My ads are named using this convention:
ConceptName-Persona-Angle-Offer-Format-MMDDYY
PHASE 1: PULL AND PARSE
Pull every ad that spent anything in the date range, with spend, results, and the metric above.
Parse each ad name into its fields. If an older ad predates this convention and has no offer field, take the offer from the campaign or ad set name, and tell me which ads you had to do that for.
Then report, in a few lines:
      * How many ads you pulled and how much they spent in total
      * How many names parsed cleanly, and what percentage of spend that covers
      * Any names that did not parse, listed, with their spend
If less than 80% of spend parses cleanly, stop and show me the problem names. A chart built on half my account is worse than no chart, because I will believe it.
PHASE 2: BUILD THE ARTIFACT
Build a live artifact containing a flowchart that reads left to right:
PERSONA → ANGLE → OFFER → FORMAT
One tree per persona. Each persona branches into every angle run against it. Each angle branches into the offers it was paired with. Each offer branches into the formats it ran in. The format node is the end of the branch and carries the numbers:
      * Total spend on that path
      * The main metric for that path
Colour the format nodes against my target: green for beating it, amber for near it, red for missing it. Put a short callout on the best performing branch saying to make more of it.
Make every node show its own rolled up spend, so I can see at a glance which persona and which angle took the money, not only which format won.
RULES FOR THE NUMBERS
      1. Roll up by summing. To get the metric for any node, add up the spend on every ad underneath it and add up the results, then divide. Never average the CPAs of the ads below it. That gives the wrong answer whenever spend is uneven, which is always.
      2. Anything under the minimum spend does not get its own branch. Group it into one node called Thin Data and show the total. Do not silently drop it.
      3. Show the unparsed spend somewhere on the chart as its own box. I want to see how much of my account is invisible.
      4. Use only the labels in my names. Do not tidy them, merge two that look similar, or invent a nicer word for one.
      5. Where a branch is winning on a very small sample, say so on the chart rather than letting the colour imply confidence I do not have.
AFTER THE CHART
In a few lines under it, not on it:
      * Which persona earned its spend and which one did not
      * Which angle won, across formats
      * Which combination you would put more money into, and which one you would stop
      * What I am not testing that the chart makes obvious. Empty branches are as useful as full ones.
