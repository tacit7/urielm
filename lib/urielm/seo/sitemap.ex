defmodule Urielm.SEO.Sitemap do
  @moduledoc """
  Builds the public XML sitemap entries for crawlers.
  """

  import Ecto.Query, warn: false

  alias Urielm.Content.{Post, Prompt, Video}
  alias Urielm.Forum.{Board, Category, Thread}
  alias Urielm.Learning.{Course, Lesson}
  alias Urielm.Repo

  @page_size 1_000
  @collections ~w(posts videos prompts courses lessons threads)

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

  @doc "Returns sitemap index entries for every page of eligible public content."
  def index_entries(opts \\ []) do
    size = page_size(opts)
    now = Keyword.get(opts, :now, DateTime.utc_now())

    [entry(child_sitemap_path("pages", 1), nil)] ++
      Enum.flat_map(@collections, fn collection ->
        count = Repo.aggregate(query(collection, now), :count)
        pages = div(count + size - 1, size)

        if pages == 0 do
          []
        else
          Enum.map(1..pages, &entry(child_sitemap_path(collection, &1), nil))
        end
      end)
  end

  @doc "Returns a bounded page of sitemap entries, or :not_found for an invalid page."
  def entries(collection, page, opts \\ [])

  def entries("pages", 1, _opts), do: {:ok, fixed_entries()}

  def entries(collection, page, opts)
      when collection in @collections and is_integer(page) and page > 0 do
    size = page_size(opts)
    query = query(collection, Keyword.get(opts, :now, DateTime.utc_now()))
    count = Repo.aggregate(query, :count)

    if page > max(div(count + size - 1, size), 1) do
      :not_found
    else
      entries =
        query
        |> order_by([row], asc: row.id)
        |> limit(^size)
        |> offset(^((page - 1) * size))
        |> Repo.all()
        |> Enum.map(&content_entry(collection, &1))

      {:ok, entries}
    end
  end

  def entries(_collection, _page, _opts), do: :not_found

  def index_xml(entries) do
    body = Enum.map_join(entries, "", &"<sitemap><loc>#{xml_escape(&1.loc)}</loc></sitemap>")

    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" <>
      "<sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">#{body}</sitemapindex>"
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

  defp absolute_url(path) when is_binary(path) do
    UrielmWeb.SEO.absolute_url(path)
  end

  defp fixed_entries do
    Enum.map(@fixed_paths, &entry(&1, nil))
  end

  defp child_sitemap_path(collection, page), do: "/sitemap-#{collection}-#{page}.xml"

  defp query("posts", now) do
    from(p in Post,
      where: p.status == "published" and not is_nil(p.published_at) and p.published_at <= ^now
    )
  end

  defp query("videos", now) do
    from(v in Video,
      where: v.visibility == "public" and not is_nil(v.published_at) and v.published_at <= ^now
    )
  end

  defp query("prompts", _now), do: Prompt
  defp query("courses", _now), do: Course

  defp query("lessons", _now) do
    from(l in Lesson,
      join: c in assoc(l, :course),
      where: not is_nil(l.slug) and not is_nil(c.slug),
      preload: [course: c]
    )
  end

  defp query("threads", _now) do
    from(t in Thread,
      join: b in Board,
      on: b.id == t.board_id,
      join: c in Category,
      on: c.id == b.category_id,
      where: t.is_removed == false and b.is_hidden == false and c.is_hidden == false
    )
  end

  defp content_entry("posts", post),
    do: entry("/blog/#{segment(post.slug)}", newest_datetime(post.published_at, post.updated_at))

  defp content_entry("videos", video),
    do:
      entry(
        "/videos/#{segment(video.slug)}",
        newest_datetime(video.published_at, video.updated_at)
      )

  defp content_entry("prompts", prompt), do: entry("/prompts/#{prompt.id}", prompt.updated_at)

  defp content_entry("courses", course),
    do: entry("/courses/#{segment(course.slug)}", course.updated_at)

  defp content_entry("lessons", lesson) do
    entry(
      "/courses/#{segment(lesson.course.slug)}/lessons/#{segment(lesson.slug)}",
      lesson.updated_at
    )
  end

  defp content_entry("threads", thread), do: entry("/forum/t/#{thread.id}", thread.updated_at)

  defp segment(value), do: URI.encode(value, &URI.char_unreserved?/1)
  defp page_size(opts), do: opts |> Keyword.get(:page_size, @page_size) |> max(1) |> min(10_000)

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
