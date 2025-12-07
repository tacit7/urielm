alias Urielm.{Repo, Content, Slugify}

IO.puts("Seeding blog posts...")

title = "Welcome to My Blog"

case Content.create_post(%{
  title: title,
  slug: Slugify.slugify(title),
  body: """
  # #{title}

  Welcome! This is your first blog post. You can write in **Markdown** format, which means:

  ## Features you can use:

  - **Bold text** using double asterisks
  - *Italic text* using single asterisks
  - `Code` inline using backticks
  - Code blocks using triple backticks

  ```elixir
  def hello(name) do
    IO.puts("Hello, \#{name}!")
  end
  ```

  You can also add:

  1. Numbered lists
  2. Like this one
  3. They're great for sequences

  Or bullet points:
  - Point one
  - Point two
  - Point three

  ### Links work too

  [Visit my website](https://urielm.dev)

  Happy writing!
  """,
  excerpt: "Welcome to the blog! This is your first post.",
  status: "published",
  published_at: DateTime.utc_now()
}) do
  {:ok, post} ->
    IO.puts("✓ Created blog post: #{post.title}")
  {:error, changeset} ->
    IO.puts("✗ Error creating blog post: #{inspect(changeset.errors)}")
end

IO.puts("\nSeed complete!")
