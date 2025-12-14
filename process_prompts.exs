# Get all pending prompts
pending_prompts =
  Ecto.Adapters.SQL.query!(
    Urielm.Repo,
    "SELECT id, title, prompt, description FROM prompts WHERE process_status = 'pending' LIMIT 50",
    []
  )

IO.puts("Processing #{Enum.count(pending_prompts.rows)} prompts...")

Enum.each(pending_prompts.rows, fn [id, title, prompt, description] ->
  # Mark as processing
  Ecto.Adapters.SQL.query!(
    Urielm.Repo,
    "UPDATE prompts SET process_status = 'processing' WHERE id = $1",
    [id]
  )

  # Prepare analysis prompt
  analysis_prompt = """
  Analyze this prompt and extract tags + category.
  Categories: Analyze Text, Coaching, Content Creation, Creative Arts, Cybersecurity, Entrepreneurs, Gaming, Job Search, Lawyers, Meetings, Product Managers, Prompt Management, Psychology, Real Estate, Software Engineers, Students & School, Visualizations

  Title: #{title}
  Description: #{description || ""}
  Prompt text: #{prompt}

  Output format (ONLY these lines):
  CATEGORY: <pick one category>
  TAGS: tag-1,tag-2,tag-3,tag-4
  """

  # Call Claude API
  case Req.post!("https://api.anthropic.com/v1/messages",
         headers: [
           {"x-api-key", System.get_env("ANTHROPIC_API_KEY")},
           {"anthropic-version", "2023-06-01"}
         ],
         json: %{
           "model" => "claude-opus-4-5-20251101",
           "max_tokens" => 100,
           "messages" => [
             %{
               "role" => "user",
               "content" => analysis_prompt
             }
           ]
         }
       ) do
    response ->
      text = response.body["content"] |> List.first() |> Map.get("text")

      category =
        text
        |> String.split("\n")
        |> Enum.find(&String.starts_with?(&1, "CATEGORY:"))
        |> String.replace_prefix("CATEGORY: ", "")
        |> String.trim()

      tags_str =
        text
        |> String.split("\n")
        |> Enum.find(&String.starts_with?(&1, "TAGS:"))
        |> String.replace_prefix("TAGS: ", "")
        |> String.trim()

      tags = tags_str |> String.split(",") |> Enum.map(&String.trim/1)

      # Insert tags and create prompt_tags
      Enum.each(tags, fn tag ->
        {:ok, _} =
          Ecto.Adapters.SQL.query(
            Urielm.Repo,
            "INSERT INTO tags (name) VALUES ($1) ON CONFLICT (name) DO NOTHING",
            [tag]
          )

        {:ok, result} =
          Ecto.Adapters.SQL.query(
            Urielm.Repo,
            "SELECT id FROM tags WHERE name = $1",
            [tag]
          )

        if Enum.any?(result.rows) do
          tag_id = result.rows |> List.first() |> List.first()

          Ecto.Adapters.SQL.query!(
            Urielm.Repo,
            "INSERT INTO prompt_tags (prompt_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
            [id, tag_id]
          )
        end
      end)

      # Update prompt
      Ecto.Adapters.SQL.query!(
        Urielm.Repo,
        "UPDATE prompts SET category = $1, process_status = 'processed' WHERE id = $2",
        [category, id]
      )

      IO.puts("✓ #{title} | #{category} | #{Enum.join(tags, ", ")}")
  end
end)

IO.puts("✓ All prompts processed")
