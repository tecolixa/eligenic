defmodule Eligenic.Adapter do
  @moduledoc """
  Behaviour definition for LLM provider adapters.
  Adapters translate Eligenic's internal reasoning loop into provider-specific API calls.
  """

  # -----------------------------------------------------------------------------
  # 🏷️ Types: Domain Definitions
  # -----------------------------------------------------------------------------

  @type message :: %{role: String.t(), content: String.t()}
  @type tool_call :: %{id: String.t(), type: String.t(), function: map()}

  # -----------------------------------------------------------------------------
  # 📝 Callbacks: Adapter Contract
  # -----------------------------------------------------------------------------

  @callback chat_completion(messages :: [message()], opts :: keyword()) ::
              {:ok,
               %{role: String.t(), content: String.t() | nil, tool_calls: [tool_call()] | nil}}
              | {:error, any()}

  @callback structured_completion(messages :: [message()], schema :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, any()}
end
