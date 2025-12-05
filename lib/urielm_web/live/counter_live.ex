defmodule UrielmWeb.CounterLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  @impl true
  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100 flex items-center justify-center">
      <div class="bg-white rounded-lg shadow-lg p-8">
        <h1 class="text-4xl font-bold text-center mb-8 text-gray-800">
          Svelte + Phoenix LiveView
        </h1>

        <.Counter count={@count} socket={@socket} />

        <div class="mt-8 text-center text-gray-600">
          <p>This counter is a Svelte component running in Phoenix LiveView</p>
          <p class="text-sm mt-2">State is managed by LiveView on the server</p>
        </div>
      </div>
    </div>
    """
  end
end
