defmodule UrielmWeb.Admin.UserDetailLive do
  use UrielmWeb, :live_view

  import UrielmWeb.AdminComponents

  alias Urielm.Accounts
  alias Urielm.Accounts.User

  @impl true
  def mount(%{"id" => id}, _session, socket) do
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
    <Layouts.app flash={@flash} current_user={@current_user} current_page="admin" socket={@socket}>
      <div class="min-h-screen bg-base-100">
        <div class="container mx-auto px-4 py-8 max-w-3xl">
          <div class="mb-6">
            <a href="/admin/users" class="text-sm text-base-content/50 hover:text-primary">
              ← Back to Users
            </a>
          </div>

          <div class="card bg-base-200 border border-base-300 mb-6">
            <div class="card-body">
              <div class="flex items-start gap-4">
                <div class="avatar">
                  <div class="w-16 rounded-full">
                    <%= if @user.avatar_url do %>
                      <img src={@user.avatar_url} alt={@user.username} />
                    <% else %>
                      <div class="bg-base-300 w-16 h-16 rounded-full flex items-center justify-center text-xl font-bold">
                        {String.first(@user.username || "?")}
                      </div>
                    <% end %>
                  </div>
                </div>

                <div class="flex-1">
                  <div class="flex items-center gap-2 flex-wrap">
                    <h1 class="text-2xl font-bold">{@user.username}</h1>
                    <.role_badge user={@user} />
                    <.status_badge user={@user} />
                  </div>
                  <%= if @user.display_name && @user.display_name != @user.username do %>
                    <p class="text-base-content/60 mt-1">{@user.display_name}</p>
                  <% end %>
                  <p class="text-sm text-base-content/50 mt-1">{@user.email}</p>
                  <p class="text-xs text-base-content/40 mt-1">
                    Joined {Calendar.strftime(@user.inserted_at, "%B %d, %Y")} &middot;
                    TL{@user.trust_level}
                    <%= if @user.trust_level_locked do %>
                      <span class="badge badge-xs badge-ghost ml-1">locked</span>
                    <% end %>
                  </p>
                  <%= if @user.bio do %>
                    <p class="text-sm text-base-content/70 mt-2">{@user.bio}</p>
                  <% end %>
                </div>
              </div>

              <%= if User.suspended?(@user) do %>
                <div class="alert alert-error mt-4">
                  <div>
                    <p class="font-semibold">Suspended</p>
                    <p class="text-sm">{@user.suspended_reason}</p>
                    <%= if @user.suspended_until do %>
                      <p class="text-xs opacity-75">
                        Until {Calendar.strftime(@user.suspended_until, "%B %d, %Y %H:%M UTC")}
                      </p>
                    <% else %>
                      <p class="text-xs opacity-75">Permanent</p>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%= if User.silenced?(@user) do %>
                <div class="alert alert-warning mt-4">
                  <div>
                    <p class="font-semibold">Silenced</p>
                    <p class="text-sm">{@user.silenced_reason}</p>
                    <%= if @user.silenced_until do %>
                      <p class="text-xs opacity-75">
                        Until {Calendar.strftime(@user.silenced_until, "%B %d, %Y %H:%M UTC")}
                      </p>
                    <% else %>
                      <p class="text-xs opacity-75">Permanent</p>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="space-y-4">
            <h2 class="text-lg font-semibold text-base-content">Actions</h2>

            <div class="card bg-base-200 border border-base-300">
              <div class="card-body">
                <h3 class="font-medium mb-3">Trust Level</h3>
                <div class="flex gap-2 flex-wrap">
                  <%= for level <- 0..4 do %>
                    <button
                      phx-click="set_trust_level"
                      phx-value-trust_level={level}
                      class={"btn btn-sm #{if @user.trust_level == level, do: "btn-primary", else: "btn-ghost"}"}
                      disabled={@user.trust_level_locked}
                    >
                      TL{level}
                    </button>
                  <% end %>
                </div>
                <%= if @user.trust_level_locked do %>
                  <p class="text-xs text-base-content/50 mt-2">
                    Trust level is locked for this user.
                  </p>
                <% end %>
              </div>
            </div>

            <div class="card bg-base-200 border border-base-300">
              <div class="card-body">
                <h3 class="font-medium mb-3">Moderator Role</h3>
                <%= if @user.is_admin do %>
                  <p class="text-sm text-base-content/50">Cannot change role of an admin.</p>
                <% else %>
                  <div class="flex gap-2">
                    <%= if @user.is_moderator do %>
                      <button phx-click="revoke_mod" class="btn btn-sm btn-warning">
                        Revoke Moderator
                      </button>
                    <% else %>
                      <button phx-click="grant_mod" class="btn btn-sm btn-primary">
                        Grant Moderator
                      </button>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

            <div class="card bg-base-200 border border-base-300">
              <div class="card-body">
                <h3 class="font-medium mb-3">Suspension</h3>
                <%= if User.suspended?(@user) do %>
                  <button phx-click="unsuspend" class="btn btn-sm btn-success">
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
                      phx-click="show_action"
                      phx-value-action="suspend"
                      class="btn btn-sm btn-error"
                    >
                      Suspend User
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>

            <div class="card bg-base-200 border border-base-300">
              <div class="card-body">
                <h3 class="font-medium mb-3">Silencing</h3>
                <%= if User.silenced?(@user) do %>
                  <button phx-click="unsilence" class="btn btn-sm btn-success">
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
                      phx-click="show_action"
                      phx-value-action="silence"
                      class="btn btn-sm btn-warning"
                    >
                      Silence User
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp action_form(assigns) do
    ~H"""
    <div class="space-y-3">
      <div>
        <label class="label">
          <span class="label-text text-sm">Duration</span>
        </label>
        <div class="flex gap-2 flex-wrap">
          <%= for {label, value} <- [{"1 day", "1d"}, {"3 days", "3d"}, {"7 days", "7d"}, {"30 days", "30d"}, {"Permanent", "permanent"}] do %>
            <button
              phx-click="set_duration"
              phx-value-duration={value}
              class={"btn btn-xs #{if @duration == value, do: "btn-primary", else: "btn-ghost"}"}
              type="button"
            >
              {label}
            </button>
          <% end %>
        </div>
      </div>

      <div>
        <label class="label">
          <span class="label-text text-sm">Reason <span class="text-error">*</span></span>
        </label>
        <textarea
          phx-keyup="set_reason"
          phx-value-reason={@reason}
          name="reason"
          placeholder="Required reason..."
          class="textarea textarea-bordered w-full text-sm"
          rows="2"
        >{@reason}</textarea>
      </div>

      <div class="flex gap-2">
        <button
          phx-click={@action}
          class={"btn btn-sm #{if @danger, do: "btn-error", else: "btn-warning"}"}
        >
          Confirm
        </button>
        <button phx-click="cancel_action" class="btn btn-sm btn-ghost">Cancel</button>
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
