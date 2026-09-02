# Create forum categories and boards matching the action plan
alias Urielm.Repo
alias Urielm.Forum
alias Urielm.Accounts

# Create test users if they don't exist
user1 =
  Repo.get_by(Accounts.User, email: "alice@example.com") ||
    Repo.insert!(%Accounts.User{
      email: "alice@example.com",
      username: "alice",
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      email_verified: true
    })

user2 =
  Repo.get_by(Accounts.User, email: "bob@example.com") ||
    Repo.insert!(%Accounts.User{
      email: "bob@example.com",
      username: "bob",
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      email_verified: true
    })

user3 =
  Repo.get_by(Accounts.User, email: "charlie@example.com") ||
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

      existing ->
        existing
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

      existing ->
        existing
    end
  end
end

# Create categories (groupings)
cat_essentials =
  SeedHelpers.get_or_create_category(%{
    "name" => "Essentials",
    "slug" => "essentials"
  })

cat_general =
  SeedHelpers.get_or_create_category(%{
    "name" => "General",
    "slug" => "general"
  })

cat_community =
  SeedHelpers.get_or_create_category(%{
    "name" => "Community",
    "slug" => "community"
  })

IO.puts("Created categories: Essentials, General, Community")

# Create boards matching action plan
boards_config = [
  # Essentials
  {cat_essentials,
   %{
     "name" => "Start Here",
     "slug" => "start-here",
     "description" => "New to the community? Start here for guides and introductions"
   }},
  {cat_essentials,
   %{
     "name" => "Announcements",
     "slug" => "announcements",
     "description" => "Official announcements and updates"
   }},

  # General
  {cat_general,
   %{
     "name" => "Q&A Help Desk",
     "slug" => "qa",
     "description" => "Ask questions and get help from the community"
   }},
  {cat_general,
   %{
     "name" => "Prompting and Workflows",
     "slug" => "prompting",
     "description" => "Share and discuss prompts, workflows, and techniques"
   }},
  {cat_general,
   %{
     "name" => "Building with AI",
     "slug" => "building",
     "description" => "Projects, code, and technical discussions"
   }},
  {cat_general,
   %{
     "name" => "Model and Tool Talk",
     "slug" => "models-tools",
     "description" => "Discuss AI models, tools, and comparisons"
   }},

  # Community
  {cat_community,
   %{
     "name" => "Show and Tell",
     "slug" => "show-and-tell",
     "description" => "Share what you've built or discovered"
   }},
  {cat_community,
   %{
     "name" => "Feedback and Ideas",
     "slug" => "feedback",
     "description" => "Suggest improvements and share ideas"
   }},
  {cat_community,
   %{
     "name" => "Off-topic",
     "slug" => "off-topic",
     "description" => "Casual conversations and everything else"
   }}
]

boards =
  Enum.map(boards_config, fn {category, attrs} ->
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
  {board_start_here, user1, "Welcome to Urielm: Start Here",
   """
   Welcome to Urielm, a community for learning, building, and thinking clearly with AI.

   This forum is for people who want practical help and thoughtful discussion: better prompts, stronger workflows, useful tools, technical builds, and real examples from day-to-day work.

   A few good first steps:

   1. Browse the main boards to see where different conversations belong.
   2. Introduce yourself in a new thread or reply here with what you are working on.
   3. Ask a specific question in Q&A Help Desk if you are stuck.
   4. Share a prompt, workflow, build, lesson, or experiment when you have something others can learn from.

   The best posts here are concrete. Show the goal, the context, what you tried, and where you want help.
   """},
  {board_start_here, user1, "How to Ask a Good Question",
   """
   You do not need to be an expert to ask here. You will usually get better help when your question includes enough context for someone else to reason with you.

   A strong question includes:

   - What you are trying to accomplish
   - What tool, model, language, or platform you are using
   - What you already tried
   - What happened instead
   - Any constraints that matter, such as budget, deadline, privacy, or skill level

   Helpful title examples:

   - "How can I make this customer-support prompt handle refunds more consistently?"
   - "LiveView form validation works locally but fails in tests"
   - "Need a workflow for summarizing long research PDFs without losing citations"

   Less helpful title examples:

   - "Help"
   - "Prompt not working"
   - "What is the best AI tool?"

   If your post includes a prompt, error message, code snippet, or model output, paste the smallest useful version directly in the thread.
   """},
  {board_start_here, user2, "How to Share Prompts, Workflows, and Builds",
   """
   When you share something that worked for you, make it easy for other people to adapt it.

   For prompts, include:

   - The task the prompt is meant to solve
   - The prompt text
   - The model or tool you used
   - One example input and output if you can share it
   - What you would still improve

   For workflows, include:

   - The steps in order
   - The tools involved
   - Where human review fits
   - What can go wrong
   - A before-and-after example if possible

   For builds, include:

   - The problem you solved
   - The stack or tools
   - A screenshot, link, or short demo if available
   - What you learned
   - What feedback you want

   Good sharing posts do not need to be polished. They just need to be clear enough that someone else can learn from them.
   """},
  {board_start_here, user3, "Community Norms",
   """
   Urielm works best when discussion stays practical, generous, and specific.

   Please:

   - Assume people are learning at different levels.
   - Critique ideas, prompts, code, and workflows without attacking the person.
   - Share sources when you make factual claims.
   - Avoid posting private data, credentials, confidential documents, or other people's personal information.
   - Be clear when something is your opinion, a guess, or an experiment.
   - Keep promotion relevant and transparent.

   AI output can be useful, but it can also be wrong. When accuracy matters, verify important claims before relying on them.

   Moderators may edit, move, close, or remove posts that make the community harder to use. If you see a problem, report it rather than escalating the thread.
   """},
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

created_threads =
  Enum.map(thread_data, fn {board, user, title, body} ->
    slug =
      title
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
