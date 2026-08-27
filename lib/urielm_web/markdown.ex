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
    # Real sanitization is HtmlSanitizeEx.markdown_html/1: it allowlists safe
    # tags/attributes (including `class` on <code> for syntax highlighting) and
    # drops event handlers, javascript: URLs, <iframe>, inline SVG, etc. Earmark
    # passes raw inline HTML straight through, so this is what actually protects
    # the Phoenix.HTML.raw/1 call downstream.
    html
    |> strip_script_and_style_blocks()
    |> HtmlSanitizeEx.markdown_html()
    |> Phoenix.HTML.raw()
  end

  # Pre-pass only: an HTML parser treats <script>/<style> contents as raw text,
  # so the scrubber removes the tags but leaves the JS/CSS source behind as
  # visible text. Not an XSS vector, but undesirable in rendered content.
  defp strip_script_and_style_blocks(html) do
    Regex.replace(~r{<(script|style)\b[^>]*>.*?</\s*\1\s*>}is, html, "")
  end
end
