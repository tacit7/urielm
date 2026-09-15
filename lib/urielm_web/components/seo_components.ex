defmodule UrielmWeb.SEOComponents do
  @moduledoc "Server-rendered content for interactive cards before their client controls mount."
  use UrielmWeb, :html
  alias UrielmWeb.LiveHelpers

  attr :thread, :map, required: true

  def thread_card(assigns) do
    ~H"""
    <article class="group grid gap-2 px-4 py-4 md:grid-cols-[minmax(0,1fr)_64px_64px_92px] md:items-center">
      <div class="min-w-0">
        <.link
          navigate={~p"/forum/t/#{@thread.id}"}
          class="font-semibold text-base-content transition-colors hover:text-primary"
        >
          {@thread.title}
        </.link>
        <p :if={@thread.body} class="mt-1 line-clamp-2 text-sm text-base-content/55">
          {@thread.body}
        </p>
        <p class="mt-2 flex flex-wrap items-center gap-2 text-xs text-base-content/40">
          <span>{@thread.author.username}</span>
          <.link
            :if={@thread[:board]}
            navigate={~p"/forum/b/#{@thread.board.slug}"}
            class="hover:text-primary"
          >
            {@thread.board.name}
          </.link>
        </p>
      </div>
      <span class="font-mono text-sm text-base-content/55 md:text-center">
        {@thread.comment_count}
      </span>
      <span class="font-mono text-sm text-base-content/55 md:text-center">
        {@thread.view_count}
      </span>
      <span class="text-xs text-base-content/40 md:text-right">
        {LiveHelpers.format_short(@thread.updated_at)}
      </span>
    </article>
    """
  end
end
