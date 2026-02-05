defmodule EligenicApp.EligenicConfig do
  @moduledoc """
  Bridges host application configurations into the Eligenic framework.
  Centralizes LLM adapter settings, security policies, and skill registrations.
  """

  # -----------------------------------------------------------------------------
  # ⚙️ Configuration: Agent Initialization
  # -----------------------------------------------------------------------------

  @doc """
  Consolidates local .exs settings into a structured options list for starting an Eligenic Agent.
  """
  def agent_opts do
    [
      adapter: Application.get_env(:eligenic, :llm_adapter),
      api_key: Application.get_env(:eligenic, :gemini_api_key),
      model: Application.get_env(:eligenic, :gemini_model),
      instrumentation: Application.get_env(:eligenic, :instrumentation),
      security_settings: Application.get_env(:eligenic, :security),
      evals: Application.get_env(:eligenic, :evals),
      skills: [
        EligenicApp.Skills.Weather,
        EligenicApp.Skills.Knowledge
      ],
      session_manager: EligenicApp.Session
    ]
  end
end
