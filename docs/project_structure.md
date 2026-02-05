# Eligenic: Proposed Project Structure

To build a robust, extensible framework, Eligenic will follow a modular structure that separates core logic, provider adapters, and developer tools.

## 1. Core Framework (`lib/eligenic/`)

This directory contains the essential behaviors and engines of the framework.

- **`agent.ex`**: The `Eligenic.Agent` behavior and GenServer implementation.
- **`tool.ex`**: The `Eligenic.Tool` parser and validation logic.
- **`skill.ex`**: The `Eligenic.Skill` abstraction for grouping tools and prompts.
- **`planner/`**:
    - **`engine.ex`**: The DAG execution engine.
    - **`planner.ex`**: The AI-driven goal decomposition logic.
- **`memory/`**:
    - **`short_term.ex`**: ETS/Process state handlers.
    - **`long_term.ex`**: Ecto-based persistent storage interfaces.

## 2. LLM Integrations (`lib/eligenic/adapters/`)

Encapsulates all provider-specific communication.

- **`adapter.ex`**: The behavior for LLM adapters.
- **`vertex_ai.ex`**: Integration with Google Gemini.
- **`openai.ex`**: Integration with GPT-4/3.5.
- **`anthropic.ex`**: Integration with Claude.

## 3. Systematic Evals & Prompts (`lib/eligenic/evals/`)

The infrastructure for versioning and automated testing.

- **`prompt_registry.ex`**: Manages prompt storage and versioning.
- **`judge.ex`**: Logic for the automated LLM-as-a-judge.
- **`golden_dataset.ex`**: Handlers for test cases and expected outputs.
- **`eval_runner.ex`**: Orchestrates the systematic evaluation pipeline.

## 4. Phoenix & LiveView Integration (`lib/eligenic_web/`)

Shared components and hooks for building UIs.

- **`components/`**:
    - **`agent_monologue.ex`**: LiveView component for streaming "thoughts".
    - **`tool_trace.ex`**: Component for visualizing tool calls.
- **`plugs/`**: Middlewares for authentication/authorization of agentic actions.

## 5. Developer Experience (Mix Tasks)

- **`mix eligenic.gen.skill`**: Scaffolds a new Skill module.
- **`mix eligenic.eval`**: Runs the systematic evaluation pipeline in CI.
- **`mix eligenic.setup`**: Configures the necessary Postgres tables for versioning and history.

---

## 6. Tree View

```text
eligenic_umbrella/
├── apps/
│   ├── eligenic/              # Core Library (Pure Elixir, No Phoenix Dep)
│   │   ├── lib/
│   │   │   ├── eligenic/
│   │   │   │   ├── agent.ex
│   │   │   │   ├── tool.ex    # Introspection & Bridge
│   │   │   │   ├── planner/
│   │   │   │   ├── adapters/
│   │   │   │   └── evals/
│   │   │   └── eligenic.ex
│   │   └── test/
│   └── eligenic_web/          # Optional Web Integration (Phoenix-based)
│       ├── lib/
│       │   ├── eligenic_web/
│       │   │   ├── components/ # LiveView UI bits
│       │   │   └── dashboard/  # The Admin/Eval UI
│       │   └── eligenic_web.ex
```
