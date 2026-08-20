defmodule UrielmWeb.PageControllerTest do
  use UrielmWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~ ~s(id="home-hero")
  end
end
