defmodule UrielmWeb.ShortUrlController do
  use UrielmWeb, :controller

  alias Urielm.Content

  def prompt(conn, %{"id" => id}) do
    redirect(conn, to: ~p"/prompts/#{id}")
  end

  def video(conn, %{"id" => id}) do
    case Content.get_video_by_short_id(id) do
      nil ->
        conn
        |> put_flash(:error, "Video not found")
        |> redirect(to: ~p"/courses")

      video ->
        redirect(conn, to: ~p"/videos/#{video.slug}")
    end
  end
end
