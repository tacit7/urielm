defmodule UrielmWeb.ThemePaletteTest do
  use ExUnit.Case, async: true

  @app_css Path.expand("../../assets/css/app.css", __DIR__)
  @themes_live Path.expand("../../lib/urielm_web/live/themes_live.ex", __DIR__)

  test "Tokyo themes use midnight blue and teal semantic accents" do
    css = File.read!(@app_css)
    themes_live = File.read!(@themes_live)

    assert css =~ "--color-secondary: #6b82bd;"
    assert css =~ "--color-info: #6b82bd;"
    assert css =~ "--color-accent: #73daca;"
    assert css =~ "--color-secondary: #304b80;"
    assert css =~ "--color-info: #304b80;"
    assert css =~ "--color-accent: #007c79;"
    assert themes_live =~ ~s|secondary: "#6b82bd"|
    assert themes_live =~ ~s|secondary: "#304b80"|

    refute css =~ "--color-secondary: #7dcfff;"
    refute css =~ "--color-secondary: #007197;"
    refute css =~ "--color-secondary: #bb9af7;"
    refute css =~ "--color-secondary: #7847bd;"
  end
end
