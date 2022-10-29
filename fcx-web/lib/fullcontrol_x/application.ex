defmodule FullControlX.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    FullControlX.print_connection_qrcode()

    children = [
      # Start the Ecto repository
      FullControlX.Repo,
      # Start the Telemetry supervisor
      FullControlXWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: FullControlX.PubSub},
      # Start the Endpoint (http/https)
      FullControlXWeb.Endpoint,
      # Start a worker by calling: FullControlX.Worker.start_link(arg)
      # {FullControlX.Worker, arg}
      {FullControlX.Driver, name: FullControlX.Driver}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FullControlX.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FullControlXWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
