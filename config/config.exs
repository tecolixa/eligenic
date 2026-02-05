# -----------------------------------------------------------------------------
# 🌍 Global Configuration
# -----------------------------------------------------------------------------
import Config

# --- Logger Integration ---
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# --- Phoenix Defaults ---
# Use Jason for JSON parsing in Phoenix (if used as a library)
config :phoenix, :json_library, Jason

# -----------------------------------------------------------------------------
# ⚙️ Environment Overrides
# -----------------------------------------------------------------------------
import_config "#{config_env()}.exs"
