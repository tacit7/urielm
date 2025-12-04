# Script for populating the database with prompts from SabrinaRamonov/prompts repo
alias Urielm.{Repo, Content}
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
