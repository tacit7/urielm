# Script for populating the database with prompts from SabrinaRamonov/prompts repo
alias Urielm.{Repo, Content, Slugify}
alias Urielm.Content.Prompt

prompts_dir = Path.expand("~/projects/prompts")

# Category mapping based on filename patterns
defmodule PromptCategorizer do
  def categorize(filename) do
    filename_lower = String.downcase(filename)

    cond do
      String.contains?(filename_lower, ["ai_", "chatgpt", "gpt", "automation"]) -> "ai"
      String.contains?(filename_lower, ["marketing", "seo", "content", "social_media", "instagram", "tiktok", "youtube"]) -> "marketing"
      String.contains?(filename_lower, ["business", "entrepreneur", "startup", "saas"]) -> "business"
      String.contains?(filename_lower, ["code", "coding", "programming", "software", "developer"]) -> "coding"
      String.contains?(filename_lower, ["adhd", "productivity", "goal", "habit", "mindfulness"]) -> "productivity"
      String.contains?(filename_lower, ["course", "learning", "education", "training", "teaching"]) -> "education"
      String.contains?(filename_lower, ["writing", "book", "story", "screenplay", "novel"]) -> "writing"
      String.contains?(filename_lower, ["finance", "investment", "trading", "crypto", "stock"]) -> "finance"
      String.contains?(filename_lower, ["career", "resume", "interview", "job", "linkedin"]) -> "career"
      String.contains?(filename_lower, ["data", "analysis", "research", "analyze"]) -> "analysis"
      true -> "prompts"
    end
  end

  def extract_description(content) do
    # Take first non-empty line, limit to 200 chars
    content
    |> String.split("\n")
    |> Enum.find("", fn line -> String.trim(line) != "" end)
    |> String.slice(0..199)
  end

  def title_from_filename(filename) do
    filename
    |> String.replace(".md", "")
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end

IO.puts("Starting to import prompts from #{prompts_dir}...")

# Get all markdown files
files = Path.wildcard(Path.join(prompts_dir, "*.md"))

IO.puts("Found #{length(files)} prompt files")

# Process each file
files
|> Enum.with_index(1)
|> Enum.each(fn {file_path, index} ->
  filename = Path.basename(file_path)

  # Read file content
  content = File.read!(file_path)

  # Extract metadata
  title = PromptCategorizer.title_from_filename(filename)
  description = PromptCategorizer.extract_description(content)
  category = PromptCategorizer.categorize(filename)

  # Create URL to the GitHub file
  url = "https://github.com/SabrinaRamonov/prompts/blob/main/#{URI.encode(filename)}"

  # Create prompt
  case Content.create_prompt(%{
    title: title,
    url: url,
    description: description,
    category: category,
    tags: ["prompt", category]
  }) do
    {:ok, _ref} ->
      if rem(index, 100) == 0 do
        IO.puts("Imported #{index}/#{length(files)} prompts...")
      end
    {:error, changeset} ->
      IO.puts("Error importing #{filename}: #{inspect(changeset.errors)}")
  end
end)

IO.puts("\nImport complete!")
IO.puts("Total prompts imported: #{Repo.aggregate(Prompt, :count, :id)}")

# Show category breakdown
categories = Content.list_categories()
IO.puts("\nCategories created:")
Enum.each(categories, fn category ->
  count = length(Content.list_prompts_by_category(category))
  IO.puts("  #{category}: #{count}")
end)

# Seed a test blog post
IO.puts("\n\nSeeding blog posts...")

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

# Chat test data
IO.puts("\n\nSeeding chat test data...")

alias Urielm.Accounts
alias Urielm.Chat

# Clean up existing test users and data
Repo.query!("DELETE FROM messages WHERE user_id IN (SELECT id FROM users WHERE email IN ('alice@test.com', 'bob@test.com'))")
Repo.query!("DELETE FROM room_memberships WHERE user_id IN (SELECT id FROM users WHERE email IN ('alice@test.com', 'bob@test.com'))")
Repo.query!("DELETE FROM users WHERE email IN ('alice@test.com', 'bob@test.com')")

# Create two test users
{:ok, user1} = Accounts.register_user(%{
  "email" => "alice@test.com",
  "password" => "password123",
  "username" => "Alice"
})

{:ok, user2} = Accounts.register_user(%{
  "email" => "bob@test.com",
  "password" => "password123",
  "username" => "Bob"
})

IO.puts("✓ Created users:")
IO.puts("  Alice (ID: #{user1.id}) - alice@test.com")
IO.puts("  Bob (ID: #{user2.id}) - bob@test.com")

# Create a chat room
{:ok, room} = Chat.create_room(%{
  name: "general",
  description: "General discussion",
  created_by_id: user1.id
})

IO.puts("\n✓ Created room: ##{room.name} (ID: #{room.id})")

# Add both users as members
Chat.add_member(user1.id, room.id)
Chat.add_member(user2.id, room.id)

IO.puts("✓ Added both users to room")

# Create test messages
messages = [
  {user1.id, "Hey Bob! How's it going?"},
  {user2.id, "Hi Alice! Doing great, thanks for asking."},
  {user1.id, "That's awesome!"},
  {user1.id, "Want to grab coffee later?"},
  {user2.id, "Sure! Let's meet at the usual place around 3 PM."},
  {user1.id, "Perfect, see you then!"},
]

Enum.each(messages, fn {user_id, body} ->
  {:ok, _msg} = Chat.create_message(%{
    body: body,
    user_id: user_id,
    room_id: room.id
  })
end)

IO.puts("\n✓ Created #{length(messages)} test messages")
IO.puts("\n📝 Test Credentials:")
IO.puts("  Alice: alice@test.com / password123")
IO.puts("  Bob: bob@test.com / password123")
IO.puts("\nVisit /chat and log in with either account to see the conversation!")
