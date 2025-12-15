defmodule UrielmWeb.Params do
  @moduledoc """
  Helpers for normalizing params in LiveView events.

  Standardize on string keys before Ecto casting to avoid mixed key errors.
  """

  @doc """
  Deeply converts all map keys to strings. Lists are traversed.

  Atoms and strings are preserved as values; only keys are coerced.
  """
  def normalize(params), do: do_normalize(params)

  defp do_normalize(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), do_normalize(v)} end)
    |> Map.new()
  end

  defp do_normalize(list) when is_list(list), do: Enum.map(list, &do_normalize/1)
  defp do_normalize(other), do: other
end
