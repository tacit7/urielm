defmodule UrielmWeb.Admin.TrustLevelSettingsLive do
  use UrielmWeb, :live_view

  import UrielmWeb.AdminComponents

  alias Urielm.TrustLevel
  alias Urielm.TrustLevelConfig

  @impl true
  def mount(_params, _session, socket) do
    configs = TrustLevel.list_configs()

    {:ok,
     socket
     |> assign(:page_title, "Trust Level Settings")
     |> assign(:configs, configs)
     |> assign(:editing, nil)
     |> assign(:edit_form, nil)}
  end

  @impl true
  def handle_event("edit", %{"level" => level_str}, socket) do
    level =
      case Integer.parse(level_str) do
        {n, ""} -> n
        _ -> nil
      end

    case level do
      nil ->
        {:noreply, put_flash(socket, :error, "Invalid trust level")}

      level ->
        config = TrustLevel.get_config(level)

        form =
          config
          |> TrustLevelConfig.changeset(%{})
          |> to_form()

        {:noreply, assign(socket, editing: level, edit_form: form)}
    end
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
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="admin"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div id="admin-trust-levels-page" class="ui-page-shell max-w-6xl">
        <header id="admin-trust-levels-header" class="ui-page-header ui-page-heading">
          <h1 class="ui-section-title">Trust level settings</h1>
          <p class="ui-section-copy">
            Configure user tiers, permissions, and rate limits.
          </p>
        </header>

        <.admin_nav current="trust-levels" />

        <div id="trust-level-configs" class="grid gap-4">
          <%= for config <- @configs do %>
            <section
              id={"trust-level-#{config.level}"}
              class="ui-card h-auto p-5 sm:p-6"
            >
              <%= if @editing == config.level do %>
                <.edit_form config={config} form={@edit_form} />
              <% else %>
                <.config_view config={config} />
                <div class="mt-5 flex justify-end">
                  <button
                    id={"edit-trust-level-#{config.level}"}
                    type="button"
                    phx-click="edit"
                    phx-value-level={config.level}
                    class="btn btn-sm btn-primary"
                  >
                    Edit level
                  </button>
                </div>
              <% end %>
            </section>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp config_view(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center gap-3">
        <div
          class="size-3.5 shrink-0 rounded-full"
          style={"background-color: var(--color-#{@config.color})"}
        />
        <h2 class="text-lg font-black text-base-content sm:text-xl">
          Level {@config.level} · {@config.name}
        </h2>
      </div>

      <div class="grid gap-5 text-sm sm:grid-cols-2">
        <div class="rounded-lg bg-base-100/45 p-4">
          <h3 class="font-bold text-base-content">Auto-promotion thresholds</h3>
          <div class="mt-2 space-y-1 text-base-content/65">
            <div>Topics: {@config.min_topics}</div>
            <div>Posts: {@config.min_posts}</div>
            <div>Days Joined: {@config.min_days_joined}</div>
            <div>Likes Given: {@config.min_likes_given}</div>
            <div>Likes Received: {@config.min_likes_received}</div>
          </div>
        </div>

        <div class="rounded-lg bg-base-100/45 p-4">
          <h3 class="font-bold text-base-content">Rate limits</h3>
          <div class="mt-2 space-y-1 text-base-content/65">
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
        <h3 class="text-sm font-bold text-base-content">Permissions</h3>
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
    <.form
      for={@form}
      id={"trust-level-form-#{@config.level}"}
      phx-submit="save"
      class="space-y-5"
    >
      <div class="flex items-center gap-3">
        <div
          class="size-3.5 shrink-0 rounded-full"
          style={"background-color: var(--color-#{@config.color})"}
        />
        <h2 class="text-lg font-black text-base-content sm:text-xl">
          Edit level {@config.level} · {@config.name}
        </h2>
      </div>

      <div class="grid gap-4 sm:grid-cols-2">
        <.input field={@form[:min_topics]} type="number" label="Minimum topics" />
        <.input field={@form[:min_posts]} type="number" label="Minimum posts" />
        <.input field={@form[:min_days_joined]} type="number" label="Minimum days joined" />
        <.input field={@form[:min_likes_given]} type="number" label="Minimum likes given" />
        <.input field={@form[:min_likes_received]} type="number" label="Minimum likes received" />
        <.input
          field={@form[:max_posts_per_minute]}
          type="number"
          label="Maximum posts per minute"
          help="Use -1 for unlimited."
        />
        <.input
          field={@form[:max_new_topics_per_day]}
          type="number"
          label="Maximum new topics per day"
          help="Use -1 for unlimited."
        />
        <.input
          field={@form[:post_edit_time_limit]}
          type="number"
          label="Post edit window (minutes)"
          help="Use -1 for unlimited."
        />
      </div>

      <fieldset>
        <legend class="mb-3 text-sm font-bold text-base-content">Permissions</legend>
        <div class="grid gap-3 sm:grid-cols-2">
          <.input field={@form[:can_pin_topics]} type="checkbox" label="Can pin topics" />
          <.input field={@form[:can_feature_topics]} type="checkbox" label="Can feature topics" />
          <.input field={@form[:can_close_topics]} type="checkbox" label="Can close topics" />
          <.input field={@form[:can_moderate]} type="checkbox" label="Can moderate" />
        </div>
      </fieldset>

      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <button
          id={"cancel-trust-level-#{@config.level}"}
          type="button"
          phx-click="cancel_edit"
          class="btn btn-ghost"
        >
          Cancel
        </button>
        <button id={"save-trust-level-#{@config.level}"} type="submit" class="btn btn-primary">
          Save changes
        </button>
      </div>
    </.form>
    """
  end
end
