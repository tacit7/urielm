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
        if not Accounts.can_view_profile?(socket.assigns.current_user, user) do
          {:ok,
           socket
           |> assign(:page_title, "@#{user.username}")
           |> assign(:user, user)
           |> assign(:profile_private, true)
           |> assign(:stats, %{
             thread_count: 0,
             comment_count: 0,
             follower_count: 0,
             following_count: 0
           })
           |> assign(:is_following, false)}
        else
          tab = Map.get(child_params, "tab", "threads")

          page =
            case child_params["page"] do
              nil ->
                1

              p when is_binary(p) ->
                case Integer.parse(p) do
                  {n, ""} when n > 0 -> n
                  _ -> 1
                end

              p when is_integer(p) ->
                p
            end

          current_user = socket.assigns.current_user

          socket =
            socket
            |> assign(:page_title, "@#{user.username}")
            |> assign(:user, user)
            |> assign(:profile_private, false)
            |> assign(:active_tab, tab)
            |> assign(:editing_username, false)
            |> assign(:editing_display_name, false)
            |> assign(:show_delete_confirm, false)
            |> assign(:show_suspend_modal, false)
            |> assign(:show_silence_modal, false)
            |> assign(:mod_reason, "")
            |> assign(:mod_duration, "forever")
            |> assign(:threads, [])
            |> assign(:comments, [])
            |> assign(:threads_meta, nil)
            |> assign(:comments_meta, nil)

          form =
            if current_user && current_user.id == user.id do
              to_form(Accounts.change_user_profile(user))
            else
              nil
            end

          socket = assign(socket, :form, form)

          if connected?(socket) do
            stats = Accounts.get_user_stats(user.id)
            is_following = current_user && Accounts.following?(current_user.id, user.id)

            socket =
              socket
              |> assign(:stats, stats)
              |> assign(:is_following, is_following || false)

            {:ok, load_tab_data(socket, tab, page)}
          else
            socket =
              socket
              |> assign(:stats, %{
                thread_count: 0,
                comment_count: 0,
                follower_count: 0,
                following_count: 0
              })
              |> assign(:is_following, false)

            {:ok, socket}
          end
        end
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
            is_following = Accounts.following?(user.id, profile_user.id)
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
    page =
      if is_binary(page) do
        case Integer.parse(page) do
          {n, ""} when n > 0 -> n
          _ -> 1
        end
      else
        page
      end

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
      case Accounts.update_user_profile(current_user, user_params) do
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
              threads: LiveHelpers.serialize_thread_list(threads, current_user),
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
    <div id="public-profile-page" class="ui-page-shell max-w-4xl">
      <%= if @profile_private do %>
        <section id="private-profile-state" class="ui-card h-auto p-6 text-center sm:p-8">
          <div class="mx-auto grid size-14 place-items-center rounded-2xl bg-base-300/70 text-base-content">
            <.um_icon name="hero-lock-closed" class="size-7" />
          </div>
          <h1 class="mt-5 text-2xl font-black text-base-content">This profile is private</h1>
          <p class="mx-auto mt-2 max-w-md text-sm leading-6 text-base-content/65">
            @{@user.username} has limited profile details and activity to account owners and moderators.
          </p>
        </section>
      <% else %>
        <section id="profile-overview" class="ui-card mb-6 h-auto p-5 sm:p-7">
          <div class="flex flex-col gap-5 sm:flex-row sm:items-start sm:gap-6">
            <div class="shrink-0">
              <%= if @user.avatar_url do %>
                <img
                  src={@user.avatar_url}
                  alt={@user.username}
                  class="size-20 rounded-full object-cover"
                />
              <% else %>
                <div class="avatar">
                  <div class="grid size-20 place-items-center rounded-full bg-primary text-primary-content">
                    <span class="text-2xl font-bold">
                      {String.slice(@user.username || "U", 0..0) |> String.upcase()}
                    </span>
                  </div>
                </div>
              <% end %>
            </div>

            <div class="min-w-0 flex-1">
              <div class="mb-1 flex flex-wrap items-center gap-2">
                <h1 class="break-words text-2xl font-black text-base-content sm:text-3xl">
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

              <div class="mt-3 flex flex-wrap items-center gap-x-4 gap-y-2 text-sm text-base-content/60">
                <%= if @user.location do %>
                  <span class="flex items-center gap-1">
                    <.um_icon name="hero-map-pin" class="size-4" />
                    {@user.location}
                  </span>
                <% end %>
                <span class="flex items-center gap-1">
                  <.um_icon name="hero-calendar-days" class="size-4" />
                  Joined {Calendar.strftime(@user.inserted_at, "%B %Y")}
                </span>
              </div>
            </div>

            <%= if @current_user && @current_user.id != @user.id do %>
              <div class="flex w-full items-center gap-2 sm:w-auto sm:shrink-0">
                <button
                  id="profile-follow-button"
                  type="button"
                  phx-click="toggle_follow"
                  class={[
                    "btn btn-sm flex-1 sm:flex-none",
                    if(@is_following, do: "btn-outline", else: "btn-primary")
                  ]}
                >
                  {if @is_following, do: "Following", else: "Follow"}
                </button>

                <%= if @current_user.is_admin || @current_user.is_moderator do %>
                  <div class="dropdown dropdown-end">
                    <button
                      id="profile-moderation-menu"
                      type="button"
                      tabindex="0"
                      class="btn btn-ghost btn-sm btn-square"
                      aria-label="Moderation actions"
                    >
                      <.um_icon name="hero-ellipsis-vertical" class="size-5" />
                    </button>
                    <ul
                      tabindex="0"
                      class="dropdown-content menu z-10 mt-2 w-52 rounded-lg border border-base-300 bg-base-200 p-2 shadow-lg"
                    >
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
            <div class="divider my-5"></div>
            <p class="whitespace-pre-line leading-7 text-base-content/80">{@user.bio}</p>
          <% end %>

          <%= if @user.website do %>
            <a
              href={@user.website}
              target="_blank"
              rel="noopener"
              class="link link-primary mt-3 inline-flex items-center gap-1 text-sm"
            >
              {String.replace(@user.website, ~r/^https?:\/\//, "")}
              <.um_icon name="hero-arrow-top-right-on-square" class="size-3.5" />
            </a>
          <% end %>
        </section>

        <section id="profile-stats" class="ui-card ui-card-compact mb-6 h-auto p-2">
          <div class="grid grid-cols-2 sm:grid-cols-4">
            <div class="stat place-items-center py-2">
              <div class="stat-value text-xl">{@stats.thread_count}</div>
              <div class="stat-desc">
                {if @stats.thread_count == 1, do: "Thread", else: "Threads"}
              </div>
            </div>
            <div class="stat place-items-center py-2">
              <div class="stat-value text-xl">{@stats.comment_count}</div>
              <div class="stat-desc">
                {if @stats.comment_count == 1, do: "Comment", else: "Comments"}
              </div>
            </div>
            <div class="stat place-items-center py-2">
              <div class="stat-value text-xl">{@stats.follower_count}</div>
              <div class="stat-desc">
                {if @stats.follower_count == 1, do: "Follower", else: "Followers"}
              </div>
            </div>
            <div class="stat place-items-center py-2">
              <div class="stat-value text-xl">{@stats.following_count}</div>
              <div class="stat-desc">Following</div>
            </div>
          </div>
        </section>

        <div class="space-y-6">
          <%= if @current_user && @current_user.id == @user.id do %>
            <section id="profile-account-settings" class="ui-card h-auto p-5 sm:p-7">
              <h2 class="text-xl font-black text-base-content">Account</h2>
              <p class="mt-1 text-sm text-base-content/70">Manage your account details.</p>

              <div class="divider my-5"></div>

              <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p class="font-bold">Username</p>
                  <p class="text-sm text-base-content/60">@{@user.username}</p>
                </div>
                <%= if @editing_username do %>
                  <.form
                    for={@form}
                    id="username-form"
                    phx-submit="update_username"
                    class="grid w-full gap-2 sm:w-auto sm:grid-cols-[minmax(12rem,1fr)_auto_auto] sm:items-end"
                  >
                    <.input
                      field={@form[:username]}
                      type="text"
                      label="New username"
                      class="input input-bordered input-sm w-full"
                    />
                    <button id="username-save" type="submit" class="btn btn-primary btn-sm">
                      Save
                    </button>
                    <button
                      id="username-cancel"
                      type="button"
                      phx-click="cancel_edit_username"
                      class="btn btn-ghost btn-sm"
                    >
                      Cancel
                    </button>
                  </.form>
                <% else %>
                  <button
                    id="username-edit"
                    type="button"
                    phx-click="edit_username"
                    class="btn btn-ghost btn-sm w-full sm:w-auto"
                  >
                    Edit
                  </button>
                <% end %>
              </div>

              <div class="divider my-4"></div>

              <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p class="font-bold">Display name</p>
                  <p class="text-sm text-base-content/60">{@user.display_name || "Not set"}</p>
                </div>
                <%= if @editing_display_name do %>
                  <.form
                    for={@form}
                    id="display-name-form"
                    phx-submit="update_display_name"
                    class="grid w-full gap-2 sm:w-auto sm:grid-cols-[minmax(12rem,1fr)_auto_auto] sm:items-end"
                  >
                    <.input
                      field={@form[:display_name]}
                      type="text"
                      label="New display name"
                      class="input input-bordered input-sm w-full"
                    />
                    <button id="display-name-save" type="submit" class="btn btn-primary btn-sm">
                      Save
                    </button>
                    <button
                      id="display-name-cancel"
                      type="button"
                      phx-click="cancel_edit_display_name"
                      class="btn btn-ghost btn-sm"
                    >
                      Cancel
                    </button>
                  </.form>
                <% else %>
                  <button
                    id="display-name-edit"
                    type="button"
                    phx-click="edit_display_name"
                    class="btn btn-ghost btn-sm w-full sm:w-auto"
                  >
                    Edit
                  </button>
                <% end %>
              </div>

              <div class="divider my-4"></div>

              <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p class="font-bold">Email</p>
                  <p class="break-all text-sm text-base-content/60">{@user.email}</p>
                </div>
                <span class="badge badge-ghost badge-sm w-fit">Private</span>
              </div>
            </section>

            <section id="profile-public-settings" class="ui-card h-auto p-5 sm:p-7">
              <h2 class="text-xl font-black text-base-content">Public profile</h2>
              <p class="mt-1 text-sm text-base-content/70">
                Update the information shown to other members.
              </p>

              <div class="divider my-5"></div>

              <.form
                for={@form}
                id="profile-form"
                phx-change="validate_profile"
                phx-submit="update_profile"
                class="space-y-4"
              >
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

                <.input
                  field={@form[:private_profile]}
                  id="profile-form-private-profile"
                  type="checkbox"
                  label="Make my profile private"
                  help="Only you, admins, and moderators can view your profile details and activity."
                  class="toggle toggle-primary"
                />

                <div class="flex justify-end">
                  <button id="profile-save" type="submit" class="btn btn-primary">
                    Save profile
                  </button>
                </div>
              </.form>
            </section>

            <section id="profile-danger-zone" class="ui-card h-auto border-error/45 p-5 sm:p-7">
              <h2 class="text-xl font-black text-error">Danger zone</h2>
              <p class="mt-1 text-sm text-base-content/70">Irreversible account actions.</p>

              <div class="divider my-5"></div>

              <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p class="font-bold">Delete account</p>
                  <p class="text-xs text-base-content/60">
                    Permanently delete your account and all data.
                  </p>
                </div>
                <button
                  id="profile-delete-open"
                  type="button"
                  phx-click="show_delete_confirm"
                  class="btn btn-error btn-sm w-full sm:w-auto"
                >
                  Delete account
                </button>
              </div>
            </section>

            <%= if @show_delete_confirm do %>
              <div id="profile-delete-modal" class="modal modal-open" role="dialog" aria-modal="true">
                <div class="modal-box">
                  <h3 class="text-lg font-black text-error">Delete account</h3>
                  <p class="py-4">
                    Are you sure you want to delete your account? This action cannot be undone.
                    All your data will be permanently deleted.
                  </p>
                  <div class="modal-action">
                    <button type="button" phx-click="cancel_delete" class="btn">Cancel</button>
                    <button type="button" phx-click="delete_account" class="btn btn-error">
                      Yes, delete
                    </button>
                  </div>
                </div>
                <button
                  type="button"
                  class="modal-backdrop"
                  phx-click="cancel_delete"
                  aria-label="Close delete account dialog"
                ></button>
              </div>
            <% end %>
          <% end %>

          <section id="profile-activity" class="ui-card h-auto p-5 sm:p-7">
            <h2 class="text-xl font-black text-base-content">Activity</h2>
            <p class="mt-1 text-sm text-base-content/70">Recent discussions and replies.</p>

            <div class="divider my-5"></div>

            <div
              id="profile-activity-tabs"
              class="tabs tabs-border mb-5 w-full"
              role="tablist"
              aria-label="Profile activity"
            >
              <button
                id="profile-threads-tab"
                type="button"
                role="tab"
                aria-selected={to_string(@active_tab == "threads")}
                class={[
                  "tab min-h-11 font-semibold",
                  @active_tab == "threads" && "tab-active text-primary"
                ]}
                phx-click="switch_tab"
                phx-value-tab="threads"
              >
                Threads
              </button>
              <button
                id="profile-comments-tab"
                type="button"
                role="tab"
                aria-selected={to_string(@active_tab == "comments")}
                class={[
                  "tab min-h-11 font-semibold",
                  @active_tab == "comments" && "tab-active text-primary"
                ]}
                phx-click="switch_tab"
                phx-value-tab="comments"
              >
                Comments
              </button>
            </div>

            <%= if @active_tab == "threads" do %>
              <%= if Enum.empty?(@threads) do %>
                <.empty_state
                  id="profile-threads-empty"
                  title="No discussions yet"
                  description="Discussions started by this member will appear here."
                  icon="hero-chat-bubble-left-right"
                  compact
                />
              <% else %>
                <div id="profile-thread-list" class="divide-y divide-base-300/60">
                  <%= for thread <- @threads do %>
                    <a
                      href={~p"/forum/t/#{thread.id}"}
                      class="group block px-1 py-4 first:pt-0 last:pb-0"
                    >
                      <p class="font-bold text-base-content transition-colors group-hover:text-primary">
                        {thread.title}
                      </p>
                      <p class="mt-1 line-clamp-1 text-sm text-base-content/60">{thread.body}</p>
                      <div class="mt-2 flex flex-wrap items-center gap-3 text-xs text-base-content/50">
                        <span>{Calendar.strftime(thread.created_at, "%b %d, %Y")}</span>
                        <span>
                          {thread.comment_count} {if thread.comment_count == 1,
                            do: "reply",
                            else: "replies"}
                        </span>
                      </div>
                    </a>
                  <% end %>
                </div>

                <%= if @threads_meta do %>
                  <div class="join mt-5 flex justify-center">
                    <%= if @threads_meta.current_page > 1 do %>
                      <button
                        class="btn btn-sm join-item"
                        phx-click="change_page"
                        phx-value-tab="threads"
                        phx-value-page={@threads_meta.current_page - 1}
                      >
                        <.um_icon name="hero-chevron-left" class="size-4" /> Previous
                      </button>
                    <% end %>
                    <span class="btn btn-sm btn-disabled join-item">
                      {@threads_meta.current_page} / {@threads_meta.total_pages}
                    </span>
                    <%= if @threads_meta.current_page < @threads_meta.total_pages do %>
                      <button
                        class="btn btn-sm join-item"
                        phx-click="change_page"
                        phx-value-tab="threads"
                        phx-value-page={@threads_meta.current_page + 1}
                      >
                        Next <.um_icon name="hero-chevron-right" class="size-4" />
                      </button>
                    <% end %>
                  </div>
                <% end %>
              <% end %>
            <% end %>

            <%= if @active_tab == "comments" do %>
              <%= if Enum.empty?(@comments) do %>
                <.empty_state
                  id="profile-comments-empty"
                  title="No replies yet"
                  description="Replies posted by this member will appear here."
                  icon="hero-chat-bubble-oval-left"
                  compact
                />
              <% else %>
                <div id="profile-comment-list" class="divide-y divide-base-300/60">
                  <%= for comment <- @comments do %>
                    <article class="px-1 py-4 first:pt-0 last:pb-0">
                      <a
                        href={~p"/forum/t/#{comment.thread_id}" <> "#comment-#{comment.id}"}
                        class="link link-primary text-sm font-bold"
                      >
                        {comment.thread_title}
                      </a>
                      <p class="mt-2 leading-6 text-base-content">{comment.body}</p>
                      <div class="mt-2 text-xs text-base-content/50">
                        {Calendar.strftime(comment.created_at, "%b %d, %Y")}
                        <%= if comment.edited_at do %>
                          <span class="ml-2">(edited)</span>
                        <% end %>
                      </div>
                    </article>
                  <% end %>
                </div>

                <%= if @comments_meta do %>
                  <div class="join mt-5 flex justify-center">
                    <%= if @comments_meta.current_page > 1 do %>
                      <button
                        class="btn btn-sm join-item"
                        phx-click="change_page"
                        phx-value-tab="comments"
                        phx-value-page={@comments_meta.current_page - 1}
                      >
                        <.um_icon name="hero-chevron-left" class="size-4" /> Previous
                      </button>
                    <% end %>
                    <span class="btn btn-sm btn-disabled join-item">
                      {@comments_meta.current_page} / {@comments_meta.total_pages}
                    </span>
                    <%= if @comments_meta.current_page < @comments_meta.total_pages do %>
                      <button
                        class="btn btn-sm join-item"
                        phx-click="change_page"
                        phx-value-tab="comments"
                        phx-value-page={@comments_meta.current_page + 1}
                      >
                        Next <.um_icon name="hero-chevron-right" class="size-4" />
                      </button>
                    <% end %>
                  </div>
                <% end %>
              <% end %>
            <% end %>
          </section>
        </div>

        <%= if @show_suspend_modal do %>
          <div id="profile-suspend-modal" class="modal modal-open" role="dialog" aria-modal="true">
            <div class="modal-box bg-base-200">
              <h3 class="text-lg font-black text-error">Suspend {@user.username}</h3>
              <p class="py-2 text-sm text-base-content/70">
                Suspended users cannot sign in or access the site.
              </p>
              <div class="mt-4 space-y-4">
                <div>
                  <label class="label">
                    <span class="label-text">Reason (required)</span>
                  </label>
                  <textarea
                    id="profile-suspend-reason"
                    class="textarea textarea-bordered w-full bg-base-100"
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
                    id="profile-suspend-duration"
                    class="select select-bordered w-full bg-base-100"
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
                  Suspend user
                </button>
              </div>
            </div>
            <button
              type="button"
              class="modal-backdrop"
              phx-click="close_mod_modal"
              aria-label="Close suspend user dialog"
            ></button>
          </div>
        <% end %>

        <%= if @show_silence_modal do %>
          <div id="profile-silence-modal" class="modal modal-open" role="dialog" aria-modal="true">
            <div class="modal-box bg-base-200">
              <h3 class="text-lg font-black text-warning">Silence {@user.username}</h3>
              <p class="py-2 text-sm text-base-content/70">
                Silenced users can browse but cannot post, comment, or vote.
              </p>
              <div class="mt-4 space-y-4">
                <div>
                  <label class="label">
                    <span class="label-text">Reason (required)</span>
                  </label>
                  <textarea
                    id="profile-silence-reason"
                    class="textarea textarea-bordered w-full bg-base-100"
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
                    id="profile-silence-duration"
                    class="select select-bordered w-full bg-base-100"
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
                  Silence user
                </button>
              </div>
            </div>
            <button
              type="button"
              class="modal-backdrop"
              phx-click="close_mod_modal"
              aria-label="Close silence user dialog"
            ></button>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
