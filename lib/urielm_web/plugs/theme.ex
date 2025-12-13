defmodule UrielmWeb.Plugs.Theme do
  @moduledoc """
  Reads the preferred theme from cookie and assigns it for layouts.

  Stores theme string such as "system", "light", "dark", or any daisyUI theme.
  """
  import Plug.Conn

  @behaviour Plug

  @cookie "phx_theme"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    theme = conn.cookies[@cookie] || "system"
    assign(conn, :theme, theme)
  end
end
