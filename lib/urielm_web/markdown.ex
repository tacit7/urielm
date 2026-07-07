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
    html
    |> String.replace(~r/<script[\s\S]*?<\/script>/i, "")
    |> Phoenix.HTML.raw()
  end
end
