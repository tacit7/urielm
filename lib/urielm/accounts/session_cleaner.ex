defmodule Urielm.Accounts.SessionCleaner do
  @moduledoc "Removes expired sessions and abandoned signup grants every hour."
  use GenServer
  require Logger
  @interval :timer.hours(1)

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    schedule()
    {:ok, nil}
  end

  @impl true
  def handle_info(:purge_expired, state) do
    try do
      Urielm.Accounts.Sessions.purge_expired()
    rescue
      _ -> Logger.error("Session cleanup failed; retrying at the next interval")
    after
      schedule()
    end

    {:noreply, state}
  end

  defp schedule, do: Process.send_after(self(), :purge_expired, @interval)
end
