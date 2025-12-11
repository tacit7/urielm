# Action Plan: Import SabrinaRamonov Prompts (Vendored) into UrielM.dev

Date: 2025-12-10  
Owner: Uriel  
Goal: Vendored markdown prompts imported into `prompts` table; tags handled **only** via `prompt_tags` join table; import is idempotent; search works.

---

## 0) Emergency hygiene (do this first)
You pasted `PGPASSWORD` in chat earlier. Treat it as compromised.

- [ ] Rotate the Postgres user password immediately (or create a new DB user and revoke the old one).
- [ ] Rotate any `DATABASE_URL` / secrets that include the leaked password.
- [ ] If you use DO managed DB, verify allowed IPs / firewall rules; reduce exposure.

---

## 1) Normalize tags (one source of truth)
Right now you have both:
- `prompts.tags` (array column)
- `prompt_tags` (join table)

Pick one. Use the join table; it is the sane choice for tagging and querying.

### 1.1 Migration: remove `prompts.tags`
- [ ] Create migration `remove_prompts_tags_array.exs`:

```elixir
defmodule UrielM.Repo.Migrations.RemovePromptsTagsArray do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      remove :tags, {:array, :string}
    end
  end
end
```

- [ ] Run migrations:
```bash
mix ecto.migrate
```

### 1.2 Update schemas and writes
- [ ] Remove `field :tags, {:array, :string}` from `Prompt` schema.
- [ ] Ensure any importer code stops writing `tags: []` to `prompts`.

---

## 2) Make imports idempotent (no duplicates)
Add a unique index on `prompts.url`.

- [ ] Create migration:
```elixir
defmodule UrielM.Repo.Migrations.UniquePromptsUrl do
  use Ecto.Migration

  def change do
    create unique_index(:prompts, [:url], where: "url IS NOT NULL")
  end
end
```

- [ ] Run:
```bash
mix ecto.migrate
```

---

## 3) Vendor workflow (already done, but make it repeatable)
Goal: you can re-vendor later without guessing what changed.

- [ ] Ensure the vendor path is stable, for example:
```
vendor/sabrinaramonov-prompts/
```

- [ ] Record provenance:
  - [ ] Keep `VENDORED_FROM_COMMIT` containing the SHA + repo URL.

Example:
```bash
echo "$(git -C /tmp/ramanov-prompts rev-parse HEAD)" > vendor/sabrinaramonov-prompts/VENDORED_FROM_COMMIT
echo "https://github.com/SabrinaRamonov/prompts" >> vendor/sabrinaromonov-prompts/VENDORED_FROM_COMMIT
```

---

## 4) Import task (vendored markdown -> DB)
Create a Mix task that:
- finds `vendor/**.md`
- extracts `title`
- stores full markdown into `prompts.prompt`
- sets `source` and `processed=true`
- upserts by `url`

### 4.1 Filesystem scan
- [ ] Implement `mix prompts.import_vendor_ramonov`
  - root: `vendor/sabrinaramonov-prompts`
  - glob: `**/*.md`
  - url: use commit SHA if you recorded it, else `main`

### 4.2 URL strategy (important)
Use a stable URL format so upserts keep working. Example:
- If you have SHA: `https://github.com/SabrinaRamonov/prompts/blob/<SHA>/<path>.md`
- Else: `https://github.com/SabrinaRamonov/prompts/blob/main/<path>.md`

### 4.3 Run import
- [ ] Run:
```bash
mix prompts.import_vendor_ramonov
```

### 4.4 Sanity checks
- [ ] Confirm counts:
```sql
select count(*) from prompts;
```
- [ ] Spot check a few rows:
```sql
select id, title, url, processed, source from prompts order by id desc limit 20;
```

---

## 5) Tag ingestion (use `prompt_tags`)
You have two choices; pick one and stop overthinking it.

### Option A: rule-based tags (fast, deterministic)
- [ ] Create a simple tag dictionary keyed by folder names or filename tokens.
- [ ] Populate `tags` by inserting into `prompt_tags` for each prompt.

### Option B: LLM-assisted tags (better quality, more cost)
- [ ] Background job:
  - read prompt markdown
  - generate a small set of tags
  - insert into `prompt_tags`
  - set `processed=true` if you use it as “tagged” rather than “imported”

### Implementation notes
- [ ] Make `prompt_tags` unique on `(prompt_id, tag)` (if not already).
- [ ] Use `insert_all` with conflict handling for speed.

---

## 6) Search indexing (tsvector)
You already have `search_vector` and a trigger. Use it.

- [ ] Ensure `prompts_search_vector_update()` uses:
  - `title`
  - `description`
  - `prompt`
- [ ] Backfill search_vector for existing rows:
```sql
update prompts set updated_at = updated_at;
```
(Trigger should fire; if it doesn’t, explicitly recompute in SQL or a one-off migration.)

- [ ] Verify GIN index exists:
  - `idx_prompts_search_vector`

---

## 7) UI integration (minimal viable)
- [ ] List page:
  - title
  - description (first paragraph preview)
  - source badge
  - tags (from join table)
- [ ] Detail page:
  - render markdown prompt (sanitize HTML)
  - copy-to-clipboard button
  - “save” / “like” hooks (you already have counters)

---

## 8) Legal / attribution (don’t be sloppy)
- [ ] Keep LICENSE from upstream repo if present.
- [ ] Add attribution:
  - “Source: SabrinaRamonov/prompts”
  - Link to the repo and original file URL.

If license is unclear, don’t mirror full content publicly; link out instead.

---

## 9) Deployment checklist
- [ ] Run migrations in prod.
- [ ] Vendor snapshot included in build artifact (or run import in CI/CD).
- [ ] Run import task in prod once:
```bash
mix prompts.import_vendor_ramonov
```
- [ ] If tagging job exists, start it and monitor.

---

## 10) Definition of Done
- [ ] `prompts.tags` is removed; no code references it.
- [ ] Import task can be run repeatedly with **no duplicates**.
- [ ] Prompt detail pages render correctly.
- [ ] Search returns relevant prompts.
- [ ] Tags display from `prompt_tags` and are queryable.
- [ ] Attribution exists on every imported prompt.

---

## Appendix: Quick commands
```bash
mix ecto.migrate
mix prompts.import_vendor_ramonov
mix test
```
