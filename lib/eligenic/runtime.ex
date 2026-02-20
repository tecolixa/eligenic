defmodule Eligenic.Runtime do
  @moduledoc """
  The execution environment behaviour for the Eligenic framework.

  By abstracting the runtime into a behaviour, Eligenic can run agents locally
  (via standard OTP processes) or perfectly distributed across a multi-node
  cluster (via Horde) without changing any underlying agent logic.
  """

  @doc """
  Spawns an agent's reasoning loop into the execution environment.
  """
  @callback spawn_reasoning_loop(logic_callback :: (-> any())) :: Task.t()
end
