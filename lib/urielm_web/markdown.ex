defmodule UrielmWeb.Markdown do
  @bare_url_regex ~r"(?<![@\w])((?:https?://|www\.)[^\s<]+|(?:[a-z0-9-]+\.)+[a-z]{2,}(?:/[^\s<]*)?)"i
  @trailing_url_punctuation ~r/[.,;:!?)}\]]+$/

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
    extension =
      opts
      |> Keyword.get(:extension, [])
      |> Keyword.put_new(:autolink, true)

    parse =
      opts
      |> Keyword.get(:parse, [])
      |> Keyword.put_new(:relaxed_autolinks, true)

    opts
    |> Keyword.drop([:code_class_prefix])
    |> Keyword.put(:extension, extension)
    |> Keyword.put(:parse, parse)
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
    |> linkify_remaining_text_urls()
    |> HtmlSanitizeEx.markdown_html()
    |> Phoenix.HTML.raw()
  end

  # Pre-pass only: an HTML parser treats <script>/<style> contents as raw text,
  # so the scrubber removes the tags but leaves the JS/CSS source behind as
  # visible text. Not an XSS vector, but undesirable in rendered content.
  defp strip_script_and_style_blocks(html) do
    Regex.replace(~r{<(script|style)\b[^>]*>.*?</\s*\1\s*>}is, html, "")
  end

  defp linkify_remaining_text_urls(html) do
    case Floki.parse_fragment(html) do
      {:ok, tree} -> tree |> linkify_nodes() |> Floki.raw_html()
      {:error, _reason} -> html
    end
  end

  defp linkify_nodes(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &linkify_node/1)

  defp linkify_node(text) when is_binary(text), do: linkify_text(text)

  defp linkify_node({tag, attrs, children}) when tag in ["a", "code", "pre"],
    do: [{tag, attrs, children}]

  defp linkify_node({tag, attrs, children}) do
    [{tag, attrs, linkify_nodes(List.wrap(children))}]
  end

  defp linkify_node(node), do: [node]

  defp linkify_text(text) do
    @bare_url_regex
    |> Regex.split(text, include_captures: true, trim: false)
    |> Enum.map(fn part ->
      if Regex.match?(@bare_url_regex, part) do
        {url, trailing} = split_trailing_punctuation(part)
        href = normalize_href(url)

        [{"a", [{"href", href}], [url]}, trailing]
      else
        part
      end
    end)
    |> List.flatten()
    |> Enum.reject(&(&1 == ""))
  end

  defp split_trailing_punctuation(url) do
    case Regex.run(@trailing_url_punctuation, url) do
      [trailing] -> {String.replace_suffix(url, trailing, ""), trailing}
      nil -> {url, ""}
    end
  end

  defp normalize_href("http://" <> _ = url), do: url
  defp normalize_href("https://" <> _ = url), do: url
  defp normalize_href(url), do: "https://" <> url
end
