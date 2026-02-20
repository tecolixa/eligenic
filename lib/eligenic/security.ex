defmodule Eligenic.Security do
  @moduledoc """
  Behaviour definition for agent security, redaction, and authorization.
  """

  # -----------------------------------------------------------------------------
  # 📝 Callbacks: Security Contract
  # -----------------------------------------------------------------------------

  @doc "Authorizes a specific tool call based on agent's identity and arguments."
  @callback authorize(identity :: Eligenic.Identity.t(), tool :: map(), args :: map()) ::
              :ok | {:error, String.t()}

  @doc "Redacts sensitive information (PII) from user content before processing."
  @callback redact(content :: String.t()) :: String.t()
end

defmodule Eligenic.Security.Default do
  @moduledoc """
  Default security implementation (Pass-through).
  """
  @behaviour Eligenic.Security

  # -----------------------------------------------------------------------------
  # 🛠️ Implementation: Pass-through
  # -----------------------------------------------------------------------------

  @impl true
  def authorize(_identity, _tool, _args), do: :ok

  @impl true
  def redact(content), do: content
end
