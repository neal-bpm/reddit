defmodule Reddit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RedditWeb.Telemetry,
      Reddit.Repo,
      {DNSCluster, query: Application.get_env(:reddit, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Reddit.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Reddit.Finch},
      # Start the ETS-based cache
      Reddit.Cache,
      # Start a worker by calling: Reddit.Worker.start_link(arg)
      # {Reddit.Worker, arg},
      # Start to serve requests, typically the last entry
      RedditWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Reddit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RedditWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
