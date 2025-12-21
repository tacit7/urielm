# Blog Posts System – Implementation Action Plan (Phoenix)

Goal: Add a proper **blog posts** system to your app, separate from lessons and courses, with clean URLs, Markdown content, and a basic publishing workflow.

---

## 0. High-level design

- **Post** = standalone long-form content
- URLs: `/blog/:slug`
- Storage:
  - `title`, `slug`, `body` (Markdown), `excerpt`, `status`, `published_at`
- Rendering:
  - Phoenix controller + HEEx templates (not LiveView)
  - Markdown → HTML at render time
- Relationship to lessons:
  - None initially (just link to posts from lessons manually)

---

## 1. Database: `posts` table

### 1.1 Create migration

Generate a migration:

```bash
mix ecto.gen.migration create_posts
```

Edit the migration:

```elixir
defmodule YourApp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :body, :text, null: false        # markdown
      add :excerpt, :text                  # optional teaser/summary
      add :status, :string, null: false, default: "draft"  # "draft" | "published"
      add :published_at, :utc_datetime
      add :author_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:posts, [:slug])
    create index(:posts, [:status])
    create index(:posts, [:published_at])
  end
end
```

Run it:

```bash
mix ecto.migrate
```

---

## 2. Domain: `Post` schema & context functions

### 2.1 Create schema file

Create `lib/your_app/content/post.ex`:

```elixir
defmodule YourApp.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "posts" do
    field :title, :string
    field :slug, :string
    field :body, :string           # markdown
    field :excerpt, :string
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime

    belongs_to :author, YourApp.Accounts.User

    timestamps()
  end

  @statuses ~w(draft published)

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :slug, :body, :excerpt, :status, :published_at, :author_id])
    |> validate_required([:title, :slug, :body, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:slug)
  end

  # Helper for published-only queries
  def published(query \\ __MODULE__) do
    from p in query,
      where: p.status == "published" and not is_nil(p.published_at) and p.published_at <= ^DateTime.utc_now()
  end
end
```

### 2.2 Context module

Create `lib/your_app/content.ex`:

```elixir
defmodule YourApp.Content do
  import Ecto.Query, warn: false
  alias YourApp.Repo
  alias YourApp.Content.Post

  # Public posts (for visitors)
  def list_published_posts do
    Post
    |> Post.published()
    |> order_by([p], desc: p.published_at)
    |> Repo.all()
  end

  def get_post_by_slug!(slug) do
    Post
    |> Post.published()
    |> Repo.get_by!(slug: slug)
  end

  # Admin/editor usage
  def list_all_posts do
    Repo.all(from p in Post, order_by: [desc: p.inserted_at])
  end

  def get_post!(id), do: Repo.get!(Post, id)

  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end
end
```

---

## 3. Slug handling

### 3.1 Utility to generate slugs

You can start simple: generate a slug in the controller or a helper.

Add a helper function (for now) in `Content` or a separate module:

```elixir
defmodule YourApp.Slugify do
  @doc """
  Turn a title like "My First Post!" into "my-first-post".
  """
  def slugify(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
```

Use this when creating new posts in the controller or admin UI.

Later you can move this into changesets (e.g. auto-populate slug if blank).

---

## 4. Controller & routes

### 4.1 Routes

In `lib/your_app_web/router.ex` under your public scope:

```elixir
scope "/", YourAppWeb do
  pipe_through :browser

  get "/blog", PostController, :index
  get "/blog/:slug", PostController, :show

  # existing routes...
end
```

### 4.2 PostController

Create `lib/your_app_web/controllers/post_controller.ex`:

```elixir
defmodule YourAppWeb.PostController do
  use YourAppWeb, :controller

  alias YourApp.Content

  def index(conn, _params) do
    posts = Content.list_published_posts()
    render(conn, :index, posts: posts, page_title: "Blog")
  end

  def show(conn, %{"slug" => slug}) do
    post = Content.get_post_by_slug!(slug)
    render(conn, :show, post: post, page_title: post.title)
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_flash(:error, "Post not found")
      |> redirect(to: ~p"/blog")
  end
end
```

---

## 5. Views & templates

Assuming you use Phoenix 1.7 view components, create:

### 5.1 View module

`lib/your_app_web/controllers/post_html.ex`:

```elixir
defmodule YourAppWeb.PostHTML do
  use YourAppWeb, :html

  embed_templates "post_html/*"

  import Phoenix.HTML.Tag

  def markdown_to_html(markdown) do
    # Minimal pipeline; replace with your preferred Markdown library
    Earmark.as_html!(markdown || "", %Earmark.Options{smartypants: false})
    |> Phoenix.HTML.raw()
  end
end
```

