defmodule Eligenic.AgentTest do
  use ExUnit.Case
  alias Eligenic.Agent

  test "agent responds to hello" do
    {:ok, pid} = Agent.start_link(history: [])
    {:ok, response} = Agent.call(pid, "hello")
    assert response == "Hello! How can I help you?"
  end
end
