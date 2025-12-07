defmodule Urielm.Slugify do
  @doc """
  Turn a title like "My First Post!" into "my-first-post".
  """
  def slugify(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
