# -----------------------------------------------------------------------------
# 🛠️ Development Environment: Active Iteration
# -----------------------------------------------------------------------------
import Config

# --- Logger: Minimal Output ---
# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# --- Phoenix: Debugging & Performance ---
# Set a higher stacktrace during development.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# --- LiveView: Advanced Diagnostics ---
config :phoenix_live_view,
  # Include debug annotations and locations in rendered markup.
  debug_heex_annotations: true,
  debug_attributes: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
