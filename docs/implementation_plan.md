# Implementation Plan: Eligenic Core Library (Phase 1)

This plan outlines the first steps to building the **Eligenic** core as a pure Elixir library that can be plugged into existing apps.

## Proposed Changes

### 1. [NEW] `Eligenic.Tool` Introspection Engine
The goal is to allow developers to turn any function into a tool with zero manual schema definition.

#### [NEW] [tool.ex](file:///Users/macken/Codev/Eligenic/apps/eligenic/lib/eligenic/tool.ex)
- Implement `fetch_spec/2`: Uses `Code.fetch_docs/1` and `Type.fetch_spec/2` (or similar) to extract parameter types and documentation.
- Implement `to_json_schema/1`: Converts Elixir types (e.g., `String.t()`, `integer()`) into JSON Schema types.
- Implement `execute/3`: Casts incoming LLM JSON arguments into the correct Elixir types and calls the function.

### 2. [NEW] `Eligenic.Agent` Behavior
The core agentic loop.

#### [NEW] [agent.ex](file:///Users/macken/Codev/Eligenic/apps/eligenic/lib/eligenic/agent.ex)
- Define a behavior with `c:init/1`, `c:handle_thought/2`, and `c:handle_action/2`.
- Implement a default GenServer that manages the loop: 
    1. Send context to LLM.
    2. Parse "Thought" and "Tool Call".
    3. Execute tool via `Eligenic.Tool`.
    4. Observe result and repeat.

### 3. [NEW] Side-Effect Bridge (Memory & Security)
Infrastructure for using host-app resources.

#### [NEW] [memory.ex](file:///Users/macken/Codev/Eligenic/apps/eligenic/lib/eligenic/memory.ex)
- Define `Eligenic.Memory` behavior: `c:store_event/2`, `c:get_history/1`.
- Implement `Eligenic.Memory.Ecto`: A default adapter that uses a provided Repo.

#### [NEW] [security.ex](file:///Users/macken/Codev/Eligenic/apps/eligenic/lib/eligenic/security.ex)
- Define `Eligenic.Security` behavior: `c:authorized?/3`.
- Implement `Eligenic.Security.Default`: Always returns `:ok`.

---

## Verification Plan

### Automated Tests
- **Introspection Unit Tests**:
    ```bash
    mix test apps/eligenic/test/eligenic/tool_test.exs
    ```
    - Verify that a function like `Math.add(a :: integer, b :: integer)` generates a valid JSON Schema with two integer properties.
    - Verify that docs are correctly extracted as the tool's description.

- **Agent Loop Mock Test**:
    - Mock an LLM response and verify the Agent process calls the expected tool and transitions its state correctly.

### Manual Verification
- I will ask the user to provide a simple module (e.g., a "User Profile" controller or service) and I will demonstrate how Eligenic can introspect it and prepare it for an LLM call.
