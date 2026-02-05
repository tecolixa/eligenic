import Config

# -----------------------------------------------------------------------------
# 🌍 Environment: Load .env for local development
# -----------------------------------------------------------------------------
if config_env() == :dev do
  Dotenvy.source!([".env", System.get_env()])
end

# -----------------------------------------------------------------------------
# 🚀 Global Runtime Settings
# -----------------------------------------------------------------------------

if System.get_env("PHX_SERVER") do
  config :eligenic_app, EligenicAppWeb.Endpoint, server: true
end

# -----------------------------------------------------------------------------
# 🌍 Production Environment Configuration
# -----------------------------------------------------------------------------

if config_env() == :prod do
  # --- Database (Ecto) ---
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "environment variable DATABASE_URL is missing."

  config :eligenic_app, EligenicApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # --- Phoenix Endpoint & Security ---
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing."

  host = System.get_env("PHX_HOST") || "example.com"

  config :eligenic_app, EligenicAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT", "4000"))
    ],
    secret_key_base: secret_key_base
end

# -----------------------------------------------------------------------------
# 💎 Eligenic Framework Runtime Settings
# -----------------------------------------------------------------------------

config :eligenic,
  gemini_api_key: System.get_env("GEMINI_API_KEY"),
  gemini_model: System.get_env("GEMINI_MODEL") || "gemini-1.5-flash"
