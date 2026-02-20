# Eligenic Architecture

Eligenic is an agentic framework built natively for the Erlang VM (BEAM). It is designed around the principles of functional isolation, concurrent execution, and domain-driven design. The architecture cleanly separates the logical "brain" of the agent from the physical execution environment, enabling it to scale efficiently across distributed clusters.

---

## 🏗️ 1. Domain-Driven Core: `%Eligenic.Agent{}`

The core of the system is the `%Eligenic.Agent{}` struct. This data structure encapsulates the entirety of an agent's definition and dependencies, isolating domain logic from the underlying process state.

```elixir
%Eligenic.Agent{
  id: "finance_bot_01",
  identity: %Eligenic.Identity{...},
  skills: [MyApp.Skills.DatabaseSearch],
  adapter: Eligenic.Adapters.Gemini,
  memory: Eligenic.Memory.ETS,
  security: MyApp.CustomSecurity
}
```

The `Eligenic.Agent` module implements the `GenServer` behavior. It acts as an asynchronous traffic controller—receiving external messages, tracking state transitions (e.g., `:idle` or `:busy`), and handing off complex LLM reasoning to the runtime layer without blocking its own message queue.

---

## 🎭 2. Agentic Identity

Every agent operates under a strict `Eligenic.Identity` definition. This struct dictates *who* the agent is and *what* it is allowed to do.

An Identity consists of:
- **`id`**: A unique string used for dynamic registry and memory indexing.
- **`persona`**: The foundational system prompt that grounds the agent's behavior.
- **`claims`**: Contextual authorization tags (e.g., `["db:read", "action:approve_invoice"]`).

During the reasoning loop, the framework automatically extracts the `persona` and injects it as an immutable system prompt into the LLM context path.

---

## ⚙️ 3. Execution & Scaling Abstractions

To achieve massive parallelism, Eligenic splits its execution model into two distinct subsystems: the Runtime (Where) and the Executor (How).

### `Eligenic.Runtime` (The Environment)
The Runtime provisions the execution environment for the agent's reasoning loop.
Instead of an agent calculating LLM operations on its own primary process, the Agent delegates the logic to the `Eligenic.Runtime`. 

### `Eligenic.Runtime.Local` (Default)
The default runtime utilizes `PartitionSupervisor`, pushing the intensive API call to a distributed worker pool. This isolates execution failures and distributes processing load optimally across all available CPU cores.

### `Eligenic.Runtime.Distributed`
For cloud-scale applications, the provided distributed runtime routes LLM task spawns across a cluster of connected Erlang nodes (`Node.list()`). 

Because `Eligenic.Runtime` is a strict `@behaviour`, Eligenic is completely decoupled from any specific clustering library. Developers can trivially write custom Runtimes that leverage tools like `Horde.TaskSupervisor` to achieve massive, dynamically rebalanced vertical and horizontal scale without Eligenic forcing those dependencies into your `mix.exs`.

### `Eligenic.Executor` (The Logic Driver)
The Executor manages the physical manifestation of the agent's decisions.
When an LLM requests a tool call, the `Eligenic.Executor` handles it safely and concurrently:
- **Concurrent Streaming**: Resolves multiple parallel tool requests using `Task.async_stream`.
- **Fault Sandboxing**: Wraps each individual external skill call in a `try/rescue` block. If an external API call crashes, the Executor catches the exception and returns it as a stringified error to the LLM, triggering dynamic replanning instead of killing the agent's process.

---

## 🔒 4. Pluggable Infrastructure

Eligenic is built on an "Adapter-First" philosophy. Every side-effecting interaction boundary is codified through an Elixir `@behaviour`, allowing developers to swap implementations effortlessly.

### Adapters (`Eligenic.Adapter`)
Standardizes communication with underlying Large Language Models (e.g., Google Gemini, Anthropic, OpenAI). Adapters map Eligenic's uniform tool schemas into provider-specific REST payloads.

