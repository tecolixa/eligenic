defmodule Eligenic.Agent do
  @moduledoc """
  Core Agent engine responsible for the reasoning loop, tool execution, and state management.
  """
  use GenServer
  require Logger

  # -----------------------------------------------------------------------------
  # 🌐 Public API
  # -----------------------------------------------------------------------------

  @doc """
  Starts an agent process with the given options.
  """
  def start_link(opts) do
    id = opts[:id]
    {name, opts} = Keyword.pop(opts, :name)

    # Naming strategy: use explicit name, or via registry if ID is present
    name =
      cond do
        name -> name
        id -> {:via, Registry, {Eligenic.AgentRegistry, id}}
        true -> nil
      end

    if name do
      GenServer.start_link(__MODULE__, opts, name: name)
    else
      GenServer.start_link(__MODULE__, opts)
    end
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
  # ⚙️ GenServer Callbacks
  # -----------------------------------------------------------------------------

  @impl true
  def init(opts) do
    id = opts[:id] || "agent_#{:erlang.unique_integer([:positive])}"
    Logger.info("Initializing Agent #{id} (Process: #{inspect(self())})")

    skills = opts[:skills] || []
    tools = opts[:tools] || Enum.flat_map(skills, &(&1.tools() || []))

    # Collect adapter-specific options
    adapter_opts = Keyword.take(opts, [:api_key, :model])

    state = %{
      id: id,
      history: [],
      skills: skills,
      tools: tools,
      adapter: opts[:adapter] || Application.get_env(:eligenic, :llm_adapter),
      adapter_opts: adapter_opts,
      memory: opts[:memory] || Eligenic.Memory.ETS,
      security: opts[:security] || Eligenic.Security.Default,
      security_settings: opts[:security_settings] || [],
      instrumentation: opts[:instrumentation] || [enabled: false]
    }

    # Load history from memory
    case state.memory.get_history(state.id) do
      {:ok, history} ->
        {:ok, %{state | history: history}}

      {:error, reason} ->
        Logger.error("Failed to load history for Agent #{id}: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    {:reply, {:ok, state.history}, state}
  end

  @impl true
  def handle_call({:call, message}, _from, state) do
    # Redact input and store in memory
    redacted_message = state.security.redact(message)
    event = %{role: "user", content: redacted_message, timestamp: DateTime.utc_now()}
    state.memory.store_event(state.id, event)

    new_history = state.history ++ [event]

    case run_loop(new_history, state) do
      {:ok, final_message, final_history} ->
        {:reply, {:ok, final_message}, %{state | history: final_history}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  # -----------------------------------------------------------------------------
  # 🧠 Reasoning Loop
  # -----------------------------------------------------------------------------

  defp run_loop(history, state) do
    # Filter tools based on security policy
    authorized_tools =
      Enum.filter(state.tools, fn tool ->
        match?(:ok, state.security.authorize(state, tool, %{}))
      end)

    completion_opts = Keyword.put(state.adapter_opts, :tools, authorized_tools)

    case state.adapter.chat_completion(history, completion_opts) do
      {:ok, %{tool_calls: tool_calls} = resp} when not is_nil(tool_calls) ->
        results = handle_tool_calls(tool_calls, state)
        new_history = history ++ [resp] ++ results

        # Store events in permanent memory memory
        Enum.each([resp | results], &state.memory.store_event(state.id, &1))

        run_loop(new_history, state)

      {:ok, %{content: content} = resp} ->
        state.memory.store_event(state.id, resp)
        {:ok, content, history ++ [resp]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # -----------------------------------------------------------------------------
  # 🛠️ Tool Execution
  # -----------------------------------------------------------------------------

  defp handle_tool_calls(calls, state) do
    Enum.map(calls, fn call ->
      case state.security.authorize(state, call.function, call.function.arguments) do
        :ok ->
          # Find the skill module that encapsulates this tool
          skill =
            Enum.find(state.skills, fn s ->
              Enum.any?(s.tools(), &(&1.function.name == call.function.name))
            end)

          content =
            if skill do
              skill.execute(call.function.name, call.function.arguments)
            else
              "Error: Tool not found"
            end

          %{role: "tool", tool_call_id: call.id, content: content}

        {:error, reason} ->
          %{role: "tool", tool_call_id: call.id, content: "Error: #{reason}"}
      end
    end)
  end
end
