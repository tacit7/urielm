defmodule UrielmWeb.ClientIPTest do
  use ExUnit.Case, async: false
  alias UrielmWeb.ClientIP

  setup do
    keys = [:trusted_proxy_ips, :trusted_proxy_cidrs, :trusted_proxy_hops]
    previous = Enum.map(keys, &{&1, Application.fetch_env(:urielm, &1)})
    Enum.each(keys, &Application.delete_env(:urielm, &1))

    on_exit(fn ->
      for {key, value} <- previous do
        case value do
          {:ok, value} -> Application.put_env(:urielm, key, value)
          :error -> Application.delete_env(:urielm, key)
        end
      end
    end)

    :ok
  end

  test "fixes mapped Cloudflare peers falling outside their IPv4 trust CIDR" do
    Application.put_env(:urielm, :trusted_proxy_cidrs, ["173.245.48.0/20"])
    peer = {0, 0, 0, 0, 0, 65535, 0xADF5, 0x3001}
    assert ClientIP.client_ip(peer, xff("198.51.100.4")) == "198.51.100.4"
  end

  test "mapped loopback and native or mapped exact tuples have equivalent trust" do
    native = {10, 0, 0, 1}
    mapped = {0, 0, 0, 0, 0, 65535, 0x0A00, 1}

    assert ClientIP.client_ip({0, 0, 0, 0, 0, 65535, 0x7F00, 1}, xff("198.51.100.4")) ==
             "198.51.100.4"

    for configured <- [native, mapped], peer <- [native, mapped] do
      Application.put_env(:urielm, :trusted_proxy_ips, [configured])
      assert ClientIP.client_ip(peer, xff("198.51.100.4")) == "198.51.100.4"
    end
  end

  test "mapped IPv4 CIDR boundaries exclude outsiders and retain IPv6 family separation" do
    Application.put_env(:urielm, :trusted_proxy_cidrs, ["173.245.48.0/20"])

    for low <- [0x3000, 0x3FFF] do
      assert ClientIP.client_ip({0, 0, 0, 0, 0, 65535, 0xADF5, low}, xff("198.51.100.4")) ==
               "198.51.100.4"
    end

    for {low, expected} <- [{0x2FFF, "173.245.47.255"}, {0x4000, "173.245.64.0"}] do
      assert ClientIP.client_ip({0, 0, 0, 0, 0, 65535, 0xADF5, low}, xff("198.51.100.4")) ==
               expected
    end

    Application.put_env(:urielm, :trusted_proxy_cidrs, ["::/0"])

    assert ClientIP.client_ip({0, 0, 0, 0, 0, 65535, 0xADF5, 0x3001}, xff("198.51.100.4")) ==
             "173.245.48.1"

    assert ClientIP.client_ip({173, 245, 48, 1}, xff("198.51.100.4")) == "173.245.48.1"

    assert ClientIP.client_ip({0x2001, 0xDB8, 0, 0, 0, 0, 0, 1}, xff("198.51.100.4")) ==
             "198.51.100.4"
  end

  test "untrusted peers ignore malicious headers and Cloudflare is not trusted by default" do
    for peer <- [{192, 0, 2, 3}, {173, 245, 48, 1}] do
      expected = peer |> :inet.ntoa() |> to_string()
      assert ClientIP.client_ip(peer, xff("198.51.100.4")) == expected
      assert ClientIP.client_ip(peer, xff("garbage, 198.51.100.5")) == expected
    end
  end

  test "loopback and configured exact proxy tuples accept canonical addresses" do
    assert ClientIP.client_ip({127, 0, 0, 1}, xff(" 2001:0DB8:0:0:0:0:0:1 ")) == "2001:db8::1"
    assert ClientIP.client_ip({0, 0, 0, 0, 0, 0, 0, 1}, xff("198.51.100.4")) == "198.51.100.4"
    Application.put_env(:urielm, :trusted_proxy_ips, [{10, 0, 0, 1}])
    assert ClientIP.client_ip({10, 0, 0, 1}, xff("::ffff:198.51.100.4")) == "198.51.100.4"
    assert ClientIP.client_ip({0, 0, 0, 0, 0, 65535, 0xC633, 0x6404}, []) == "198.51.100.4"
    assert ClientIP.client_ip({127, 0, 0, 1}, xff("198.51.100.4")) == "127.0.0.1"
  end

  test "IPv4 CIDRs include both boundaries and exclude adjacent addresses" do
    Application.put_env(:urielm, :trusted_proxy_cidrs, ["192.0.2.4/30"])

    for last <- [4, 5, 6, 7] do
      assert ClientIP.client_ip({192, 0, 2, last}, xff("198.51.100.4")) == "198.51.100.4"
    end

    for last <- [3, 8] do
      assert ClientIP.client_ip({192, 0, 2, last}, xff("198.51.100.4")) == "192.0.2.#{last}"
    end
  end

  test "IPv6 CIDRs enforce prefix boundaries and address family" do
    Application.put_env(:urielm, :trusted_proxy_cidrs, ["2001:db8::/126"])

    for last <- [0, 1, 2, 3] do
      assert ClientIP.client_ip({0x2001, 0xDB8, 0, 0, 0, 0, 0, last}, xff("198.51.100.4")) ==
               "198.51.100.4"
    end

    assert ClientIP.client_ip({0x2001, 0xDB8, 0, 0, 0, 0, 0, 4}, xff("198.51.100.4")) ==
             "2001:db8::4"

    assert ClientIP.client_ip({192, 0, 2, 4}, xff("198.51.100.4")) == "192.0.2.4"
    Application.put_env(:urielm, :trusted_proxy_cidrs, ["192.0.2.4/32", "2001:db8::4/128"])
    assert ClientIP.client_ip({192, 0, 2, 4}, xff("198.51.100.4")) == "198.51.100.4"

    assert ClientIP.client_ip({0x2001, 0xDB8, 0, 0, 0, 0, 0, 4}, xff("198.51.100.4")) ==
             "198.51.100.4"
  end

  test "invalid CIDR configuration does not grant trust" do
    Application.put_env(:urielm, :trusted_proxy_cidrs, [
      "bad",
      "192.0.2.0/33",
      "::/129",
      "192.0.2.0/-1",
      "192.0.2.0/24suffix",
      nil
    ])

    assert ClientIP.client_ip({192, 0, 2, 4}, xff("198.51.100.4")) == "192.0.2.4"
  end

  test "missing and malformed selected headers fall back without shifting empty entries" do
    assert ClientIP.client_ip({127, 0, 0, 1}, []) == "127.0.0.1"

    for value <- [
          "",
          " ",
          "198.51.100.4,",
          "garbage",
          "127.1",
          "2130706433",
          "198.51.100.999",
          "[2001:db8::1]",
          "198.51.100.1:80",
          "fe80::1%eth0"
        ] do
      assert ClientIP.client_ip({127, 0, 0, 1}, xff(value)) == "127.0.0.1"
    end
  end

  test "only positive hop counts and sufficiently long chains are accepted" do
    for hops <- [0, -1, "1", nil, 1.5] do
      Application.put_env(:urielm, :trusted_proxy_hops, hops)
      assert ClientIP.client_ip({127, 0, 0, 1}, xff("198.51.100.1")) == "127.0.0.1"
    end

    Application.put_env(:urielm, :trusted_proxy_hops, 2)
    assert ClientIP.client_ip({127, 0, 0, 1}, xff("198.51.100.1")) == "127.0.0.1"
    assert ClientIP.client_ip({127, 0, 0, 1}, xff("198.51.100.1,,203.0.113.1")) == "127.0.0.1"

    assert ClientIP.client_ip({127, 0, 0, 1}, [
             {"x-forwarded-for", "198.51.100.1"},
             {"x-forwarded-for", "203.0.113.1"}
           ]) == "198.51.100.1"
  end

  defp xff(value), do: [{"x-forwarded-for", value}]
end
