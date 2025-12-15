defmodule Urielm.Params do
  @moduledoc """
  Param normalization helpers for core contexts.

  Use to standardize incoming maps to string-keyed maps before casting with Ecto.
  """

  @doc """
  Deeply converts all map keys to strings. Lists are traversed.
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
