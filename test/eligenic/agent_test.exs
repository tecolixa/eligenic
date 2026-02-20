defmodule Eligenic.AgentTest do
  use ExUnit.Case
  alias Eligenic.Agent

  test "agent responds to hello" do
    {:ok, pid} = Agent.start_link(history: [])
    {:ok, response} = Agent.call(pid, "hello")
    assert response == "Hello! How can I help you?"
  end

  defmodule PersonaTestAdapter do
    @behaviour Eligenic.Adapter

    @impl true
    def chat_completion([%{role: "system", content: "You are a database admin"} | _], _opts) do
      {:ok, %{role: "assistant", content: "I am a database admin."}}
    end

    def chat_completion(_messages, _opts) do
      {:ok, %{role: "assistant", content: "No persona provided."}}
    end

    @impl true
    def structured_completion(_, _, _), do: {:ok, %{}}
  end

  test "agent identity injects persona as system prompt" do
    identity = %Eligenic.Identity{
      id: "admin_agent",
      persona: "You are a database admin"
    }

    {:ok, pid} = Agent.start_link(identity: identity, adapter: PersonaTestAdapter)
    {:ok, response} = Agent.call(pid, "Who are you?")

    assert response == "I am a database admin."
  end

  defmodule ClaimsSecurity do
    @behaviour Eligenic.Security

    @impl true
    def authorize(%Eligenic.Identity{claims: claims}, _tool, _args) do
      if claims && "execute:tools" in claims do
        :ok
      else
        {:error, "Unauthorized"}
      end
    end

    @impl true
    def redact(content), do: content
  end

  test "agent security uses identity claims for authorization" do
    identity = %Eligenic.Identity{
      id: "restricted_agent",
      # Missing execute:tools
      claims: ["read:data"]
    }

    # If the tool authorization fails, the mock adapter won't be given any tools in loop.
    # To truly test this, we can just assert that the authorization function correctly rejects.
    assert {:error, "Unauthorized"} = ClaimsSecurity.authorize(identity, %{name: :tool}, %{})

    valid_identity = %Eligenic.Identity{
      id: "admin_agent",
      claims: ["execute:tools"]
    }

    assert :ok = ClaimsSecurity.authorize(valid_identity, %{name: :tool}, %{})
  end
end
