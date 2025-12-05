# Prompt Search System – Action Plan

Goal: Make the **prompts** table power a **user-friendly** search UI so normal humans can find prompts without knowing anything about Postgres.

---

## 1. Data Model & Migrations

### 1.1. Create / verify `prompts` table

- [ ] Ensure the `prompts` table exists with these columns:
  - `id BIGSERIAL PRIMARY KEY`
  - `title VARCHAR(255) NOT NULL`
  - `url VARCHAR(255) NOT NULL`
  - `description TEXT`
  - `category VARCHAR(255) NOT NULL`
  - `tags VARCHAR(255)[]`
  - `inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
  - `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- [ ] Confirm Ecto timestamps use `utc_datetime_usec`.

If not present, add a migration to create it.

### 1.2. Add `search_vector` column

- [ ] Add a generated `tsvector` column on `prompts`:

  ```sql
  ALTER TABLE prompts
  ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (
    setweight(coalesce(to_tsvector('simple', title), ''), 'A')
    || setweight(coalesce(to_tsvector('simple', category), ''), 'B')
    || setweight(coalesce(to_tsvector('simple', array_to_string(tags, ' ')), ''), 'C')
    || setweight(coalesce(to_tsvector('simple', description), ''), 'D')
  ) STORED;
  ```

- [ ] Add index for search:

  ```sql
  CREATE INDEX idx_prompts_search_vector
    ON prompts
    USING GIN (search_vector);
  ```

- [ ] Add index on category for filtering:

  ```sql
  CREATE INDEX idx_prompts_category
    ON prompts (category);
  ```

### 1.3. Enable trigram extension (for typo tolerance, optional but recommended)

- [ ] Add migration to enable `pg_trgm`:

  ```sql
  CREATE EXTENSION IF NOT EXISTS pg_trgm;
  ```

- [ ] Add GIN index on title:

  ```sql
  CREATE INDEX idx_prompts_title_trgm
  ON prompts
  USING GIN (title gin_trgm_ops);
  ```

---

## 2. Ecto Schema & Changeset

**File:** `lib/my_app/prompts/prompt.ex` (adjust namespace)

- [ ] Define schema:

  ```elixir
  schema "prompts" do
    field :title, :string
    field :url, :string
    field :description, :string
    field :category, :string
    field :tags, {:array, :string}

    # virtual rank field for search results
    field :rank, :float, virtual: true

    timestamps(type: :utc_datetime_usec)
  end
  ```

- [ ] Define changeset validation:

  ```elixir
  @required_fields ~w(title url category)a
  @optional_fields ~w(description tags)a

  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, max: 255)
    |> validate_length(:url, max: 255)
    |> validate_length(:category, max: 255)
    |> validate_format(:url, ~r/^https?:\/\//i)
  end
  ```

---

## 3. Search API (Backend)

Create / update your context module, e.g. `lib/my_app/prompts.ex`.

### 3.1. Base query with filters

- [ ] Implement a helper to apply filters:

  ```elixir
  defp base_query(opts) do
    import Ecto.Query

    base = from p in Prompt

    base =
      case Map.get(opts, :category) do
        nil -> base
        category -> from p in base, where: p.category == ^category
      end

    base =
      case Map.get(opts, :tags) do
        nil -> base
        [] -> base
        tags -> from p in base, where: fragment("? && ?", p.tags, ^tags)
      end

    base
  end
  ```

### 3.2. Full-text search with `plainto_tsquery`

- [ ] Implement user-friendly search that accepts plain text:

  ```elixir
  def search_prompts(search_text, opts \ %{}) do
    import Ecto.Query
    alias MyApp.Repo

    query_text = search_text |> to_string() |> String.trim()
    base = base_query(opts)

    cond do
      query_text == "" ->
        Repo.all(from p in base, order_by: [asc: p.title])

      true ->
        ft_query =
          from p in base,
            where:
              fragment(
                "search_vector @@ plainto_tsquery('simple', ?)",
                ^query_text
              ),
            select_merge: %{
              rank:
                fragment(
                  "ts_rank(search_vector, plainto_tsquery('simple', ?))",
                  ^query_text
                )
            },
            order_by: [desc: fragment("rank")]

        results = Repo.all(ft_query)

        if results == [] do
          fuzzy_fallback(query_text, base)
        else
          results
        end
    end
  end
  ```

### 3.3. Fuzzy fallback with trigram similarity

- [ ] Implement trigram fallback when full-text search returns nothing:

  ```elixir
  defp fuzzy_fallback(query_text, base) do
    import Ecto.Query
    alias MyApp.Repo

    fuzzy_query =
      from p in base,
        where: fragment("similarity(?, ?) > 0.2", p.title, ^query_text),
        order_by: [desc: fragment("similarity(?, ?)", p.title, ^query_text)]

    Repo.all(fuzzy_query)
  end
  ```

