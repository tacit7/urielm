defmodule UrielmWeb.Markdown do
  def to_html(markdown, opts \\ []) do
    case MDEx.to_html(markdown || "", mdex_opts(opts)) do
      {:ok, html} -> sanitize_and_wrap(html)
      {:error, _reason} -> sanitize_and_wrap("")
    end
  end

  def to_html!(markdown, opts \\ []) do
    MDEx.to_html!(markdown || "", mdex_opts(opts))
    |> sanitize_and_wrap()
  end

  defp mdex_opts(opts) do
    opts
    |> Keyword.drop([:code_class_prefix])
    |> Keyword.put_new(:render, unsafe_: true)
  end

  # sobelow_skip ["XSS.Raw"]
  defp sanitize_and_wrap(html) do
    # Real sanitization is HtmlSanitizeEx.markdown_html/1: it allowlists safe
    # tags/attributes (including `class` on <code> for syntax highlighting) and
    # drops event handlers, javascript: URLs, <iframe>, inline SVG, etc. MDEx
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
