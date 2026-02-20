defmodule Eligenic.Runtime.Distributed do
  @moduledoc """
  An example multi-node clustered runtime using native Erlang Distribution.
  Distributes agent reasoning loops across the global cluster registry.

  For production setups, users can implement this `@behaviour` and
  plug in tools like `Horde.TaskSupervisor` for perfect rebalancing.
  """

  @behaviour Eligenic.Runtime

  @impl true
  def spawn_reasoning_loop(logic_callback) when is_function(logic_callback, 0) do
    # Select a random node from the connected cluster
    nodes = [node() | Node.list()]
    target_node = Enum.random(nodes)

    Task.Supervisor.async_nolink(
      {Eligenic.TaskSupervisors, target_node},
      logic_callback
    )
  end
end
