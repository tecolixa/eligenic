defmodule Eligenic.Presence do
  @moduledoc """
  The presence behaviour for tracking active agents in the cluster.

  By abstracting presence, Eligenic can use native Erlang `:pg` for basic
  discovery, or integrate with `Phoenix.Presence`, Redis, or other distributed
  key-value stores for rich metadata tracking and robust cluster architectures.
  """

  @doc """
  Registers the given process as an active agent in the cluster.
  Can optionally accept metadata (like the agent's ID or status).
  """
  @callback track(pid :: pid(), metadata :: map()) :: :ok | {:error, term()}

  @doc """
  Returns a list of all active agent PIDs known to the presence tracker.
  """
  @callback list_active() :: [pid()]
end
