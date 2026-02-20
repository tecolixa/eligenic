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

  @doc """
  Resolves an Identity struct from a keyword list of options.
  If an `:identity` struct exists in `opts`, it is returned.
  If a `fallback_id` is provided, a fresh Identity is generated using it.
  Otherwise, a random default identity is generated.
  """
  @spec from_opts(keyword(), String.t() | nil) :: t()
  def from_opts(opts, fallback_id \\ nil) do
    cond do
      identity = opts[:identity] -> identity
      fallback_id != nil -> %__MODULE__{id: fallback_id}
      true -> generate_default()
    end
  end
end
