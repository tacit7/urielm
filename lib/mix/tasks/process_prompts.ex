defmodule Mix.Tasks.ProcessPrompts do
  use Mix.Task

  import Ecto.Query
  alias Urielm.Repo
  alias Urielm.Content.{Prompt, Tag}

  @shortdoc "Process pending prompts using Romanov tagging"

  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("Starting prompt processing...")

    process_pending_prompts()

    IO.puts("Processing complete!")
  end

  defp process_pending_prompts do
    case Repo.all(from(p in Prompt, where: p.process_status == "pending", limit: 50)) do
      [] ->
        send_nats_message("Agent complete: All pending prompts processed")
        IO.puts("No more pending prompts.")

      prompts ->
        Enum.each(prompts, &process_prompt/1)

        # Recursively process next batch
        process_pending_prompts()
    end
  end

  defp process_prompt(prompt) do
    IO.puts("Processing: #{prompt.title}...")

    # Mark as processing
    Repo.update_all(
      from(p in Prompt, where: p.id == ^prompt.id),
      set: [process_status: "processing"]
    )

    # Use the Romanov tagging prompt
    # For now, we'll use a placeholder - in production this would call the tagging service
    case extract_tags_and_category(prompt) do
      {:ok, tags, category} ->
        # Create/link tags
        tag_ids = ensure_tags_exist(tags)

        # Insert prompt_tags
        Enum.each(tag_ids, fn tag_id ->
          Repo.insert_all(
            "prompt_tags",
            [
              %{
                prompt_id: prompt.id,
                tag_id: tag_id,
                inserted_at: NaiveDateTime.utc_now(),
                updated_at: NaiveDateTime.utc_now()
              }
            ],
            on_conflict: :nothing
          )
        end)

        # Update category
        Repo.update_all(
          from(p in Prompt, where: p.id == ^prompt.id),
          set: [category: category, process_status: "processed"]
        )

        tag_names = Enum.map(tag_ids, fn id ->
          Repo.get!(Tag, id).name
        end)

        message = "Processed: #{prompt.title} | Category: #{category} | Tags: #{Enum.join(tag_names, ", ")}"
        send_nats_message(message)
        IO.puts(message)

      {:error, reason} ->
        IO.puts("Error processing #{prompt.title}: #{reason}")

        Repo.update_all(
          from(p in Prompt, where: p.id == ^prompt.id),
          set: [process_status: "pending"]
        )
    end
  end

  defp extract_tags_and_category(prompt) do
    # This would normally call Claude with the Romanov tagging prompt
    # For now, returning a default implementation
    case call_tagging_service(prompt) do
      {:ok, result} ->
        tags = parse_tags(result["tags"])
        category = parse_category(result["category"])
        {:ok, tags, category}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp call_tagging_service(prompt) do
    # Call Claude with the Romanov tagging prompt
    romanov_prompt = """
    You are a tagging assistant for a prompts catalog. For each prompt, extract 3–6 high‑signal tags (max 8) that complement the prompt's category. Tags must NOT duplicate the category or simple variants of it.

    You receive
    - id, title, category (one of: Analyze Text, Coaching, Content Creation, Creative Arts, Cybersecurity, Entrepreneurs, Gaming, Job Search, Lawyers, Meetings, Product Managers, Prompt Management, Psychology, Real Estate, Software Engineers, Students & School, Visualizations), prompt text (first 300 chars), optional description, URL.

    Rules
    - Count: 3–6 tags (max 8), lowercase kebab‑case.
    - No category repeats: never output the category name or its near‑synonym as a tag.
    - Tags should be orthogonal facets: task/intent, platform/context, audience/industry, technique/format/tone, specific artifact types.
    - Prefer concise, reusable tags; avoid generic noise (prompt, general, misc, generate, create, write).
    - Slugify: lowercase → non-alphanumerics → "-" → collapse/trim dashes; prefer singular nouns (subject-line, caption, campaign).
    - Reuse consistent tags you've already used; only invent new ones when they add filtering value.

    Composition guidance
    - Task/intent (1–3): content-strategy, title-optimization, summarization, brainstorming, lead-generation, code-review, debugging, resume-optimization.
    - Platform/context (0–2): instagram, youtube, email, linkedin, github, tiktok, powerpoint.
    - Audience/industry (0–2): smb, enterprise, home-garden, students, jobseekers, legal, healthcare.
    - Technique/format/tone (0–1): outline, long-form, tutorial, advanced, visualizations, diagram.
    - Language/stack (only if clearly central): elixir, phoenix, svelte, python, sql.

    Category handling
    - Treat the category as given metadata (do not output as a tag).
    - Choose tags that specialize the prompt within that category.

    Heuristics
    - Prefer terms clearly present in title and first paragraph.
    - Promote strong dictionary hits (platforms, common tasks/intents).
    - Avoid incidental words that don't help filtering.
    - URL path tokens may help for platforms.

    Output format
    - For each prompt, output only:
      - id: <id>
      - tags: [tag-1, tag-2, tag-3, ...]
      - category: <one of the 18 categories>

    Now analyze this prompt and extract tags and category:
    ID: #{prompt.id}
    Title: #{prompt.title}
    Description: #{prompt.description || ""}
    Prompt (first 300 chars): #{String.slice(prompt.prompt || "", 0, 300)}
    URL: #{prompt.url || ""}

    Respond in JSON format like:
    {
      "id": #{prompt.id},
      "tags": ["tag-1", "tag-2", "tag-3"],
      "category": "Category Name"
    }
    """

    case call_claude(romanov_prompt) do
      {:ok, response} ->
        parse_response(response)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp call_claude(prompt) do
    # Call Anthropic API using Erlang's httpc
    api_key = System.get_env("ANTHROPIC_API_KEY") || ""

    if api_key == "" do
      {:error, "ANTHROPIC_API_KEY not set"}
    else
      headers = [
        {~c"x-api-key", String.to_charlist(api_key)},
        {~c"anthropic-version", ~c"2023-06-01"},
        {~c"content-type", ~c"application/json"}
      ]

      body =
        Jason.encode!(%{
          model: "claude-opus-4-5-20251101",
          max_tokens: 1024,
          messages: [
            %{
              role: "user",
              content: prompt
            }
          ]
        })

      url = ~c"https://api.anthropic.com/v1/messages"

      try do
        {:ok, {status_line, _, response_body}} =
          :httpc.request(:post, {url, headers, ~c"application/json", body}, [], [])

        {status_code, _} = parse_status_line(status_line)

        case status_code do
          200 ->
            body_str = to_string(response_body)
            {:ok, data} = Jason.decode(body_str)
            content = data["content"] |> List.first() |> Map.get("text", "")
            {:ok, content}

          status ->
            {:error, "API error: #{status} - #{inspect(response_body)}"}
        end
      rescue
        e ->
          {:error, "Request failed: #{inspect(e)}"}
      end
    end
  end

  defp parse_status_line(status_line) do
    # status_line is a tuple like {_, 200, _}
    case status_line do
      {_, code, _} -> {code, status_line}
      _ -> {500, status_line}
    end
  end

  defp parse_response(response) do
    # Extract JSON from response
    json_regex = ~r/\{[\s\S]*\}/

    case Regex.run(json_regex, response) do
      [json_str] ->
        case Jason.decode(json_str) do
          {:ok, data} ->
            {:ok, %{"tags" => Map.get(data, "tags", []), "category" => Map.get(data, "category", "")}}

          {:error, _} ->
            {:error, "Failed to parse JSON response"}
        end

      _ ->
        {:error, "No JSON found in response"}
    end
  end

  defp parse_tags(tags_str) when is_list(tags_str) do
    tags_str
  end

  defp parse_tags(tags_str) when is_binary(tags_str) do
    tags_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
  end

  defp parse_category(cat) when is_binary(cat) do
    cat
  end

  defp parse_category(cat) do
    cat |> to_string()
  end

  defp ensure_tags_exist(tags) do
    Enum.map(tags, fn tag_name ->
      slug = tag_name |> String.downcase() |> String.replace(" ", "-")

      case Repo.get_by(Tag, slug: slug) do
        %Tag{id: id} ->
          id

        nil ->
          {:ok, tag} =
            Repo.insert(%Tag{
              name: tag_name,
              slug: slug
            })

          tag.id
      end
    end)
  end

  defp send_nats_message(message) do
    # Send NATS message using the mcp__eits__i-nats-send mechanism
    # This would be sent back through the session
    IO.puts("[NATS] #{message}")

    # In actual deployment, this would integrate with Eye in the Sky NATS
    # For now, just log the message
  end
end
