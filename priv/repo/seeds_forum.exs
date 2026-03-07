# Create forum categories and boards matching the action plan
alias Urielm.Repo
alias Urielm.Forum
alias Urielm.Accounts

# Create test users if they don't exist
user1 = Repo.get_by(Accounts.User, email: "alice@example.com") ||
  Repo.insert!(%Accounts.User{
    email: "alice@example.com",
    username: "alice",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    email_verified: true
  })

user2 = Repo.get_by(Accounts.User, email: "bob@example.com") ||
  Repo.insert!(%Accounts.User{
    email: "bob@example.com",
    username: "bob",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    email_verified: true
  })

user3 = Repo.get_by(Accounts.User, email: "charlie@example.com") ||
  Repo.insert!(%Accounts.User{
    email: "charlie@example.com",
    username: "charlie",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    email_verified: true
  })

IO.puts("Created users: alice, bob, charlie")

# Helper to get or create category
defmodule SeedHelpers do
  def get_or_create_category(attrs) do
    alias Urielm.{Repo, Forum}
    case Repo.get_by(Forum.Category, slug: attrs["slug"]) do
      nil ->
        case Forum.create_category(attrs) do
          {:ok, cat} -> cat
          {:error, _} -> Repo.get_by(Forum.Category, slug: attrs["slug"])
        end
      existing -> existing
    end
  end

  def get_or_create_board(attrs) do
    alias Urielm.{Repo, Forum}
    case Repo.get_by(Forum.Board, slug: attrs["slug"]) do
      nil ->
        case Forum.create_board(attrs) do
          {:ok, board} -> board
          {:error, _} -> Repo.get_by(Forum.Board, slug: attrs["slug"])
        end
      existing -> existing
    end
  end
end

# Create categories (groupings)
cat_essentials = SeedHelpers.get_or_create_category(%{
  "name" => "Essentials",
  "slug" => "essentials"
})

cat_general = SeedHelpers.get_or_create_category(%{
  "name" => "General",
  "slug" => "general"
})

cat_community = SeedHelpers.get_or_create_category(%{
  "name" => "Community",
  "slug" => "community"
})

IO.puts("Created categories: Essentials, General, Community")

# Create boards matching action plan
boards_config = [
  # Essentials
  {cat_essentials, %{
    "name" => "Start Here",
    "slug" => "start-here",
    "description" => "New to the community? Start here for guides and introductions"
  }},
  {cat_essentials, %{
    "name" => "Announcements",
    "slug" => "announcements",
    "description" => "Official announcements and updates"
  }},

  # General
  {cat_general, %{
    "name" => "Q&A Help Desk",
    "slug" => "qa",
    "description" => "Ask questions and get help from the community"
  }},
  {cat_general, %{
    "name" => "Prompting and Workflows",
    "slug" => "prompting",
    "description" => "Share and discuss prompts, workflows, and techniques"
  }},
  {cat_general, %{
    "name" => "Building with AI",
    "slug" => "building",
    "description" => "Projects, code, and technical discussions"
  }},
  {cat_general, %{
    "name" => "Model and Tool Talk",
    "slug" => "models-tools",
    "description" => "Discuss AI models, tools, and comparisons"
  }},

  # Community
  {cat_community, %{
    "name" => "Show and Tell",
    "slug" => "show-and-tell",
    "description" => "Share what you've built or discovered"
  }},
  {cat_community, %{
    "name" => "Feedback and Ideas",
    "slug" => "feedback",
    "description" => "Suggest improvements and share ideas"
  }},
  {cat_community, %{
    "name" => "Off-topic",
    "slug" => "off-topic",
    "description" => "Casual conversations and everything else"
  }}
]

boards = Enum.map(boards_config, fn {category, attrs} ->
  board = SeedHelpers.get_or_create_board(Map.put(attrs, "category_id", category.id))
  IO.puts("  Board: #{board.name}")
  board
end)

IO.puts("Created #{length(boards)} boards")

# Get specific boards for seeding threads
board_start_here = Enum.find(boards, &(&1.slug == "start-here"))
board_qa = Enum.find(boards, &(&1.slug == "qa"))
board_prompting = Enum.find(boards, &(&1.slug == "prompting"))
board_building = Enum.find(boards, &(&1.slug == "building"))
board_show_tell = Enum.find(boards, &(&1.slug == "show-and-tell"))
board_feedback = Enum.find(boards, &(&1.slug == "feedback"))

