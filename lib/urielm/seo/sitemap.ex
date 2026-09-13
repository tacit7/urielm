defmodule Urielm.SEO.Sitemap do
  @moduledoc """
  Builds the public XML sitemap entries for crawlers.
  """

  import Ecto.Query, warn: false

  alias Urielm.Content.{Post, Prompt, Video}
  alias Urielm.Forum.{Board, Category, Thread}
  alias Urielm.Learning.{Course, Lesson}
  alias Urielm.Repo

  @host "https://urielm.dev"
  @default_limit 5_000
  @max_limit 45_000

  @fixed_paths [
    "/",
    "/blog",
    "/prompts",
    "/courses",
    "/videos",
    "/code-kata",
    "/forum",
    "/forum/categories",
    "/forum/tags",
    "/privacy",
    "/terms"
  ]

  @doc """
  Returns bounded sitemap entries for public canonical pages.
  """
  def entries(opts \\ []) do
    limit = opts |> Keyword.get(:limit, @default_limit) |> clamp_limit()
    now = Keyword.get(opts, :now, DateTime.utc_now())

    fixed_entries() ++
      post_entries(limit, now) ++
      video_entries(limit, now) ++
      prompt_entries(limit) ++
      course_entries(limit) ++
      lesson_entries(limit) ++
      thread_entries(limit)
  end

  @doc """
  Renders a complete XML sitemap document.
  """
  def to_xml(entries) when is_list(entries) do
    body =
      entries
      |> Enum.map(&url_node/1)
      |> Enum.join("")

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">#{body}</urlset>
    """
  end

  def absolute_url(path) when is_binary(path) do
    @host <> path
  end

  defp fixed_entries do
    Enum.map(@fixed_paths, &entry(&1, nil))
  end

  defp post_entries(limit, now) do
    from(p in Post,
      where: p.status == "published" and not is_nil(p.published_at) and p.published_at <= ^now,
      order_by: [desc: p.published_at, desc: p.id],
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.map(&entry("/blog/#{&1.slug}", newest_datetime(&1.published_at, &1.updated_at)))
  end

  defp video_entries(limit, now) do
    from(v in Video,
      where: v.visibility == "public" and not is_nil(v.published_at) and v.published_at <= ^now,
      order_by: [desc: v.published_at, desc: v.id],
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.map(&entry("/videos/#{&1.slug}", newest_datetime(&1.published_at, &1.updated_at)))
  end

  defp prompt_entries(limit) do
    from(p in Prompt,
      order_by: [desc: p.updated_at, desc: p.id],
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.map(&entry("/prompts/#{&1.id}", &1.updated_at))
  end

  defp course_entries(limit) do
    from(c in Course,
      order_by: [desc: c.updated_at, desc: c.id],
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.map(&entry("/courses/#{&1.slug}", &1.updated_at))
  end

  defp lesson_entries(limit) do
    from(l in Lesson,
      join: c in assoc(l, :course),
      where: not is_nil(l.slug) and not is_nil(c.slug),
      order_by: [desc: l.updated_at, desc: l.id],
      limit: ^limit,
      select: {l, c.slug}
    )
    |> Repo.all()
    |> Enum.map(fn {lesson, course_slug} ->
      entry("/courses/#{course_slug}/lessons/#{lesson.slug}", lesson.updated_at)
    end)
  end

  defp thread_entries(limit) do
    from(t in Thread,
      join: b in Board,
      on: b.id == t.board_id,
      join: c in Category,
      on: c.id == b.category_id,
      where: t.is_removed == false and b.is_hidden == false and c.is_hidden == false,
      order_by: [desc: t.updated_at, desc: t.id],
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.map(&entry("/forum/t/#{&1.id}", &1.updated_at))
  end

  defp entry(path, lastmod) do
    %{loc: absolute_url(path), lastmod: format_lastmod(lastmod)}
  end

  defp url_node(%{loc: loc, lastmod: nil}) do
    "<url><loc>#{xml_escape(loc)}</loc></url>"
  end

  defp url_node(%{loc: loc, lastmod: lastmod}) do
    "<url><loc>#{xml_escape(loc)}</loc><lastmod>#{xml_escape(lastmod)}</lastmod></url>"
  end

  defp format_lastmod(nil), do: nil

  defp format_lastmod(%DateTime{} = datetime) do
    datetime
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp format_lastmod(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> format_lastmod()
  end

  defp newest_datetime(nil, datetime), do: datetime
  defp newest_datetime(datetime, nil), do: datetime

  defp newest_datetime(%DateTime{} = left, %DateTime{} = right) do
    if DateTime.compare(left, right) == :gt, do: left, else: right
  end

  defp clamp_limit(limit) when is_integer(limit), do: limit |> max(1) |> min(@max_limit)
  defp clamp_limit(_limit), do: @default_limit

  defp xml_escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
