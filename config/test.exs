# -----------------------------------------------------------------------------
# 🧪 Test Environment: Validation Logic
# -----------------------------------------------------------------------------
import Config

# --- Logger: Silent Mode ---
config :logger, level: :warning

# --- Phoenix: Optimization ---
config :phoenix, :plug_init_mode, :runtime
config :phoenix, :sort_verified_routes_query_params, true

# --- LiveView: Runtime Checks ---
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# --- Eligenic: Framework Core ---
config :eligenic,
  llm_adapter: Eligenic.Adapters.Mock
