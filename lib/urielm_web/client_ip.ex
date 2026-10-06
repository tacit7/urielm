defmodule UrielmWeb.ClientIP do
  @moduledoc """
  Resolves a canonical client address for HTTP and LiveView rate limits.

  Forwarded headers are trusted only when the socket peer matches
  `:trusted_proxy_ips` (IP tuples, defaulting to loopback) or
  `:trusted_proxy_cidrs` (CIDR strings, defaulting to none).
  `:trusted_proxy_hops` must match the number of appending proxies in the
  deployment. IPv4-mapped socket peers and exact trusted tuples are normalized
  to IPv4 before trust checks; IPv6 CIDRs do not grant IPv4 trust.
  Invalid addresses or incomplete chains fall back to the peer.
  """
  import Bitwise

  @loopback [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}]

  def client_ip(peer, headers) do
    peer = unmap(peer)
    hops = Application.get_env(:urielm, :trusted_proxy_hops, 1)

    with true <- trusted?(peer),
         true <- is_integer(hops) and hops > 0,
         addresses when length(addresses) >= hops <- forwarded_addresses(headers),
         {:ok, ip} <- parse_ip(Enum.at(addresses, -hops)) do
      canonical(ip)
    else
      _ -> canonical(peer)
    end
  end

  defp trusted?(peer) do
    Enum.any?(Application.get_env(:urielm, :trusted_proxy_ips, @loopback), &(unmap(&1) == peer)) or
      Enum.any?(Application.get_env(:urielm, :trusted_proxy_cidrs, []), &within_cidr?(peer, &1))
  end

  defp forwarded_addresses(headers) do
    for {"x-forwarded-for", value} <- headers,
        is_binary(value),
        address <- String.split(value, ","),
        do: String.trim(address)
  end

  defp within_cidr?(peer, cidr) when is_binary(cidr) do
    with [address, prefix] <- String.split(cidr, "/"),
         {:ok, network} <- parse_ip(address),
         true <- tuple_size(peer) == tuple_size(network),
         {bits, ""} <- Integer.parse(prefix),
         size = tuple_size(network) * if(tuple_size(network) == 4, do: 8, else: 16),
         true <- bits >= 0 and bits <= size do
      integer_ip(peer) >>> (size - bits) == integer_ip(network) >>> (size - bits)
    else
      _ -> false
    end
  end

  defp within_cidr?(_, _), do: false

  defp integer_ip(ip) do
    width = if tuple_size(ip) == 4, do: 8, else: 16
    ip |> Tuple.to_list() |> Enum.reduce(0, fn part, acc -> (acc <<< width) + part end)
  end

  # parse_strict_address rejects inet's abbreviated/legacy IPv4 forms.
  defp parse_ip(address) when is_binary(address) do
    if String.contains?(address, "%") do
      {:error, :einval}
    else
      :inet.parse_strict_address(String.to_charlist(address))
    end
  end

  defp parse_ip(_), do: {:error, :einval}

  # Share normalization between socket trust and bucket output.
  defp unmap({0, 0, 0, 0, 0, 65535, high, low}),
    do: {high >>> 8, high &&& 255, low >>> 8, low &&& 255}

  defp unmap(ip), do: ip

  defp canonical(ip), do: ip |> unmap() |> :inet.ntoa() |> to_string()
end
