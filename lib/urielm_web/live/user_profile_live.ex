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

        changeset = Accounts.change_user_profile(user)

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
         |> assign(:comments_meta, nil)
         |> assign(:preferences_section, "account")
         |> assign(:form, to_form(changeset))
         |> assign(:editing_username, false)
         |> assign(:editing_display_name, false)
         |> assign(:show_delete_confirm, false)}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tab = Map.get(params, "tab", "threads")
    page = Map.get(params, "page", "1") |> String.to_integer()
    section = Map.get(params, "section", "account")
    user_id = socket.assigns.user.id

    socket = socket
      |> assign(:active_tab, tab)
      |> assign(:preferences_section, section)

    socket =
      case tab do
        "preferences" ->
          socket

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

    path = if tab == "preferences" do
      ~p"/u/#{username}?tab=preferences&section=account"
    else
      ~p"/u/#{username}?tab=#{tab}&page=1"
    end

    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_event("switch_preferences_section", %{"section" => section}, socket) do
    username = socket.assigns.user.username
    {:noreply, push_patch(socket, to: ~p"/u/#{username}?tab=preferences&section=#{section}")}
  end

  @impl true
  def handle_event("edit_username", _params, socket) do
    {:noreply, assign(socket, :editing_username, true)}
  end

  @impl true
  def handle_event("cancel_edit_username", _params, socket) do
    changeset = Accounts.change_user_profile(socket.assigns.user)
    {:noreply, socket |> assign(:editing_username, false) |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("update_username", %{"user" => %{"username" => username}}, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.user

    if current_user && current_user.id == profile_user.id do
      case Accounts.update_user(current_user, %{username: username}) do
        {:ok, updated_user} ->
          changeset = Accounts.change_user_profile(updated_user)

          {:noreply,
           socket
           |> assign(:user, updated_user)
           |> assign(:form, to_form(changeset))
           |> assign(:editing_username, false)
           |> put_flash(:info, "Username updated successfully")}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  @impl true
  def handle_event("edit_display_name", _params, socket) do
    {:noreply, assign(socket, :editing_display_name, true)}
  end

  @impl true
  def handle_event("cancel_edit_display_name", _params, socket) do
    changeset = Accounts.change_user_profile(socket.assigns.user)
    {:noreply, socket |> assign(:editing_display_name, false) |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("update_display_name", %{"user" => %{"display_name" => display_name}}, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.user

    if current_user && current_user.id == profile_user.id do
      case Accounts.update_user(current_user, %{display_name: display_name}) do
        {:ok, updated_user} ->
          changeset = Accounts.change_user_profile(updated_user)

          {:noreply,
           socket
           |> assign(:user, updated_user)
           |> assign(:form, to_form(changeset))
           |> assign(:editing_display_name, false)
           |> put_flash(:info, "Display name updated successfully")}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  @impl true
  def handle_event("show_delete_confirm", _params, socket) do
    {:noreply, assign(socket, :show_delete_confirm, true)}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :show_delete_confirm, false)}
  end

  @impl true
  def handle_event("delete_account", _params, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      case Accounts.delete_user(current_user) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Account deleted successfully")
           |> redirect(to: ~p"/auth/logout")}

        {:error, _} ->
          {:noreply,
           socket
           |> assign(:show_delete_confirm, false)
           |> put_flash(:error, "Failed to delete account")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  @impl true
  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("update_profile", %{"user" => user_params}, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.user

    # Only allow users to update their own profile
    if current_user && current_user.id == profile_user.id do
      case Accounts.update_user(current_user, user_params) do
        {:ok, updated_user} ->
          changeset = Accounts.change_user_profile(updated_user)

          {:noreply,
           socket
           |> assign(:user, updated_user)
           |> assign(:form, to_form(changeset))
           |> put_flash(:info, "Profile updated successfully")}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
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
                <%= if @user.is_moderator && !@user.is_admin do %>
                  <span class="badge badge-warning">Moderator</span>
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
          <%= if @current_user && @current_user.id == @user.id do %>
            <a
              class={["tab", @active_tab == "preferences" && "tab-active"]}
              phx-click="switch_tab"
              phx-value-tab="preferences"
            >
              Preferences
            </a>
          <% end %>
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
          <% end %>

          <%= if @active_tab == "comments" do %>
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

          <%= if @active_tab == "preferences" do %>
            <!-- Preferences Tab -->
            <div class="space-y-6">
              <!-- Sub-navigation -->
              <div class="flex gap-2 overflow-x-auto pb-2 border-b border-base-300">
                <button
                  phx-click="switch_preferences_section"
                  phx-value-section="account"
                  class={[
                    "btn btn-sm",
                    if(@preferences_section == "account", do: "btn-primary", else: "btn-ghost")
                  ]}
                >
                  Account
                </button>
                <button
                  phx-click="switch_preferences_section"
                  phx-value-section="profile"
                  class={[
                    "btn btn-sm",
                    if(@preferences_section == "profile", do: "btn-primary", else: "btn-ghost")
                  ]}
                >
                  Profile
                </button>
              </div>

              <%= if @preferences_section == "account" do %>
                <!-- Account Section -->
                <div class="space-y-6">
                  <div>
                    <h3 class="text-xl font-semibold mb-2">Username</h3>

                    <%= if @editing_username do %>
                      <.form for={@form} id="username-form" phx-submit="update_username">
                        <.input
                          field={@form[:username]}
                          type="text"
                          class="w-full input input-bordered bg-base-200"
                        />
                        <div class="flex gap-2 mt-4">
                          <button type="submit" class="btn btn-primary btn-sm">
                            change
                          </button>
                          <button
                            type="button"
                            phx-click="cancel_edit_username"
                            class="btn btn-ghost btn-sm text-primary"
                          >
                            Cancel
                          </button>
                        </div>
                      </.form>
                    <% else %>
                      <div class="flex items-center gap-2">
                        <p class="text-base-content/80">{@user.username}</p>
                        <button
                          type="button"
                          phx-click="edit_username"
                          class="btn btn-ghost btn-xs"
                          aria-label="Edit username"
                        >
                          <.um_icon name="hero-pencil-square" class="w-4 h-4" />
                        </button>
                      </div>
                      <p class="text-sm text-base-content/60 mt-1">
                        People can mention you as @{@user.username}
                      </p>
                    <% end %>
                  </div>

                  <div>
                    <h3 class="text-xl font-semibold mb-2">Display Name</h3>

                    <%= if @editing_display_name do %>
                      <.form for={@form} id="display-name-form" phx-submit="update_display_name">
                        <.input
                          field={@form[:display_name]}
                          type="text"
                          class="w-full input input-bordered bg-base-200"
                        />
                        <div class="flex gap-2 mt-4">
                          <button type="submit" class="btn btn-primary btn-sm">
                            change
                          </button>
                          <button
                            type="button"
                            phx-click="cancel_edit_display_name"
                            class="btn btn-ghost btn-sm text-primary"
                          >
                            Cancel
                          </button>
                        </div>
                      </.form>
                    <% else %>
                      <div class="flex items-center gap-2">
                        <p class="text-base-content/80">{@user.display_name || "Not set"}</p>
                        <button
                          type="button"
                          phx-click="edit_display_name"
                          class="btn btn-ghost btn-xs"
                          aria-label="Edit display name"
                        >
                          <.um_icon name="hero-pencil-square" class="w-4 h-4" />
                        </button>
                      </div>
                    <% end %>
                  </div>

                  <div>
                    <h3 class="text-xl font-semibold mb-2">Email</h3>
                    <p class="text-base-content/80">{@user.email}</p>
                    <p class="text-sm text-base-content/60 mt-1">Never shown to the public</p>
                  </div>

                  <!-- Danger Zone -->
                  <div class="pt-8 mt-8 border-t border-error/20">
                    <h3 class="text-xl font-semibold mb-2 text-error">Danger Zone</h3>
                    <p class="text-sm text-base-content/60 mb-4">
                      Once you delete your account, there is no going back. Please be certain.
                    </p>
                    <button
                      type="button"
                      phx-click="show_delete_confirm"
                      class="btn btn-error btn-outline btn-sm"
                    >
                      Delete My Account
                    </button>
                  </div>
                </div>

                <!-- Delete Confirmation Modal -->
                <%= if @show_delete_confirm do %>
                  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" phx-click="cancel_delete">
                    <div class="modal-box bg-base-200" onclick="event.stopPropagation()">
                      <h3 class="font-bold text-lg text-error">Delete Account</h3>
                      <p class="py-4">
                        Are you absolutely sure you want to delete your account? This action cannot be undone.
                        All your posts, comments, and data will be permanently deleted.
                      </p>
                      <div class="modal-action">
                        <button
                          type="button"
                          phx-click="cancel_delete"
                          class="btn btn-ghost"
                        >
                          Cancel
                        </button>
                        <button
                          type="button"
                          phx-click="delete_account"
                          class="btn btn-error"
                        >
                          Yes, Delete My Account
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>

              <%= if @preferences_section == "profile" do %>
                <!-- Profile Section -->
                <.form for={@form} id="profile-form" phx-change="validate_profile" phx-submit="update_profile">
                  <div class="space-y-4">
                    <.input
                      field={@form[:bio]}
                      type="textarea"
                      label="About me"
                      placeholder="Tell us about yourself..."
                      class="w-full textarea textarea-bordered bg-base-200 h-32"
                    />
                    <p class="text-sm text-base-content/60 -mt-2">Max 1000 characters</p>

                    <.input
                      field={@form[:location]}
                      type="text"
                      label="Location"
                      placeholder="Your location"
                      class="w-full input input-bordered bg-base-200"
                    />

                    <.input
                      field={@form[:website]}
                      type="url"
                      label="Website"
                      placeholder="https://example.com"
                      class="w-full input input-bordered bg-base-200"
                    />

                    <div class="pt-4">
                      <button type="submit" class="btn btn-primary">
                        Save Changes
                      </button>
                    </div>
                  </div>
                </.form>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    </Layouts.app>
    """
  end
end
