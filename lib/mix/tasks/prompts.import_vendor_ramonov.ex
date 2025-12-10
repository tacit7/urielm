defmodule Mix.Tasks.Prompts.ImportVendorRamonov do
  use Mix.Task

  @shortdoc "Import vendored SabrinaRamonov prompts from vendor/ into the prompts table"

  @vendor_root "vendor/prompts"
  @repo_url "https://github.com/SabrinaRamonov/prompts"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    root = Path.expand(@vendor_root)
    files = Path.wildcard(Path.join(root, "**/*.md"))

    if files == [] do
      Mix.shell().error("No .md files found under #{root}")
      System.halt(1)
    end

    sha = read_sha(root)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      files
      |> Enum.map(fn file ->
        rel = Path.relative_to(file, root)
        md = File.read!(file)
        title = extract_title(md) || humanize_filename(rel)
        category = top_level_dir(rel)

        description = extract_description(md)

        url =
          case sha do
            nil -> "#{@repo_url}/blob/main/#{rel}"
            sha -> "#{@repo_url}/blob/#{sha}/#{rel}"
          end

        %{
          title: title,
          url: url,
          prompt: md,
          category: category,
          description: description,
          source: "SabrinaRamonov/prompts (vendored#{if sha, do: " @ #{sha}", else: ""})",
          processed: true,
          inserted_at: now,
          updated_at: now
        }
      end)

    # chunk inserts so you don't blow up memory on big imports
    entries
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      Urielm.Repo.insert_all(
        Urielm.Content.Prompt,
        chunk,
        on_conflict: :nothing
      )
    end)

    Mix.shell().info("Imported/updated #{length(entries)} prompts from vendor.")
  end

  defp read_sha(root) do
    path = Path.join(root, "VENDORED_FROM_COMMIT")

    if File.exists?(path) do
      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> List.first()
      |> case do
        <<sha::binary-size(40)>> -> sha
        _ -> nil
      end
    else
      nil
    end
  end

  defp extract_title(md) do
    case Regex.run(~r/^\s*#\s+(.+?)\s*$/m, md) do
      [_, t] -> String.trim(t)
      _ -> nil
    end
  end

  defp extract_description(md) do
    md
    |> String.split("\n")
    |> drop_until_after_title()
    |> Enum.join("\n")
    |> first_paragraph()
    |> strip_basic_markdown()
    |> String.slice(0, 280)
    |> empty_to_nil()
  end

  defp drop_until_after_title(lines) do
    case Enum.split_while(lines, fn l -> not String.match?(l, ~r/^\s*#\s+/) end) do
      {_before, []} -> lines
      {_before, [_title | rest]} -> rest
    end
  end

  defp first_paragraph(text) do
    text
    |> String.trim()
    |> String.split(~r/\n\s*\n/, parts: 2)
    |> List.first()
    |> to_string()
  end

  defp strip_basic_markdown(text) do
    text
    |> String.replace(~r/`([^`]+)`/, "\\1")
    |> String.replace(~r/\*\*([^*]+)\*\*/, "\\1")
    |> String.replace(~r/\*([^*]+)\*/, "\\1")
    |> String.replace(~r/\[([^\]]+)\]\([^\)]+\)/, "\\1")
    |> String.trim()
  end

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(s), do: s

  defp humanize_filename(rel) do
    rel
    |> Path.rootname()
    |> Path.basename()
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> String.trim()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp top_level_dir(rel) do
    rel
    |> String.split("/", parts: 2)
    |> case do
      [_one] -> nil
      [dir, _] -> dir
    end
  end
end
