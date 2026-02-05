defmodule Eligenic.Instrumentation do
  @moduledoc """
  Core instrumentation engine for Eligenic.
  Provides a bridge to :telemetry events for agent activities, tool calls, and LLM latency.
  """

  # -----------------------------------------------------------------------------
  # 📡 Telemetry: Event Emission
  # -----------------------------------------------------------------------------

  @doc "Emits a raw telemetry event for the Eligenic namespace."
  def emit(event, measurements, metadata \\ %{}) do
    :telemetry.execute([:eligenic, :agent, event], measurements, metadata)
  end

  # -----------------------------------------------------------------------------
  # 📊 Reporting: Domain-Specific Metrics
  # -----------------------------------------------------------------------------

  @doc "Reports the start of a tool call with system timestamp."
  def report_tool_call(agent_id, tool_name, args) do
    emit(:tool_call_start, %{system_time: System.system_time()}, %{
      agent_id: agent_id,
      tool: tool_name,
      args: args
    })
  end

  @doc "Reports LLM completion metrics including model name and duration."
  def report_completion(agent_id, model, duration) do
    emit(:completion_stop, %{duration: duration}, %{
      agent_id: agent_id,
      model: model
    })
  end
end
