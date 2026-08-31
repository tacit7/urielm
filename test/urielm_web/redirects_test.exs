defmodule UrielmWeb.RedirectsTest do
  use ExUnit.Case, async: true

  alias UrielmWeb.Redirects

  test "allows local paths with query strings and fragments" do
    assert Redirects.safe_return_path("/forum?sort=new#latest") == "/forum?sort=new#latest"
  end

  test "rejects absolute and protocol-relative URLs" do
    assert Redirects.safe_return_path("https://evil.test/phish") == "/"
    assert Redirects.safe_return_path("//evil.test/phish") == "/"
  end

  test "rejects control characters and backslashes" do
    assert Redirects.safe_return_path("/safe\r\nLocation: //evil.test") == "/"
    assert Redirects.safe_return_path("/\\evil.test") == "/"
  end
end
