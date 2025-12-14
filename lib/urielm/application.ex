defmodule Urielm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      UrielmWeb.Telemetry,
      Urielm.Repo,
      {DNSCluster, query: Application.get_env(:urielm, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Urielm.PubSub},
      # Enable Server-Side Rendering (SSR) for LiveSvelte
      {NodeJS.Supervisor, name: NodeJS, path: System.find_executable("node")},
      # Rate limiter for forum operations
      Urielm.RateLimiter,
      # Start a worker by calling: Urielm.Worker.start_link(arg)
      # {Urielm.Worker, arg},
      # Start to serve requests, typically the last entry
      UrielmWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Urielm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    UrielmWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
