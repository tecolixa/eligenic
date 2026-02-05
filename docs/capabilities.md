# Eligenic: Capabilities and Provisions

As a framework, Eligenic provides the "batteries" for building sophisticated agentic applications. It handles the repetitive boilerplate and complex orchestration, allowing developers to focus on defining their agents' unique skills and logic.

## 1. Core Primitives

### `Eligenic.Agent` (The Behavior)
A behavior that handles the standard agentic loop.
- **Thought-Act-Observe Loop:** Handles the iterative process of reasoning, tool selection, and result interpretation.
- **State Management:** Native GenServer-based state for conversation history, internal monologue, and current goals.
- **Streaming:** First-class support for streaming LLM "thoughts" and token responses.

### `Eligenic.Tool` (The Bridge)
A way to expose existing Elixir functions to LLMs without rewriting them.
- **Introspection:** Automatic generation of JSON Schema from existing `@spec` and `@doc` attributes in your app.
- **Pluggability:** Simply "register" a module or function as a tool, and Eligenic handles the rest.
- **Type-Safe Execution:** Automatic casting of LLM JSON arguments to Elixir types based on your function specs.

---

## 2. Orchestration & Planning

### The Planner Engine
For complex, multi-step goals, Eligenic provides a Planner.
- **Goal Decomposition:** Breaks high-level user requests into a Directed Acyclic Graph (DAG) of tasks.
- **Dynamic Replanning:** If a tool fails or provides unexpected data, the planner can adjust the remaining graph on the fly.
- **Context Routing:** Intelligently feeds relevant ancestors' output to downstream tasks.

### Multi-Agent Coordination
- **Broker/PubSub:** Agents can communicate with each other using standard Phoenix PubSub.
- **Handoffs:** Built-in patterns for one agent (e.g., a "Router") to hand off a task to a specialized sub-agent.

---

## 3. UI and Observability (Phoenix Integration)

### LiveView Hooks & Components
Eligenic provides out-of-the-box UI elements for real-time AI interactions:
- **Thinking Bubbles:** Visual indicators of an agent's internal monologue or planning phase.
- **Tool Traces:** Interactive logs showing exactly which tool was called, with what arguments, and the result.
- **Human-in-the-Loop:** Easy integration for forcing manual approval before sensitive tool executions.

### Observability
- **Telemetry Integration:** Standard `:telemetry` events for LLM latency, token usage, and tool success rates.
- **Tracing:** Detailed traces of an agent's reasoning process for debugging and evaluation.

---

## 4. Security and Reliability

### Guardrails & Security
- **Configurable Authorization:** Hook Eligenic into your existing Auth system (e.g., `MyApp.Policy.can?(user, :call_tool, tool)`).
- **Audit Logging:** Emits telemetry events so you can audit agent actions using your existing logging infrastructure.

### Fault Tolerance & Persistence
- **State Recovery:** Agents can snapshot their state to your existing Postgres DB (via a configurable repo adapter).
- **Resiliency:** Standard Elixir supervision, with the ability to resume long-running agentic tasks even after a deployment or crash.
