# Eligenic: Security & Evals by Design

To move agents from "demos" to "production," Eligenic treats Security and Evaluation as core infrastructure that works out-of-the-box but remains fully configurable.

## 1. Security: The Safe Agentic Loop

Eligenic provides a "Secured Loop" that protects both the user and the system at every step.

### A. Data Protection (PII & Secrets)
- **Automatic Masking:** A pluggable `Security.Filter` behavior can detect and redact PII (emails, phone numbers, API keys) from the context before it leaves your server for an external LLM.
- **De-masking on Return:** If the agent needs to "talk about" a user but shouldn't "see" their PII, Eligenic can swap real values with placeholders and restore them when the response arrives.

### B. Tool-Level Authorization (RBAC/ABAC)
- **The Gatekeeper:** Every tool call is intercepted by `Eligenic.Security.authorize(agent, tool, args)`.
- **Host Integration:** This hooks directly into your existing app's auth logic. For example:
  ```elixir
  # In your app
  defmodule MyApp.SecurityProvider do
    use Eligenic.Security
    def authorized?(agent, :delete_user, %{id: target_id}) do
      # Agent only has access if it has the :admin capability
      agent.capabilities.admin? && target_id != agent.owner_id
    end
  end
  ```

### C. Prompt Injection Defense
- **Input Sanitization:** Built-in heuristics to detect "IGNORE PREVIOUS INSTRUCTIONS" style attacks.
- **Structural Integrity:** By using "System" prompts and structured outputs (JSON/Tool calls), Eligenic limits the surface area for text-based hijacking.

---

## 2. Evals: Systematic Reliability

Evaluation in Eligenic is not an afterthought; it is a **continuous pipeline** integrated into the development loop.

### A. The "Golden Set" & Regression Testing
- **Golden Dataset:** A curated list of (Input -> ToolCall -> ExpectedOutput) triplets.
- **Automated Runner:** Run `mix eligenic.eval` to execute your current prompt/tool versions against the Golden Set and see a diff of any changes in behavior.

### B. LLM-as-a-Judge (The "Supervisor")
- **Dual Model Setup:** Use a cheap/fast model (like Gemini Flash) for production agents, but use a "High-HQ" model (like Gemini Pro or GPT-4o) as the **Judge** to score responses on:
  - **Accuracy:** Did it pick the right tool?
  - **Tone:** Does it stay within the brand voice?
  - **Safety:** Did it try to reveal system secrets?

### C. Live Tracing & Feedback
- **Feedback Loops:** User "Up/Down" votes in your Phoenix UI are automatically tagged and stored, allowing you to "promote" successful runs into your Golden Dataset.
- **Observability:** Integration with `:telemetry` means you can monitor agent "failure rates" in your existing Grafana/Prometheus dashboards.

---

## 3. The "Plug-and-Play" Model

- **Greenfield:** Eligenic provides basic PII regex filters and a JSON-based eval registry.
- **Enterprise:** Plug in your own custom PII detection service (like Amazon Macie or custom models) and your own specialized security policies.
