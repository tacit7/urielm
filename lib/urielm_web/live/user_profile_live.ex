defmodule UrielmWeb.UserProfileLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Accounts
  alias Urielm.Accounts.User
  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, session, socket) do
    # Handle both direct mount and child mount via live_render
    child_params =
      case params do
        :not_mounted_at_router -> session["child_params"] || %{}
        params -> params
      end

    username = child_params["username"]
    user = Accounts.get_user_by_username(username)

    case user do
      nil ->
        {:ok, socket |> put_flash(:error, "User not found") |> redirect(to: ~p"/")}

      user when user.active == false ->
        {:ok, socket |> put_flash(:error, "User not found") |> redirect(to: ~p"/")}

      user ->
        tab = Map.get(child_params, "tab", "threads")

        page =
          case child_params["page"] do
            nil -> 1
            p when is_binary(p) -> String.to_integer(p)
            p when is_integer(p) -> p
          end

        stats = Accounts.get_user_stats(user.id)
        current_user = socket.assigns.current_user
        is_following = current_user && Accounts.is_following?(current_user.id, user.id)

        form =
          if current_user && current_user.id == user.id do
            to_form(Accounts.change_user_profile(user))
          else
            nil
          end

        socket =
          socket
          |> assign(:page_title, "@#{user.username}")
          |> assign(:user, user)
          |> assign(:stats, stats)
          |> assign(:is_following, is_following || false)
          |> assign(:active_tab, tab)
          |> assign(:form, form)
          |> assign(:editing_username, false)
          |> assign(:editing_display_name, false)
          |> assign(:show_delete_confirm, false)
          |> assign(:show_suspend_modal, false)
          |> assign(:show_silence_modal, false)
          |> assign(:mod_reason, "")
          |> assign(:mod_duration, "forever")

        socket = load_tab_data(socket, tab, page)

        {:ok, socket}
    end
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
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, load_tab_data(socket, tab, 1)}
  end

  @impl true
  def handle_event("change_page", %{"tab" => tab, "page" => page}, socket) do
    page = if is_binary(page), do: String.to_integer(page), else: page
    {:noreply, load_tab_data(socket, tab, page)}
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

    {:noreply,
     socket |> assign(:editing_display_name, false) |> assign(:form, to_form(changeset))}
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

  ## Moderation actions

  @impl true
  def handle_event("show_suspend_modal", _params, socket) do
    {:noreply, assign(socket, show_suspend_modal: true, mod_reason: "", mod_duration: "forever")}
  end

  @impl true
  def handle_event("show_silence_modal", _params, socket) do
    {:noreply, assign(socket, show_silence_modal: true, mod_reason: "", mod_duration: "forever")}
  end

  @impl true
  def handle_event("close_mod_modal", _params, socket) do
    {:noreply, assign(socket, show_suspend_modal: false, show_silence_modal: false)}
  end

  @impl true
  def handle_event("update_mod_form", %{"reason" => reason, "duration" => duration}, socket) do
    {:noreply, assign(socket, mod_reason: reason, mod_duration: duration)}
  end

  @impl true
  def handle_event("suspend_user", _params, socket) do
    current_user = socket.assigns.current_user
    target_user = socket.assigns.user
    reason = socket.assigns.mod_reason
    duration = socket.assigns.mod_duration

    if can_moderate?(current_user, target_user) && reason != "" do
      until = duration_to_datetime(duration)

      case Accounts.suspend_user(target_user, current_user, reason: reason, until: until) do
        {:ok, updated_user} ->
          {:noreply,
           socket
           |> assign(:user, updated_user)
           |> assign(:show_suspend_modal, false)
           |> put_flash(:info, "User suspended successfully")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to suspend user")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized or missing reason")}
    end
  end

  @impl true
  def handle_event("unsuspend_user", _params, socket) do
    current_user = socket.assigns.current_user
    target_user = socket.assigns.user

    if can_moderate?(current_user, target_user) do
      case Accounts.unsuspend_user(target_user, current_user) do
        {:ok, updated_user} ->
          {:noreply,
           socket
           |> assign(:user, updated_user)
           |> put_flash(:info, "User unsuspended successfully")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to unsuspend user")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  @impl true
  def handle_event("silence_user", _params, socket) do
    current_user = socket.assigns.current_user
    target_user = socket.assigns.user
    reason = socket.assigns.mod_reason
    duration = socket.assigns.mod_duration

    if can_moderate?(current_user, target_user) && reason != "" do
      until = duration_to_datetime(duration)

      case Accounts.silence_user(target_user, current_user, reason: reason, until: until) do
        {:ok, updated_user} ->
          {:noreply,
           socket
           |> assign(:user, updated_user)
           |> assign(:show_silence_modal, false)
           |> put_flash(:info, "User silenced successfully")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to silence user")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized or missing reason")}
    end
  end

  @impl true
  def handle_event("unsilence_user", _params, socket) do
    current_user = socket.assigns.current_user
    target_user = socket.assigns.user

    if can_moderate?(current_user, target_user) do
      case Accounts.unsilence_user(target_user, current_user) do
        {:ok, updated_user} ->
          {:noreply,
           socket
           |> assign(:user, updated_user)
           |> put_flash(:info, "User unsilenced successfully")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to unsilence user")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  defp load_tab_data(socket, tab, page) do
    user_id = socket.assigns.user.id
    current_user = socket.assigns.current_user

    socket = assign(socket, :active_tab, tab)

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
              threads: Enum.map(threads, &LiveHelpers.serialize_thread_card(&1, current_user)),
              threads_meta: meta,
              comments: [],
              comments_meta: nil
            )

          {:error, _} ->
            assign(socket, threads: [], threads_meta: nil, comments: [], comments_meta: nil)
        end

      "comments" ->
        case Forum.paginate_comments_by_author(user_id, %{page: page, page_size: 20}) do
          {:ok, {comments, meta}} ->
            assign(socket,
              comments: Enum.map(comments, &LiveHelpers.serialize_comment(&1, current_user)),
              comments_meta: meta,
              threads: [],
              threads_meta: nil
            )

          {:error, _} ->
            assign(socket, comments: [], comments_meta: nil, threads: [], threads_meta: nil)
        end

      _ ->
        socket
        |> assign(:threads, [])
        |> assign(:comments, [])
        |> assign(:threads_meta, nil)
        |> assign(:comments_meta, nil)
    end
  end

  defp can_moderate?(current_user, target_user) do
    current_user &&
      current_user.id != target_user.id &&
      (current_user.is_admin || current_user.is_moderator)
  end

  defp duration_to_datetime("forever"), do: nil
  defp duration_to_datetime("1h"), do: DateTime.add(DateTime.utc_now(), 1, :hour)
  defp duration_to_datetime("1d"), do: DateTime.add(DateTime.utc_now(), 1, :day)
  defp duration_to_datetime("3d"), do: DateTime.add(DateTime.utc_now(), 3, :day)
  defp duration_to_datetime("1w"), do: DateTime.add(DateTime.utc_now(), 7, :day)
  defp duration_to_datetime("1m"), do: DateTime.add(DateTime.utc_now(), 30, :day)
  defp duration_to_datetime("3m"), do: DateTime.add(DateTime.utc_now(), 90, :day)
  defp duration_to_datetime("6m"), do: DateTime.add(DateTime.utc_now(), 180, :day)
  defp duration_to_datetime("1y"), do: DateTime.add(DateTime.utc_now(), 365, :day)
  defp duration_to_datetime(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <div class="max-w-4xl mx-auto p-6">
        <!-- Profile Header Card -->
        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <div class="flex items-center gap-6">
              <!-- Avatar -->
              <div class="flex-shrink-0">
                <%= if @user.avatar_url do %>
                  <img
                    src={@user.avatar_url}
                    alt={@user.username}
                    class="w-20 h-20 rounded-full object-cover"
                  />
                <% else %>
                  <div class="avatar placeholder">
                    <div class="bg-primary text-primary-content w-20 rounded-full">
                      <span class="text-2xl">
                        {String.slice(@user.username || "U", 0..0) |> String.upcase()}
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>

              <!-- User Info -->
              <div class="flex-1">
                <div class="flex items-center gap-3 mb-1">
                  <h1 class="text-2xl font-bold">
                    {if @user.display_name && @user.display_name != @user.username,
                      do: @user.display_name,
                      else: @user.username}
                  </h1>
                  <%= if @user.is_admin do %>
                    <span class="badge badge-error badge-sm">Admin</span>
                  <% end %>
                  <%= if @user.is_moderator && !@user.is_admin do %>
                    <span class="badge badge-warning badge-sm">Moderator</span>
                  <% end %>
                  <%= if User.suspended?(@user) do %>
                    <span class="badge badge-error badge-outline badge-sm">Suspended</span>
                  <% end %>
                  <%= if User.silenced?(@user) do %>
                    <span class="badge badge-warning badge-outline badge-sm">Silenced</span>
                  <% end %>
                </div>

                <%= if @user.display_name && @user.display_name != @user.username do %>
                  <p class="text-sm text-base-content/60">@{@user.username}</p>
                <% end %>

                <div class="flex items-center gap-4 text-sm text-base-content/60 mt-2">
                  <%= if @user.location do %>
                    <span class="flex items-center gap-1">
                      <.um_icon name="map_pin" class="w-4 h-4" />
                      {@user.location}
                    </span>
                  <% end %>
                  <span class="flex items-center gap-1">
                    <.um_icon name="calendar" class="w-4 h-4" />
                    Joined {Calendar.strftime(@user.inserted_at, "%B %Y")}
                  </span>
                </div>
              </div>

              <!-- Follow / Mod Actions -->
              <%= if @current_user && @current_user.id != @user.id do %>
                <div class="flex items-center gap-2">
                  <button
                    phx-click="toggle_follow"
                    class={[
                      "btn btn-sm",
                      if(@is_following, do: "btn-outline", else: "btn-primary")
                    ]}
                  >
                    {if @is_following, do: "Following", else: "Follow"}
                  </button>

                  <%= if @current_user.is_admin || @current_user.is_moderator do %>
                    <div class="dropdown dropdown-end">
                      <label tabindex="0" class="btn btn-sm btn-ghost">
                        <.um_icon name="hero-ellipsis-vertical" class="w-5 h-5" />
                      </label>
                      <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow bg-base-200 rounded-box w-52">
                        <%= if User.suspended?(@user) do %>
                          <li>
                            <button phx-click="unsuspend_user" class="text-success">
                              <.um_icon name="hero-check-circle" class="w-4 h-4" /> Unsuspend
                            </button>
                          </li>
                        <% else %>
                          <li>
                            <button phx-click="show_suspend_modal" class="text-error">
                              <.um_icon name="hero-no-symbol" class="w-4 h-4" /> Suspend
                            </button>
                          </li>
                        <% end %>
                        <%= if User.silenced?(@user) do %>
                          <li>
                            <button phx-click="unsilence_user" class="text-success">
                              <.um_icon name="hero-check-circle" class="w-4 h-4" /> Unsilence
                            </button>
                          </li>
                        <% else %>
                          <li>
                            <button phx-click="show_silence_modal" class="text-warning">
                              <.um_icon name="hero-speaker-x-mark" class="w-4 h-4" /> Silence
                            </button>
                          </li>
                        <% end %>
                      </ul>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>

            <%= if @user.bio do %>
              <div class="divider my-3"></div>
              <p class="text-base-content/80">{@user.bio}</p>
            <% end %>

            <%= if @user.website do %>
              <a
                href={@user.website}
                target="_blank"
                rel="noopener"
                class="link link-primary text-sm mt-2"
              >
                {String.replace(@user.website, ~r/^https?:\/\//, "")}
              </a>
            <% end %>
          </div>
        </div>

        <!-- Stats Card -->
        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body py-4">
            <div class="stats stats-horizontal w-full">
              <div class="stat place-items-center py-2">
                <div class="stat-value text-xl">{@stats.thread_count}</div>
                <div class="stat-desc">{if @stats.thread_count == 1, do: "Thread", else: "Threads"}</div>
              </div>
              <div class="stat place-items-center py-2">
                <div class="stat-value text-xl">{@stats.comment_count}</div>
                <div class="stat-desc">{if @stats.comment_count == 1, do: "Comment", else: "Comments"}</div>
              </div>
              <div class="stat place-items-center py-2">
                <div class="stat-value text-xl">{@stats.follower_count}</div>
                <div class="stat-desc">{if @stats.follower_count == 1, do: "Follower", else: "Followers"}</div>
              </div>
              <div class="stat place-items-center py-2">
                <div class="stat-value text-xl">{@stats.following_count}</div>
                <div class="stat-desc">Following</div>
              </div>
            </div>
          </div>
        </div>

        <div class="space-y-6">
          <!-- Account Settings Card (own profile only) -->
          <%= if @current_user && @current_user.id == @user.id do %>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title">Account</h2>
                <p class="text-sm text-base-content/70">Manage your account settings</p>

                <div class="divider"></div>

                <!-- Username -->
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium">Username</p>
                    <p class="text-sm text-base-content/60">@{@user.username}</p>
                  </div>
                  <%= if @editing_username do %>
                    <.form for={@form} id="username-form" phx-submit="update_username" class="flex items-center gap-2">
                      <.input field={@form[:username]} type="text" class="input input-sm input-bordered" />
                      <button type="submit" class="btn btn-primary btn-sm">Save</button>
                      <button type="button" phx-click="cancel_edit_username" class="btn btn-ghost btn-sm">Cancel</button>
                    </.form>
                  <% else %>
                    <button phx-click="edit_username" class="btn btn-ghost btn-sm">Edit</button>
                  <% end %>
                </div>

                <div class="divider my-2"></div>

                <!-- Display Name -->
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium">Display Name</p>
                    <p class="text-sm text-base-content/60">{@user.display_name || "Not set"}</p>
                  </div>
                  <%= if @editing_display_name do %>
                    <.form for={@form} id="display-name-form" phx-submit="update_display_name" class="flex items-center gap-2">
                      <.input field={@form[:display_name]} type="text" class="input input-sm input-bordered" />
                      <button type="submit" class="btn btn-primary btn-sm">Save</button>
                      <button type="button" phx-click="cancel_edit_display_name" class="btn btn-ghost btn-sm">Cancel</button>
                    </.form>
                  <% else %>
                    <button phx-click="edit_display_name" class="btn btn-ghost btn-sm">Edit</button>
                  <% end %>
                </div>

                <div class="divider my-2"></div>

                <!-- Email -->
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium">Email</p>
                    <p class="text-sm text-base-content/60">{@user.email}</p>
                  </div>
                  <span class="text-xs text-base-content/50">Private</span>
                </div>
              </div>
            </div>

            <!-- Profile Card -->
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title">Profile</h2>
                <p class="text-sm text-base-content/70">Update your public profile information</p>

                <div class="divider"></div>

                <.form for={@form} id="profile-form" phx-change="validate_profile" phx-submit="update_profile" class="space-y-4">
                  <.input
                    field={@form[:bio]}
                    type="textarea"
                    label="Bio"
                    placeholder="Tell us about yourself..."
                  />

                  <.input
                    field={@form[:location]}
                    type="text"
                    label="Location"
                    placeholder="City, Country"
                  />

                  <.input
                    field={@form[:website]}
                    type="url"
                    label="Website"
                    placeholder="https://example.com"
                  />

                  <.input
                    field={@form[:avatar_url]}
                    type="url"
                    label="Avatar URL"
                    placeholder="https://example.com/avatar.jpg"
                  />

                  <div class="card-actions">
                    <button type="submit" class="btn btn-primary">Save Profile</button>
                  </div>
                </.form>
              </div>
            </div>

            <!-- Danger Zone Card -->
            <div class="card bg-base-100 shadow-xl border-2 border-error">
              <div class="card-body">
                <h2 class="card-title text-error">Danger Zone</h2>
                <p class="text-sm text-base-content/70">Irreversible and destructive actions</p>

                <div class="divider"></div>

                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium">Delete Account</p>
                    <p class="text-xs text-base-content/60">Permanently delete your account and all data</p>
                  </div>
                  <button phx-click="show_delete_confirm" class="btn btn-error btn-sm">Delete Account</button>
                </div>
              </div>
            </div>

            <!-- Delete Confirmation Modal -->
            <%= if @show_delete_confirm do %>
              <div class="fixed inset-0 z-50">
                <div class="absolute inset-0 bg-black/50" phx-click="cancel_delete"></div>
                <div class="relative flex items-center justify-center h-full pointer-events-none">
                  <div class="modal-box pointer-events-auto">
                    <h3 class="font-bold text-lg text-error">Delete Account</h3>
                    <p class="py-4">
                      Are you sure you want to delete your account? This action cannot be undone.
                      All your data will be permanently deleted.
                    </p>
                    <div class="modal-action">
                      <button type="button" phx-click="cancel_delete" class="btn">Cancel</button>
                      <button type="button" phx-click="delete_account" class="btn btn-error">Yes, Delete</button>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>

          <!-- Activity Card -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Activity</h2>
              <p class="text-sm text-base-content/70">Recent threads and comments</p>

              <div class="divider"></div>

              <!-- Activity Tabs -->
              <div class="tabs tabs-boxed mb-4 w-fit">
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

              <%= if @active_tab == "threads" do %>
                <%= if Enum.empty?(@threads) do %>
                  <p class="text-base-content/50 text-center py-8">No threads yet</p>
                <% else %>
                  <div class="space-y-3">
                    <%= for thread <- @threads do %>
                      <a href={~p"/forum/t/#{thread.id}"} class="block p-3 rounded-lg bg-base-200 hover:bg-base-300 transition-colors">
                        <p class="font-medium">{thread.title}</p>
                        <p class="text-sm text-base-content/60 line-clamp-1">{thread.body}</p>
                        <div class="flex items-center gap-3 text-xs text-base-content/50 mt-1">
                          <span>{Calendar.strftime(thread.created_at, "%b %d, %Y")}</span>
                          <span>{thread.comment_count} {if thread.comment_count == 1, do: "reply", else: "replies"}</span>
                        </div>
                      </a>
                    <% end %>
                  </div>

                  <%= if @threads_meta do %>
                    <div class="flex justify-center gap-2 mt-4">
                      <%= if @threads_meta.current_page > 1 do %>
                        <button
                          class="btn btn-sm"
                          phx-click="change_page"
                          phx-value-tab="threads"
                          phx-value-page={@threads_meta.current_page - 1}
                        >
                          &laquo; Prev
                        </button>
                      <% end %>
                      <span class="btn btn-sm btn-disabled">
                        {@threads_meta.current_page} / {@threads_meta.total_pages}
                      </span>
                      <%= if @threads_meta.current_page < @threads_meta.total_pages do %>
                        <button
                          class="btn btn-sm"
                          phx-click="change_page"
                          phx-value-tab="threads"
                          phx-value-page={@threads_meta.current_page + 1}
                        >
                          Next &raquo;
                        </button>
                      <% end %>
                    </div>
                  <% end %>
                <% end %>
              <% end %>

              <%= if @active_tab == "comments" do %>
                <%= if Enum.empty?(@comments) do %>
                  <p class="text-base-content/50 text-center py-8">No comments yet</p>
                <% else %>
                  <div class="space-y-3">
                    <%= for comment <- @comments do %>
                      <div class="p-3 rounded-lg bg-base-200">
                        <a href={~p"/forum/t/#{comment.thread_id}" <> "#comment-#{comment.id}"} class="text-sm link link-primary">
                          {comment.thread_title}
                        </a>
                        <p class="text-base-content mt-1">{comment.body}</p>
                        <div class="text-xs text-base-content/50 mt-1">
                          {Calendar.strftime(comment.created_at, "%b %d, %Y")}
                          <%= if comment.edited_at do %>
                            <span class="ml-2">(edited)</span>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>

                  <%= if @comments_meta do %>
                    <div class="flex justify-center gap-2 mt-4">
                      <%= if @comments_meta.current_page > 1 do %>
                        <button
                          class="btn btn-sm"
                          phx-click="change_page"
                          phx-value-tab="comments"
                          phx-value-page={@comments_meta.current_page - 1}
                        >
                          &laquo; Prev
                        </button>
                      <% end %>
                      <span class="btn btn-sm btn-disabled">
                        {@comments_meta.current_page} / {@comments_meta.total_pages}
                      </span>
                      <%= if @comments_meta.current_page < @comments_meta.total_pages do %>
                        <button
                          class="btn btn-sm"
                          phx-click="change_page"
                          phx-value-tab="comments"
                          phx-value-page={@comments_meta.current_page + 1}
                        >
                          Next &raquo;
                        </button>
                      <% end %>
                    </div>
                  <% end %>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Suspend Modal -->
      <%= if @show_suspend_modal do %>
        <div class="fixed inset-0 z-50">
          <div class="absolute inset-0 bg-black/50" phx-click="close_mod_modal"></div>
          <div class="relative flex items-center justify-center h-full pointer-events-none">
          <div class="modal-box bg-base-200 pointer-events-auto">
            <h3 class="font-bold text-lg text-error">Suspend {@user.username}</h3>
            <p class="py-2 text-sm text-base-content/70">
              Suspended users cannot login or access the site.
            </p>
            <div class="space-y-4 mt-4">
              <div>
                <label class="label">
                  <span class="label-text">Reason (required)</span>
                </label>
                <textarea
                  class="textarea textarea-bordered w-full bg-base-300"
                  placeholder="Why is this user being suspended?"
                  phx-change="update_mod_form"
                  name="reason"
                  rows="3"
                ><%= @mod_reason %></textarea>
              </div>
              <div>
                <label class="label">
                  <span class="label-text">Duration</span>
                </label>
                <select
                  class="select select-bordered w-full bg-base-300"
                  phx-change="update_mod_form"
                  name="duration"
                >
                  <option value="1h" selected={@mod_duration == "1h"}>1 hour</option>
                  <option value="1d" selected={@mod_duration == "1d"}>1 day</option>
                  <option value="3d" selected={@mod_duration == "3d"}>3 days</option>
                  <option value="1w" selected={@mod_duration == "1w"}>1 week</option>
                  <option value="1m" selected={@mod_duration == "1m"}>1 month</option>
                  <option value="3m" selected={@mod_duration == "3m"}>3 months</option>
                  <option value="6m" selected={@mod_duration == "6m"}>6 months</option>
                  <option value="1y" selected={@mod_duration == "1y"}>1 year</option>
                  <option value="forever" selected={@mod_duration == "forever"}>Forever</option>
                </select>
              </div>
            </div>
            <div class="modal-action">
              <button type="button" phx-click="close_mod_modal" class="btn btn-ghost">
                Cancel
              </button>
              <button
                type="button"
                phx-click="suspend_user"
                class="btn btn-error"
                disabled={@mod_reason == ""}
              >
                Suspend User
              </button>
            </div>
          </div>
          </div>
        </div>
      <% end %>

      <!-- Silence Modal -->
      <%= if @show_silence_modal do %>
        <div class="fixed inset-0 z-50">
          <div class="absolute inset-0 bg-black/50" phx-click="close_mod_modal"></div>
          <div class="relative flex items-center justify-center h-full pointer-events-none">
          <div class="modal-box bg-base-200 pointer-events-auto">
            <h3 class="font-bold text-lg text-warning">Silence {@user.username}</h3>
            <p class="py-2 text-sm text-base-content/70">
              Silenced users can browse but cannot post, comment, or vote.
            </p>
            <div class="space-y-4 mt-4">
              <div>
                <label class="label">
                  <span class="label-text">Reason (required)</span>
                </label>
                <textarea
                  class="textarea textarea-bordered w-full bg-base-300"
                  placeholder="Why is this user being silenced?"
                  phx-change="update_mod_form"
                  name="reason"
                  rows="3"
                ><%= @mod_reason %></textarea>
              </div>
              <div>
                <label class="label">
                  <span class="label-text">Duration</span>
                </label>
                <select
                  class="select select-bordered w-full bg-base-300"
                  phx-change="update_mod_form"
                  name="duration"
                >
                  <option value="1h" selected={@mod_duration == "1h"}>1 hour</option>
                  <option value="1d" selected={@mod_duration == "1d"}>1 day</option>
                  <option value="3d" selected={@mod_duration == "3d"}>3 days</option>
                  <option value="1w" selected={@mod_duration == "1w"}>1 week</option>
                  <option value="1m" selected={@mod_duration == "1m"}>1 month</option>
                  <option value="3m" selected={@mod_duration == "3m"}>3 months</option>
                  <option value="6m" selected={@mod_duration == "6m"}>6 months</option>
                  <option value="1y" selected={@mod_duration == "1y"}>1 year</option>
                  <option value="forever" selected={@mod_duration == "forever"}>Forever</option>
                </select>
              </div>
            </div>
            <div class="modal-action">
              <button type="button" phx-click="close_mod_modal" class="btn btn-ghost">
                Cancel
              </button>
              <button
                type="button"
                phx-click="silence_user"
                class="btn btn-warning"
                disabled={@mod_reason == ""}
              >
                Silence User
              </button>
            </div>
          </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
