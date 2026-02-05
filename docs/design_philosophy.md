# Eligenic: Agentic Elixir Framework Design Philosophy

Eligenic aims to be the premier framework for building agentic applications on the Erlang VM (BEAM). By leveraging the unique strengths of Elixir and Phoenix, we can build AI systems that are more reliable, stateful, and observable than those built in traditional imperative environments.

## Why Elixir for Agents? (Pure Elixir Core)

In Eligenic, an "Agent" is a standard Elixir **Process** (GenServer). The framework is designed to be a pure Elixir library that can run in any BEAM application, whether it's a Nerves device, a CLI tool, or a Phoenix web app.

- **Non-Invasive Integration:** Eligenic does not "own" your application lifecycle. It provides modules and behaviors that you plug into your existing supervision trees.
- **Isolation & Fault Tolerance:** Uses standard BEAM principles to isolate AI interactions. If an LLM call fails, only that agent's process is affected.
- **Concurrency:** Leverages lightweight processes for multi-agent workflows without requiring a web server.

## Phoenix Integration (The Consumer)

While Eligenic is Phoenix-agnostic, it is "Phoenix-optimized." It provides optional bridges for the web layer:
- **LiveView Hooks:** Optional components to stream agent state to a UI.
- **PubSub Integration:** Uses standard `Phoenix.PubSub` if available for distributed coordination, but can fall back to local message passing.

## Core Abstractions

### Skills as Plugins
A **Skill** allows you to "agentize" existing code. 
- **Introspection:** Eligenic uses reflection on `@spec` and `@doc` to automatically turn your existing functions into AI-callable Tools.
- **Zero-Boilerplate:** You don't rewrite your logic for the AI; you just point Eligenic at your existing modules.

### Skills
A **Skill** is a modular set of capabilities an agent can possess. It combines:
- **Tools:** The actual functions the agent can call.
- **Prompts:** The domain-specific instructions.
- **Logic:** Any Elixir code needed to bridge the two.

### Tasks
A **Task** is a discrete goal assigned to an agent. Tasks in Eligenic are:
- **Decoupled:** A planner creates tasks; workers execute them.
- **Acyclic (mostly):** Favoring DAGs for complex workflows.
- **Observable:** Every step of a task is a message in the system.

### Memory
- **Short-term:** Process state / ETS.
- **Long-term:** Postgres (via Ecto) for persistent history and vector storage.

## Plug-and-Play vs. Configurable

Eligenic operates on a "Bring Your Own Infra" (BYOI) model while providing sensible defaults for greenfield projects.

### The "Adapter First" Approach
Every side-effecting system (Memory, Caching, Security, Evals) is defined by an Elixir **Behavior**.
- **Provided:** Eligenic comes with built-in modules for standard use cases (e.g., `Eligenic.Memory.Postgres` for Ecto, `Eligenic.Cache.ETS`).
- **Configurable:** If your app already has a custom billing system, a specialized Redis cache, or a legacy Postgres schema, you simply implement the Eligenic behavior in your own module and configure the framework to use it.

### Feature Mapping
- **Memory:** Use your existing `Repo` for conversation history.
- **Tools/Actions:** Use your existing `BusinessDomain` modules as skills.
- **Security:** Wrap Eligenic in your existing `Bodyguard` or `CanCan` style authorization.
- **Observability:** Emit standard `:telemetry` events that hook into your existing Grafana dashboards.

---

## The Vision
Eligenic should feel like "standard Elixir." It shouldn't feel like a DSL. If you know how to write a function and use a `GenServer`, you should be able to build a world-class AI agent.
