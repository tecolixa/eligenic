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
      {DynamicSupervisor, name: Eligenic.AgentSupervisor, strategy: :one_for_one},

      # Native Erlang Process Group scopes for Eligenic.Broker.PG swarms
      %{
        id: :eligenic_broker_scope,
        start: {:pg, :start_link, [:eligenic_broker_scope]}
      },

      # Native Erlang Process Group scope for Eligenic.Observer cluster discovery
      %{
        id: :eligenic_cluster,
        start: {:pg, :start_link, [:eligenic_cluster]}
      },

      # Task supervisor for concurrent, isolated agent tasks
      {PartitionSupervisor, child_spec: Task.Supervisor, name: Eligenic.TaskSupervisors}
    ]

    opts = [strategy: :one_for_one, name: Eligenic.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
