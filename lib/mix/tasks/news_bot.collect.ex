defmodule Mix.Tasks.NewsBot.Collect do
  @moduledoc """
  Collects deduped AI news articles into a run directory for agent review.

      mix news_bot.collect --from 2026-09-18 --to 2026-09-21 --limit 50
      mix news_bot.collect --from 2026-09-18 --to 2026-09-21 --output-dir tmp/news_bot_runs/manual
  """

  use Mix.Task

  alias Urielm.NewsBot

  @shortdoc "Collects deduped AI news articles into markdown files"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, _positional, invalid} =
      OptionParser.parse(args,
        strict: [
          from: :string,
          to: :string,
          limit: :integer,
          output_dir: :string,
          json: :boolean
        ]
      )

    if invalid != [] do
      Mix.raise(usage())
    end

    start_dependencies!()

    today = Date.utc_today()
    from = parse_date!(opts[:from], Date.add(today, -3))
    to = parse_date!(opts[:to], today)
    limit = Keyword.get(opts, :limit, 50)
    output_dir = Keyword.get_lazy(opts, :output_dir, &default_output_dir/0)

    {:ok, result} =
      NewsBot.collect_articles(
        from: from,
        to: to,
        limit: limit,
        output_dir: output_dir
      )

    payload = %{
      output_dir: result.output_dir,
      manifest_path: result.manifest_path,
      readme_path: result.readme_path,
      count: length(result.articles),
      articles:
        Enum.map(result.articles, fn article ->
          %{
            title: article.title,
            publisher: article.publisher,
            source: article.source,
            path: article.path,
            fetch_status: article.fetch_status
          }
        end)
    }

    if opts[:json] do
      Mix.shell().info(Jason.encode!(payload))
    else
      print_result(payload)
    end

    payload
  end

  defp print_result(%{count: 0, output_dir: output_dir}) do
    Mix.shell().info("No new news candidates found. Created run directory: #{output_dir}")
  end

  defp print_result(%{count: count, output_dir: output_dir, articles: articles}) do
    Mix.shell().info("Collected #{count} news articles in #{output_dir}:")

    Enum.each(articles, fn article ->
      Mix.shell().info("- #{article.publisher} #{article.title} #{article.path}")
    end)
  end

  defp parse_date!(nil, default), do: default

  defp parse_date!(value, _default) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      {:error, _reason} -> Mix.raise("expected date in YYYY-MM-DD format, got: #{value}")
    end
  end

  defp default_output_dir do
    timestamp =
      DateTime.utc_now()
      |> Calendar.strftime("%Y%m%dT%H%M%SZ")

    Path.join(["tmp", "news_bot_runs", timestamp])
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
      mix news_bot.collect [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--limit 50] [--output-dir DIR] [--json]
    """
    |> String.trim()
  end
end
