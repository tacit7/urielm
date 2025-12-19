defmodule UrielmWeb.UserProfileLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Accounts
  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

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
        current_user = socket.assigns.current_user
        is_following = current_user && Accounts.is_following?(current_user.id, user.id)

        {:ok,
         socket
         |> assign(:page_title, "@#{user.username}")
         |> assign(:user, user)
         |> assign(:stats, stats)
         |> assign(:is_following, is_following || false)
         |> assign(:active_tab, "threads")
         |> assign(:threads, [])
         |> assign(:comments, [])
         |> assign(:threads_meta, nil)
         |> assign(:comments_meta, nil)}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tab = Map.get(params, "tab", "threads")
    page = Map.get(params, "page", "1") |> String.to_integer()
    user_id = socket.assigns.user.id

    socket = assign(socket, :active_tab, tab)

    socket =
      case tab do
        "threads" ->
          case Forum.paginate_threads_by_author(user_id, %{
                 page: page,
                 page_size: 20,
                 order_by: [:inserted_at],
                 order_directions: [:desc]
               }) do
            {:ok, {threads, meta}} ->
              assign(socket,
                threads:
                  Enum.map(
                    threads,
                    &LiveHelpers.serialize_thread_card(&1, socket.assigns.current_user)
                  ),
                threads_meta: meta
              )

            {:error, _} ->
              assign(socket, threads: [], threads_meta: nil)
          end

        "comments" ->
          case Forum.paginate_comments_by_author(user_id, %{page: page, page_size: 20}) do
            {:ok, {comments, meta}} ->
              assign(socket,
                comments:
                  Enum.map(
                    comments,
                    &LiveHelpers.serialize_comment(&1, socket.assigns.current_user)
                  ),
                comments_meta: meta
              )

            {:error, _} ->
              assign(socket, comments: [], comments_meta: nil)
          end

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_follow", _params, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.user

    case current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to follow users")}

      user ->
        case Accounts.toggle_follow(user.id, profile_user.id) do
          {:ok, _} ->
            is_following = Accounts.is_following?(user.id, profile_user.id)
            stats = Accounts.get_user_stats(profile_user.id)

            {:noreply,
             socket
             |> assign(:is_following, is_following)
             |> assign(:stats, stats)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to toggle follow")}
        end
    end
  end

  @impl true
  def handle_event("load_more", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    username = socket.assigns.user.username
    page = 1
    {:noreply, push_patch(socket, to: ~p"/u/#{username}?tab=#{tab}&page=#{page}")}
  end

  # pagination handled via handle_params; no incremental loaders

  # comment serialization moved to LiveHelpers.serialize_comment/2

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="" socket={@socket}>
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
                  {String.slice(@user.username || "U", 0..0) |> String.upcase()}
                </div>
              <% end %>
            </div>
            
    <!-- User Info -->
            <div class="flex-1">
              <div class="flex items-center gap-4 mb-2">
                <h1 class="text-3xl font-bold">{@user.username}</h1>
                <%= if @user.is_admin do %>
                  <span class="badge badge-error">Admin</span>
                <% end %>
              </div>

              <%= if @user.display_name && @user.display_name != @user.username do %>
                <p class="text-lg text-base-content/90 mb-2">{@user.display_name}</p>
              <% end %>

              <%= if @user.bio do %>
                <p class="text-base-content/70 mb-3 max-w-2xl">{@user.bio}</p>
              <% end %>

              <div class="flex items-center gap-4 text-sm text-base-content/60 mb-4">
                <%= if @user.location do %>
                  <span class="flex items-center gap-1">
                    <.um_icon name="map_pin" class="w-4 h-4" />
                    {@user.location}
                  </span>
                <% end %>
                <%= if @user.website do %>
                  <a href={@user.website} target="_blank" rel="noopener" class="flex items-center gap-1 link link-hover">
                    <.um_icon name="link" class="w-4 h-4" />
                    {String.replace(@user.website, ~r/^https?:\/\//, "")}
                  </a>
                <% end %>
                <span class="flex items-center gap-1">
                  <.um_icon name="calendar" class="w-4 h-4" />
                  Joined {Calendar.strftime(@user.inserted_at, "%B %Y")}
                </span>
              </div>

              <div class="flex items-center gap-6 mb-4">
                <div class="text-center">
                  <p class="text-2xl font-bold">{@stats.thread_count}</p>
                  <p class="text-sm text-base-content/70">
                    {if @stats.thread_count == 1, do: "Thread", else: "Threads"}
                  </p>
                </div>
                <div class="text-center">
                  <p class="text-2xl font-bold">{@stats.comment_count}</p>
                  <p class="text-sm text-base-content/70">
                    {if @stats.comment_count == 1, do: "Comment", else: "Comments"}
                  </p>
                </div>
                <div class="text-center">
                  <p class="text-2xl font-bold">{@stats.follower_count}</p>
                  <p class="text-sm text-base-content/70">
                    {if @stats.follower_count == 1, do: "Follower", else: "Followers"}
                  </p>
                </div>
                <div class="text-center">
                  <p class="text-2xl font-bold">{@stats.following_count}</p>
                  <p class="text-sm text-base-content/70">Following</p>
                </div>
              </div>

              <%= if @current_user && @current_user.id != @user.id do %>
                <button
                  phx-click="toggle_follow"
                  class={[
                    "btn btn-sm",
                    if(@is_following, do: "btn-outline", else: "btn-primary")
                  ]}
                >
                  <%= if @is_following do %>
                    Following
                  <% else %>
                    Follow
                  <% end %>
                </button>
              <% end %>
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
        <div id="profile-content">
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
                            {thread.title}
                          </h3>
                          <p class="text-sm text-base-content/60 mt-1 line-clamp-1">
                            {thread.body}
                          </p>
                          <div class="flex items-center gap-3 text-xs text-base-content/50 mt-2">
                            <span>{Calendar.strftime(thread.created_at, "%b %d, %Y")}</span>
                            <span>•</span>
                            <span>
                              {thread.comment_count} {if thread.comment_count == 1,
                                do: "reply",
                                else: "replies"}
                            </span>
                          </div>
                        </div>
                      </div>
                    </a>
                  </div>
                <% end %>
              <% end %>

              <div class="flex items-center justify-center gap-2 py-4">
                <%= if @threads_meta do %>
                  <.pagination
                    meta={@threads_meta}
                    path={fn n -> ~p"/u/#{@user.username}?tab=threads&page=#{n}" end}
                  />
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
                      <a
                        href={~p"/forum/t/#{comment.thread_id}"}
                        class="text-sm link link-primary mb-2"
                      >
                        {comment.thread_title}
                      </a>
                      <p class="text-base-content mb-2">
                        {comment.body}
                        <%= if comment.edited_at do %>
                          <span class="text-xs text-base-content/50 ml-2">(edited)</span>
                        <% end %>
                      </p>
                      <div class="text-xs text-base-content/50">
                        {Calendar.strftime(comment.created_at, "%b %d, %Y at %l:%M %p")}
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>

              <div class="flex items-center justify-center gap-2 py-4">
                <%= if @comments_meta do %>
                  <.pagination
                    meta={@comments_meta}
                    path={fn n -> ~p"/u/#{@user.username}?tab=comments&page=#{n}" end}
                  />
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    </Layouts.app>
    """
  end
end
