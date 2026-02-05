defmodule Eligenic.Skill do
  @moduledoc """
  Behaviour definition for Eligenic Skills.
  Skills encapsulate a set of tools and their execution logic.
  """

  # -----------------------------------------------------------------------------
  # 🏗️ Macro Support: Integration
  # -----------------------------------------------------------------------------

  defmacro __using__(_opts) do
    quote do
      @behaviour Eligenic.Skill
    end
  end

  # -----------------------------------------------------------------------------
  # 📝 Callbacks: Skill Contract
  # -----------------------------------------------------------------------------

  @doc "Returns the list of tool definitions provided by this skill."
  @callback tools() :: [map()]

  @doc "Executes a specific tool by name with the provided arguments."
  @callback execute(name :: String.t(), args :: map()) :: any()
end
