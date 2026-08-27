defmodule UrielmWeb.Admin.UserDetailLive do
  use UrielmWeb, :live_view

  import UrielmWeb.AdminComponents

  alias Urielm.Accounts
  alias Urielm.Accounts.User

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      case Accounts.get_user(id) do
        nil ->
          {:ok, redirect(socket, to: "/admin/users")}

        user ->
          {:ok,
           socket
           |> assign(:page_title, "Manage #{user.username}")
           |> assign(:user, user)
           |> assign(:action, nil)
           |> assign(:duration, "7d")
           |> assign(:reason, "")}
      end
    else
      {:ok,
       socket
       |> assign(:page_title, "User Detail")
       |> assign(:user, nil)
       |> assign(:action, nil)
       |> assign(:duration, "7d")
       |> assign(:reason, "")}
    end
  end

  @impl true
  def handle_event("show_action", %{"action" => action}, socket) do
    {:noreply, assign(socket, :action, action)}
  end

  @impl true
  def handle_event("cancel_action", _params, socket) do
    {:noreply, assign(socket, action: nil, reason: "", duration: "7d")}
  end

  @impl true
  def handle_event("set_duration", %{"duration" => duration}, socket) do
    {:noreply, assign(socket, :duration, duration)}
  end

  @impl true
  def handle_event("set_reason", %{"reason" => reason}, socket) do
    {:noreply, assign(socket, :reason, reason)}
  end

  @impl true
  def handle_event("grant_mod", _params, socket) do
    case Accounts.grant_moderator(socket.assigns.user, socket.assigns.current_user) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:user, updated)
         |> assign(:action, nil)
         |> put_flash(:info, "#{updated.username} is now a moderator")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to grant moderator")}
    end
  end

  @impl true
  def handle_event("revoke_mod", _params, socket) do
    case Accounts.revoke_moderator(socket.assigns.user, socket.assigns.current_user) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:user, updated)
         |> assign(:action, nil)
         |> put_flash(:info, "Moderator role removed from #{updated.username}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to revoke moderator")}
    end
  end

  @impl true
  def handle_event("suspend", _params, socket) do
    %{user: user, current_user: admin, duration: duration, reason: reason} = socket.assigns

    if String.trim(reason) == "" do
      {:noreply, put_flash(socket, :error, "Reason is required")}
    else
      until = parse_duration(duration)
      opts = [reason: reason, until: until]

      case Accounts.suspend_user(user, admin, opts) do
        {:ok, updated} ->
          {:noreply,
           socket
           |> assign(:user, updated)
           |> assign(:action, nil)
           |> assign(:reason, "")
           |> put_flash(:info, "#{updated.username} has been suspended")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to suspend user")}
      end
    end
  end

  @impl true
  def handle_event("unsuspend", _params, socket) do
    case Accounts.unsuspend_user(socket.assigns.user, socket.assigns.current_user) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:user, updated)
         |> put_flash(:info, "#{updated.username}'s suspension has been lifted")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove suspension")}
    end
  end

  @impl true
  def handle_event("silence", _params, socket) do
    %{user: user, current_user: admin, duration: duration, reason: reason} = socket.assigns

    if String.trim(reason) == "" do
      {:noreply, put_flash(socket, :error, "Reason is required")}
    else
      until = parse_duration(duration)
      opts = [reason: reason, until: until]

      case Accounts.silence_user(user, admin, opts) do
        {:ok, updated} ->
          {:noreply,
           socket
           |> assign(:user, updated)
           |> assign(:action, nil)
           |> assign(:reason, "")
           |> put_flash(:info, "#{updated.username} has been silenced")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to silence user")}
      end
    end
  end

  @impl true
  def handle_event("unsilence", _params, socket) do
    case Accounts.unsilence_user(socket.assigns.user, socket.assigns.current_user) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:user, updated)
         |> put_flash(:info, "#{updated.username}'s silence has been lifted")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove silence")}
    end
  end

  @impl true
  def handle_event("set_trust_level", %{"trust_level" => level}, socket) do
    trust_level =
      case Integer.parse(level) do
        {n, ""} -> n
        _ -> nil
      end

    case trust_level do
      nil ->
        {:noreply, put_flash(socket, :error, "Invalid trust level")}

      trust_level ->
        case Accounts.update_trust_level(
               socket.assigns.user,
               trust_level,
               socket.assigns.current_user
             ) do
          {:ok, updated} ->
            {:noreply,
             socket
             |> assign(:user, updated)
             |> put_flash(:info, "Trust level updated to TL#{trust_level}")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update trust level")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="admin"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div id="admin-user-detail-page" class="ui-page-shell max-w-6xl">
        <header id="admin-user-detail-header" class="ui-page-header ui-page-heading">
          <h1 class="ui-section-title">User details</h1>
          <p class="ui-section-copy">Review account status, roles, and moderation controls.</p>
        </header>

        <.admin_nav current="users" />

        <.link
          id="admin-user-back-link"
          navigate={~p"/admin/users"}
          class="btn btn-ghost btn-sm -ml-2 mb-5 gap-2 text-base-content/55 hover:text-primary"
        >
          <.um_icon name="hero-arrow-left" class="size-4" /> All users
        </.link>

        <%= if @user do %>
          <section id="admin-user-overview" class="ui-card mb-8 h-auto p-5 sm:p-7">
            <div class="flex flex-col gap-4 sm:flex-row sm:items-start">
              <div class="avatar shrink-0">
                <div class="size-16 rounded-full">
                  <%= if @user.avatar_url do %>
                    <img src={@user.avatar_url} alt={@user.username} />
                  <% else %>
                    <div class="grid size-16 place-items-center rounded-full bg-base-300 text-xl font-bold">
                      {String.first(@user.username || "?")}
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h2 class="min-w-0 break-words text-2xl font-black text-base-content">
                    {@user.username}
                  </h2>
                  <.role_badge user={@user} />
                  <.status_badge user={@user} />
                </div>
                <p
                  :if={@user.display_name && @user.display_name != @user.username}
                  class="mt-1 text-base-content/65"
                >
                  {@user.display_name}
                </p>
                <p class="mt-1 break-all text-sm text-base-content/55">{@user.email}</p>
                <p class="mt-2 text-xs text-base-content/45">
                  Joined {Calendar.strftime(@user.inserted_at, "%B %d, %Y")} · TL{@user.trust_level}
                  <span :if={@user.trust_level_locked} class="badge badge-xs badge-ghost ml-1">
                    locked
                  </span>
                </p>
                <p :if={@user.bio} class="mt-3 max-w-3xl text-sm leading-6 text-base-content/70">
                  {@user.bio}
                </p>
              </div>
            </div>

            <div
              :if={User.suspended?(@user)}
              id="admin-user-suspended-status"
              class="alert alert-error mt-5 items-start"
            >
              <.um_icon name="hero-no-symbol" class="size-5 shrink-0" />
              <div>
                <p class="font-semibold">Suspended</p>
                <p class="text-sm">{@user.suspended_reason}</p>
                <p class="text-xs opacity-75">
                  {if @user.suspended_until,
                    do: "Until #{Calendar.strftime(@user.suspended_until, "%B %d, %Y %H:%M UTC")}",
                    else: "Permanent"}
                </p>
              </div>
            </div>

            <div
              :if={User.silenced?(@user)}
              id="admin-user-silenced-status"
              class="alert alert-warning mt-5 items-start"
            >
              <.um_icon name="hero-speaker-x-mark" class="size-5 shrink-0" />
              <div>
                <p class="font-semibold">Silenced</p>
                <p class="text-sm">{@user.silenced_reason}</p>
                <p class="text-xs opacity-75">
                  {if @user.silenced_until,
                    do: "Until #{Calendar.strftime(@user.silenced_until, "%B %d, %Y %H:%M UTC")}",
                    else: "Permanent"}
                </p>
              </div>
            </div>
          </section>

          <section id="admin-user-actions" aria-labelledby="admin-user-actions-title">
            <div class="mb-5">
              <h2 id="admin-user-actions-title" class="text-xl font-black text-base-content">
                Account controls
              </h2>
              <p class="mt-1 text-sm text-base-content/55">
                Changes apply immediately and are recorded for moderation review.
              </p>
            </div>

            <div class="grid gap-4 lg:grid-cols-2">
              <section id="admin-user-trust-control" class="ui-card h-auto p-5 sm:p-6">
                <h3 class="font-bold text-base-content">Trust level</h3>
                <div class="mt-4 flex flex-wrap gap-2">
                  <button
                    :for={level <- 0..4}
                    id={"admin-user-trust-level-#{level}"}
                    type="button"
                    phx-click="set_trust_level"
                    phx-value-trust_level={level}
                    class={[
                      "btn btn-sm",
                      if(@user.trust_level == level, do: "btn-primary", else: "btn-ghost")
                    ]}
                    disabled={@user.trust_level_locked}
                  >
                    TL{level}
                  </button>
                </div>
                <p :if={@user.trust_level_locked} class="mt-3 text-xs text-base-content/50">
                  Trust level is locked for this user.
                </p>
              </section>

              <section id="admin-user-role-control" class="ui-card h-auto p-5 sm:p-6">
                <h3 class="font-bold text-base-content">Moderator role</h3>
                <%= if @user.is_admin do %>
                  <p class="mt-3 text-sm text-base-content/55">Admin roles cannot be changed here.</p>
                <% else %>
                  <div class="mt-4">
                    <button
                      :if={@user.is_moderator}
                      id="admin-user-revoke-moderator"
                      type="button"
                      phx-click="revoke_mod"
                      class="btn btn-warning btn-sm"
                    >
                      Revoke moderator
                    </button>
                    <button
                      :if={!@user.is_moderator}
                      id="admin-user-grant-moderator"
                      type="button"
                      phx-click="grant_mod"
                      class="btn btn-primary btn-sm"
                    >
                      Grant moderator
                    </button>
                  </div>
                <% end %>
              </section>

              <section id="admin-user-suspension-control" class="ui-card h-auto p-5 sm:p-6">
                <h3 class="font-bold text-base-content">Suspension</h3>
                <div class="mt-4">
                  <%= if User.suspended?(@user) do %>
                    <button
                      id="admin-user-unsuspend"
                      type="button"
                      phx-click="unsuspend"
                      class="btn btn-success btn-sm"
                    >
                      Remove Suspension
                    </button>
                  <% else %>
                    <%= if @action == "suspend" do %>
                      <.action_form
                        action="suspend"
                        label="Suspend user"
                        duration={@duration}
                        reason={@reason}
                        danger={true}
                      />
                    <% else %>
                      <button
                        id="admin-user-show-suspend"
                        type="button"
                        phx-click="show_action"
                        phx-value-action="suspend"
                        class="btn btn-error btn-sm"
                      >
                        Suspend user
                      </button>
                    <% end %>
                  <% end %>
                </div>
              </section>

              <section id="admin-user-silence-control" class="ui-card h-auto p-5 sm:p-6">
                <h3 class="font-bold text-base-content">Silencing</h3>
                <div class="mt-4">
                  <%= if User.silenced?(@user) do %>
                    <button
                      id="admin-user-unsilence"
                      type="button"
                      phx-click="unsilence"
                      class="btn btn-success btn-sm"
                    >
                      Remove Silence
                    </button>
                  <% else %>
                    <%= if @action == "silence" do %>
                      <.action_form
                        action="silence"
                        label="Silence user"
                        duration={@duration}
                        reason={@reason}
                        danger={false}
                      />
                    <% else %>
                      <button
                        id="admin-user-show-silence"
                        type="button"
                        phx-click="show_action"
                        phx-value-action="silence"
                        class="btn btn-warning btn-sm"
                      >
                        Silence user
                      </button>
                    <% end %>
                  <% end %>
                </div>
              </section>
            </div>
          </section>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp action_form(assigns) do
    ~H"""
    <div id={"admin-#{@action}-form"} class="space-y-4">
      <div>
        <p class="mb-2 text-sm font-semibold text-base-content">Duration</p>
        <div class="flex flex-wrap gap-2">
          <%= for {label, value} <- [{"1 day", "1d"}, {"3 days", "3d"}, {"7 days", "7d"}, {"30 days", "30d"}, {"Permanent", "permanent"}] do %>
            <button
              id={"admin-#{@action}-duration-#{value}"}
              phx-click="set_duration"
              phx-value-duration={value}
              class={[
                "btn btn-xs",
                if(@duration == value, do: "btn-primary", else: "btn-ghost")
              ]}
              type="button"
            >
              {label}
            </button>
          <% end %>
        </div>
      </div>

      <div>
        <label for={"admin-#{@action}-reason"} class="label">
          <span class="label-text text-sm font-semibold">
            Reason <span class="text-error">*</span>
          </span>
        </label>
        <textarea
          id={"admin-#{@action}-reason"}
          phx-keyup="set_reason"
          phx-value-reason={@reason}
          name="reason"
          placeholder="Required reason..."
          class="textarea textarea-bordered min-h-24 w-full resize-y rounded-lg bg-base-100 text-sm"
          rows="3"
        >{@reason}</textarea>
      </div>

      <div class="flex gap-2">
        <button
          id={"admin-#{@action}-confirm"}
          type="button"
          phx-click={@action}
          class={["btn btn-sm", if(@danger, do: "btn-error", else: "btn-warning")]}
        >
          Confirm
        </button>
        <button
          id={"admin-#{@action}-cancel"}
          type="button"
          phx-click="cancel_action"
          class="btn btn-ghost btn-sm"
        >
          Cancel
        </button>
      </div>
    </div>
    """
  end

  defp parse_duration("permanent"), do: nil
  defp parse_duration("1d"), do: DateTime.add(DateTime.utc_now(), 1, :day)
  defp parse_duration("3d"), do: DateTime.add(DateTime.utc_now(), 3, :day)
  defp parse_duration("7d"), do: DateTime.add(DateTime.utc_now(), 7, :day)
  defp parse_duration("30d"), do: DateTime.add(DateTime.utc_now(), 30, :day)
  defp parse_duration(_), do: DateTime.add(DateTime.utc_now(), 7, :day)
end
