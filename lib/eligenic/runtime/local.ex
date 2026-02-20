defmodule Eligenic.Runtime.Local do
  @moduledoc """
  Local node runtime utilizing `PartitionSupervisor`.
  Distributes agent reasoning loops horizontally across available CPU cores
  on the current machine. Highly recommended for single-server setups.
  """

  @behaviour Eligenic.Runtime

  @impl true
  def spawn_reasoning_loop(logic_callback) when is_function(logic_callback, 0) do
    Task.Supervisor.async_nolink(
      {:via, PartitionSupervisor, {Eligenic.TaskSupervisors, self()}},
      logic_callback
    )
  end
end
