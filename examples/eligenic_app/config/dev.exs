import Config

# Configure your database
config :eligenic_app, EligenicApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "eligenic_app_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
config :eligenic_app, EligenicAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "VnsQxl0rYOBo/0QyAdYMiv3r7iyafUySEWHN/GHh9zAWVzMvPLQngIBN3mqjKkwO",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:eligenic_app, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:eligenic_app, ~w(--watch)]}
  ]

# Reload browser tabs when matching files change.
config :eligenic_app, EligenicAppWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/eligenic_app_web/router\.ex$",
      ~r"lib/eligenic_app_web/(controllers|live|components)/.*\.(ex|heex)$"
    ]
  ]

config :eligenic_app, dev_routes: true
