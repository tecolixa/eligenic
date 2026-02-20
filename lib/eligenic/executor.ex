defmodule Eligenic.Executor do
  @moduledoc """
  Abstracts away the execution of physical logic. Responsible for translating
  the AI's intent into action by locating tools and invoking skills safely.
  """
  require Logger

  # -----------------------------------------------------------------------------
  # 🛠️ Concurrent Tool Execution
  # -----------------------------------------------------------------------------

  @doc """
  Executes a list of LLM tool calls concurrently using a bounded async stream.
  Provides sandboxed crash protection (`try/rescue`) to prevent bad skill logic
  from tearing down the reasoning loop process.
  """
  def execute_tools(calls, agent) do
    calls
    |> Task.async_stream(
      fn call -> execute_single_tool(call, agent) end,
      max_concurrency: 5
    )
    |> Enum.map(fn {:ok, result} -> result end)
  end

  defp execute_single_tool(call, agent) do
    case agent.security.authorize(agent.identity, call.function, call.function.arguments) do
      :ok ->
        skill =
          Enum.find(agent.skills, fn s ->
            Enum.any?(s.tools(), &(&1.function.name == call.function.name))
          end)

        content =
          if skill do
            try do
              skill.execute(call.function.name, call.function.arguments)
            rescue
              e ->
                Logger.error("Tool crash [#{call.function.name}]: #{inspect(e)}")
                "Error executing tool: #{inspect(e)}"
            end
          else
            "Error: Tool not found"
          end

        %{role: "tool", tool_call_id: call.id, content: content}

      {:error, reason} ->
        %{role: "tool", tool_call_id: call.id, content: "Error: #{reason}"}
    end
  end
end
