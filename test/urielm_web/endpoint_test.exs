defmodule UrielmWeb.EndpointTest do
  use UrielmWeb.ConnCase, async: true

  test "GET /sw.js retires stale service-worker registrations", %{conn: conn} do
    conn = get(conn, "/sw.js")

    assert response(conn, 200) =~ "registration.unregister"
    assert [content_type] = get_resp_header(conn, "content-type")
    assert content_type =~ "javascript"
  end

  test "browser CSP allows YouTube video playback", %{conn: conn} do
    conn = get(conn, "/videos")

    assert [csp] = get_resp_header(conn, "content-security-policy")
    assert csp =~ "frame-src 'self' https://www.youtube.com https://www.youtube-nocookie.com"
    assert csp =~ "script-src 'self' https://www.youtube.com"
  end
end
