#!/usr/bin/env elixir

# Load app
File.cd!("/Users/urielmaldonado/projects/urielm")
Mix.start()
Mix.env(:dev)
{:ok, _} = Application.ensure_all_started(:urielm)

import Ecto.Query
alias Urielm.Repo
alias Urielm.Content.{Prompt, Tag}

defmodule PromptProcessor do
  def run do
    IO.puts("Starting prompt processing...")
    process_batch()
  end

  defp process_batch do
    case Repo.all(from(p in Prompt, where: p.process_status == "pending", limit: 5)) do
      [] ->
        IO.puts("No more pending prompts.")

      prompts ->
        Enum.each(prompts, &process_prompt/1)
        process_batch()
    end
  end

  defp process_prompt(prompt) do
    IO.puts("Processing: #{prompt.title}...")

    # Mark as processing
    Repo.update_all(
      from(p in Prompt, where: p.id == ^prompt.id),
      set: [process_status: "processing"]
    )

    # For now, simulate tag extraction
    tags = extract_tags(prompt)
    category = extract_category(prompt)

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

    tag_names = Enum.map(tag_ids, fn id -> Repo.get!(Tag, id).name end)
    message = "Processed: #{prompt.title} | Category: #{category} | Tags: #{Enum.join(tag_names, ", ")}"
    IO.puts(message)
  end

  defp extract_tags(prompt) do
    # Placeholder - would call Claude
    title = String.downcase(prompt.title)

    cond do
      String.contains?(title, "tiktok") -> ["social-media", "tiktok", "content"]
      String.contains?(title, "email") -> ["email", "copywriting", "marketing"]
      String.contains?(title, "ai") -> ["ai", "automation", "tools"]
      true -> ["prompt", "content", "creation"]
    end
  end

  defp extract_category(prompt) do
    title = String.downcase(prompt.title)

    cond do
      String.contains?(title, "ai") -> "Software Engineers"
      String.contains?(title, "prompt") -> "Prompt Management"
      String.contains?(title, "content") -> "Content Creation"
      true -> "Prompt Management"
    end
  end

  defp ensure_tags_exist(tags) do
    Enum.map(tags, fn tag_name ->
      slug = tag_name |> String.downcase() |> String.replace(" ", "-")

      case Repo.get_by(Tag, slug: slug) do
        %Tag{id: id} -> id

        nil ->
          {:ok, tag} = Repo.insert(%Tag{name: tag_name, slug: slug})
          tag.id
      end
    end)
  end
end

PromptProcessor.run()
