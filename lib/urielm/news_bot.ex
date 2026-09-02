defmodule Urielm.NewsBot do
  @moduledoc """
  Discovers source-dated AI news candidates and prepares forum post drafts.
  """

  import Ecto.Query, warn: false

  alias Urielm.Forum.Thread
  alias Urielm.NewsBot.DateParser
  alias Urielm.Repo

  @sources [
    %{
      name: "OpenAI",
      type: :rss,
      url: "https://openai.com/news/rss.xml"
    },
    %{
      name: "Microsoft",
      type: :rss,
      url: "https://news.microsoft.com/source/topics/ai/feed/"
    },
    %{
      name: "Anthropic",
      type: :anthropic_html,
      url: "https://www.anthropic.com/news",
      base_url: "https://www.anthropic.com"
    }
  ]

  @type candidate :: %{
          required(:title) => String.t(),
          required(:url) => String.t(),
          required(:source) => String.t(),
          required(:published_on) => Date.t(),
          required(:created_at) => DateTime.t(),
          required(:summary) => String.t(),
          required(:body) => String.t()
        }

  def discover(opts \\ []) do
    fetcher = Keyword.get(opts, :fetcher, &fetch/1)
    sources = Keyword.get(opts, :sources, @sources)
    from = Keyword.fetch!(opts, :from)
    to = Keyword.fetch!(opts, :to)
    limit = Keyword.get(opts, :limit, 7)

    sources
    |> Task.async_stream(&source_candidates(&1, fetcher),
      ordered: false,
      timeout: :infinity
    )
    |> Enum.flat_map(fn
      {:ok, {:ok, candidates}} -> candidates
      _ -> []
    end)
    |> Enum.filter(&(Date.compare(&1.published_on, from) in [:eq, :gt]))
    |> Enum.filter(&(Date.compare(&1.published_on, to) in [:eq, :lt]))
    |> Enum.reject(&source_posted?/1)
    |> Enum.sort_by(&{DateTime.to_iso8601(&1.created_at), &1.source, &1.title})
    |> Enum.take(limit)
    |> then(&{:ok, &1})
  end

  def source_posted?(%{url: url}) do
    source_posted?(url)
  end

  def source_posted?(url) when is_binary(url) do
    canonical = canonical_url(url)
    pattern = "%#{canonical}%"
    slash_pattern = "%#{canonical}/%"

    from(t in Thread,
      join: b in assoc(t, :board),
      where:
        b.slug == "ai-news" and t.is_removed == false and
          (ilike(t.body, ^pattern) or ilike(t.body, ^slash_pattern)),
      select: 1,
      limit: 1
    )
    |> Repo.exists?()
  end

  defp source_candidates(%{type: :rss, url: url} = source, fetcher) do
    with {:ok, rss} <- fetch_body(fetcher, url) do
      rss_candidates(rss, source)
    end
  end

  defp source_candidates(%{type: :anthropic_html, url: url} = source, fetcher) do
    with {:ok, html} <- fetch_body(fetcher, url) do
      html
      |> anthropic_article_urls(source)
      |> Task.async_stream(&anthropic_article_candidate(&1, source, fetcher),
        ordered: false,
        timeout: :infinity
      )
      |> Enum.flat_map(fn
        {:ok, [candidate]} -> [candidate]
        _ -> []
      end)
      |> then(&{:ok, &1})
    end
  end

  defp rss_candidates(rss, source) do
    with {:ok, document} <- Floki.parse_document(rss) do
      candidates =
        document
        |> Floki.find("item")
        |> Enum.flat_map(&rss_candidate(&1, source))

      {:ok, candidates}
    end
  end

  defp rss_candidate(item, source) do
    with {:ok, title} <- item_text(item, "title"),
         {:ok, url} <- item_text(item, "link"),
         {:ok, pub_date} <- item_text(item, "pubdate"),
         {:ok, created_at} <- DateParser.parse_rfc822(pub_date) do
      summary =
        item
        |> item_text("description", fallback_summary(source.name, title))
        |> html_to_text()
        |> reject_feed_boilerplate()
        |> case do
          "" -> fallback_summary(source.name, title)
          text -> text
        end

      url = canonical_url(url)

      [
        %{
          title: title,
          url: url,
          source: source.name,
          published_on: DateTime.to_date(created_at),
          created_at: created_at,
          summary: summary,
          body: body(title, summary, url, source.name)
        }
      ]
    else
      _ -> []
    end
  end

  defp anthropic_article_urls(html, source) do
    ~r/href="(\/news\/[a-z0-9-]+)"/
    |> Regex.scan(html)
    |> Enum.map(fn [_, path] -> URI.merge(source.base_url, path) |> URI.to_string() end)
    |> Enum.uniq()
  end

  defp anthropic_article_candidate(url, source, fetcher) do
    with {:ok, html} <- fetch_body(fetcher, url),
         {:ok, title} <- meta_content(html, "og:title"),
         {:ok, summary} <- meta_content(html, "og:description"),
         {:ok, published_on} <- anthropic_date(html),
         {:ok, time} <- Time.new(12, 0, 0),
         {:ok, created_at} <- DateTime.new(published_on, time, "Etc/UTC") do
      url = canonical_url(url)
      summary = clean_text(summary)

      [
        %{
          title: clean_text(title),
          url: url,
          source: source.name,
          published_on: published_on,
          created_at: created_at,
          summary: summary,
          body: body(title, summary, url, source.name)
        }
      ]
    else
      _ -> []
    end
  end

  defp fetch_body(fetcher, url) do
    case fetcher.(url) do
      {:ok, %{status: status, body: body}} when status in 200..299 and is_binary(body) ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_status, status, url}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch(url) do
    Req.get(url,
      headers: [
        {"user-agent", "UrielmNewsBot/1.0 (+https://urielm.dev/)"}
      ],
      receive_timeout: 15_000
    )
  end

  defp item_text(item, selector) do
    case item_text(item, selector, "") do
      "" -> {:error, {:missing_item_text, selector}}
      text -> {:ok, text}
    end
  end

  defp item_text(item, selector, default) do
    item
    |> Floki.find(selector)
    |> List.first()
    |> case do
      nil -> default
      node -> node |> Floki.text(sep: " ") |> clean_text()
    end
  end

  defp body(title, summary, url, source_name) do
    bullets = summary_bullets(summary, title)

    """
    #{summary}

    Key points:

    #{Enum.map_join(bullets, "\n", &"- #{&1}")}

    Publisher: #{source_name}
    Source: #{url}
    """
  end

  defp summary_bullets(summary, title) do
    summary
    |> String.split(~r/(?<=[.!?])\s+/)
    |> Enum.map(&clean_text/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.take(3)
    |> pad_bullets(title)
  end

  defp pad_bullets(bullets, _title) when length(bullets) >= 3, do: bullets

  defp pad_bullets(bullets, title) do
    fallback = [
      "#{title} was published in the selected date range.",
      "The article is relevant to AI product, research, policy, safety, or infrastructure work.",
      "The source link is included for the full details."
    ]

    (bullets ++ fallback)
    |> Enum.uniq()
    |> Enum.take(3)
  end

  defp clean_text(text) do
    text
    |> to_string()
    |> decode_entities()
    |> String.replace_prefix("<![CDATA[", "")
    |> String.replace_suffix("]]>", "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp canonical_url(url) do
    url
    |> clean_text()
    |> String.trim_trailing("/")
  end

  defp html_to_text(text) do
    with {:ok, nodes} <- Floki.parse_fragment(text) do
      nodes
      |> Floki.text(sep: " ")
      |> clean_text()
    else
      _ -> clean_text(text)
    end
  end

  defp reject_feed_boilerplate(text) do
    if String.match?(text, ~r/^The post .+ appeared first on /i) do
      ""
    else
      text
    end
  end

  defp fallback_summary(source_name, title) do
    "#{source_name} published #{title}."
  end

  defp meta_content(html, property) do
    with {:ok, document} <- Floki.parse_document(html),
         [content | _] <-
           document
           |> Floki.find("meta[property=\"#{property}\"]")
           |> Floki.attribute("content") do
      {:ok, clean_text(content)}
    else
      _ -> {:error, {:missing_meta, property}}
    end
  end

  defp anthropic_date(html) do
    with [date] <-
           Regex.run(
             ~r/\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \d{1,2}, 20\d{2}\b/,
             html
           ),
         {:ok, parsed} <- DateParser.parse(date) do
      {:ok, parsed}
    else
      _ -> :error
    end
  end

  defp decode_entities(text) do
    text
    |> String.replace("&amp;", "&")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("&#x27;", "'")
    |> String.replace("&apos;", "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
  end
end
