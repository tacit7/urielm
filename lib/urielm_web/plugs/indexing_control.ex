defmodule UrielmWeb.Plugs.IndexingControl do
  @moduledoc """
  Adds robots indexing headers to utility and private app surfaces.
  """

  import Plug.Conn

  @behaviour Plug

  @header_value "noindex, nofollow"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    if noindex_path?(conn.path_info) do
      put_resp_header(conn, "x-robots-tag", @header_value)
    else
      conn
    end
  end

  defp noindex_path?(["admin" | _]), do: true
  defp noindex_path?(["auth" | _]), do: true
  defp noindex_path?(["api" | _]), do: true
  defp noindex_path?(["signin"]), do: true
  defp noindex_path?(["signup" | _]), do: true
  defp noindex_path?(["suspended"]), do: true
  defp noindex_path?(["profile"]), do: true
  defp noindex_path?(["settings"]), do: true
  defp noindex_path?(["chat"]), do: true
  defp noindex_path?(["saved"]), do: true
  defp noindex_path?(["notifications"]), do: true
  defp noindex_path?(["themes"]), do: true
  defp noindex_path?(["forum", "search"]), do: true
  defp noindex_path?(["forum", "b", _board_slug, "new"]), do: true
  defp noindex_path?(_path_info), do: false
end
