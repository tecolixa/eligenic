# -----------------------------------------------------------------------------
# 🧪 Test Environment: Validation Logic
# -----------------------------------------------------------------------------
import Config

# --- Logger: Silent Mode ---
config :logger, level: :warning

# --- Eligenic: Framework Core ---
config :eligenic,
  llm_adapter: Eligenic.Adapters.Mock
