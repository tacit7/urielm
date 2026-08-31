defmodule UrielmWeb.Redirects do
  @moduledoc """
  Helpers for constraining stored redirect destinations to local paths.
  """

  @fallback "/"

  def safe_return_path(path, fallback \\ @fallback)
  def safe_return_path(nil, fallback), do: fallback
  def safe_return_path("", fallback), do: fallback

  def safe_return_path(path, fallback) when is_binary(path) and is_binary(fallback) do
    path = String.trim(path)

    if local_path?(path), do: path, else: fallback
  end

  def safe_return_path(_path, fallback), do: fallback

  defp local_path?(path) do
    String.starts_with?(path, "/") and
      not String.starts_with?(path, "//") and
      not String.contains?(path, "\\") and
      not String.contains?(path, ["\r", "\n"]) and
      match?(%URI{scheme: nil, host: nil}, URI.parse(path))
  end
end
