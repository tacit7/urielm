defmodule UrielmWeb.Admin.TrustLevelSettingsLive do
  use UrielmWeb, :live_view

  alias Urielm.TrustLevel
  alias Urielm.TrustLevelConfig

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user && socket.assigns.current_user.is_admin do
      configs = TrustLevel.list_configs()

      {:ok,
       socket
       |> assign(:page_title, "Trust Level Settings")
       |> assign(:configs, configs)
       |> assign(:editing, nil)
       |> assign(:edit_form, nil)}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_event("edit", %{"level" => level_str}, socket) do
    level = String.to_integer(level_str)
    config = TrustLevel.get_config(level)

    form =
      config
      |> TrustLevelConfig.changeset(%{})
      |> to_form()

    {:noreply, assign(socket, editing: level, edit_form: form)}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: nil, edit_form: nil)}
  end

  @impl true
  def handle_event("save", %{"trust_level_config" => attrs}, socket) do
    level = socket.assigns.editing

    case TrustLevel.update_config(level, attrs) do
      {:ok, _config} ->
        configs = TrustLevel.list_configs()

        {:noreply,
         socket
         |> assign(:configs, configs)
         |> assign(:editing, nil)
         |> assign(:edit_form, nil)
         |> put_flash(:info, "Trust level updated successfully")}

      {:error, changeset} ->
        form = to_form(changeset)

        {:noreply,
         socket
         |> assign(:edit_form, form)
         |> put_flash(:error, "Failed to update trust level")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="admin" socket={@socket}>
      <div class="min-h-screen bg-base-100">
        <div class="container mx-auto px-4 py-8 max-w-6xl">
          <div class="mb-8">
            <h1 class="text-3xl font-bold text-base-content">Trust Level Settings</h1>
            <p class="text-base-content/60 mt-2">
              Configure user tiers, permissions, and rate limits
            </p>
          </div>

          <div class="grid gap-4">
            <%= for config <- @configs do %>
              <div class="card bg-base-200 border border-base-300">
                <div class="card-body">
                  <%= if @editing == config.level do %>
                    <.edit_form config={config} form={@edit_form} />
                  <% else %>
                    <.config_view config={config} />
                    <div class="card-actions justify-end mt-4">
                      <button
                        phx-click="edit"
                        phx-value-level={config.level}
                        class="btn btn-sm btn-primary"
                      >
                        Edit
                      </button>
                    </div>
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

  defp config_view(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center gap-4">
        <div
          class="w-4 h-4 rounded-full"
          style={"background-color: var(--color-#{@config.color})"}
        />
        <div>
          <h2 class="text-xl font-bold text-base-content">
            Level {@config.level} - {@config.name}
          </h2>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4 text-sm">
        <div>
          <span class="text-base-content/60">Auto-Promotion Thresholds</span>
          <div class="space-y-1 mt-2">
            <div>Topics: {@config.min_topics}</div>
            <div>Posts: {@config.min_posts}</div>
            <div>Days Joined: {@config.min_days_joined}</div>
            <div>Likes Given: {@config.min_likes_given}</div>
            <div>Likes Received: {@config.min_likes_received}</div>
          </div>
        </div>

        <div>
          <span class="text-base-content/60">Rate Limits</span>
          <div class="space-y-1 mt-2">
            <div>
              Posts/Minute: {if @config.max_posts_per_minute == -1,
                do: "Unlimited",
                else: @config.max_posts_per_minute}
            </div>
            <div>
              Topics/Day: {if @config.max_new_topics_per_day == -1,
                do: "Unlimited",
                else: @config.max_new_topics_per_day}
            </div>
            <div>
              Edit Window: {if @config.post_edit_time_limit == -1,
                do: "Unlimited",
                else: "#{@config.post_edit_time_limit} min"}
            </div>
          </div>
        </div>
      </div>

      <div class="space-y-2">
        <span class="text-base-content/60 text-sm">Permissions</span>
        <div class="flex flex-wrap gap-2">
          <%= if @config.can_pin_topics do %>
            <span class="badge badge-success">Can Pin Topics</span>
          <% end %>
          <%= if @config.can_feature_topics do %>
            <span class="badge badge-success">Can Feature Topics</span>
          <% end %>
          <%= if @config.can_close_topics do %>
            <span class="badge badge-success">Can Close Topics</span>
          <% end %>
          <%= if @config.can_moderate do %>
            <span class="badge badge-success">Can Moderate</span>
          <% end %>
          <%= if not (@config.can_pin_topics or @config.can_feature_topics or @config.can_close_topics or @config.can_moderate) do %>
            <span class="text-base-content/40 text-sm">No special permissions</span>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp edit_form(assigns) do
    ~H"""
    <form phx-submit="save" class="space-y-4">
      <div class="flex items-center gap-4 mb-4">
        <div
          class="w-4 h-4 rounded-full"
          style={"background-color: var(--color-#{@config.color})"}
        />
        <h2 class="text-xl font-bold text-base-content">
          Level {@config.level} - {@config.name}
        </h2>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="label">
            <span class="label-text font-semibold">Min Topics</span>
          </label>
          <.input
            name="trust_level_config[min_topics]"
            type="number"
            value={@config.min_topics}
            label="Min Topics"
          />
        </div>

        <div>
          <label class="label">
            <span class="label-text font-semibold">Min Posts</span>
          </label>
          <.input
            name="trust_level_config[min_posts]"
            type="number"
            value={@config.min_posts}
            label="Min Posts"
          />
        </div>

        <div>
          <label class="label">
            <span class="label-text font-semibold">Min Days Joined</span>
          </label>
          <.input
            name="trust_level_config[min_days_joined]"
            type="number"
            value={@config.min_days_joined}
            label="Min Days Joined"
          />
        </div>

        <div>
          <label class="label">
            <span class="label-text font-semibold">Min Likes Given</span>
          </label>
          <.input
            name="trust_level_config[min_likes_given]"
            type="number"
            value={@config.min_likes_given}
            label="Min Likes Given"
          />
        </div>

        <div>
          <label class="label">
            <span class="label-text font-semibold">Min Likes Received</span>
          </label>
          <.input
            name="trust_level_config[min_likes_received]"
            type="number"
            value={@config.min_likes_received}
            label="Min Likes Received"
          />
        </div>

        <div>
          <label class="label">
            <span class="label-text font-semibold">Max Posts Per Minute</span>
          </label>
          <.input
            name="trust_level_config[max_posts_per_minute]"
            type="number"
            value={@config.max_posts_per_minute}
            label="Max Posts Per Minute"
          />
          <p class="text-xs text-base-content/60 mt-1">-1 for unlimited</p>
        </div>

        <div>
          <label class="label">
            <span class="label-text font-semibold">Max New Topics Per Day</span>
          </label>
          <.input
            name="trust_level_config[max_new_topics_per_day]"
            type="number"
            value={@config.max_new_topics_per_day}
            label="Max New Topics Per Day"
          />
          <p class="text-xs text-base-content/60 mt-1">-1 for unlimited</p>
        </div>

        <div>
          <label class="label">
            <span class="label-text font-semibold">Post Edit Time Limit (min)</span>
          </label>
          <.input
            name="trust_level_config[post_edit_time_limit]"
            type="number"
            value={@config.post_edit_time_limit}
            label="Post Edit Time Limit (min)"
          />
          <p class="text-xs text-base-content/60 mt-1">-1 for unlimited</p>
        </div>
      </div>

      <div class="space-y-2">
        <label class="label">
          <span class="label-text font-semibold">Permissions</span>
        </label>

        <div class="space-y-2">
          <label class="label cursor-pointer gap-2">
            <input
              type="checkbox"
              name="trust_level_config[can_pin_topics]"
              value="true"
              checked={@config.can_pin_topics}
              class="checkbox checkbox-sm"
            />
            <span class="label-text">Can Pin Topics</span>
          </label>

          <label class="label cursor-pointer gap-2">
            <input
              type="checkbox"
              name="trust_level_config[can_feature_topics]"
              value="true"
              checked={@config.can_feature_topics}
              class="checkbox checkbox-sm"
            />
            <span class="label-text">Can Feature Topics</span>
          </label>

          <label class="label cursor-pointer gap-2">
            <input
              type="checkbox"
              name="trust_level_config[can_close_topics]"
              value="true"
              checked={@config.can_close_topics}
              class="checkbox checkbox-sm"
            />
            <span class="label-text">Can Close Topics</span>
          </label>

          <label class="label cursor-pointer gap-2">
            <input
              type="checkbox"
              name="trust_level_config[can_moderate]"
              value="true"
              checked={@config.can_moderate}
              class="checkbox checkbox-sm"
            />
            <span class="label-text">Can Moderate</span>
          </label>
        </div>
      </div>

      <div class="card-actions justify-end gap-2 mt-6">
        <button type="button" phx-click="cancel_edit" class="btn btn-ghost">
          Cancel
        </button>
        <button type="submit" class="btn btn-primary">
          Save Changes
        </button>
      </div>
    </form>
    """
  end
end
