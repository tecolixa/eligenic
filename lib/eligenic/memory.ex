defmodule Eligenic.Memory do
  @moduledoc """
  Behaviour definition for agent memory persistence.
  Allows pluggable storage engines (ETS, Postgres, Redis).
  """

  # -----------------------------------------------------------------------------
  # 🏷️ Types: Domain Definitions
  # -----------------------------------------------------------------------------

  @type event :: %{role: String.t(), content: any(), timestamp: DateTime.t()}

  # -----------------------------------------------------------------------------
  # 📝 Callbacks: Memory Contract
  # -----------------------------------------------------------------------------

  @doc "Persists a single interaction event for a specific agent."
  @callback store_event(agent_id :: String.t(), event :: event()) :: :ok | {:error, any()}

  @doc "Retrieves the complete interaction history for a specific agent."
  @callback get_history(agent_id :: String.t()) :: {:ok, [event()]} | {:error, any()}
end

defmodule Eligenic.Memory.ETS do
  @moduledoc """
  Standard ETS-based volatile memory implementation.
  Useful for development and testing.
  """
  @behaviour Eligenic.Memory

  # -----------------------------------------------------------------------------
  # 🏗️ Lifecycle: Initialization
  # -----------------------------------------------------------------------------

  @doc "Ensures the ETS table is initialized globally."
  def start_link do
    if :ets.whereis(:eligenic_memory) == :undefined do
      :ets.new(:eligenic_memory, [:set, :public, :named_table])
    end

    :ok
  end

  # -----------------------------------------------------------------------------
  # 🛠️ Implementation: Store & Fetch
  # -----------------------------------------------------------------------------

  @impl true
  def store_event(agent_id, event) do
    history = get_history_raw(agent_id)
    :ets.insert(:eligenic_memory, {agent_id, history ++ [event]})
    :ok
  end

  @impl true
  def get_history(agent_id) do
    {:ok, get_history_raw(agent_id)}
  end

  defp get_history_raw(agent_id) do
    case :ets.lookup(:eligenic_memory, agent_id) do
      [{^agent_id, history}] -> history
      [] -> []
    end
  end
end