### Memory (`Eligenic.Memory`)
Abstracts how conversation histories are persisted and retrieved.
- **`Eligenic.Memory.ETS`**: Fast, in-memory volatile storage (default).
- **Extensible**: The interface supports seamless swapping to `Postgres` or `Redis` backends within the `%Eligenic.Agent{}` struct definition to achieve long-term persistence.

### Security (`Eligenic.Security`)
The security layer intercepts the execution pipeline immediately prior to physical action.
`Eligenic.Security.authorize(identity, tool, args)` cross-references the Agent's configured `claims` against the requested `tool`, offering first-class protection against unauthorized LLM actions or prompt injections.

### Instrumentation (`Eligenic.Instrumentation`)
Eligenic natively instruments its own performance using Erlang's `:telemetry` library. Core framework events, including LLM request latency and token metrics, are emitted asynchronously, allowing immediate integration with systems like Prometheus, Grafana, or LiveView Dashboards.

---

## 🗣️ 5. Agent-to-Agent Communication (`Eligenic.Broker`)

Because `Eligenic.Agent` is fundamentally an OTP `GenServer`, the framework bypasses heavy networking protocols (like REST or gRPC) that plague other languages when orchestrating multi-agent systems. 

All communication flows through the `@behaviour Eligenic.Broker`. This abstraction acts as the "nervous system" connecting independent agents together. By default, Eligenic provides `Eligenic.Broker.PG`, which utilizes native Erlang Process Groups to enable instant swarm topologies locally and across clustered nodes without needing external dependencies like `Phoenix.PubSub`.

The Broker supports three core communication paradigms:

### Direct Message Passing (1:1 Synchronous)
The simplest way agents interact is via direct `GenServer.call/3` boundaries. Using `Eligenic.Broker.request/2`, an agent can directly trigger a sub-agent.

For example, a "Manager Agent" breaking down a user's request can use a tool to call a specialized sub-agent:
```elixir
{:ok, summary} = Eligenic.Broker.request("finance_analyst_01", "Summarize Q3 earnings.")
```
This guarantees the Manager gets the precise data it needs before resuming its reasoning loop. Thanks to the `Eligenic.Runtime` async abstraction, the `finance_analyst_01` agent calculates its payload in the background *without* blocking its own message queue.

### The Planner Engine (1:Many Deterministic DAGs)
For complex workflows, Eligenic aims to use a formal **Planner**. Instead of agents freely chatting and potentially losing context, a Planner deconstructs a large prompt into a Directed Acyclic Graph (DAG) of discrete tasks.

The routing logic yields output through the Broker to sequentially unblock dependent downstream agents, ensuring mathematically verifiable, error-isolated handoffs.

### PubSub Swarms (1:Many Asynchronous)
For massive, uncoupled agent topologies (e.g., thousands of agents operating independently across nodes), Eligenic leans heavily on decentralized event broadcasting.

Because each Agent is just an isolated process, they can cleanly subscribe to global topics. When a state changes, an event is published:
```elixir
Eligenic.Broker.publish("market_events", {:price_drop, "AAPL", 145.20})
```

**The Elixir Advantage:**
In Python, forcing 10,000 agents to constantly listen to a websocket or poll a database is excruciatingly heavy overhead. In Eligenic, 10,000 "Trading Bot Agents" can simply call `Eligenic.Broker.subscribe("market_events")` during their initialization. When an orchestrator publishes a price drop, all 10,000 agents wake up concurrently, calculate whether the drop meets their specific `persona`'s risk tolerance, and independently decide to execute a trade. This enables true decentralized swarm intelligence out of the box.

Because the Broker is a `@behaviour`, enterprise users can flawlessly swap `Eligenic.Broker.PG` for a custom integration connecting Agents seamlessly to enterprise **Kafka, RabbitMQ, or Redis** instances simply by passing a new `:broker` module into the Agent struct.
