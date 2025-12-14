defmodule Mix.Tasks.SeedPrompts do
  use Mix.Task
  alias Urielm.Repo
  alias Urielm.Content.Prompt

  @shortdoc "Seeds prompts from ~/projects/prompts directory"

  def run(_args) do
    Mix.Task.run("app.start")

    prompts_dir = Path.expand("~/projects/prompts")

    prompts_dir
    |> Path.join("*.md")
    |> Path.wildcard()
    |> Enum.each(&import_prompt/1)

    IO.puts("✓ Prompt seeding complete!")
  end

  defp import_prompt(file_path) do
    content = File.read!(file_path)
    filename = Path.basename(file_path, ".md")

    # Convert filename to title (snake_case or spaces to Title Case)
    title =
      filename
      |> String.replace("_", " ")
      |> String.split(" ")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    # Get first line as description (truncate if too long)
    description =
      content
      |> String.split("\n")
      |> List.first()
      |> case do
        nil ->
          nil

        line ->
          line
          |> String.trim()
          |> String.slice(0, 200)
      end

    attrs = %{
      title: title,
      prompt: content,
      description: description,
      source: "ramanov",
      category: "prompts",
      url: filename
    }

    %Prompt{}
    |> Prompt.changeset(attrs)
    |> Repo.insert!()

    IO.puts("  ✓ Imported: #{title}")
  rescue
    e ->
      IO.puts("  ✗ Failed to import #{file_path}: #{inspect(e)}")
  end
end
