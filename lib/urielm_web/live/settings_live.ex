defmodule UrielmWeb.SettingsLive do
  use UrielmWeb, :live_view
  alias Urielm.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:user, user)
     |> assign(:profile_form, to_form(Accounts.User.changeset(user, %{})))
     |> assign(
       :password_form,
       to_form(%{"current_password" => "", "new_password" => "", "confirm_password" => ""})
     )}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    case Accounts.update_user(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")
         |> assign(:user, user)
         |> assign(:current_user, user)
         |> assign(:profile_form, to_form(Accounts.User.changeset(user, %{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  def handle_event("change_password", %{"password" => password_params}, socket) do
    %{
      "current_password" => current_password,
      "new_password" => new_password,
      "confirm_password" => confirm_password
    } = password_params

    cond do
      new_password != confirm_password ->
        {:noreply, put_flash(socket, :error, "New passwords do not match")}

      not Accounts.User.valid_password?(socket.assigns.current_user, current_password) ->
        {:noreply, put_flash(socket, :error, "Current password is incorrect")}

      true ->
        case Accounts.update_user_password(socket.assigns.current_user, %{password: new_password}) do
          {:ok, _user} ->
            {:noreply,
             socket
             |> put_flash(:info, "Password changed successfully")
             |> assign(
               :password_form,
               to_form(%{
                 "current_password" => "",
                 "new_password" => "",
                 "confirm_password" => ""
               })
             )}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to change password")}
        end
    end
  end

  def handle_event("delete_account", _params, socket) do
    case Accounts.delete_user(socket.assigns.current_user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account deleted successfully")
         |> redirect(to: "/auth/logout")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete account")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-4xl">
      <div class="mb-8">
        <h1 class="text-3xl font-bold">Settings</h1>
        <p class="text-base-content/70">Manage your account settings and preferences</p>
      </div>

      <div class="space-y-6">
        <%!-- Profile Information Card --%>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Profile Information</h2>
            <p class="text-sm text-base-content/70">
              Update your personal information and account details
            </p>

            <div class="divider"></div>

            <%!-- Avatar Section --%>
            <div class="flex items-center gap-4 mb-4">
              <div class="avatar placeholder">
                <div class="bg-primary text-primary-content w-20 rounded-full">
                  <%= if @user.avatar_url do %>
                    <img src={@user.avatar_url} alt={@user.name || @user.email} />
                  <% else %>
                    <span class="text-2xl">{get_initials(@user)}</span>
                  <% end %>
                </div>
              </div>
              <div>
                <button class="btn btn-outline btn-sm">Change Photo</button>
                <p class="text-xs text-base-content/60 mt-1">JPG, PNG, or GIF. Max 2MB.</p>
              </div>
            </div>

            <.form for={@profile_form} phx-submit="update_profile" class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Full Name</span>
                </label>
                <input
                  type="text"
                  name="user[name]"
                  value={@user.name}
                  placeholder="Enter your full name"
                  class="input input-bordered w-full"
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text">Username</span>
                </label>
                <input
                  type="text"
                  name="user[username]"
                  value={@user.username}
                  placeholder="Enter your username"
                  class="input input-bordered w-full"
                />
                <label class="label">
                  <span class="label-text-alt">
                    3-20 characters, letters, numbers, and underscores only
                  </span>
                </label>
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text">Email Address</span>
                </label>
                <input
                  type="email"
                  name="user[email]"
                  value={@user.email}
                  placeholder="Enter your email"
                  class="input input-bordered w-full"
                />
              </div>

              <div class="card-actions">
                <button type="submit" class="btn btn-primary">
                  Save Profile
                </button>
              </div>
            </.form>
          </div>
        </div>

        <%!-- Change Password Card --%>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Change Password</h2>
            <p class="text-sm text-base-content/70">
              Update your password to keep your account secure
            </p>

            <div class="divider"></div>

            <.form for={@password_form} phx-submit="change_password" class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Current Password</span>
                </label>
                <input
                  type="password"
                  name="password[current_password]"
                  placeholder="Enter current password"
                  class="input input-bordered w-full"
                  required
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text">New Password</span>
                </label>
                <input
                  type="password"
                  name="password[new_password]"
                  placeholder="Enter new password"
                  minlength="8"
                  class="input input-bordered w-full"
                  required
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text">Confirm New Password</span>
                </label>
                <input
                  type="password"
                  name="password[confirm_password]"
                  placeholder="Confirm new password"
                  minlength="8"
                  class="input input-bordered w-full"
                  required
                />
              </div>

              <div class="card-actions">
                <button type="submit" class="btn btn-primary">
                  Change Password
                </button>
              </div>
            </.form>
          </div>
        </div>

        <%!-- Theme Settings Card --%>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Appearance</h2>
            <p class="text-sm text-base-content/70">Customize your theme preference</p>

            <div class="divider"></div>

            <div class="space-y-4">
              <div class="flex items-center justify-between">
                <div>
                  <p class="font-medium">Theme</p>
                  <p class="text-xs text-base-content/60">Choose your preferred color scheme</p>
                </div>
                <div class="join">
                  <button
                    class="btn btn-sm join-item"
                    data-theme="light"
                    phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
                  >
                    Light
                  </button>
                  <button
                    class="btn btn-sm join-item"
                    data-theme="dark"
                    phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
                  >
                    Dark
                  </button>
                  <button
                    class="btn btn-sm join-item"
                    phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
                  >
                    System
                  </button>
                </div>
              </div>
              <div class="flex justify-end">
                <a href="/themes" class="btn btn-outline btn-sm">
                  More Themes
                </a>
              </div>
            </div>
          </div>
        </div>

        <%!-- Danger Zone Card --%>
        <div class="card bg-base-100 shadow-xl border-2 border-error">
          <div class="card-body">
            <h2 class="card-title text-error">Danger Zone</h2>
            <p class="text-sm text-base-content/70">Irreversible and destructive actions</p>

            <div class="divider"></div>

            <div class="flex items-center justify-between">
              <div>
                <p class="font-medium">Delete Account</p>
                <p class="text-xs text-base-content/60">
                  Permanently delete your account and all data
                </p>
              </div>
              <button
                class="btn btn-error"
                onclick="delete_account_modal.showModal()"
              >
                Delete Account
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <%!-- Delete Account Confirmation Modal --%>
    <dialog id="delete_account_modal" class="modal">
      <div class="modal-box">
        <h3 class="font-bold text-lg text-error">Delete Account</h3>
        <p class="py-4">
          Are you sure you want to delete your account? This action cannot be undone.
          All your data, including courses, saved prompts, and comments will be permanently deleted.
        </p>
        <div class="modal-action">
          <form method="dialog">
            <button class="btn">Cancel</button>
          </form>
          <button phx-click="delete_account" class="btn btn-error">
            Yes, Delete My Account
          </button>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  defp get_initials(user) do
    cond do
      user.name ->
        user.name
        |> String.split(" ")
        |> Enum.map(&String.first/1)
        |> Enum.join("")
        |> String.upcase()
        |> String.slice(0, 2)

      user.email ->
        String.upcase(String.first(user.email))

      true ->
        "U"
    end
  end
end
