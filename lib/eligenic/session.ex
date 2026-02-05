defmodule Eligenic.Session do
  @moduledoc """
  Behavior for managing agent sessions.
  Handles persistence of session metadata (IDs, user ownership, status).
  """

  @type id :: String.t()
  @type session :: map()

  # -----------------------------------------------------------------------------
  # 📜 Callbacks: Session Contract
  # -----------------------------------------------------------------------------

  @callback get_session(id()) :: {:ok, session()} | {:error, term()}
  @callback create_session(map()) :: {:ok, session()} | {:error, term()}
  @callback update_session(session(), map()) :: {:ok, session()} | {:error, term()}
  @callback list_sessions(user_id :: term()) :: {:ok, [session()]} | {:error, term()}

  # -----------------------------------------------------------------------------
  # 📥 Internal Implementation: ETS (Volatile)
  # -----------------------------------------------------------------------------

  defmodule ETS do
    @moduledoc """
    Default volatile session store using ETS.
    """
    @behaviour Eligenic.Session

    @table :eligenic_sessions

    def start_link do
      if :ets.info(@table) == :undefined do
        :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
      end

      :ok
    end

    @impl true
    def get_session(id) do
      case :ets.lookup(@table, id) do
        [{^id, session}] -> {:ok, session}
        [] -> {:error, :not_found}
      end
    end

    @impl true
    def create_session(attrs) do
      id = attrs[:id] || "session_#{:erlang.unique_integer([:positive])}"
      session = Map.put(attrs, :id, id)
      :ets.insert(@table, {id, session})
      {:ok, session}
    end

    @impl true
    def update_session(session, attrs) do
      updated = Map.merge(session, attrs)
      :ets.insert(@table, {session.id, updated})
      {:ok, updated}
    end

    @impl true
    def list_sessions(user_id) do
      sessions =
        :ets.tab2list(@table)
        |> Enum.map(fn {_, s} -> s end)
        |> Enum.filter(&(&1[:user_id] == user_id))

      {:ok, sessions}
    end
  end
end
