defmodule UrielmWeb.RegistrationLimiter do
  @moduledoc """
  Shared registration budget, checked before either registration changeset hashes a password.

  Forwarded addresses are accepted only from `:trusted_proxy_ips`, a list of IP tuples
  (defaults to IPv4/IPv6 loopback for a local reverse proxy). Configure this list when
  the app's proxy runs on another host. `:trusted_proxy_hops` defaults to one appending
  proxy; its rightmost address is used, never attacker-prepended entries.
  """
  alias Urielm.RateLimiter

  def check(ip, email) do
    identifier = if is_binary(email), do: email |> String.trim() |> String.downcase(), else: ""

    RateLimiter.check_all([
      {"auth_ip:#{ip}", "signup", max_requests: 5, window_seconds: 60},
      {"auth_id:#{identifier}", "signup", max_requests: 3, window_seconds: 60}
    ])
  end

  def client_ip(peer, headers) do
    trusted =
      Application.get_env(:urielm, :trusted_proxy_ips, [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}])

    hops = Application.get_env(:urielm, :trusted_proxy_hops, 1)

    forwarded =
      for {"x-forwarded-for", value} <- headers,
          address <- String.split(value, ","),
          do: String.trim(address)

    address = if peer in trusted and is_integer(hops) and hops > 0, do: Enum.at(forwarded, -hops)

    case parse_ip(address) do
      {:ok, ip} -> ip |> :inet.ntoa() |> to_string()
      _ -> peer |> :inet.ntoa() |> to_string()
    end
  end

  defp parse_ip(address) when is_binary(address),
    do: :inet.parse_address(String.to_charlist(address))

  defp parse_ip(_), do: {:error, :einval}
end
