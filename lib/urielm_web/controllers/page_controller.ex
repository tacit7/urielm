defmodule UrielmWeb.PageController do
  use UrielmWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
