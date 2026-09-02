defmodule UrielmWeb.SettingsLive do
  use UrielmWeb, :live_view
  alias Urielm.Accounts
  alias Urielm.Params

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:user, user)
     |> assign(:profile_form, to_form(Accounts.change_user_profile(user)))
     |> assign(
       :capability_badges_form,
       to_form(Accounts.change_user_capability_badges(user), as: :capability_badges)
     )
     |> assign(
       :password_form,
       to_form(%{"current_password" => "", "new_password" => "", "confirm_password" => ""},
         as: :password
       )
     )}
  end

  @impl true
  def handle_event("update_profile", %{"user" => user_params0}, socket) do
    case Accounts.update_user_profile(
           socket.assigns.current_user,
           Params.normalize(user_params0)
         ) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")
         |> assign(:user, user)
         |> assign(:current_user, user)
         |> assign(:profile_form, to_form(Accounts.change_user_profile(user)))}

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
  def handle_event("update_capability_badges", %{"capability_badges" => badge_params}, socket) do
    case Accounts.update_user_capability_badges(socket.assigns.current_user, badge_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Capability badges updated successfully")
         |> assign(:user, user)
         |> assign(:current_user, user)
         |> assign(
           :capability_badges_form,
           to_form(Accounts.change_user_capability_badges(user), as: :capability_badges)
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update capability badges")}
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
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="settings"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div id="settings-page" class="ui-page-shell max-w-4xl">
        <header id="settings-header" class="ui-page-header ui-page-heading">
          <h1 class="ui-section-title">Settings</h1>
          <p class="ui-section-copy">Manage your account details, security, and appearance.</p>
        </header>

        <div class="space-y-6">
          <section id="profile-settings-section" class="ui-card h-auto p-5 sm:p-7">
            <h2 class="text-xl font-black text-base-content">Profile information</h2>
            <p class="text-sm text-base-content/70">
              Update your personal information and account details.
            </p>

            <div class="divider my-6"></div>

            <div class="mb-5 flex items-center gap-4">
              <div class="avatar">
                <%= if @user.avatar_url do %>
                  <div class="size-20 overflow-hidden rounded-full">
                    <img src={@user.avatar_url} alt={@user.name || @user.email} />
                  </div>
                <% else %>
                  <div class="grid size-20 place-items-center rounded-full bg-primary text-primary-content">
                    <span class="text-2xl font-bold">{get_initials(@user)}</span>
                  </div>
                <% end %>
              </div>
              <div>
                <p class="font-bold text-base-content">Profile image</p>
                <p class="mt-1 text-xs leading-5 text-base-content/55">
                  Shown on your profile and community activity.
                </p>
              </div>
            </div>

            <.form
              for={@profile_form}
              id="profile-settings-form"
              phx-submit="update_profile"
              class="space-y-4"
            >
              <.input
                field={@profile_form[:display_name]}
                type="text"
                label="Display name"
                maxlength="50"
                placeholder="Enter your display name"
              />

              <.input
                field={@profile_form[:private_profile]}
                id="profile-private-profile"
                type="checkbox"
                label="Make my profile private"
                help="Only you, admins, and moderators can view your profile details and activity."
                class="toggle toggle-primary"
              />

              <.input
                field={@profile_form[:email]}
                type="email"
                label="Email address"
                help="Email changes are not supported from this form."
                placeholder="Enter your email"
                disabled
              />

              <.input
                field={@profile_form[:bio]}
                type="textarea"
                label="Bio"
                help="Maximum 1,000 characters."
                placeholder="Tell us about yourself..."
              />

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

              <div class="flex justify-end">
                <.button
                  id="profile-settings-submit"
                  type="submit"
                  loading_label="Saving profile…"
                  class="btn btn-primary"
                >
                  Save profile
                </.button>
              </div>
            </.form>
          </section>

          <section id="capability-badges-settings-section" class="ui-card h-auto p-5 sm:p-7">
            <h2 class="text-xl font-black text-base-content">Capability badges</h2>
            <p class="text-sm text-base-content/70">
              Choose how your assisted forum posts disclose agent, skill, and tool usage.
            </p>

            <div class="divider my-6"></div>

            <.form
              for={@capability_badges_form}
              id="capability-badges-settings-form"
              phx-submit="update_capability_badges"
              class="space-y-5"
            >
              <div class="grid gap-4 sm:grid-cols-2">
                <.input
                  field={@capability_badges_form[:agent_name]}
                  type="select"
                  label="Agent badge"
                  options={[
                    {"Codex", "Codex"},
                    {"Claude", "Claude"},
                    {"Grok", "Grok"},
                    {"Custom", "Custom"}
                  ]}
                />

                <.input
                  field={@capability_badges_form[:model_name]}
                  type="text"
                  label="Model label"
                  maxlength="40"
                  placeholder="GPT-5"
                />
              </div>

              <.input
                field={@capability_badges_form[:provider]}
                type="text"
                label="Provider"
                maxlength="40"
                placeholder="OpenAI"
              />

              <div class="grid gap-4 sm:grid-cols-2">
                <.input
                  field={@capability_badges_form[:skills_text]}
                  id="capability-skills-text"
                  type="textarea"
                  label="Skills"
                  help="One skill per line. These appear as skill chips on assisted forum posts."
                  placeholder="Phoenix skill\nUI craft\nDocs search"
                  class="textarea min-h-32 w-full resize-y rounded-lg border-base-300 bg-base-100/65 text-base-content placeholder:text-base-content/30 focus:border-secondary focus:outline-none"
                />

                <.input
                  field={@capability_badges_form[:tools_text]}
                  id="capability-tools-text"
                  type="textarea"
                  label="Tools"
                  help="One tool per line. Commas also work for quick entry."
                  placeholder="Terminal\nGit\nBrowser"
                  class="textarea min-h-32 w-full resize-y rounded-lg border-base-300 bg-base-100/65 text-base-content placeholder:text-base-content/30 focus:border-secondary focus:outline-none"
                />
              </div>

              <div class="space-y-3 rounded-xl border border-base-300/70 bg-base-100/45 p-4">
                <.input
                  field={@capability_badges_form[:agent_badge_enabled]}
                  id="capability-agent-badge-enabled"
                  type="checkbox"
                  label="Show agent badge beside my forum name"
                  help="Example: Codex · GPT-5"
                  class="toggle toggle-primary"
                />

                <.input
                  field={@capability_badges_form[:capability_chips_enabled]}
                  id="capability-chips-enabled"
                  type="checkbox"
                  label="Show skills and tools used on assisted posts"
                  help="Forum posts show up to three chips, then collapse extras into a count."
                  class="toggle toggle-primary"
                />
              </div>

              <div
                id="capability-badges-preview"
                class="rounded-xl border border-primary/25 bg-primary/6 p-4"
              >
                <p class="text-xs font-bold text-base-content/50">Forum preview</p>
                <div class="mt-3 flex flex-wrap items-center gap-2">
                  <span class="font-semibold text-base-content">yourname</span>
                  <span class="badge h-5 min-h-5 gap-1 border-primary/25 bg-primary/10 px-2 text-xs font-bold text-primary">
                    <span class="size-1.5 rounded-full bg-current"></span>
                    {@capability_badges_form[:agent_name].value} · {@capability_badges_form[
                      :model_name
                    ].value}
                  </span>
                </div>
                <div class="mt-3 flex flex-wrap gap-1.5">
                  <span class="badge h-6 min-h-6 border-primary/25 bg-primary/10 px-2 text-xs font-semibold text-primary">
                    Phoenix skill
                  </span>
                  <span class="badge h-6 min-h-6 border-accent/25 bg-accent/10 px-2 text-xs font-semibold text-accent">
                    Terminal
                  </span>
                  <span class="badge h-6 min-h-6 border-accent/25 bg-accent/10 px-2 text-xs font-semibold text-accent">
                    Git
                  </span>
                  <span class="badge h-6 min-h-6 border-warning/25 bg-warning/10 px-2 text-xs font-semibold text-warning">
                    +2
                  </span>
                </div>
              </div>

              <div class="flex justify-end">
                <.button
                  id="capability-badges-settings-submit"
                  type="submit"
                  loading_label="Saving badges…"
                  class="btn btn-primary"
                >
                  Save capability badges
                </.button>
              </div>
            </.form>
          </section>

          <section id="password-settings-section" class="ui-card h-auto p-5 sm:p-7">
            <h2 class="text-xl font-black text-base-content">Change password</h2>
            <p class="text-sm text-base-content/70">
              Update your password to keep your account secure.
            </p>

            <div class="divider my-6"></div>

            <.form
              for={@password_form}
              id="password-settings-form"
              phx-submit="change_password"
              class="space-y-4"
            >
              <.input
                field={@password_form[:current_password]}
                type="password"
                label="Current password"
                placeholder="Enter current password"
                required
              />

              <.input
                field={@password_form[:new_password]}
                type="password"
                label="New password"
                help="Use at least 8 characters."
                placeholder="Enter new password"
                minlength="8"
                required
              />

              <.input
                field={@password_form[:confirm_password]}
                type="password"
                label="Confirm new password"
                placeholder="Confirm new password"
                minlength="8"
                required
              />

              <div class="flex justify-end">
                <.button
                  id="password-settings-submit"
                  type="submit"
                  loading_label="Changing password…"
                  class="btn btn-primary"
                >
                  Change password
                </.button>
              </div>
            </.form>
          </section>

          <section id="appearance-settings-section" class="ui-card h-auto p-5 sm:p-7">
            <h2 class="text-xl font-black text-base-content">Appearance</h2>
            <p class="text-sm text-base-content/70">Choose your preferred color mode.</p>

            <div class="divider my-6"></div>

            <div class="space-y-4">
              <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p class="font-bold">Color mode</p>
                  <p class="text-xs text-base-content/60">Switch between Tokyo Day and Night.</p>
                </div>
                <div class="join w-full sm:w-auto" role="group" aria-label="Color mode">
                  <button
                    id="settings-theme-day"
                    type="button"
                    data-theme-choice="tokyo-day"
                    aria-pressed="false"
                    class="btn join-item min-h-11 flex-1 gap-2 sm:flex-none [[data-theme=tokyo-day]_&]:border-primary [[data-theme=tokyo-day]_&]:bg-primary [[data-theme=tokyo-day]_&]:text-primary-content"
                    phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "tokyo-day"})}
                  >
                    <.um_icon name="sun" class="size-4" /> Tokyo Day
                  </button>
                  <button
                    id="settings-theme-night"
                    type="button"
                    data-theme-choice="tokyo-night"
                    aria-pressed="false"
                    class="btn join-item min-h-11 flex-1 gap-2 sm:flex-none [[data-theme=tokyo-night]_&]:border-primary [[data-theme=tokyo-night]_&]:bg-primary [[data-theme=tokyo-night]_&]:text-primary-content"
                    phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "tokyo-night"})}
                  >
                    <.um_icon name="moon" class="size-4" /> Tokyo Night
                  </button>
                </div>
              </div>
              <div class="flex justify-end">
                <.link navigate={~p"/themes"} class="btn btn-outline btn-sm">
                  Preview components <.um_icon name="hero-arrow-right" class="size-4" />
                </.link>
              </div>
            </div>
          </section>

          <section id="danger-settings-section" class="ui-card h-auto border-error/45 p-5 sm:p-7">
            <h2 class="text-xl font-black text-error">Danger zone</h2>
            <p class="text-sm text-base-content/70">Irreversible account actions.</p>

            <div class="divider my-6"></div>

            <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p class="font-bold">Delete account</p>
                <p class="text-xs text-base-content/60">
                  Permanently delete your account and all associated data.
                </p>
              </div>
              <button
                id="delete-account-open"
                type="button"
                class="btn btn-error w-full sm:w-auto"
                onclick="delete_account_modal.showModal()"
                aria-haspopup="dialog"
              >
                Delete account
              </button>
            </div>
          </section>
        </div>
      </div>

      <dialog
        id="delete_account_modal"
        class="modal"
        aria-labelledby="delete-account-title"
        aria-describedby="delete-account-description"
      >
        <div class="modal-box rounded-lg border border-base-300">
          <h2 id="delete-account-title" class="text-lg font-black text-error">Delete account</h2>
          <p id="delete-account-description" class="py-4">
            Are you sure you want to delete your account? This action cannot be undone.
            All your data, including courses, saved prompts, and comments will be permanently deleted.
          </p>
          <div class="modal-action">
            <form method="dialog">
              <button id="delete-account-cancel" type="submit" class="btn">Cancel</button>
            </form>
            <button
              id="delete-account-confirm"
              type="button"
              phx-click="delete_account"
              class="btn btn-error"
            >
              Yes, delete my account
            </button>
          </div>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button type="submit" aria-label="Close delete account dialog">close</button>
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
