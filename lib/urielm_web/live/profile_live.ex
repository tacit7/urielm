defmodule UrielmWeb.ProfileLive do
  use UrielmWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="profile" socket={@socket}>
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold">Profile</h1>
      <p class="mt-4 text-base-content/70">Profile page coming soon...</p>
    </div>
    </Layouts.app>
    """
  end
end
