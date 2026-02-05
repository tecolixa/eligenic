# Using Eligenic

Eligenic is designed to be a "plug-and-play" library for adding agentic capabilities to any Elixir app.

## 1. Define Skills from Existing Code

You can turn any existing module into an AI Skill using the `Eligenic.Tool` introspection.

```elixir
defmodule MyApp.Calculator do
  @doc "Adds two numbers together"
  @spec add(a :: integer(), b :: integer()) :: integer()
  def add(a, b), do: a + b
end

# In your agent config:
tools = [
  Eligenic.Tool.introspect(MyApp.Calculator, :add) |> elem(1)
]
```

## 2. Start an Agent

Agents are standard processes. You can start them manually or in a supervisor.

```elixir
# Manual start
{:ok, pid} = Eligenic.Agent.start_link(tools: tools)

# Send a message
{:ok, response} = Eligenic.call(pid, "Help me add 5 and 10")
```

## 3. Customize Infrastructure

Eligenic uses behaviors for Memory and Security, allowing you to use your existing infra.

### Custom Memory (Ecto)
```elixir
defmodule MyApp.Memory do
  @behaviour Eligenic.Memory
  def store_event(agent_id, event), do: MyApp.Repo.insert(...)
  def get_history(agent_id), do: {:ok, MyApp.Repo.all(...)}
end

# Usage:
Agent.start_link(memory: MyApp.Memory)
```

### Custom Security (Auth/Masking)
```elixir
defmodule MyApp.Security do
  @behaviour Eligenic.Security
  def authorize(agent, tool, args), do: if(agent.admin, do: :ok, else: {:error, "Forbidden"})
  def redact(content), do: String.replace(content, ~r/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/, "REDACTED")
end
```

## 4. Multi-LLM Support

Toggle providers in your `config.exs`:

```elixir
config :eligenic,
  llm_adapter: Eligenic.Adapters.VertexAI # or OpenAI, etc.
```