### 5.2 Index template

`lib/your_app_web/controllers/post_html/index.html.heex`:

```heex
<div class="max-w-3xl mx-auto px-4 py-8 space-y-6">
  <h1 class="text-3xl font-bold mb-4">Blog</h1>

  <%= if @posts == [] do %>
    <p class="text-base-content/60">
      No posts yet.
    </p>
  <% end %>

  <ul class="space-y-6">
    <%= for post <- @posts do %>
      <li class="border-b border-base-300 pb-4">
        <h2 class="text-xl font-semibold mb-1">
          <.link navigate={~p"/blog/#{post.slug}"} class="hover:text-primary">
            <%= post.title %>
          </.link>
        </h2>

        <p class="text-xs text-base-content/60 mb-2">
          <%= if post.published_at do %>
            <%= Calendar.strftime(post.published_at, "%b %d, %Y") %>
          <% end %>
        </p>

        <p class="text-sm text-base-content/80">
          <%= post.excerpt || String.slice(post.body, 0, 160) <> "..." %>
        </p>
      </li>
    <% end %>
  </ul>
</div>
```

### 5.3 Show template

`lib/your_app_web/controllers/post_html/show.html.heex`:

```heex
<div class="max-w-3xl mx-auto px-4 py-8">
  <p class="text-xs text-base-content/60 mb-2">
    <.link navigate={~p"/blog"} class="hover:text-primary">&larr; Back to blog</.link>
  </p>

  <h1 class="text-3xl font-bold mb-2">
    <%= @post.title %>
  </h1>

  <p class="text-xs text-base-content/60 mb-6">
    <%= if @post.published_at do %>
      <%= Calendar.strftime(@post.published_at, "%b %d, %Y") %>
    <% end %>
  </p>

  <article class="prose prose-sm sm:prose lg:prose-lg max-w-none">
    <%= markdown_to_html(@post.body) %>
  </article>
</div>
```

Make sure you have `prose` classes from Tailwind Typography plugin if you want nicer default styling.

---

## 6. Admin / authoring flow (minimal)

You can bootstrap authoring using `mix phx.gen.html` later, but for now a simple approach:

### 6.1 Seed a test post

In `priv/repo/seeds.exs`:

```elixir
alias YourApp.{Repo, Content.Post}
alias YourApp.Slugify

title = "My First Blog Post"

%Post{}
|> Post.changeset(%{
  title: title,
  slug: Slugify.slugify(title),
  body: """
  # #{title}

  This is your first post written in **Markdown**.

  - You can add lists
  - Code blocks
  - Links, etc.
  """,
  status: "published",
  published_at: DateTime.utc_now()
})
|> Repo.insert!()
```

Run:

```bash
mix run priv/repo/seeds.exs
```

Then visit: `http://localhost:4000/blog` and `http://localhost:4000/blog/my-first-blog-post`

### 6.2 Later: add an admin-only UI

When you care about actually editing posts in the browser, add:

- Admin scope in router
- LiveView or HTML forms for CRUD
- Auth checks on those routes

Not necessary for v1.

---

## 7. Integration with the rest of the app

### 7.1 Navigation

Add a link to the blog in your main nav / layout:

```heex
<.link navigate={~p"/blog"} class="btn btn-ghost btn-sm">
  Blog
</.link>
```

### 7.2 Linking from lessons

For now, just add manual links inside lesson bodies or description fields, e.g.:

```markdown
For more detail, read the blog post:
[Understanding Pattern Matching in Elixir](/blog/understanding-pattern-matching-in-elixir)
```

Later, if you want structured relationships, you can add a `lesson_posts` join table.

---

## 8. Quality & future improvements

Once basic posts work, you can iterate:

- Add:
  - `seo_title`, `seo_description`
  - `tags` or `categories` (when you have enough content)
  - `cover_image_url`
- Caching:
  - Cache rendered HTML per post if Markdown → HTML becomes a bottleneck.
- Search:
  - Add a simple full-text search on `title`, `body`, `excerpt`.

For now, just get the `posts` table, controller, and templates working and ship 2–3 real posts through it before adding complexity.

---

## 9. Execution checklist

1. Create `posts` table migration and run it.
2. Add `Post` schema in `YourApp.Content.Post`.
3. Add `Content` context helpers for listing and fetching posts.
4. Add slug helper for titles.
5. Add routes: `/blog` and `/blog/:slug`.
6. Implement `PostController` with `index` and `show`.
7. Add `PostHTML` view module and templates.
8. Seed at least one published post and verify rendering.
9. Add a "Blog" link to your main navigation.
10. Write actual content, then revisit admin UI and extras.
