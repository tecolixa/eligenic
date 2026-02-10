# Eligenic OS: Reference Implementation

> [!WARNING]
> **Experimental Prototype.**
> This application is a reference implementation for the **Eligenic** framework. It is currently in a research/prototypal stage (v0.1.0) and is not intended for production workloads.

**Eligenic OS** is a high-performance, event-driven playground for autonomous AI agents. Built with **Elixir** and **Phoenix LiveView**, it demonstrates the power of process-level isolation and acyclic orchestration (DAGs) in agentic workflows.

---

## ✨ Features

- **Neural Interface (LiveView)**: A low-latency, real-time chat interface for interacting with autonomous agents.
- **Capability-Driven Skills**: Demonstration of how Elixir functions are introspected into AI-callable tools.
- **Contextual Memory**: Shows how agents maintain and query ancestral context through temporary and persistent storage.
- **Fault-Tolerant Orchestration**: Leverages OTP supervisors to manage agent lifecycles and recovery.

## 🛠️ Technology Stack

- **Framework**: Phoenix v1.8
- **Orchestration**: Eligenic (Experimental)
- **AI Adapter**: Google Gemini 3 Flash / Pro
- **Styling**: Tailwind CSS v4 (Custom Premium Aesthetic)

---

## 🚀 Quick Start

### 1. Prerequisites
Ensure you have the following installed:
- Elixir 1.15+ / Erlang OTP 26+
- PostgreSQL

### 2. Configure Environment
Eligenic OS requires a Google Gemini API key.
```bash
# Copy the template
cp .env.example .env

# Edit .env and add your API Key
# export GEMINI_API_KEY=your_key_here

# Load the variables into your session
source .env
```

### 3. Setup and Run
```bash
# Install dependencies, setup database, and compile assets
mix setup

# Fire up the engine
mix phx.server
```

Once running, visit [`localhost:4000`](http://localhost:4000) to access the Neural Interface.

---

## 🧪 Experimental Roadmap

- [ ] Multi-Modal Tooling (Images/Files)
- [ ] Distributed Agent Clusters (libcluster)
- [ ] Recursive Replanning Logic
- [ ] Advanced Knowledge Graph Integration

---

## 🛡️ Security Note
As a prototype, this application uses default security policies. Always ensure PII redaction and tool authorization settings are reviewed before exposing any agentic interface to untrusted inputs.

---
Developed as a demonstration for the **Eligenic Framework**.
