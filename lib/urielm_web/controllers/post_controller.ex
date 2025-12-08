defmodule UrielmWeb.PostController do
  use UrielmWeb, :controller

  alias Urielm.Content

  def index(conn, _params) do
    posts = Content.list_published_posts()
    render(conn, :index, posts: posts, page_title: "Blog", layout: {UrielmWeb.Layouts, :app}, current_page: "blog")
  end

  def show(conn, %{"slug" => slug}) do
    post = Content.get_post_by_slug!(slug)
    render(conn, :show, post: post, page_title: post.title, layout: {UrielmWeb.Layouts, :app}, current_page: "blog")
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_flash(:error, "Post not found")
      |> redirect(to: ~p"/blog")
  end
end
