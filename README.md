# Eligenic

**Eligenic** is a pluggable, highly configurable Agentic framework for Elixir and Phoenix.

It allows you to turn your existing business logic into AI-callable tools with zero boilerplate, while providing robust security, memory, and evaluation infrastructure.

## Key Features

- **Zero-Boilerplate Introspection**: Automatically turn your existing Elixir functions into AI tools using `@doc` and typespecs.
- **Pluggable Architecture**: Bring your own storage (Ecto, Redis), security policies, and telemetry.
- **Production Ready**: Built-in support for PII redaction, tool-level authorization, and systematic evaluations.
- **Multi-LLM Support**: Unified adapter interface for Gemini, OpenAI, Anthropic, and more.

## Project Structure

Eligenic is organized as a clean, standalone library with a reference implementation:

- `lib/`: The core framework source code.
- `test/`: Comprehensive test suite for the core library.
- `examples/eligenic_app`: A standalone Phoenix application demonstrating production-grade integration.

## Running the Application

To run the sample Phoenix application:

1.  **Install dependencies**:
    ```bash
    mix deps.get
    ```

2.  **Set up the database**:
    Ensure you have Postgres running, then:
    ```bash
    mix ecto.setup
    ```

3.  **Start the Phoenix server**:
    ```bash
    mix phx.server
    ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Installation

Add `eligenic` to your `mix.exs`:

```elixir
def deps do
  [
    {:eligenic, "~> 0.1.0"}
  ]
end
```

## Usage

Eligenic is designed to be a "plug-and-play" library for adding agentic capabilities to any Elixir app.

### 1. Define Skills from Existing Code

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

### 2. Start an Agent

Agents are standard processes. You can start them manually or in a supervisor.

```elixir
# Manual start
{:ok, pid} = Eligenic.Agent.start_link(tools: tools)

# Send a message
{:ok, response} = Eligenic.call(pid, "Help me add 5 and 10")
```

### 3. Customize Infrastructure

Eligenic uses behaviors for Memory and Security, allowing you to use your existing infra.

#### Custom Memory (Ecto)
```elixir
defmodule MyApp.Memory do
  @behaviour Eligenic.Memory
  def store_event(agent_id, event), do: MyApp.Repo.insert(...)
  def get_history(agent_id), do: {:ok, MyApp.Repo.all(...)}
end

# Usage:
# Agent.start_link(memory: MyApp.Memory)
```

#### Custom Security (Auth/Masking)
```elixir
defmodule MyApp.Security do
  @behaviour Eligenic.Security
  def authorize(agent, tool, args), do: if(agent.admin, do: :ok, else: {:error, "Forbidden"})
  def redact(content), do: String.replace(content, ~r/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/, "REDACTED")
end
```

### 4. Multi-LLM Support

Toggle providers in your `config.exs`:

```elixir
config :eligenic,
  llm_adapter: Eligenic.Adapters.VertexAI # or OpenAI, etc.
```

## Contributing

Eligenic is developed by [Tecolixa](https://github.com/tecolixa). Contributions are welcome!

## License

Eligenic is released under the Apache License 2.0.