### 3.4. Add a simple REST/JSON endpoint

- [ ] Create an endpoint like `GET /api/prompts/search` with query params:
  - `q` (string, optional)
  - `category` (string, optional)
  - `tags[]` (array, optional)

- [ ] Response shape (example):

  ```json
  [
    {
      "id": 1,
      "title": "TikTok Hook Generator",
      "url": "https://...",
      "description": "Generate hooks for short-form video",
      "category": "tiktok",
      "tags": ["hook", "shorts", "video"],
      "rank": 0.71234
    }
  ]
  ```

---

## 4. Frontend UX Plan

Goal: make search feel simple and instant for users who just want “good prompts for X”.

### 4.1. Search bar

- [ ] Single prominent input at the top:
  - Placeholder: `Search prompts, e.g. "tiktok hooks", "email subject line"`
  - Debounced search request (300–400 ms) on input change.
  - Press Enter triggers immediate search.

### 4.2. Filters

- [ ] Category filter (chips or dropdown):
  - Show “All” + known categories from DB.
  - Clicking a category calls the same search endpoint with `category` param.

- [ ] Tag filter (optional v2):
  - Multi-select tags or show a tag cloud.
  - Each clicked tag adds to `tags[]` in the API request.

### 4.3. Results list

For each prompt result show:

- [ ] Title (clickable, opens details or copies prompt).
- [ ] Category badge.
- [ ] Short description (truncate long text).
- [ ] Tags as clickable chips (`#tiktok`, `#hook`, etc.).
- [ ] Primary call-to-action button:
  - `Copy prompt` or `Use prompt`.

### 4.4. Empty state

- [ ] If no results:
  - Show message: `No prompts found for "QUERY".`
  - Suggest:
    - Related categories.
    - Top tags.
    - Maybe a “Try searching just 'tiktok' or 'hook'” hint.

### 4.5. Loading and error states

- [ ] Show a subtle loading spinner while search is in progress.
- [ ] Show a non-annoying error state if the API fails:
  - `Something went wrong while searching. Please try again.`

---

## 5. Data Import from Sabrina’s Library

### 5.1. Export / scrape source data

- [ ] Export the Notion table to CSV or JSON.
- [ ] Inspect columns and map to:
  - `title`
  - `url`
  - `description`
  - `category`
  - `tags`

### 5.2. Normalize categories and tags

- [ ] Decide on a clean category list (`"tiktok"`, `"email"`, `"marketing"`, etc.).
- [ ] Normalize variations (`"TikTok"`, `"tik tok"` → `"tiktok"`).
- [ ] Standardize tag style:
  - lower_snake_case or kebab-case, e.g. `short_form`, `yt_shorts`, `hook`.

### 5.3. Bulk import

- [ ] Write a one-off mix task or script:
  - Parse CSV/JSON.
  - Clean / normalize categories and tags.
  - Insert via `Repo.insert_all/3` into `prompts`.

- [ ] Verify `search_vector` is populated automatically (generated column).

---

## 6. Testing

### 6.1. Unit tests

- [ ] Add tests for `MyApp.Prompts.search_prompts/2`:
  - Empty query returns alphabetized list.
  - Simple term (`"tiktok"`) matches expected prompts.
  - Phrase (`"tiktok hooks for carousels"`) returns relevant items.
  - Category filter limits results correctly.
  - Tag filter limits results correctly.
  - When FTS has no match but trigram does, results still appear.

### 6.2. Integration / feature tests

- [ ] Add tests that hit the search API endpoint and assert JSON structure and ordering.

---

## 7. Performance & Monitoring

- [ ] Confirm queries use the GIN index on `search_vector` (check with `EXPLAIN ANALYZE`).
- [ ] Verify trigram index is used for fuzzy queries.
- [ ] Add simple logging or metrics:
  - Track search query string.
  - Track number of results returned.
  - Optional: top queries for future UX improvements.

---

## 8. Future Enhancements (Nice-to-have)

- [ ] Add “Most popular prompts” list (by usage count or copy count).
- [ ] Allow users to “star” or “favorite” prompts.
- [ ] Add simple synonym handling (e.g. `ig` → `instagram`, `yt` → `youtube`).
- [ ] Add multilingual support if you ever include non-English prompt sets.
- [ ] Add curated collections (e.g. “Starter pack for TikTok creators”).

---

This is enough to build a **real** prompt search feature:
- sensible schema
- robust search behavior
- straightforward API
- UI patterns that feel natural to non-technical users.
