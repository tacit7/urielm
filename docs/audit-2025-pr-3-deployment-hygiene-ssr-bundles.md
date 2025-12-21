# PR 3 — Deployment Hygiene: Stop Committing Generated SSR Bundles

This PR clarifies the source-of-truth for SSR output and removes noisy, generated diffs from the repo by treating `priv/svelte/*` as a build artifact (similar to `priv/static/assets/*`).

---

## Why this PR exists (context for juniors)

This project uses LiveSvelte with SSR:
- Client bundle output: `priv/static/assets/js/*` (already git-ignored)
- Server bundle output (SSR): `priv/svelte/server.js` (currently **committed**)

Committing generated files causes:
- frequent merge conflicts
- noisy PR diffs that hide real changes
- confusion about what should be edited (source vs output)

Also: `deploy.sh` already runs `node build.js --deploy`, which generates SSR output on the server — so committing SSR output is usually unnecessary.

---

## Goals
- Treat `priv/svelte/*` as a generated build output (not hand-edited source).
- Reduce PR diff noise and merge conflicts.
- Ensure deploy/build scripts generate SSR output reliably.
- Document the SSR build step so juniors can debug deployments.

## Non-goals
- No change to SSR runtime behavior.
- No change to UI components.
- No change to the Node/esbuild toolchain beyond documentation and git hygiene.

---

## Files you will likely touch
- `.gitignore`
- `assets/build.js` (only if output path needs to be adjusted/standardized)
- `deploy.sh` (verify SSR build is included)
- Docs:
  - Update an existing deploy doc (e.g. `docs/DEPLOYMENT.md`) or add a short section there
- Git history change (one-time):
  - remove committed build output under `priv/svelte/`

---

## Step-by-step implementation plan

### Step 0 — Verify SSR output is truly generated

1. Delete the SSR output locally (don’t commit yet):
   - `rm -rf priv/svelte`
2. Rebuild assets:
   - `mix assets.build` (dev build)
   - or `cd assets && node build.js --deploy && cd ..`
3. Confirm that `priv/svelte/server.js` is regenerated.

If it isn’t, stop and inspect:
- `assets/build.js` → `optsServer.outdir` should be `../priv/svelte`

---

### Step 1 — Add `priv/svelte/` to `.gitignore`

In `.gitignore`, add:

```
/priv/svelte/
```

Keep it consistent with existing policy:
- `priv/static/assets/*` is already ignored → treat SSR output the same way.

---

### Step 2 — Remove committed SSR output from the repo

One-time cleanup:
- `git rm -r priv/svelte`

Then rebuild to ensure it still exists locally for dev:
- `mix assets.build`

Important:
- This PR must include the `.gitignore` change **and** the removal, or the repo will keep re-adding the file.

---

### Step 3 — Ensure deploy builds SSR output

Confirm `deploy.sh` builds SSR output (it already runs `node build.js --deploy`).

Make sure the order remains:
1) install deps
2) `mix tailwind ... --minify`
3) `node build.js --deploy` (produces `priv/static/assets/js/*` and `priv/svelte/server.js`)
4) `mix phx.digest`

If production deploy uses a different mechanism than `deploy.sh`, update that path too.

---

### Step 4 — Document SSR build expectations

Update `docs/DEPLOYMENT.md` (or add a short section) to include:
- why `priv/svelte/` is generated
- how to regenerate it locally (`mix assets.build` / `mix assets.deploy`)
- Node version expectations (build.js target is `node19.6.1`)
- what to check if SSR errors appear in production

---

## Regression check idea

This is more of a “process test” than an ExUnit test:
- In CI (or as a manual checklist), run `mix assets.deploy` and verify:
  - `priv/svelte/server.js` exists after the build
  - `git status` is clean (generated files remain untracked)

If you want to automate it, add a small shell script under `bin/` and call it from CI.

---

## How to verify locally
- `mix assets.build` (dev)
- `MIX_ENV=prod mix assets.deploy` (prod-like)
- `git status` should show no tracked changes to `priv/svelte/*`
- Finish with: `mix precommit`

---

## Common pitfalls
- Don’t remove SSR output without ensuring the deploy pipeline builds it.
- Don’t change output directories unless you also update docs/scripts.
- Don’t try to “fix” this by committing build output again — it defeats the purpose.

