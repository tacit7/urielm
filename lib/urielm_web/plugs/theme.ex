defmodule UrielmWeb.Plugs.Theme do
  @moduledoc """
  Reads the preferred theme from cookie and assigns it for layouts.

  Normalizes persisted theme preferences to the supported Tokyo theme pair.
  """
  import Plug.Conn

  @behaviour Plug

  @cookie "phx_theme"
  @light_themes ~w(tokyo-day light catppuccin-latte github-light cupcake bumblebee emerald corporate retro valentine garden lofi pastel fantasy wireframe cmyk autumn acid lemonade winter)

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    theme = normalize_theme(conn.cookies[@cookie])
    assign(conn, :theme, theme)
  end

  defp normalize_theme(theme) when theme in @light_themes, do: "tokyo-day"
  defp normalize_theme(_theme), do: "tokyo-night"
end
