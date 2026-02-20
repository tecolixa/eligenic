defmodule Eligenic.Agent do
  @moduledoc """
  Core Agent engine responsible for the reasoning loop, tool execution, and state management.
  """
  use GenServer
  require Logger

  # -----------------------------------------------------------------------------
  # Struct Definition
  # -----------------------------------------------------------------------------

  defstruct [
    :id,
    :identity,
    :adapter,
    history: [],
    skills: [],
    tools: [],
    adapter_opts: [],
    broker: Eligenic.Broker.PG,
    memory: Eligenic.Memory.ETS,
    runtime: Eligenic.Runtime.Local,
    security: Eligenic.Security.Default,
    security_settings: [],
    instrumentation: [enabled: false],
    status: :idle,
    max_iterations: 10
  ]

  # -----------------------------------------------------------------------------
  # Public API
  # -----------------------------------------------------------------------------

  @doc """
  Starts an agent process with the given options.
  """
  def start_link(opts) do
    # Require an Identity to be passed to start the process (or generate a UUID default)
    identity = Eligenic.Identity.from_opts(opts)

    # Let the user explicitly pass a native name tuple if they want,
    # otherwise register the process name globally using the Identity's ID.
    name = Keyword.get(opts, :name, {:via, Registry, {Eligenic.AgentRegistry, identity.id}})

    # Start the server, forcefully cascading the strictly resolved identity
    opts = Keyword.put(opts, :identity, identity)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Processes a user query by initiating the reasoning loop.
  """
  def call(agent, message) do
    GenServer.call(agent, {:call, message}, 30_000)
  end

  @doc """
  Returns the current interaction history of the agent.
  """
  def get_history(agent) do
    GenServer.call(agent, :get_history)
  end

  # -----------------------------------------------------------------------------
  # GenServer Callbacks
  # -----------------------------------------------------------------------------

  @impl true
  def init(opts) do
    agent = define_agent(opts)

    Logger.info("Initializing Agent #{agent.id} (Process: #{inspect(self())})")

    # Load history from memory
    case agent.memory.get_history(agent.id) do
      {:ok, history} ->
        {:ok, %{agent | history: history}}

      {:error, reason} ->
        Logger.error("Failed to load history for Agent #{agent.id}: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  # -----------------------------------------------------------------------------
  # GenServer Callbacks: Messaging
  # -----------------------------------------------------------------------------

  @impl true
  def handle_call(:get_history, _from, agent) do
    {:reply, {:ok, agent.history}, agent}
  end

  @impl true
  def handle_call({:call, message}, from, %__MODULE__{status: :idle} = agent) do
    # Redact input and store in memory
    redacted_message = agent.security.redact(message)
    event = %{role: "user", content: redacted_message, timestamp: DateTime.utc_now()}
    agent.memory.store_event(agent.id, event)

    new_history = agent.history ++ [event]

    task =
      agent.runtime.spawn_reasoning_loop(fn ->
        run_loop(new_history, agent, 0)
      end)

    {:noreply, %{agent | status: {:busy, from, task.ref}, history: new_history}}
  end

  def handle_call({:call, _message}, _from, agent) do
    {:reply, {:error, :busy}, agent}
  end

  @impl true
  def handle_info({ref, result}, %__MODULE__{status: {:busy, from, ref}} = agent) do
    Process.demonitor(ref, [:flush])

    case result do
      {:ok, final_message, final_history} ->
        GenServer.reply(from, {:ok, final_message})
        {:noreply, %{agent | status: :idle, history: final_history}}

      {:error, reason} ->
        GenServer.reply(from, {:error, reason})
        {:noreply, %{agent | status: :idle}}
    end
  end

  def handle_info(
        {:DOWN, ref, :process, _pid, reason},
        %__MODULE__{status: {:busy, from, ref}} = agent
      ) do
    GenServer.reply(from, {:error, {:task_crashed, reason}})
    {:noreply, %{agent | status: :idle}}
  end

  # -----------------------------------------------------------------------------
  # Reasoning Loop
  # -----------------------------------------------------------------------------

  defp run_loop(_history, agent, iteration) when iteration >= agent.max_iterations do
    {:error, :max_iterations_reached}
  end

  defp run_loop(history, agent, iteration) do
    completion_opts =
      agent.adapter_opts
      |> Keyword.put(:tools, agent.tools)
      |> Keyword.put(:agent_id, agent.id)

    # Inject persona into history if defined and not already present
    history_for_llm = inject_persona(history, agent.identity)

    case agent.adapter.chat_completion(history_for_llm, completion_opts) do
      {:ok, %{tool_calls: tool_calls} = resp} when not is_nil(tool_calls) ->
        results = Eligenic.Executor.execute_tools(tool_calls, agent)
        new_history = history ++ [resp] ++ results

        # Store events in permanent memory memory
        Enum.each([resp | results], &agent.memory.store_event(agent.id, &1))

        run_loop(new_history, agent, iteration + 1)

      {:ok, %{content: content} = resp} ->
        agent.memory.store_event(agent.id, resp)
        {:ok, content, history ++ [resp]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # -----------------------------------------------------------------------------
  # Internal Data Builders
  # -----------------------------------------------------------------------------

  defp define_agent(opts) do
    # Strictly rely on the Identity struct passed by start_link
    identity = opts[:identity]

    skills = opts[:skills] || []
    tools = opts[:tools] || Enum.flat_map(skills, &(&1.tools() || []))
    adapter_opts = Keyword.take(opts, [:api_key, :model])

    overrides = %{
      id: identity.id,
      identity: identity,
      skills: skills,
      tools: tools,
      adapter: opts[:adapter] || Application.get_env(:eligenic, :llm_adapter),
      adapter_opts: adapter_opts
    }

    __MODULE__
    |> struct(opts)
    |> struct(overrides)
  end

  # -----------------------------------------------------------------------------
  # Persona Injection
  # -----------------------------------------------------------------------------

  defp inject_persona(history, %Eligenic.Identity{persona: persona}) when is_binary(persona) do
    # Check if the first message is already a system prompt
    case history do
      [%{role: "system"} | _] -> history
      _ -> [%{role: "system", content: persona} | history]
    end
  end

  defp inject_persona(history, _identity), do: history
end
