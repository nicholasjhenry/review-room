defmodule ReviewRoom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ReviewRoomWeb.Telemetry,
      ReviewRoom.Repo,
      {DNSCluster, query: Application.get_env(:review_room, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ReviewRoom.PubSub},
      # Start the PresenceTracker for real-time snippet collaboration
      {ReviewRoom.Snippets.PresenceTracker, pubsub_server: ReviewRoom.PubSub},
      # Start a worker by calling: ReviewRoom.Worker.start_link(arg)
      # {ReviewRoom.Worker, arg},
      # Start to serve requests, typically the last entry
      ReviewRoomWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReviewRoom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ReviewRoomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
