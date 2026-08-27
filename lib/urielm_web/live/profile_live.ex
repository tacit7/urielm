defmodule UrielmWeb.ProfileLive do
  use UrielmWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="profile"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div id="profile-page" class="ui-page-shell max-w-4xl">
        <header id="profile-header" class="ui-page-header ui-page-heading">
          <h1 class="ui-section-title">Profile</h1>
          <p class="ui-section-copy">Review your public identity and account details.</p>
        </header>

        <.empty_state
          id="profile-overview-empty-state"
          title="Profile overview is coming soon"
          description="Your account preferences and editable profile details are available in Settings."
          icon="hero-user-circle"
          compact
        >
          <:action>
            <.link navigate={~p"/settings"} class="btn btn-primary btn-sm rounded-full">
              Open settings <.um_icon name="hero-arrow-right" class="size-4" />
            </.link>
          </:action>
        </.empty_state>
      </div>
    </Layouts.app>
    """
  end
end
