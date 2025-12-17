defmodule UrielmWeb.UserProfileLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Accounts
  alias Urielm.Forum

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    user = Accounts.get_user_by_username(username)

    case user do
      nil ->
        {:ok, socket |> put_flash(:error, "User not found") |> redirect(to: ~p"/")}

      user when user.active == false ->
        {:ok, socket |> put_flash(:error, "User not found") |> redirect(to: ~p"/")}

      user ->
        stats = Accounts.get_user_stats(user.id)

        {:ok,
         socket
         |> assign(:page_title, "@#{user.username}")
         |> assign(:user, user)
         |> assign(:stats, stats)
         |> assign(:active_tab, "threads")
         |> assign(:threads, [])
         |> assign(:comments, [])
         |> assign(:thread_page, 0)
         |> assign(:comment_page, 0)
         |> assign(:has_more_threads, true)
         |> assign(:has_more_comments, true)
         |> load_threads(user.id, 0)}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tab = Map.get(params, "tab", "threads")
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("load_more", %{"tab" => tab}, socket) do
    user = socket.assigns.user

    case tab do
      "threads" ->
        new_page = socket.assigns.thread_page + 1
        {:noreply, load_threads(socket, user.id, new_page)}

      "comments" ->
        new_page = socket.assigns.comment_page + 1
        {:noreply, load_comments(socket, user.id, new_page)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    user = socket.assigns.user

    case tab do
      "threads" ->
        {:noreply, assign(socket, :active_tab, "threads")}

      "comments" ->
        if Enum.empty?(socket.assigns.comments) do
          {:noreply, load_comments(assign(socket, :active_tab, "comments"), user.id, 0)}
        else
          {:noreply, assign(socket, :active_tab, "comments")}
        end

      _ ->
        {:noreply, socket}
    end
  end

  defp load_threads(socket, user_id, page) do
    limit = 20
    offset = page * limit

    threads = Forum.list_threads_by_author(user_id, limit: limit, offset: offset)
    threads_serialized = Enum.map(threads, &serialize_thread(&1, socket.assigns.current_user))

    has_more = length(threads) == limit

    socket
    |> assign(:threads, socket.assigns.threads ++ threads_serialized)
    |> assign(:thread_page, page)
    |> assign(:has_more_threads, has_more)
  end

  defp load_comments(socket, user_id, page) do
    limit = 20
    offset = page * limit

    comments = Forum.list_comments_by_author(user_id, limit: limit, offset: offset)
    comments_serialized = Enum.map(comments, &serialize_comment(&1, socket.assigns.current_user))

    has_more = length(comments) == limit

    socket
    |> assign(:comments, socket.assigns.comments ++ comments_serialized)
    |> assign(:comment_page, page)
    |> assign(:has_more_comments, has_more)
  end

  defp serialize_thread(thread, current_user) do
    is_saved = current_user && Forum.is_thread_saved?(current_user.id, thread.id)
    is_subscribed = current_user && Forum.is_subscribed?(current_user.id, thread.id)
    is_unread = current_user && Forum.is_thread_unread?(current_user.id, thread.id)

    %{
      id: to_string(thread.id),
      title: thread.title,
      body: String.slice(thread.body, 0, 150),
      score: thread.score,
      comment_count: thread.comment_count,
      author: %{
        id: thread.author.id,
        username: thread.author.username
      },
      created_at: thread.inserted_at,
      user_vote: get_user_vote(current_user, "thread", thread.id),
      is_saved: is_saved,
      is_subscribed: is_subscribed,
      is_unread: is_unread
    }
  end

  defp serialize_comment(comment, current_user) do
    %{
      id: to_string(comment.id),
      body: comment.body,
      score: comment.score,
      author: %{
        id: comment.author.id,
        username: comment.author.username
      },
      created_at: comment.inserted_at,
      thread_id: to_string(comment.thread_id),
      thread_title: comment.thread.title,
      user_vote: get_user_vote(current_user, "comment", comment.id),
      edited_at: comment.edited_at
    }
  end

  defp get_user_vote(nil, _target_type, _target_id), do: nil

  defp get_user_vote(user, target_type, target_id) do
    case Forum.get_user_vote(user.id, target_type, target_id) do
      nil -> nil
      vote -> vote.value
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <div class="max-w-4xl mx-auto p-6">
        <!-- Profile Header -->
        <div class="bg-base-200 rounded-lg p-8 mb-8">
          <div class="flex items-center gap-6 mb-6">
            <!-- Avatar -->
            <div class="flex-shrink-0">
              <%= if @user.avatar_url do %>
                <img
                  src={@user.avatar_url}
                  alt={@user.username}
                  class="w-24 h-24 rounded-full object-cover"
                />
              <% else %>
                <div class="w-24 h-24 rounded-full bg-base-300 flex items-center justify-center text-3xl font-bold">
                  <%= String.slice(@user.username || "U", 0..0) |> String.upcase() %>
                </div>
              <% end %>
            </div>

            <!-- User Info -->
            <div class="flex-1">
              <div class="flex items-center gap-4 mb-2">
                <h1 class="text-3xl font-bold"><%= @user.username %></h1>
                <%= if @user.is_admin do %>
                  <span class="badge badge-error">Admin</span>
                <% end %>
              </div>

              <p class="text-base-content/70 mb-4">
                Joined <%= Calendar.strftime(@user.inserted_at, "%B %Y") %>
              </p>

              <div class="flex items-center gap-6">
                <div class="text-center">
                  <p class="text-2xl font-bold"><%= @stats.thread_count %></p>
                  <p class="text-sm text-base-content/70">
                    <%= if @stats.thread_count == 1, do: "Thread", else: "Threads" %>
                  </p>
                </div>
                <div class="text-center">
                  <p class="text-2xl font-bold"><%= @stats.comment_count %></p>
                  <p class="text-sm text-base-content/70">
                    <%= if @stats.comment_count == 1, do: "Comment", else: "Comments" %>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tabs -->
        <div class="tabs tabs-bordered mb-6">
          <a
            class={["tab", @active_tab == "threads" && "tab-active"]}
            phx-click="switch_tab"
            phx-value-tab="threads"
          >
            Threads
          </a>
          <a
            class={["tab", @active_tab == "comments" && "tab-active"]}
            phx-click="switch_tab"
            phx-value-tab="comments"
          >
            Comments
          </a>
        </div>

        <!-- Content -->
        <div phx-hook="InfiniteScroll" id="profile-content">
          <%= if @active_tab == "threads" do %>
            <!-- Threads Tab -->
            <div class="space-y-4">
              <%= if Enum.empty?(@threads) do %>
                <div class="text-center py-12">
                  <p class="text-base-content/50">No threads yet</p>
                </div>
              <% else %>
                <%= for thread <- @threads do %>
                  <div class="card bg-base-200 border border-base-300 hover:shadow-lg transition-shadow">
                    <a href={~p"/forum/t/#{thread.id}"} class="block p-4 group">
                      <div class="flex justify-between items-start gap-4">
                        <div class="flex-1">
                          <h3 class="font-semibold text-lg group-hover:text-primary transition-colors">
                            <%= thread.title %>
                          </h3>
                          <p class="text-sm text-base-content/60 mt-1 line-clamp-1">
                            <%= thread.body %>
                          </p>
                          <div class="flex items-center gap-3 text-xs text-base-content/50 mt-2">
                            <span><%= Calendar.strftime(thread.created_at, "%b %d, %Y") %></span>
                            <span>•</span>
                            <span><%= thread.comment_count %> <%= if thread.comment_count == 1, do: "reply", else: "replies" %></span>
                          </div>
                        </div>
                      </div>
                    </a>
                  </div>
                <% end %>
              <% end %>

              <div
                id="threads-loader"
                phx-hook="InfiniteScroll"
                phx-value-tab="threads"
                class="py-4 text-center"
              >
                <%= if @has_more_threads do %>
                  <span class="text-base-content/50">Load more...</span>
                <% end %>
              </div>
            </div>
          <% else %>
            <!-- Comments Tab -->
            <div class="space-y-4">
              <%= if Enum.empty?(@comments) do %>
                <div class="text-center py-12">
                  <p class="text-base-content/50">No comments yet</p>
                </div>
              <% else %>
                <%= for comment <- @comments do %>
                  <div class="card bg-base-200 border border-base-300">
                    <div class="card-body p-4">
                      <a href={~p"/forum/t/#{comment.thread_id}"} class="text-sm link link-primary mb-2">
                        <%= comment.thread_title %>
                      </a>
                      <p class="text-base-content mb-2">
                        <%= comment.body %>
                        <%= if comment.edited_at do %>
                          <span class="text-xs text-base-content/50 ml-2">(edited)</span>
                        <% end %>
                      </p>
                      <div class="text-xs text-base-content/50">
                        <%= Calendar.strftime(comment.created_at, "%b %d, %Y at %l:%M %p") %>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>

              <div
                id="comments-loader"
                phx-hook="InfiniteScroll"
                phx-value-tab="comments"
                class="py-4 text-center"
              >
                <%= if @has_more_comments do %>
                  <span class="text-base-content/50">Load more...</span>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
