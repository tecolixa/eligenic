defmodule Eligenic.Identity do
  @moduledoc """
  Represents the foundational identity, permissions, and persona of an Agent.
  """

  @enforce_keys [:id]
  defstruct [
    # Cryptographic ID or UUID string
    :id,
    # Human-readable name (e.g., "DataAnalyst_01")
    :name,
    # Base system instructions/prompt
    :persona,
    # Who the agent is acting on behalf of (e.g., %User{id: 123})
    :principal,
    # Scopes and permissions (e.g., ["db:read", "file:write"])
    :claims,
    # For verifiable agent-to-agent messaging
    :public_key
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t() | nil,
          persona: String.t() | nil,
          principal: any() | nil,
          claims: [String.t()] | nil,
          public_key: binary() | nil
        }

  @doc """
  Generates a default identity if none is provided.
  This maintains backwards compatibility by ensuring every agent has a unique ID.
  """
  @spec generate_default() :: t()
  def generate_default do
    %__MODULE__{
      id: "agent_#{:erlang.unique_integer([:positive])}"
    }
  end
end
