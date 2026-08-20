defmodule UrielmWeb.Plugs.ThemeTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias UrielmWeb.Plugs.Theme

  test "defaults to Tokyo Night" do
    conn =
      :get
      |> conn("/")
      |> fetch_cookies()
      |> Theme.call([])

    assert conn.assigns.theme == "tokyo-night"
  end

  test "keeps supported Tokyo preferences" do
    conn = conn_with_theme("tokyo-day")

    assert conn.assigns.theme == "tokyo-day"
  end

  test "migrates legacy light and dark preferences" do
    assert conn_with_theme("light").assigns.theme == "tokyo-day"
    assert conn_with_theme("catppuccin-latte").assigns.theme == "tokyo-day"
    assert conn_with_theme("dark").assigns.theme == "tokyo-night"
    assert conn_with_theme("midnight").assigns.theme == "tokyo-night"
  end

  defp conn_with_theme(theme) do
    :get
    |> conn("/")
    |> put_req_cookie("phx_theme", theme)
    |> fetch_cookies()
    |> Theme.call([])
  end
end
