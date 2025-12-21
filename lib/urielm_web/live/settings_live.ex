defmodule UrielmWeb.SettingsLive do
  use UrielmWeb, :live_view
  alias Urielm.Accounts
  alias Urielm.Params

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if is_nil(user) do
      {:ok, redirect(socket, to: ~p"/signup")}
    else
      {:ok,
       socket
       |> assign(:page_title, "Settings")
       |> assign(:user, user)
       |> assign(:profile_form, to_form(Accounts.User.changeset(user, %{})))
       |> assign(
         :password_form,
         to_form(%{"current_password" => "", "new_password" => "", "confirm_password" => ""},
           as: :password
         )
       )}
    end
  end

  @impl true
  def handle_event("update_profile", %{"user" => user_params0}, socket) do
    case Accounts.update_user(socket.assigns.current_user, Params.normalize(user_params0)) do
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

  @impl true
  def handle_event("change_password", %{"password" => password_params0}, socket) do
    %{
      "current_password" => current_password,
      "new_password" => new_password,
      "confirm_password" => confirm_password
    } = Params.normalize(password_params0)

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
               to_form(
                 %{
                   "current_password" => "",
                   "new_password" => "",
                   "confirm_password" => ""
                 },
                 as: :password
               )
             )}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to change password")}
        end
    end
  end

  @impl true
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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="settings" socket={@socket}>
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
                <.input
                  field={@profile_form[:name]}
                  type="text"
                  label="Full Name"
                  placeholder="Enter your full name"
                />

                <div class="form-control">
                  <.input
                    field={@profile_form[:username]}
                    type="text"
                    label="Username"
                    placeholder="Enter your username"
                  />
                  <label class="label">
                    <span class="label-text-alt">
                      3-20 characters, letters, numbers, and underscores only
                    </span>
                  </label>
                </div>

                <.input
                  field={@profile_form[:email]}
                  type="email"
                  label="Email Address"
                  placeholder="Enter your email"
                />

                <.input
                  field={@profile_form[:bio]}
                  type="textarea"
                  label="Bio"
                  placeholder="Tell us about yourself..."
                />
                <label class="label">
                  <span class="label-text-alt">Max 1000 characters</span>
                </label>

                <.input
                  field={@profile_form[:location]}
                  type="text"
                  label="Location"
                  placeholder="City, Country"
                />

                <.input
                  field={@profile_form[:website]}
                  type="url"
                  label="Website"
                  placeholder="https://example.com"
                />

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
                <.input
                  field={@password_form[:current_password]}
                  type="password"
                  label="Current Password"
                  placeholder="Enter current password"
                  required
                />

                <.input
                  field={@password_form[:new_password]}
                  type="password"
                  label="New Password"
                  placeholder="Enter new password"
                  minlength="8"
                  required
                />

                <.input
                  field={@password_form[:confirm_password]}
                  type="password"
                  label="Confirm New Password"
                  placeholder="Confirm new password"
                  minlength="8"
                  required
                />

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
    </Layouts.app>
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