# Create sample threads
thread_data = [
  {board_start_here, user1, "Welcome to the Community!",
   "Welcome! This is your new home for discussing AI, prompts, and building cool things. Take a look around and introduce yourself."},

  {board_qa, user2, "How do I write better prompts?",
   "I'm new to prompting and want to improve. What are some techniques for getting better responses from LLMs? Looking for practical tips."},

  {board_qa, user3, "Best practices for system prompts?",
   "What makes a good system prompt? Should I be specific or general? How long should they be? Would love to see examples."},

  {board_prompting, user1, "My favorite prompt patterns",
   "After months of experimenting, here are the prompt patterns that work best for me:\n\n1. **Role + Task + Context** - Always specify who the AI should be\n2. **Few-shot examples** - Show don't tell\n3. **Chain of thought** - Ask it to think step by step\n\nWhat patterns work for you?"},

  {board_building, user2, "Built a CLI tool with Claude",
   "Just finished building a CLI tool that uses Claude for code review. It scans your git diff and provides feedback. Would love your thoughts on the approach."},

  {board_building, user3, "Phoenix + LiveView + AI = Amazing",
   "Been integrating AI into my Phoenix app and the developer experience is incredible. LiveView streams work perfectly for streaming responses. Here's what I learned..."},

  {board_show_tell, user1, "Created an AI-powered resume reviewer",
   "Sharing my weekend project: an app that reviews resumes using AI and provides actionable feedback. Built with Elixir and Claude. Link in comments!"},

  {board_feedback, user2, "Suggestion: Dark mode toggle",
   "Would love to have a quick dark mode toggle in the navbar. Currently have to go to settings each time."}
]

created_threads = Enum.map(thread_data, fn {board, user, title, body} ->
  slug = title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> String.slice(0, 50)

  case Forum.create_thread(board.id, user.id, %{
    "title" => title,
    "body" => body,
    "slug" => slug
  }) do
    {:ok, thread} ->
      # Note: mark_as_solved skipped due to params normalization bug
      thread
    {:error, _} ->
      IO.puts("  Skipping duplicate thread: #{title}")
      nil
  end
end)
|> Enum.reject(&is_nil/1)

IO.puts("Created #{length(created_threads)} threads")

# Add comments
if length(created_threads) > 0 do
  Enum.each(Enum.take(created_threads, 3), fn thread ->
    Forum.create_comment(thread.id, user2.id, %{
      "body" => "Great post! Thanks for sharing."
    })
    Forum.create_comment(thread.id, user3.id, %{
      "body" => "This is really helpful. I had the same question."
    })
  end)
  IO.puts("Added comments to threads")

  # Add votes
  Enum.each(created_threads, fn thread ->
    Forum.cast_vote(user1.id, "thread", thread.id, 1)
    Forum.cast_vote(user2.id, "thread", thread.id, 1)
    Forum.cast_vote(user3.id, "thread", thread.id, 1)
  end)
  IO.puts("Added votes to threads")
end

# Create tags
tags = [
  %{"name" => "Beginner", "slug" => "beginner"},
  %{"name" => "Advanced", "slug" => "advanced"},
  %{"name" => "Tutorial", "slug" => "tutorial"},
  %{"name" => "Discussion", "slug" => "discussion"},
  %{"name" => "Claude", "slug" => "claude"},
  %{"name" => "GPT", "slug" => "gpt"},
  %{"name" => "Elixir", "slug" => "elixir"},
  %{"name" => "Phoenix", "slug" => "phoenix"}
]

Enum.each(tags, fn attrs ->
  case Forum.create_tag(attrs) do
    {:ok, _} -> :ok
    {:error, _} -> :ok
  end
end)
IO.puts("Created tags")

IO.puts("\n✅ Forum seed data created successfully!")
IO.puts("\nCategories:")
IO.puts("  - Essentials (Start Here, Announcements)")
IO.puts("  - General (Q&A, Prompting, Building, Models & Tools)")
IO.puts("  - Community (Show and Tell, Feedback, Off-topic)")
IO.puts("\nTest Accounts:")
IO.puts("  alice@example.com / password123")
IO.puts("  bob@example.com / password123")
IO.puts("  charlie@example.com / password123")
