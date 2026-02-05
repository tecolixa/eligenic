defmodule Eligenic do
  @moduledoc """
  Eligenic: A production-ready Agentic Framework for Elixir.

  This module serves as the primary entry point for orchestrating autonomous agents,
  handling lifecycle management, and providing a clean messaging interface.
  """

  # -----------------------------------------------------------------------------
  # 🏗️ Supervision: Tree Integration
  # -----------------------------------------------------------------------------

  @doc """
  Returns a child specification for starting an agent in a static supervision tree.
  """
  def child_spec(opts) do
    %{
      id: opts[:id] || Eligenic.Agent,
      start: {Eligenic.Agent, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  # -----------------------------------------------------------------------------
  # 🚀 Lifecycle: Dynamic Management
  # -----------------------------------------------------------------------------

  @doc """
  Starts a new agent dynamically in the Eligenic Agent Supervisor.
  """
  def start_agent(opts \\ []) do
    DynamicSupervisor.start_child(Eligenic.AgentSupervisor, {Eligenic.Agent, opts})
  end

  @doc """
  Finds an active agent by its unique ID.
  """
  def find_agent(id) do
    case Registry.lookup(Eligenic.AgentRegistry, id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Ensures an agent with the given ID is running, starting it if necessary.
  """
  def ensure_agent(id, opts \\ []) do
    case find_agent(id) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, :not_found} ->
        opts = Keyword.put(opts, :id, id)

        case start_agent(opts) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          error -> error
        end
    end
  end

  @doc """
  Retrieves the interaction history of an agent.
  """
  def get_history(agent) when is_pid(agent) or is_tuple(agent) do
    Eligenic.Agent.get_history(agent)
  end

  def get_history(id) when is_binary(id) do
    case find_agent(id) do
      {:ok, pid} -> Eligenic.Agent.get_history(pid)
      error -> error
    end
  end

  # -----------------------------------------------------------------------------
  # 📅 Sessions: Conversation Lifecycle
  # -----------------------------------------------------------------------------

  @doc """
  Initializes a conversation session. Returns existing session or creates a new one.
  """
  def init_session(id, opts \\ []) do
    manager = opts[:session_manager] || Eligenic.Session.ETS

    case manager.get_session(id) do
      {:ok, session} ->
        {:ok, session}

      {:error, :not_found} ->
        attrs = Enum.into(opts, %{id: id})
        manager.create_session(attrs)
    end
  end

  @doc """
  Ensures a session's agent is running and returns the PID.
  """
  def resume_session(session_id, opts \\ []) do
    manager = opts[:session_manager] || Eligenic.Session.ETS

    with {:ok, session} <- manager.get_session(session_id),
         {:ok, agent_pid} <- ensure_agent(session.agent_id, opts) do
      {:ok, agent_pid, session}
    end
  end

  # -----------------------------------------------------------------------------
  # 💬 Messaging: Agent Interaction
  # -----------------------------------------------------------------------------

  @doc """
  Sends a message/query to an active agent.
  """
  def call(agent, message) when is_pid(agent) or is_tuple(agent) do
    Eligenic.Agent.call(agent, message)
  end

  def call(id, message) when is_binary(id) do
    case find_agent(id) do
      {:ok, pid} -> Eligenic.Agent.call(pid, message)
      error -> error
    end
  end
end
