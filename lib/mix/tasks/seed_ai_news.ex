defmodule Mix.Tasks.SeedAiNews do
  @moduledoc """
  Seeds the forum with 50+ AI news discussion posts from December 2025.
  Usage: mix seed_ai_news
  """
  use Mix.Task

  alias Urielm.{Repo, Forum, Accounts}
  alias Urielm.Accounts.User

  @shortdoc "Seeds forum with AI news posts"

  def run(_) do
    Mix.Task.run("app.start")

    IO.puts("🤖 Starting AI news seed...")

    # Get or create board
    {:ok, board} = get_or_create_board()

    # Get or create users
    users = ensure_users()

    # Create posts
    count = create_posts(board, users)

    IO.puts("✅ Seeded #{count} AI news posts!")
  end

  defp get_or_create_board do
    case Repo.get_by(Urielm.Forum.Board, slug: "ai-development") do
      nil ->
        category = Repo.get_by!(Urielm.Forum.Category, slug: "discussions")

        Forum.create_board(%{
          category_id: category.id,
          name: "AI & Development",
          slug: "ai-development",
          description: "Discuss AI development tools, costs, and the future of coding"
        })

      board ->
        {:ok, board}
    end
  end

  defp ensure_users do
    usernames = [
      "alex_dev",
      "sarah_codes",
      "tech_observer",
      "ai_skeptic",
      "code_enthusiast",
      "dev_insights",
      "ml_researcher",
      "startup_founder",
      "enterprise_dev",
      "open_source_fan"
    ]

    Enum.map(usernames, fn username ->
      case Repo.get_by(User, username: username) do
        nil ->
          {:ok, user} =
            Accounts.register_user(%{
              username: username,
              display_name: username,
              email: "#{username}@example.com",
              password: "password123"
            })

          user
          |> Ecto.Changeset.change(trust_level: 4, email_verified: true)
          |> Repo.update!()

        user ->
          user
      end
    end)
    |> Enum.into(%{}, fn user -> {user.username, user} end)
  end

  # AI News posts data
  @post_data [
    {"Claude Opus 4.5 beats every human candidate in engineering tests",
     "Anthropic just released Claude Opus 4.5, and the benchmarks are wild. It outperformed every human engineering candidate in their internal tests. This is a game changer for AI-assisted development. Anyone tried it yet?",
     "alex_dev", 45},
    {"AI coding tools hit 65% developer adoption rate",
     "Stack Overflow's 2025 survey shows 65% of developers using AI coding tools weekly. That's massive adoption in just 2 years. Are we seeing the end of traditional coding?",
     "sarah_codes", 38},
    {"Security nightmare: 30+ vulnerabilities found in AI coding tools",
     "Researchers discovered over 30 security flaws in popular AI-powered IDEs that allow data leaks and remote code execution. We need to talk about the security implications of these tools.",
     "tech_observer", 52},
    {"Software dev jobs for 22-25 year olds down 20% since 2022",
     "Stanford study shows junior dev employment dropped nearly 20% between 2022-2025. Is AI really replacing entry-level developers?",
     "ai_skeptic", 67},
    {"Cursor shows 1000% YoY growth, takes #1 position",
     "According to Brex Benchmark, Cursor demonstrated approximately 1000% year-over-year growth. How is everyone's experience with it?",
     "code_enthusiast", 41},
    {"Anthropic valued at $350 billion after Microsoft and Nvidia investment",
     "Anthropic just got a massive valuation boost to $350B with new investments from Microsoft and Nvidia. The AI arms race is heating up.",
     "dev_insights", 29},
    {"Claude Code acquired Bun, hits $1B milestone",
     "Anthropic acquired Bun as Claude Code reached $1 billion milestone in early December. What does this mean for the JavaScript ecosystem?",
     "ml_researcher", 33},
    {"95% of businesses found zero value in AI implementation",
     "MIT study found that 95% of businesses that tried AI found zero value. The hype vs reality gap is massive. Thoughts?",
     "startup_founder", 89},
    {"AI agents still failing at basic workplace tasks",
     "Upwork study shows agents from OpenAI, Google, and Anthropic fail many straightforward workplace tasks. Are we overselling AI capabilities?",
     "enterprise_dev", 56},
    {"SWE-bench scores jump from 33% to 70% in one year",
     "AI coding performance on SWE-bench went from 33% to 70%+ in just 12 months. The improvement rate is insane.",
     "open_source_fan", 44},
    {"Gemini 3 vs Claude Opus 4.5: The gap is narrowing",
     "Google's Gemini 3 and Claude Opus 4.5 are so close in performance that OpenAI went into 'code red' mode. Competition is driving innovation.",
     "alex_dev", 31},
    {"15 companies launched AI code generation tools this year",
     "Count them - 15 different companies introduced AI tools that generate code faster than humans write. Market is getting crowded.",
     "sarah_codes", 27},
    {"State AGs warn AI companies about chatbot violations",
     "Bipartisan group sent letters to Meta, Google, OpenAI warning their chatbots may violate state laws. Regulatory pressure is coming.",
     "tech_observer", 35},
    {"Microsoft reveals 7 AI trends for 2026",
     "Microsoft unveiled their prediction for next year's AI landscape. Focus is shifting from hype to real-world results.",
     "code_enthusiast", 22},
    {"Anthropic revenue: $1B to $5B in 8 months",
     "Anthropic's revenue jumped from $1 billion to over $5 billion in just 8 months. Insane growth trajectory.",
     "dev_insights", 41},
    {"Claude for Life Sciences launches",
     "Anthropic just announced Claude for Life Sciences. They're expanding beyond coding into scientific research.",
     "ml_researcher", 18},
    {"Accenture training 30,000 staff on Claude AI",
     "Accenture formed a Business Group with 30,000 professionals getting Claude training. Enterprise adoption is accelerating.",
     "startup_founder", 24},
    {"Snowflake + Anthropic: $200M partnership for agentic AI",
     "Snowflake and Anthropic announced $200M partnership to bring agentic AI to enterprises. December has been wild for announcements.",
     "enterprise_dev", 19},
    {"Anthropic IPO talks: One of the largest ever?",
     "Anthropic in early talks for what could be one of the largest IPOs ever. They're racing OpenAI to public markets.",
     "open_source_fan", 48},
    {"Claude available in Slack for team coding tasks",
     "Claude Code integration in Slack lets teams delegate coding from chat. Game changer for remote teams.",
     "alex_dev", 26},
    {"Is Cursor worth the cost?",
     "I'm paying almost as much for Cursor as I used to pay junior devs. Is anyone else concerned about the economics here?",
     "sarah_codes", 73},
    {"GitHub Copilot vs Cursor vs Codeium in 2025",
     "Tried all three extensively. Here's my take on which one actually delivers. What's your preference?",
     "tech_observer", 39},
    {"Claude Haiku 4.5: Fast and cheap but still powerful",
     "New Claude Haiku 4.5 matches coding capabilities from months ago at fraction of the cost. Perfect for high-volume tasks.",
     "code_enthusiast", 28},
    {"AI coding tools making developers lazy or more productive?",
     "Honest question: Are we becoming better developers or just better at prompting? The community seems split.",
     "dev_insights", 91},
    {"Free tier AI coding: Gemini vs Claude vs GPT",
     "Comparing free tiers for broke developers. Which one gives you the most value without paying?",
     "ml_researcher", 55},
    {"Lovable.dev pricing is getting out of control",
     "Anyone else notice Lovable's pricing keeps increasing? Used to be affordable, now it's enterprise-level costs.",
     "startup_founder", 62},
    {"Self-hosting LLMs for coding: DevStral 2 review",
     "Been running DevStral 2 locally. Open source LLMs are finally getting good enough for real work.",
     "enterprise_dev", 34},
    {"Token pricing trends: $30 to 6 cents in 3 years",
     "The cost of 1 million tokens dropped from $30 to 6 cents. Why would anyone think prices will increase?",
     "open_source_fan", 47},
    {"Agentic CLIs are replacing IDE extensions",
     "We're shifting from autocomplete in your editor to autonomous agents in the terminal. The paradigm is changing.",
     "alex_dev", 29},
    {"Claude Desktop vs Claude Web vs Claude Code",
     "What's the actual difference? When should you use each one? Confused about the ecosystem.",
     "sarah_codes", 36},
    {"AI infrastructure spending hits record highs",
     "Startups poured record amounts into AI infrastructure in 2025. Is this sustainable or another bubble?",
     "tech_observer", 44},
    {"Windsurf vs Cursor: Which agentic IDE is better?",
     "Both claim to be the best agentic IDE. Has anyone done a real comparison? I'm trying to choose.",
     "code_enthusiast", 51},
    {"Rate limiting killed my AI workflow",
     "Hit token-per-minute limits on Gemini and lost $75 in an hour. These rate limits are brutal for serious dev work.",
     "dev_insights", 68},
    {"Claude's computer use API is underrated",
     "Everyone talks about coding, but Claude's computer use capability is wild. It can control your entire desktop.",
     "ml_researcher", 32},
    {"OpenAI's defensive posture after Claude and Gemini releases",
     "OpenAI went 'code red' after seeing Claude Opus 4.5 and Gemini 3 performance. Competition is good for us.",
     "startup_founder", 38},
    {"Local AI coding: Worth the GPU investment?",
     "Thinking about buying a 4090 to run models locally. Is it worth it vs paying for API access?",
     "enterprise_dev", 49},
    {"Bolt.new vs Lovable vs v0: AI webapp builders compared",
     "Tested all three popular AI webapp builders. Results surprised me. Here's what actually worked.",
     "open_source_fan", 42},
    {"Anthropic's safety research vs capability research balance",
     "Anthropic claims to focus on safety, but they're releasing powerful models faster than anyone. What's the real priority?",
     "alex_dev", 54},
    {"Junior devs: Should you even learn to code in 2025?",
     "With 20% drop in entry-level jobs and AI doing basic coding, what should new developers focus on?",
     "sarah_codes", 103},
    {"Context windows hitting 1M+ tokens: What's the impact?",
     "Claude has 1M token context. Gemini went to 2M. What does this enable that we couldn't do before?",
     "tech_observer", 31},
    {"AI pair programming: Helpful or harmful for skill development?",
     "Been using Cursor for 6 months. I've shipped more but I'm worried I'm not learning fundamentals anymore.",
     "code_enthusiast", 76},
    {"Prompt engineering is the new skill developers need",
     "Writing good prompts is becoming more important than knowing syntax. Is this the future?",
     "dev_insights", 58},
    {"Claude API costs vs subscription: Which is cheaper?",
     "Running the numbers on API usage vs $20/month subscription. The math doesn't add up the way you'd think.",
     "ml_researcher", 37},
    {"AI coding tools and the VC subsidy problem",
     "These tools are heavily subsidized by VC money. What happens when they need to turn a profit?",
     "startup_founder", 81},
    {"Cursor's custom model: Necessary or gimmick?",
     "Cursor built their own model because API costs were too high. Is this the future for all AI tools?",
     "enterprise_dev", 29},
    {"Multi-model strategy: Use different AI for different tasks",
     "I use Sonnet for most work, Opus for complex stuff, Gemini when stuck. Anyone else mixing models?",
     "open_source_fan", 45},
    {"AI debugging is still terrible",
     "AI is great at writing code but awful at debugging. The hallucinations make it worse sometimes.",
     "alex_dev", 64},
    {"Should AI code need human review?",
     "Our team requires all AI-generated code to be reviewed. Others ship it directly. What's your policy?",
     "sarah_codes", 72},
    {"Token limits forcing me to chunk my codebase",
     "Even with 1M context, I can't fit my entire codebase. How are you all handling this?",
     "tech_observer", 41},
    {"Claude extended thinking: Worth the extra cost?",
     "The new extended thinking mode is amazing but expensive. When is it actually worth using?",
     "code_enthusiast", 33},
    {"AI testing tools: Do they actually work?",
     "Tried several AI test generation tools. Most produce garbage tests. Any recommendations?",
     "dev_insights", 47},
    {"Anthropic vs OpenAI: Which has better developer tools?",
     "Comparing ecosystems - APIs, documentation, pricing, features. Which would you choose?",
     "ml_researcher", 36},
    {"GPU shortage affecting AI development timelines",
     "Can't get H100s or even good consumer GPUs. Is this bottleneck slowing down AI progress?",
     "startup_founder", 28},
    {"Claude's constitutional AI approach actually working?",
     "Anthropic talks a lot about safety. Is their constitutional AI approach making a difference?",
     "enterprise_dev", 31},
    {"Gemini free tier is surprisingly good",
     "Using Gemini's free API tier with generous limits. It's been solid for side projects.",
     "open_source_fan", 39},
    {"AI code review tools: Helpful or annoying?",
     "Integrated AI code review into our PR process. Team is split on whether it's useful.",
     "alex_dev", 42},
    {"Will AI coding tools consolidate or fragment?",
     "We have 15+ major tools now. Market consolidation coming or will it stay fragmented?",
     "sarah_codes", 34},
    {"Real cost of running AI coding tools at scale",
     "Our engineering team of 50 spent $47K last month on AI tools. Is this normal?",
     "tech_observer", 88},
    {"DeepSeek vs Western AI models: Performance gap closing?",
     "Chinese AI models are catching up fast and cheaper. Should we be paying attention?",
     "code_enthusiast", 43},
    {"AI-generated tech debt is accumulating",
     "We shipped fast with AI but now have massive tech debt from poorly structured AI code. Warning to others.",
     "dev_insights", 71},
    {"Claude Code vs Cursor vs Windsurf: 2025 shootout",
     "Did a comprehensive comparison. Each has strengths. Here's my breakdown for different use cases.",
     "ml_researcher", 53},
    {"Anthropic's $13B raise: What are they building?",
     "They raised $13B at $183B valuation. Revenue is $5B+. What's the endgame here?",
     "startup_founder", 37},
    {"API vs local models: TCO analysis",
     "Ran the numbers on total cost of ownership for API access vs self-hosting. Results were surprising.",
     "enterprise_dev", 46},
    {"AI coding killed my motivation to learn",
     "Honest confession: AI makes coding so easy that I've lost motivation to understand things deeply. Anyone else?",
     "open_source_fan", 94},
    {"Prompt libraries: Share your best coding prompts",
     "Building a collection of effective prompts for different coding tasks. What are your go-to prompts?",
     "alex_dev", 49},
    {"Multi-file edits: Which AI handles them best?",
     "Tested multiple AI tools on complex multi-file refactors. Clear winner emerged.",
     "sarah_codes", 38},
    {"AI coding in regulated industries",
     "Working in healthcare tech. Legal is blocking AI code tools. How are you handling compliance?",
     "tech_observer", 32},
    {"The great AI correction of 2025",
     "MIT Tech Review called it the 'great AI hype correction.' Are expectations finally becoming realistic?",
     "code_enthusiast", 55},
    {"Anthropic IPO timing: Before or after OpenAI?",
     "Both racing to go public. Which happens first and does it matter?", "dev_insights", 27},
    {"AI coding tools and open source sustainability",
     "If AI can generate code, who maintains open source? The incentive structure is breaking.",
     "ml_researcher", 61},
    {"Claude in Excel: Actually useful or gimmick?",
     "Anthropic integrated Claude into Excel. Has anyone found real use cases for this?",
     "startup_founder", 23},
    {"Agentic AI vs copilot mode: What's better?",
     "Full autonomous agents vs AI assistants. Which model works better for real development?",
     "enterprise_dev", 48},
    {"Token pricing predictions for 2026",
     "Current trend is down, but VC subsidy ending. What's everyone's prediction for next year's pricing?",
     "open_source_fan", 52},
    {"AI code quality: Getting better or worse?",
     "6 months of AI-assisted development. Our code quality metrics tell an interesting story.",
     "alex_dev", 44},
    {"Claude vs GPT-4 for system design discussions",
     "Both are good at code, but which is better for high-level architecture conversations?",
     "sarah_codes", 36},
    {"Snowflake's $200M bet on Anthropic",
     "Snowflake investing heavily in bringing Claude to data warehouses. Big implications for data engineering.",
     "tech_observer", 29},
    {"Developer skill evolution in the AI era",
     "Traditional coding skills matter less. What skills should developers focus on now?",
     "code_enthusiast", 79},
    {"AI infrastructure costs: The hidden expense",
     "Everyone talks about subscription costs. Nobody talks about the infrastructure needed to support AI workflows.",
     "dev_insights", 41},
    {"Accenture's 30K Claude-trained consultants",
     "Accenture training 30,000 people on Claude. Enterprise adoption is real now.",
     "ml_researcher", 26}
  ]

  defp create_posts(board, users) do
    total = length(@post_data)
    IO.puts("\n📝 Creating #{total} posts...")

    user_list = Map.values(users)

    Enum.with_index(@post_data, 1)
    |> Enum.each(fn {{title, body, preferred_author, score}, index} ->
      # Use preferred author if exists, otherwise random
      author =
        Map.get(users, preferred_author) || Enum.random(user_list)

      slug = Urielm.Slugify.slugify(title) <> "-#{System.unique_integer([:positive])}"

      case Forum.create_thread(board.id, author.id, %{
             title: title,
             slug: slug,
             body: body
           }) do
        {:ok, thread} ->
          # Add upvotes
          add_upvotes(thread, user_list, score)

          if rem(index, 10) == 0 do
            IO.puts("  ✓ Created #{index}/#{total} posts")
          end

        {:error, changeset} ->
          IO.inspect(changeset.errors, label: "Error creating post #{index}")
      end
    end)

    IO.puts("  ✓ All posts created")
    total
  end

  defp add_upvotes(thread, users, target_score) do
    users
    |> Enum.take_random(min(target_score, length(users)))
    |> Enum.each(fn user ->
      Forum.cast_vote(user.id, "thread", thread.id, 1)
    end)
  end
end
