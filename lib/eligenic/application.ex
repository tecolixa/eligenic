defmodule Eligenic.Application do
  @moduledoc """
  Core application for the Eligenic framework.
  Sets up the global memory store and the dynamic supervisor for AI agents.
  """
  use Application

  # -----------------------------------------------------------------------------
  # 🏔️ Lifecycle: Startup
  # -----------------------------------------------------------------------------

  @impl true
  def start(_type, _args) do
    # Initialize default ETS stores
    :ok = Eligenic.Memory.ETS.start_link()
    :ok = Eligenic.Session.ETS.start_link()

    children = [
      # Registry for looking up agents by their unique ID
      {Registry, keys: :unique, name: Eligenic.AgentRegistry},

      # Dynamic supervisor for managing individual agent processes
      {DynamicSupervisor, name: Eligenic.AgentSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: Eligenic.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
