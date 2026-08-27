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
          |> assign(:featured_post, List.first(posts))
          |> assign(:archive_posts, Enum.drop(posts, 1))
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
          |> assign(:featured_post, nil)
          |> assign(:archive_posts, [])
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
      <div id="blog-reading-shell" class="flex min-h-screen flex-col bg-base-100">
        <div class="mx-auto w-full max-w-[72ch] flex-1 px-5 py-12 sm:px-7 lg:py-20">
          <p class="mb-8 text-sm text-base-content/50">
            <.link
              patch={~p"/blog"}
              class="group inline-flex items-center gap-2 font-medium transition-colors hover:text-primary"
            >
              <.um_icon
                name="hero-arrow-left"
                class="size-4 transition-transform group-hover:-translate-x-0.5"
              /> Back to blog
            </.link>
          </p>

          <header id="blog-article-header" class="mb-12 lg:mb-16">
            <p class="ui-eyebrow text-secondary">Practical AI</p>
            <h1 class="mt-3 text-4xl font-black leading-[1.03] tracking-[-0.045em] text-base-content sm:text-5xl lg:text-6xl">
              {@post.title}
            </h1>

            <p
              :if={@post.excerpt}
              class="mt-5 text-lg leading-relaxed text-base-content/60 sm:text-xl"
            >
              {@post.excerpt}
            </p>

            <div class="mt-6 flex flex-wrap items-center gap-2.5 text-sm text-base-content/45">
              <span>
                <%= if @post.published_at do %>
                  {Calendar.strftime(@post.published_at, "%b %d, %Y")}
                <% else %>
                  Draft
                <% end %>
              </span>

              <span class="size-1 rounded-full bg-base-content/20" aria-hidden="true"></span>

              <span id="blog-reading-time">{read_time(@post.body)} min read</span>

              <span class="size-1 rounded-full bg-base-content/20" aria-hidden="true"></span>

              <span>Uriel Maldonado</span>
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

          <article class="prose blog-prose" id="blog-article" phx-hook="HighlightCode">
            {UrielmWeb.Markdown.to_html!(@post.body, code_class_prefix: "language-")}
          </article>

          <footer
            id="blog-article-footer"
            class="ui-card mt-16 flex flex-col items-start justify-between gap-5 p-6 sm:flex-row sm:items-center"
          >
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.14em] text-base-content/40">
                Continue exploring
              </p>
              <p class="mt-1 font-semibold text-base-content">
                More practical notes on building with AI
              </p>
            </div>
            <.link patch={~p"/blog"} class="btn btn-outline btn-sm rounded-full">
              Back to all posts
            </.link>
          </footer>

          <nav class="mt-8 flex justify-between gap-4 border-t border-base-300/30 pt-8">
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
      <div id="blog-index" class="flex min-h-screen flex-col overflow-hidden bg-base-100">
        <div class="ui-page-shell flex-1">
          <header id="blog-index-header" class="ui-page-header ui-page-heading">
            <h1 class="ui-section-title">
              Ideas worth building on.
            </h1>
            <p class="ui-section-copy">
              Practical notes on Elixir, Phoenix, AI workflows, and the craft of turning ambitious ideas into useful products.
            </p>
          </header>

          <%= if @posts == [] do %>
            <.empty_state
              id="blog-empty-state"
              title="The first note is taking shape"
              description="New essays about building thoughtful software and useful AI workflows will appear here."
              icon="hero-pencil-square"
              tone="secondary"
              class="mt-12 sm:mt-14"
            >
              <:action>
                <.link navigate={~p"/"} class="btn btn-outline btn-sm rounded-full">
                  Explore the site
                </.link>
              </:action>
            </.empty_state>
          <% else %>
            <article
              id={"blog-featured-post-#{@featured_post.id}"}
              class="ui-card ui-card-interactive overflow-hidden bg-base-200/60"
            >
              <.link
                patch={~p"/blog/#{@featured_post.slug}"}
                class="group grid lg:grid-cols-[1.2fr_0.8fr]"
              >
                <div class="flex flex-col justify-center p-6 sm:p-8 lg:p-10">
                  <span class="badge h-auto w-fit border-primary/20 bg-primary/10 px-3 py-1 text-xs font-bold uppercase tracking-[0.12em] text-primary">
                    Latest essay
                  </span>
                  <h2 class="mt-5 text-2xl font-black leading-tight tracking-[-0.03em] text-base-content transition-colors group-hover:text-primary sm:text-3xl lg:text-4xl">
                    {@featured_post.title}
                  </h2>
                  <p class="mt-4 max-w-2xl text-sm leading-relaxed text-base-content/65 sm:text-base">
                    {post_summary(@featured_post)}
                  </p>
                  <div class="mt-6 flex flex-wrap items-center gap-2.5 text-xs text-base-content/45 sm:text-sm">
                    <span>{format_post_date(@featured_post)}</span>
                    <span class="size-1 rounded-full bg-base-content/20" aria-hidden="true"></span>
                    <span>{read_time(@featured_post.body)} min read</span>
                    <span class="ml-1 inline-flex items-center gap-1 font-semibold text-primary transition-transform group-hover:translate-x-0.5">
                      Read essay <.um_icon name="hero-arrow-right" class="size-4" />
                    </span>
                  </div>
                </div>

                <%= if @featured_post.hero_image do %>
                  <div class="order-first min-h-48 overflow-hidden lg:order-last lg:min-h-80">
                    <img
                      src={@featured_post.hero_image}
                      alt=""
                      class="h-full w-full object-cover transition duration-500 group-hover:scale-[1.02]"
                    />
                  </div>
                <% else %>
                  <div class="order-first grid min-h-44 place-items-center bg-[radial-gradient(circle_at_30%_25%,color-mix(in_oklab,var(--color-secondary)_22%,transparent),transparent_42%),linear-gradient(145deg,var(--color-base-300),var(--color-base-200))] lg:order-last lg:min-h-80">
                    <span class="grid size-20 -rotate-3 place-items-center rounded-3xl border border-secondary/30 bg-base-100/30 text-secondary shadow-xl shadow-base-300/30 transition-transform duration-300 group-hover:rotate-0 group-hover:scale-105">
                      <.um_icon name="hero-sparkles" class="size-9" />
                    </span>
                  </div>
                <% end %>
              </.link>
            </article>

            <%= if @archive_posts != [] do %>
              <section class="mt-12 sm:mt-16" aria-labelledby="blog-archive-heading">
                <div class="mb-5 flex items-end justify-between gap-4">
                  <div>
                    <h2
                      id="blog-archive-heading"
                      class="text-2xl font-black tracking-tight text-base-content"
                    >
                      More from the blog
                    </h2>
                  </div>
                  <p class="hidden text-sm text-base-content/45 sm:block">
                    {article_count(@archive_posts)}
                  </p>
                </div>

                <div id="blog-posts" class="grid gap-4 md:grid-cols-2">
                  <%= for post <- @archive_posts do %>
                    <article
                      id={"blog-post-#{post.id}"}
                      class="ui-card ui-card-interactive overflow-hidden"
                    >
                      <.link
                        patch={~p"/blog/#{post.slug}"}
                        class="group flex h-full flex-col p-6 sm:p-7"
                      >
                        <div class="flex items-center gap-2 text-xs font-medium text-base-content/45">
                          <span>{format_post_date(post)}</span>
                          <span class="size-1 rounded-full bg-base-content/20" aria-hidden="true">
                          </span>
                          <span>{read_time(post.body)} min read</span>
                        </div>
                        <h3 class="mt-4 text-xl font-bold leading-snug tracking-tight text-base-content transition-colors group-hover:text-primary">
                          {post.title}
                        </h3>
                        <p class="mt-3 line-clamp-3 text-sm leading-relaxed text-base-content/60">
                          {post_summary(post)}
                        </p>
                        <span class="mt-6 inline-flex items-center gap-1 self-start text-sm font-semibold text-primary transition-transform group-hover:translate-x-0.5">
                          Read article <.um_icon name="hero-arrow-right" class="size-4" />
                        </span>
                      </.link>
                    </article>
                  <% end %>
                </div>
              </section>
            <% end %>
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

  defp format_post_date(post) do
    if post.published_at do
      Calendar.strftime(post.published_at, "%b %d, %Y")
    else
      "Draft"
    end
  end

  defp article_count(posts) do
    count = length(posts)
    "#{count} #{if count == 1, do: "article", else: "articles"}"
  end

  defp post_summary(%{excerpt: excerpt}) when is_binary(excerpt) and excerpt != "", do: excerpt
  defp post_summary(post), do: truncate_body(post.body)

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
