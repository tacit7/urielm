defmodule Urielm.RateLimiter do
  @moduledoc """
  Simple in-memory rate limiter for preventing spam in forum operations.

  Tracks requests per user per action and enforces limits.
  Cleans up old entries periodically to prevent memory bloat.

  Example:
    RateLimiter.check_limit("user:123", "create_thread", max_requests: 5, window_seconds: 60)
  """

  use GenServer
  require Logger

  @cleanup_interval :timer.minutes(5)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_cleanup()
    {:ok, %{}}
  end

  @doc """
  Check if a user has exceeded rate limit for an action.

  Returns {:ok, remaining} if within limit, {:error, :rate_limited} if exceeded.

  Respects :rate_limit_bypass environment variable for testing.
  """
  def check_limit(user_key, action, opts \\ []) do
    # Bypass rate limiting in test environment
    if Application.get_env(:urielm, :rate_limit_bypass, false) do
      {:ok, 999}
    else
      max_requests = Keyword.get(opts, :max_requests, 10)
      window_seconds = Keyword.get(opts, :window_seconds, 60)

      GenServer.call(__MODULE__, {:check_limit, user_key, action, max_requests, window_seconds})
    end
  end

  @impl true
  def handle_call({:check_limit, user_key, action, max_requests, window_seconds}, _from, state) do
    key = "#{user_key}:#{action}"
    now = System.monotonic_time(:second)
    window_start = now - window_seconds

    # Get all requests for this user:action in current window
    requests = Map.get(state, key, [])
    recent_requests = Enum.filter(requests, &(&1 > window_start))

    case length(recent_requests) do
      count when count < max_requests ->
        # Still within limit, record this request
        new_requests = [now | recent_requests]
        new_state = Map.put(state, key, new_requests)
        remaining = max_requests - count - 1
        {:reply, {:ok, remaining}, new_state}

      _ ->
        # Exceeded limit
        {:reply, {:error, :rate_limited}, state}
    end
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:second)

    # Remove entries older than 24 hours
    cleaned_state =
      state
      |> Enum.reduce(%{}, fn {key, timestamps}, acc ->
        recent = Enum.filter(timestamps, &(&1 > now - 86400))

        case recent do
          [] -> acc
          _ -> Map.put(acc, key, recent)
        end
      end)

    schedule_cleanup()
    {:noreply, cleaned_state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
