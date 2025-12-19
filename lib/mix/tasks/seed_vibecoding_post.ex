defmodule Mix.Tasks.SeedVibeCodingPost do
  @moduledoc """
  Seeds the forum with the r/vibecoding post about AI development costs.
  Usage: mix seed_vibecoding_post
  """
  use Mix.Task

  alias Urielm.{Repo, Forum}
  alias Urielm.Accounts.User

  @shortdoc "Seeds forum with r/vibecoding post content"

  def run(_) do
    Mix.Task.run("app.start")

    IO.puts("🎯 Starting vibecoding post seed...")

    # Create category and board
    {:ok, category} = create_category()
    {:ok, board} = create_board(category)

    # Create users
    users = create_users()

    # Create main thread
    {:ok, thread} = create_main_thread(board, users)

    # Create comments
    create_comments(thread, users)

    IO.puts("✅ Vibecoding post seeded successfully!")
    IO.puts("📍 Thread: #{thread.slug}")
  end

  defp create_category do
    case Forum.create_category(%{
           name: "Discussions",
           slug: "discussions",
           position: 0
         }) do
      {:ok, category} ->
        IO.puts("✓ Created category: #{category.name}")
        {:ok, category}

      {:error, changeset} ->
        # Category might already exist
        case Repo.get_by(Urielm.Forum.Category, slug: "discussions") do
          nil ->
            IO.inspect(changeset.errors)
            {:error, changeset}

          category ->
            IO.puts("✓ Using existing category: #{category.name}")
            {:ok, category}
        end
    end
  end

  defp create_board(category) do
    case Forum.create_board(%{
           category_id: category.id,
           name: "AI & Development",
           slug: "ai-development",
           description: "Discuss AI development tools, costs, and the future of coding"
         }) do
      {:ok, board} ->
        IO.puts("✓ Created board: #{board.name}")
        {:ok, board}

      {:error, _changeset} ->
        # Board might already exist
        case Repo.get_by(Urielm.Forum.Board, slug: "ai-development") do
          nil ->
            {:error, "Failed to create board"}

          board ->
            IO.puts("✓ Using existing board: #{board.name}")
            {:ok, board}
        end
    end
  end

  defp create_users do
    # Original usernames mapped to valid format
    users_data = [
      {"mbtonev", "mbtonev"},
      {"ISueDrunks", "isuedrunks"},
      {"zunithemime", "zunithemime"},
      {"TastyIndividual6772", "tastyindividual"},
      {"dxdementia", "dxdementia"},
      {"abyssazaur", "abyssazaur"},
      {"snoodoodlesrevived", "snoodoodles"},
      {"GlassVase1", "glassvase1"},
      {"RearCog", "rearcog"},
      {"Repulsive-Hurry8172", "repulsive-hurry"},
      {"caldazar24", "caldazar24"},
      {"Andreas_Moeller", "andreas-moeller"},
      {"kyngston", "kyngston"},
      {"midnitewarrior", "midnitewarrior"},
      {"Hermano888", "hermano888"},
      {"liltingly", "liltingly"},
      {"bpexhusband", "bpexhusband"},
      {"AlgoTrading69", "algotrading69"},
      {"walmartbonerpills", "walmartbonerpills"},
      {"wogandmush", "wogandmush"},
      {"WolfeheartGames", "wolfeheartgames"},
      {"Only-Cheetah-9579", "only-cheetah"},
      {"Forsaken-Parsley798", "forsaken-parsley"},
      {"yycTechGuy", "yyctechguy"},
      {"alanism", "alanism"},
      {"lennyp4", "lennyp4"},
      {"powerofnope", "powerofnope"},
      {"chowderTV", "chowdertv"},
      {"Different_Ad8172", "different-ad"},
      {"monster2018", "monster2018"},
      {"lucayala", "lucayala"},
      {"tanman0401", "tanman0401"},
      {"Savings-Cry-3201", "savings-cry"},
      {"Sugary_Plumbs", "sugary-plumbs"},
      {"brumor69", "brumor69"}
    ]

    IO.puts("\n👥 Creating #{length(users_data)} users...")

    Enum.map(users_data, fn {display_username, username} ->
      email = "#{username}@example.com"

      # Try to create user directly with high trust level to bypass rate limits
      case Repo.get_by(User, username: username) do
        nil ->
          case %User{}
               |> User.registration_changeset(%{
                 username: username,
                 display_name: display_username,
                 email: email,
                 password: "password123"
               })
               |> Ecto.Changeset.put_change(:trust_level, 4)
               |> Ecto.Changeset.put_change(:email_verified, true)
               |> Repo.insert() do
            {:ok, user} -> user
            {:error, _} -> nil
          end

        user ->
          # Update existing user to trust level 4
          user
          |> Ecto.Changeset.change(trust_level: 4)
          |> Repo.update!()
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> then(fn users ->
      IO.puts("✓ Created/found #{length(users)} users")
      # Map by original display username for easier reference
      display_map =
        Enum.into(users, %{}, fn user -> {user.display_name, user} end)

      display_map
    end)
  end

  defp create_main_thread(board, users) do
    author = users["mbtonev"]

    case Forum.create_thread(board.id, author.id, %{
           title:
             "AI development will become extremely expensive after VC money is burned. Did you agree?",
           slug: "ai-development-expensive-after-vc",
           body: """
           The current AI development landscape is heavily subsidized by venture capital. What happens when that money runs out?

           I'm seeing people spend almost a developer's salary just on AI tools like Cursor each month. This can't be sustainable.

           What do you think?
           """
         }) do
      {:ok, thread} ->
        IO.puts("✓ Created thread: #{thread.title}")
        {:ok, thread}

      {:error, changeset} ->
        IO.inspect(changeset.errors)
        {:error, changeset}
    end
  end

  defp create_comments(thread, users) do
    IO.puts("\n💬 Creating comments...")

    # Top-level comment by ISueDrunks
    {:ok, c1} =
      Forum.create_comment(thread.id, users["ISueDrunks"].id, %{
        body: """
        For those using already expensive platforms, like Lovable.

        Download VS Code or AntiGravity, vibe for free. Pay $20 and you pretty much have unlimited vibes.
        """
      })

    # Reply to c1
    {:ok, c1_1} =
      Forum.create_comment(thread.id, users["zunithemime"].id, %{
        parent_id: c1.id,
        body:
          "100% use antigravity. I've tried most ide and it's the only one that has been working for my project 98% of the time. When it doesn't it will fix in no more than 2 debugging sessions"
      })

    {:ok, _c1_2} =
      Forum.create_comment(thread.id, users["ISueDrunks"].id, %{
        parent_id: c1_1.id,
        body:
          "It's decent for sure, I really like it. Gemini Flash was added today, fast as hell."
      })

    {:ok, c1_3} =
      Forum.create_comment(thread.id, users["mbtonev"].id, %{
        parent_id: c1.id,
        body: "What you vibes in VS code for free, which is the service or model?"
      })

    {:ok, c1_4} =
      Forum.create_comment(thread.id, users["ISueDrunks"].id, %{
        parent_id: c1_3.id,
        body: """
        Gemini has a free API tier that's pretty generous, you can use it in VS with the Gemini extension.

        If you can spare $20 a month, sign up for ChatGPT or Gemini, both are great in VS Code. You can even watch along in your browser if you fire up npm run dev.
        """
      })

    {:ok, c1_5} =
      Forum.create_comment(thread.id, users["TastyIndividual6772"].id, %{
        parent_id: c1_4.id,
        body: "Do you not run into tokens per minute issues ?"
      })

    {:ok, _c1_6} =
      Forum.create_comment(thread.id, users["ISueDrunks"].id, %{
        parent_id: c1_5.id,
        body: """
        I did with free Gemini when using Gemini 3 Pro. I haven't been limited since resubscribing to Gemini, I do quite a bit for a few hours each morning before I go to work.

        I used Codex a lot, but mostly to write Python and PowerShell cmdlets then run locally. Stuff like OCR/extraction from documents.
        """
      })

    # Another top-level comment
    {:ok, c2} =
      Forum.create_comment(thread.id, users["dxdementia"].id, %{
        body:
          "yes, it's an inverse bubble. traditionally a bubble will pop and prices will crash, like the housing market. but in this case, and the bubble is popping as we speak, it will lead to extremely inflated costs."
      })

    {:ok, _c2_1} =
      Forum.create_comment(thread.id, users["abyssazaur"].id, %{
        parent_id: c2.id,
        body: "Aka not a bubble"
      })

    {:ok, _c2_2} =
      Forum.create_comment(thread.id, users["snoodoodlesrevived"].id, %{
        parent_id: c2.id,
        body:
          "Well not really, it's just that the costs are subsidized because if they charged full price, they wouldn't be able to get adoption as fast as they are."
      })

    {:ok, _c2_3} =
      Forum.create_comment(thread.id, users["GlassVase1"].id, %{
        parent_id: c2.id,
        body: """
        Short term token prices will spike, long term they'll crash due to reduced inference costs from stronger GPUs.

        LLMs will probably start to stagnate and mature, which has likely already started.
        """
      })

    # More top-level comments
    {:ok, c3} =
      Forum.create_comment(thread.id, users["RearCog"].id, %{
        body: "I agree. I wouldn't be surprised if it 10x in cost."
      })

    {:ok, _c3_1} =
      Forum.create_comment(thread.id, users["mbtonev"].id, %{
        parent_id: c3.id,
        body:
          "I see a guy today paid this month for AI, almost a salary for the developer to Cursor"
      })

    {:ok, c4} =
      Forum.create_comment(thread.id, users["TastyIndividual6772"].id, %{
        body:
          "At the current state yes, unless things change. The api usage is significantly higher than what you get in monthly paid plans. We don't know if its the api overpriced or if the companies take a loss on the monthly plans but my guess is the second statement is true with the hope it becomes profitable in the future"
      })

    {:ok, _c4_1} =
      Forum.create_comment(thread.id, users["mbtonev"].id, %{
        parent_id: c4.id,
        body:
          "I know for sure Cursor also works on loss, that is why they try with their custom model"
      })

    {:ok, c5} =
      Forum.create_comment(thread.id, users["kyngston"].id, %{
        body:
          "the price for 1 million tokens has dropped from $30 to 6 cents in 3 years. why would that price go up?"
      })

    {:ok, _c5_1} =
      Forum.create_comment(thread.id, users["midnitewarrior"].id, %{
        parent_id: c5.id,
        body: """
        Share price of these AI companies is filled with hype. When reality hits, and the shareholders see the bubble pop, and how much these companies are losing, it's going to be time to turn a profit or die.

        Those 6 cents/1 million token price is subsidized by the shareholders, as happens in all bubbles in order to grab market share. When reality hits, that subsidy the shareholders are providing will disappear. The real, true cost of AI tokens will be discovered then, and it will be more than 6 cents a share.
        """
      })

    {:ok, c6} =
      Forum.create_comment(thread.id, users["bpexhusband"].id, %{
        body: "Over time all technology gets less expensive. So don't worry."
      })

    {:ok, _c6_1} =
      Forum.create_comment(thread.id, users["Savings-Cry-3201"].id, %{
        parent_id: c6.id,
        body: """
        Counterpoint - graphics cards. They decidedly have not gotten cheaper over the last five years, driven by crypto and AI.

        The bubble is fueled by speculation and venture capitalism. Once that money runs out then AI won't be subsidized and will have to start being profitable and that's when the price hikes and enshittification kicks in.
        """
      })

    {:ok, c7} =
      Forum.create_comment(thread.id, users["WolfeheartGames"].id, %{
        body: """
        No. The recent hardware for training is so powerful that the ability to do research and produce models is achievable with disposable income for a lot of people even after the RAM price increases.

        This is only going to get more efficient. Either model architectures will be more efficient, the cost of hardware will go down with a bubble pop, or new faster hardware will be released. Most likely 2 of 3.
        """
      })

    {:ok, _c8} =
      Forum.create_comment(thread.id, users["Forsaken-Parsley798"].id, %{
        body: "No."
      })

    {:ok, _c9} =
      Forum.create_comment(thread.id, users["yycTechGuy"].id, %{
        body:
          "I agree. But the open source LLMs are getting better (DevStral 2) and self hosting your LLM will be a thing."
      })

    {:ok, _c10} =
      Forum.create_comment(thread.id, users["alanism"].id, %{
        body: """
        Not necessarily. If the company is out of runway and can not raise additional rounds, they will be out of business or get acquired.

        At the same time, token cost should go way down at same time.
        """
      })

    {:ok, _c11} =
      Forum.create_comment(thread.id, users["chowderTV"].id, %{
        body:
          "Claude code for all code execution, Gemini for planning and documenting, and ChatGPT for debugging. Pay for Claude code, use free version of Gemini and chatjippety"
      })

    {:ok, c12} =
      Forum.create_comment(thread.id, users["monster2018"].id, %{
        body: """
        Right now a $20/month Gemini plus subscription gets you (as far as I can tell practically unlimited. Like there is no practical way to actually hit a rate limit in real life as one person using the account) access to Gemini 3, Claude 4.5 Opus and Sonnet, and ChatGPT OSS 2.5B.

        What I do is use sonnet by default, and then use opus for more technically complex tasks. And then when I run into a bug that Opus gets stuck in a rut, I try Gemini 3 and it works 100% of the time.
        """
      })

    {:ok, c12_1} =
      Forum.create_comment(thread.id, users["lucayala"].id, %{
        parent_id: c12.id,
        body: "Why does Gemini plus give you access to Claude???"
      })

    {:ok, _c12_2} =
      Forum.create_comment(thread.id, users["snoodoodlesrevived"].id, %{
        parent_id: c12_1.id,
        body: "Google is a major stakeholder in Anthropic"
      })

    IO.puts("✓ Created #{27} comments with nested replies")

    # Add votes
    add_votes(thread, [c1, c2, c3, c4, c5, c6, c7], users)
  end

  defp add_votes(thread, comments, users) do
    IO.puts("\n👍 Adding votes...")

    # Vote on thread (32 upvotes net)
    upvote_thread(thread, users, 32)

    # Vote on top comment (26 upvotes)
    upvote_comment(Enum.at(comments, 0), users, 26)

    # Vote on other comments
    upvote_comment(Enum.at(comments, 1), users, 9)
    upvote_comment(Enum.at(comments, 2), users, 6)
    upvote_comment(Enum.at(comments, 3), users, 5)
    upvote_comment(Enum.at(comments, 4), users, 4)
    upvote_comment(Enum.at(comments, 5), users, 3)
    upvote_comment(Enum.at(comments, 6), users, 3)

    IO.puts("✓ Added votes")
  end

  defp upvote_thread(thread, users, count) do
    users
    |> Map.values()
    |> Enum.take(count)
    |> Enum.each(fn user ->
      Forum.cast_vote(user.id, "thread", thread.id, 1)
    end)
  end

  defp upvote_comment(comment, users, count) do
    users
    |> Map.values()
    |> Enum.take(count)
    |> Enum.each(fn user ->
      Forum.cast_vote(user.id, "comment", comment.id, 1)
    end)
  end
end
