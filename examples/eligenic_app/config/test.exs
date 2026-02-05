import Config

# Configure your database
config :eligenic_app, EligenicApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "eligenic_app_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is needed, cost: 2
# you can enable the server option below.
config :eligenic_app, EligenicAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "VnsQxl0rYOBo/0QyAdYMiv3r7iyafUySEWHN/GHh9zAWVzMvPLQngIBN3mqjKkwO",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# --- Eligenic: Mock Adapter for Tests ---
config :eligenic,
  llm_adapter: Eligenic.Adapters.Mock
