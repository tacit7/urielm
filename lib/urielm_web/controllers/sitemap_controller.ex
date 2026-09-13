defmodule UrielmWeb.SitemapController do
  use UrielmWeb, :controller

  alias Urielm.SEO.Sitemap

  def index(conn, _params) do
    send_xml(conn, Sitemap.index_entries() |> Sitemap.index_xml())
  end

  def show(conn, %{"collection" => collection, "page" => page}) do
    with {page, ""} when page > 0 <- Integer.parse(page),
         {:ok, entries} <- Sitemap.entries(collection, page) do
      send_xml(conn, Sitemap.to_xml(entries))
    else
      _ -> send_resp(conn, :not_found, "Not found")
    end
  end

  defp send_xml(conn, xml) do
    conn
    |> put_resp_content_type("application/xml")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(:ok, xml)
  end
end
