defmodule Urielm.Forum.ThreadCloser do
  @moduledoc """
  Scheduled task that periodically closes threads that have passed their close_at time.
  """
  use GenServer
  alias Urielm.Forum

  # Check every hour
  @check_interval :timer.hours(1)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Schedule first check
    schedule_check()
    {:ok, state}
  end

  @impl true
  def handle_info(:check_expired, state) do
    count = Forum.close_expired_threads()

    if count > 0 do
      IO.puts("ThreadCloser: Closed #{count} expired threads")
    end

    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_expired, @check_interval)
  end
end
