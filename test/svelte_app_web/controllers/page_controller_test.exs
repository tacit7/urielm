defmodule UrielmWeb.PageControllerTest do
  use UrielmWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    # Assert a stable headline substring from HomeLive
    assert html_response(conn, 200) =~ "Building the future with"
  end
end
