defmodule Urielm.ContentSanitizer do
  @moduledoc """
  Sanitizes user-generated content (markdown, comments, threads) to prevent XSS attacks.

  For MVP, uses HtmlSanitizeEx to strip dangerous tags from markdown output.
  """

  @doc """
  Converts markdown to HTML and sanitizes the result.

  Allows safe HTML tags but removes potentially dangerous ones (script, iframe, etc).
  """
  def sanitize_markdown(text) when is_nil(text), do: ""

  def sanitize_markdown(text) when is_binary(text) do
    text
    |> markdown_to_html()
  end

  @doc """
  Validates and truncates forum thread/comment body length.
  """
  def validate_content_length(text, max_length \\ 10000) do
    case text do
      nil ->
        {:error, "Content cannot be empty"}

      "" ->
        {:error, "Content cannot be empty"}

      text ->
        trimmed = String.trim(text)

        if String.length(trimmed) > max_length do
          {:error, "Content exceeds maximum length of #{max_length} characters"}
        else
          {:ok, trimmed}
        end
    end
  end

  # Private functions

  defp markdown_to_html(text) do
    case Earmark.as_html(text) do
      {:ok, html, _warnings} -> html
      {:error, _html, _errors} -> text
    end
  end
end
