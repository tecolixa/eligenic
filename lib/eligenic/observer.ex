defmodule Eligenic.Observer do
  @moduledoc """
  Cluster-wide observability interface for tracking live Agents.
  Uses Erlang's `:pg` (Process Groups) to discover active agents and
  extracts runtime statistics without blocking their execution loops.
  """

  @doc """
  Returns a list of all actively running Eligenic Agent PIDs across
  the entire connected Erlang distribution cluster using the configured Presence tracking.
  """
  @spec active_agents() :: [pid()]
  def active_agents do
    presence = Application.get_env(:eligenic, :presence, Eligenic.Presence.PG)
    presence.list_active()
  end

  @doc """
  Retrieves the operational statistics of a specific Agent process.
  This includes its identity, iteration counts, and active tools.
  """
  @spec agent_stats(pid() | String.t()) :: {:ok, map()} | {:error, term()}
  def agent_stats(agent) when is_pid(agent) do
    try do
      GenServer.call(agent, :get_stats, 5_000)
    catch
      :exit, _reason -> {:error, :agent_unreachable}
    end
  end

  def agent_stats(id) when is_binary(id) do
    case Eligenic.find_agent(id) do
      {:ok, pid} -> agent_stats(pid)
      error -> error
    end
  end
end
