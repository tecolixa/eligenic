defmodule EligenicApp.AgentIntegrationTest do
  use EligenicApp.DataCase

  test "weather_agent can be started with tools" do
    {:ok, pid} =
      start_supervised(
        {Eligenic.Agent, name: :weather_test_agent_1, tools: EligenicApp.Skills.Weather.tools()}
      )

    assert Process.alive?(pid)

    state = :sys.get_state(pid)
    assert length(state.tools) == 2
  end

  test "agent can handle a weather query" do
    {:ok, pid} =
      start_supervised(
        {Eligenic.Agent, name: :weather_test_agent_2, tools: EligenicApp.Skills.Weather.tools()}
      )

    {:ok, response} = Eligenic.call(pid, "What is the temperature in London?")
    assert response == "I am a mock AI."
  end
end
