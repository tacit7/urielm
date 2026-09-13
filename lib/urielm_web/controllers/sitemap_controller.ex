defmodule UrielmWeb.SitemapController do
  use UrielmWeb, :controller

  alias Urielm.SEO.Sitemap

  def index(conn, _params) do
    xml =
      Sitemap.entries()
      |> Sitemap.to_xml()

    conn
    |> put_resp_content_type("application/xml")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(:ok, xml)
  end
end
