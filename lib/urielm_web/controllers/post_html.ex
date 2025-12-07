defmodule UrielmWeb.PostHTML do
  use UrielmWeb, :html

  embed_templates "post_html/*"

  def markdown_to_html(markdown) do
    case Earmark.as_html(markdown || "") do
      {:ok, html, _warnings} ->
        Phoenix.HTML.raw(html)

      {:error, _html, _warnings} ->
        Phoenix.HTML.raw(markdown || "")
    end
  end
end
