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
      <div id="blog-index" class="flex min-h-screen flex-col bg-base-100">
        <div class="mx-auto w-full max-w-4xl flex-1 px-5 py-16 sm:px-7 lg:py-24">
          <header id="blog-index-header" class="mb-12 lg:mb-14">
            <p class="ui-eyebrow">Writing & notes</p>
            <h1 class="ui-section-title">Blog</h1>
            <p class="ui-section-copy">
              Essays, notes, and deep dives on Elixir, Phoenix, AI workflows, and building products that matter. A space to think out loud.
            </p>
          </header>

          <%= if @posts == [] do %>
            <div
              id="blog-empty-state"
              class="ui-card border-dashed px-6 py-14 text-center text-base-content/55"
            >
              <.um_icon name="hero-document-text" class="mx-auto mb-3 size-7 text-primary/60" />
              <p class="font-medium text-base-content/70">No posts yet</p>
              <p class="mt-1 text-sm">New notes will appear here when they are published.</p>
            </div>
          <% else %>
            <div id="blog-posts" class="space-y-5">
              <%= for {post, index} <- Enum.with_index(@posts) do %>
                <article
                  id={"blog-post-#{post.id}"}
                  class={[
                    "ui-card ui-card-interactive ui-card-compact relative p-5 sm:p-6",
                    if index == 0 do
                      "bg-base-200/70"
                    else
                      "bg-base-100/70"
                    end
                  ]}
                >
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
