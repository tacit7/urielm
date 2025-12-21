defmodule UrielmWeb.BlogLive do
  use UrielmWeb, :live_view

  alias Urielm.Content

  @impl true
  def mount(params, session, socket) do
    # Get params from session (passed by ShellLive)
    child_params = session["child_params"] || %{}

    socket =
      if slug = child_params["slug"] do
        # Show individual post
        case Content.get_post_by_slug(slug) do
          nil ->
            socket
            |> assign(:posts, nil)
            |> assign(:post, nil)
            |> assign(:page_title, "Post not found")

          post ->
            socket
            |> assign(:post, post)
            |> assign(:posts, nil)
            |> assign(:page_title, post.title)
            |> assign(:meta_description, post.excerpt || String.slice(post.body, 0, 160))
        end
      else
        # Show blog index
        posts = Content.list_published_posts()

        socket
        |> assign(:posts, posts)
        |> assign(:post, nil)
        |> assign(:page_title, "Blog")
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @posts do %>
      <div class="min-h-screen bg-base-100 flex flex-col">
        <div class="flex-1 max-w-4xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-20 lg:py-28">
          <header class="mb-12 lg:mb-16">
            <h1 class="text-3xl sm:text-4xl font-bold tracking-tight mb-4">
              Blog
            </h1>
            <p class="text-base sm:text-lg text-base-content/75 max-w-[70ch] leading-relaxed">
              Essays, notes, and deep dives on Elixir, Phoenix, AI workflows, and building products that matter. A space to think out loud.
            </p>
          </header>

          <%= if @posts == [] do %>
            <p class="text-base-content/60 text-center py-12">
              No posts yet.
            </p>
          <% else %>
            <div class="space-y-5">
              <%= for {post, index} <- Enum.with_index(@posts) do %>
                <article class={[
                  "border rounded-lg p-5 sm:p-6 transition-all hover:border-primary/60",
                  if index == 0 do
                    "border-base-300 bg-base-200/60 shadow-sm"
                  else
                    "border-base-300/50 bg-base-100 hover:shadow-sm"
                  end
                ]}>
                  <div class="flex items-start justify-between gap-4 mb-2">
                    <h2 class="text-lg sm:text-xl font-semibold flex-1 leading-tight">
                      <.link
                        patch={~p"/blog/#{post.slug}"}
                        class="hover:text-primary transition-colors"
                      >
                        {post.title}
                      </.link>
                    </h2>
                    <%= if index == 0 do %>
                      <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium whitespace-nowrap bg-primary/10 text-primary/80">
                        Latest
                      </span>
                    <% end %>
                  </div>

                  <p class="text-xs text-base-content/50 mb-3">
                    <%= if post.published_at do %>
                      {Calendar.strftime(post.published_at, "%B %d, %Y")}
                    <% end %>
                  </p>

                  <p class="text-sm text-base-content/70 line-clamp-2 leading-relaxed">
                    {post.excerpt || String.slice(post.body, 0, 180) <> "…"}
                  </p>
                </article>
              <% end %>
            </div>
          <% end %>
        </div>

        <footer class="border-t border-base-300/30 bg-base-100/50 py-8 px-4 sm:px-6 lg:px-8 mt-auto">
          <div class="max-w-4xl mx-auto">
            <p class="text-xs text-base-content/40 text-center">
              More writing coming. Follow along.
            </p>
          </div>
        </footer>
      </div>
    <% else %>
      <div class="min-h-screen bg-base-100 flex flex-col">
        <div class="flex-1 mx-auto w-full px-4 sm:px-6 lg:px-8 py-10 lg:py-14 max-w-[70ch]">
          <p class="text-xs sm:text-[13px] text-base-content/50 lg:text-base-content/40 mb-6">
            <.link
              patch={~p"/blog"}
              class="inline-flex items-center gap-1 hover:text-primary transition-colors"
            >
              &larr; Back to blog
            </.link>
          </p>

          <header class="mb-12 lg:mb-16">
            <h1 class="text-4xl sm:text-5xl font-bold tracking-tight text-base-content mb-4">
              {@post.title}
            </h1>

            <div class="flex flex-wrap items-center gap-3 text-xs sm:text-sm text-base-content/50 lg:text-base-content/35">
              <span>
                <%= if @post.published_at do %>
                  {Calendar.strftime(@post.published_at, "%b %d, %Y")}
                <% else %>
                  Draft
                <% end %>
              </span>

              <span class="hidden sm:inline text-base-content/30 lg:text-base-content/25">•</span>

              <span class="inline-flex items-center gap-1">
                <span class="w-1.5 h-1.5 rounded-full bg-primary/50 lg:bg-primary/30"></span>
                <span>Blog</span>
              </span>
            </div>
          </header>

          <%= if @post.hero_image do %>
            <div class="mb-12 lg:mb-16">
              <img
                src={@post.hero_image}
                alt={@post.title}
                class="w-full h-auto rounded-lg"
                loading="lazy"
              />
            </div>
          <% end %>

          <article class="prose" id="blog-article" phx-hook="HighlightCode">
            {raw(markdown_to_html(@post.body))}
          </article>
        </div>
      </div>
    <% end %>
    """
  end

  defp markdown_to_html(markdown) do
    markdown
    |> Earmark.as_html!()
  end
end
