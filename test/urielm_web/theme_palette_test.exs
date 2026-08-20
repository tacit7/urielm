defmodule UrielmWeb.ThemePaletteTest do
  use ExUnit.Case, async: true

  @app_css Path.expand("../../assets/css/app.css", __DIR__)

  test "Tokyo themes use blue, cyan, and teal semantic accents" do
    css = File.read!(@app_css)

    assert css =~ "--color-secondary: #7dcfff;"
    assert css =~ "--color-accent: #73daca;"
    assert css =~ "--color-secondary: #007197;"
    assert css =~ "--color-accent: #007c79;"

    refute css =~ "--color-secondary: #bb9af7;"
    refute css =~ "--color-secondary: #7847bd;"
  end
end
