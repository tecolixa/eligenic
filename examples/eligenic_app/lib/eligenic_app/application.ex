defmodule EligenicApp.Application do
  @moduledoc """
  Reference implementation application for the Eligenic framework.
  Sets up the Phoenix environment, database, and local environment variables.
  """
  use Application

  # -----------------------------------------------------------------------------
  # 🏔️ Lifecycle: Startup
  # -----------------------------------------------------------------------------

  @impl true
  def start(_type, _args) do
    children = [
      EligenicAppWeb.Telemetry,
      EligenicApp.Repo,
      {DNSCluster, query: Application.get_env(:eligenic_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EligenicApp.PubSub},
      # Start the Endpoint (http/https)
      EligenicAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: EligenicApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # -----------------------------------------------------------------------------
  # ⚙️ Configuration: Runtime Updates
  # -----------------------------------------------------------------------------

  @impl true
  def config_change(changed, _new, removed) do
    EligenicAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
