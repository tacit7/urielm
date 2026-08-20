defmodule UrielmWeb.BlogLive do
  use UrielmWeb, :live_view

  alias Urielm.Content

  @impl true
  def mount(_params, session, socket) do
    # Get params from session (passed by ShellLive)
    child_params = session["child_params"] || %{}

    socket =
      if slug = child_params["slug"] do
        # Show individual post
        if connected?(socket) do
          case Content.get_post_by_slug(slug) do
            nil ->
              socket
              |> assign(:post, nil)
              |> assign(:posts, nil)
              |> assign(:meta_description, nil)
              |> assign(:og_title, nil)
              |> assign(:canonical_url, nil)
              |> push_navigate(to: ~p"/blog")

            post ->
              all_posts = Content.list_published_posts()
              current_index = Enum.find_index(all_posts, &(&1.id == post.id))

              prev_post =
                if current_index && current_index < length(all_posts) - 1,
                  do: Enum.at(all_posts, current_index + 1),
                  else: nil

              next_post =
                if current_index && current_index > 0,
                  do: Enum.at(all_posts, current_index - 1),
                  else: nil

              socket
              |> assign(:post, post)
              |> assign(:posts, nil)
              |> assign(:prev_post, prev_post)
              |> assign(:next_post, next_post)
              |> assign(:page_title, post.title)
              |> assign(:meta_description, post.excerpt || truncate_body(post.body, 160))
              |> assign(:og_title, post.title)
              |> assign(:og_type, "article")
              |> assign(:og_image, post.hero_image)
              |> assign(:canonical_url, "https://urielm.dev/blog/#{post.slug}")
          end
        else
          socket
          |> assign(:post, nil)
          |> assign(:posts, [])
          |> assign(:prev_post, nil)
          |> assign(:next_post, nil)
          |> assign(:og_title, nil)
          |> assign(:meta_description, nil)
          |> assign(:canonical_url, nil)
        end
      else
        # Show blog index
        if connected?(socket) do
          posts = Content.list_published_posts()

          socket
          |> assign(:posts, posts)
          |> assign(:post, nil)
          |> assign(:prev_post, nil)
          |> assign(:next_post, nil)
          |> assign(:page_title, "Blog")
          |> assign(:og_title, "Blog")
          |> assign(:canonical_url, "https://urielm.dev/blog")
        else
          socket
          |> assign(:post, nil)
          |> assign(:posts, [])
          |> assign(:prev_post, nil)
          |> assign(:next_post, nil)
          |> assign(:og_title, nil)
          |> assign(:meta_description, nil)
          |> assign(:canonical_url, nil)
        end
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @post do %>
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

              <span class="hidden sm:inline text-base-content/30 lg:text-base-content/25">•</span>

              <span>{read_time(@post.body)} min read</span>
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
            {UrielmWeb.Markdown.to_html!(@post.body, code_class_prefix: "language-")}
          </article>

          <nav class="mt-16 pt-8 border-t border-base-300/30 flex justify-between gap-4">
            <%= if @prev_post do %>
              <.link
                patch={~p"/blog/#{@prev_post.slug}"}
                class="group flex flex-col gap-1 max-w-[45%]"
              >
                <span class="text-xs text-base-content/40 group-hover:text-base-content/60">
                  &larr; Older
                </span>
                <span class="text-sm font-medium text-base-content/70 group-hover:text-primary transition-colors line-clamp-2">
                  {@prev_post.title}
                </span>
              </.link>
            <% else %>
              <div></div>
            <% end %>
            <%= if @next_post do %>
              <.link
                patch={~p"/blog/#{@next_post.slug}"}
                class="group flex flex-col gap-1 items-end max-w-[45%] text-right"
              >
                <span class="text-xs text-base-content/40 group-hover:text-base-content/60">
                  Newer &rarr;
                </span>
                <span class="text-sm font-medium text-base-content/70 group-hover:text-primary transition-colors line-clamp-2">
                  {@next_post.title}
                </span>
              </.link>
            <% else %>
              <div></div>
            <% end %>
          </nav>
        </div>

        <script type="application/ld+json">
          {raw(Jason.encode!(%{
            "@context" => "https://schema.org",
            "@type" => "BlogPosting",
            "headline" => @post.title,
            "description" => @meta_description,
            "url" => "https://urielm.dev/blog/#{@post.slug}",
            "datePublished" => if(@post.published_at, do: DateTime.to_iso8601(@post.published_at), else: nil),
            "image" => @post.hero_image,
            "author" => %{"@type" => "Person", "name" => "Uriel Maldonado"}
          }) |> String.replace("<", "\\u003c"))}
        </script>
      </div>
    <% else %>
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
                  "ui-card ui-card-interactive ui-card-compact relative p-5 sm:p-6",
                  if index == 0 do
                    "bg-base-200/70"
                  else
                    "bg-base-100/70"
                  end
                ]}>
                  <.link
                    patch={~p"/blog/#{post.slug}"}
                    class="absolute inset-0 z-0 rounded-lg"
                    aria-label={post.title}
                  >
                  </.link>
                  <div class="relative z-10">
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
                        {Calendar.strftime(post.published_at, "%B %d, %Y")} · {read_time(post.body)} min read
                      <% end %>
                    </p>

                    <p class="text-sm text-base-content/70 line-clamp-2 leading-relaxed">
                      {post.excerpt || truncate_body(post.body)}
                    </p>
                  </div>
                </article>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp read_time(body) do
    words = body |> String.split(~r/\s+/) |> Enum.count()
    max(1, ceil(words / 200))
  end

  defp truncate_body(body, max \\ 180) do
    if String.length(body) <= max do
      body
    else
      body
      |> String.slice(0, max)
      |> String.split(" ")
      |> Enum.drop(-1)
      |> Enum.join(" ")
      |> Kernel.<>("…")
    end
  end
end
