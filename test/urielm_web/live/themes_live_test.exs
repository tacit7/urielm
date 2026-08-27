defmodule UrielmWeb.ThemesLiveTest do
  use UrielmWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders a responsive shared page hierarchy with theme controls", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/themes")

    assert has_element?(view, "#themes-page.ui-page-shell")
    assert has_element?(view, "#themes-page-header.ui-page-header")
    assert has_element?(view, "#theme-options")
    assert has_element?(view, "#theme-option-tokyo-night[aria-pressed='true']")
    assert has_element?(view, "#theme-option-tokyo-day[aria-pressed='false']")
    assert has_element?(view, "#theme-preview[data-theme='tokyo-night']")
    assert has_element?(view, "#apply-theme-button")
  end

  test "updates the component preview when a color mode is selected", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/themes")
    themes_view = find_live_child(view, "page-themes")

    themes_view
    |> element("#theme-option-tokyo-day")
    |> render_click()

    assert has_element?(themes_view, "#theme-option-tokyo-day[aria-pressed='true']")
    assert has_element?(themes_view, "#theme-option-tokyo-night[aria-pressed='false']")
    assert has_element?(themes_view, "#theme-preview[data-theme='tokyo-day']")
  end
end
