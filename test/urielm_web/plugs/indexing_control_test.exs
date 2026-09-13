defmodule UrielmWeb.Plugs.IndexingControlTest do
  use UrielmWeb.ConnCase, async: false

  test "marks account HTML routes noindex without changing the page render", %{conn: conn} do
    conn = get(conn, ~p"/signin")
    document = LazyHTML.from_fragment(html_response(conn, 200))

    assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
    assert LazyHTML.filter(document, "#signin-form") != []
  end

  test "leaves privacy policy indexable", %{conn: conn} do
    conn = get(conn, ~p"/privacy")
    document = LazyHTML.from_fragment(html_response(conn, 200))

    assert get_resp_header(conn, "x-robots-tag") == []
    assert LazyHTML.filter(document, "#privacy-policy-page") != []
  end

  test "marks internal search and theme utility routes noindex", %{conn: conn} do
    search_conn = get(conn, ~p"/forum/search")
    theme_conn = build_conn() |> get(~p"/themes")

    assert get_resp_header(search_conn, "x-robots-tag") == ["noindex"]
    assert get_resp_header(theme_conn, "x-robots-tag") == ["noindex"]
  end
end
