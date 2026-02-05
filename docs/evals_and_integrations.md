# Eligenic: Integrations & Evals

To build reliable agentic systems, Eligenic provides a robust layer for communicating with LLMs and a structured way to evaluate their performance.

## 1. LLM Integrations (The Adapter Layer)

Eligenic abstracts away the differences between LLM providers (Vertex AI, OpenAI, Anthropic, Ollama) through a unified adapter pattern.

### Unified Request Interface
```elixir
# Example of a generic request
Eligenic.Chat.completion(
  model: "gemini-1.5-flash",
  messages: [...],
  tools: [MySkill.tools()],
  temperature: 0.7
)
```

- **Structured Output:** Native support for forcing models to return specific Elixir structs or JSON schemas.
- **Streaming:** A consistent `GenStage` or `Stream` interface for real-time token delivery, regardless of the backend.
- **Provider Switching:** Swap models (e.g., from Gemini to GPT-4o) with a single config change, without rewriting your agent's logic.

---

## 2. Evals (Evaluation & Quality Control)

"It works on my machine" is not enough for LLMs. Eligenic treats Evals as a first-class citizen.

### LLM-as-a-Judge
Developers can use a "Judge" agent (usually a more capable/expensive model) to evaluate a "Worker" agent.
- **Scorecards:** Define criteria (e.g., "Factuality", "Tone", "Tool Accuracy") and have the Judge provide a 1-5 score and reasoning.
- **Regression Testing:** Automatically run high-capability models against a suite of "Golden Queries" after every prompt change to ensure performance hasn't dropped.

### Tool Call Verification
Since tools are Elixir functions, Eligenic can run deterministic "Unit Tests" on them:
- Did the LLM provide all required arguments?
- Is the argument type correct?
- Did the LLM correctly interpret the *result* of the tool?

### Evaluation Datasets
- **Storage:** Use Postgres to store historic inputs, agent monologues, and final outputs.
- **Labelling:** Simple hooks to allow humans to "Thumbs Up/Down" reactions in a LiveView UI, which then feeds back into your evaluation datasets.

---

## 3. Prompt Engineering & Versioning

Prompts are code. Eligenic helps manage them as such.
- **Prompt Templates:** Support for HEEx-like templates for prompts.
- **Versioning:** Link specific prompt versions to evaluation results, so you can objectively choose the best prompt for a specific task.
