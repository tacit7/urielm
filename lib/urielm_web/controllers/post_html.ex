defmodule UrielmWeb.PostHTML do
  use UrielmWeb, :html

  embed_templates "post_html/*"

  def markdown_to_html(markdown), do: UrielmWeb.Markdown.to_html(markdown)
end
