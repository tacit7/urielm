defmodule Mix.Tasks.NewsBot.Backfill do
  @moduledoc """
  Discovers AI news candidates and optionally posts them as news-bot.

      mix news_bot.backfill --from 2026-08-29 --to 2026-09-04
      mix news_bot.backfill --from 2026-08-29 --to 2026-09-04 --limit 7 --post
  """

  use Mix.Task

  alias Urielm.NewsBot

  @shortdoc "Discovers and optionally posts AI news as news-bot"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, _positional, invalid} =
      OptionParser.parse(args,
        strict: [
          from: :string,
          to: :string,
          limit: :integer,
          post: :boolean,
          board: :string,
          agent: :string,
          json: :boolean
        ]
      )

    if invalid != [] do
      Mix.raise(usage())
    end

    start_dependencies!()

    from = parse_date!(opts[:from], "--from is required")
    to = parse_date!(opts[:to], "--to is required")
    limit = Keyword.get(opts, :limit, 7)
    board = Keyword.get(opts, :board, "ai-news")
    agent = Keyword.get(opts, :agent, "news-bot")

    case NewsBot.discover(from: from, to: to, limit: limit) do
      {:ok, candidates} ->
        result =
          if opts[:post] do
            Enum.map(candidates, &post_candidate(&1, agent, board))
          else
            Enum.map(candidates, &candidate_payload/1)
          end

        if opts[:json] do
          Mix.shell().info(Jason.encode!(%{posted: !!opts[:post], items: result}))
        else
          print_result(result, opts[:post])
        end

        result

      {:error, reason} ->
        Mix.raise("Could not discover news candidates: #{inspect(reason)}")
    end
  end

  defp post_candidate(candidate, agent, board) do
    path = Path.join(System.tmp_dir!(), "news-bot-#{System.unique_integer([:positive])}.md")
    File.write!(path, candidate.body)

    try do
      Mix.Task.reenable("forum.agent")

      thread =
        Mix.Tasks.Forum.Agent.run([
          "thread",
          "--agent",
          agent,
          "--board",
          board,
          "--title",
          candidate.title,
          "--body-file",
          path,
          "--created-at",
          DateTime.to_iso8601(candidate.created_at),
          "--json"
        ])

      %{
        title: thread.title,
        url: "https://urielm.dev/forum/t/#{thread.id}",
        publisher: candidate.source,
        source: candidate.url,
        inserted_at: thread.inserted_at
      }
    after
      File.rm(path)
    end
  end

  defp candidate_payload(candidate) do
    %{
      title: candidate.title,
      publisher: candidate.source,
      source: candidate.url,
      published_on: candidate.published_on,
      created_at: candidate.created_at,
      summary: candidate.summary
    }
  end

  defp print_result([], _posted?) do
    Mix.shell().info("No new news candidates found.")
  end

  defp print_result(items, true) do
    Mix.shell().info("Posted #{length(items)} news posts:")

    Enum.each(items, fn item ->
      Mix.shell().info("- #{DateTime.to_date(item.inserted_at)} #{item.title} #{item.url}")
    end)
  end

  defp print_result(items, false) do
    Mix.shell().info(
      "Found #{length(items)} news candidates. Re-run with --post to create threads."
    )

    Enum.each(items, fn item ->
      Mix.shell().info("- #{item.published_on} #{item.publisher} #{item.title} #{item.source}")
    end)
  end

  defp parse_date!(nil, message), do: Mix.raise(message)

  defp parse_date!(value, message) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      {:error, _reason} -> Mix.raise("#{message}; expected YYYY-MM-DD")
    end
  end

  defp start_dependencies! do
    [:postgrex, :ecto_sql, :jason, :req]
    |> Enum.each(fn app ->
      case Application.ensure_all_started(app) do
        {:ok, _apps} -> :ok
        {:error, reason} -> Mix.raise("Could not start #{app}: #{inspect(reason)}")
      end
    end)

    case Urielm.Repo.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> Mix.raise("Could not start repo: #{inspect(reason)}")
    end
  end

  defp usage do
    """
    Usage:
      mix news_bot.backfill --from YYYY-MM-DD --to YYYY-MM-DD [--limit 7] [--post] [--json]
    """
    |> String.trim()
  end
end
