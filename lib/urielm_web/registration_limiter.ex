defmodule UrielmWeb.RegistrationLimiter do
  @moduledoc """
  Shared registration budget, checked before either registration changeset hashes a password.

  Client addresses are resolved by `UrielmWeb.ClientIP` for both transports.
  """
  alias Urielm.RateLimiter

  def check(ip, email) do
    identifier = if is_binary(email), do: email |> String.trim() |> String.downcase(), else: ""

    RateLimiter.check_all([
      {"auth_ip:#{ip}", "signup", max_requests: 5, window_seconds: 60},
      {"auth_id:#{identifier}", "signup", max_requests: 3, window_seconds: 60}
    ])
  end

  defdelegate client_ip(peer, headers), to: UrielmWeb.ClientIP
end
