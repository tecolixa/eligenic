# -----------------------------------------------------------------------------
# 🌍 Global Configuration
# -----------------------------------------------------------------------------
import Config

# --- Logger Integration ---
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# -----------------------------------------------------------------------------
# ⚙️ Environment Overrides
# -----------------------------------------------------------------------------
import_config "#{config_env()}.exs"
