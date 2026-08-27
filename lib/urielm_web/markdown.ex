defmodule UrielmWeb.Markdown do
  def to_html(markdown, opts \\ []) do
    case Earmark.as_html(markdown || "", opts) do
      {:ok, html, _} -> sanitize_and_wrap(html)
      {:error, html, _} -> sanitize_and_wrap(html)
    end
  end

  def to_html!(markdown, opts \\ []) do
    Earmark.as_html!(markdown || "", opts)
    |> sanitize_and_wrap()
  end

  defp sanitize_and_wrap(html) do
    # Earmark passes raw inline HTML straight through, so a regex that only
    # strips <script> is not a sanitizer. Run the output through
    # html_sanitize_ex's markdown scrubber, which allowlists safe tags and
    # attributes (including `class` on <code> for syntax highlighting) and
    # drops event handlers, javascript: URLs, iframes, and inline SVG.
    html
    |> HtmlSanitizeEx.markdown_html()
    |> Phoenix.HTML.raw()
  end
end
