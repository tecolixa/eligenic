import Config

# -----------------------------------------------------------------------------
# 🏠 Infrastructure: Database & Phoenix Endpoint
# -----------------------------------------------------------------------------

config :eligenic_app,
  ecto_repos: [EligenicApp.Repo],
  generators: [timestamp_type: :utc_datetime]

config :eligenic_app, EligenicAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: EligenicAppWeb.ErrorHTML, json: EligenicAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EligenicApp.PubSub,
  live_view: [signing_salt: "dv9wX6Zt"]

# -----------------------------------------------------------------------------
# 🎨 Assets: Esbuild & Tailwind
# -----------------------------------------------------------------------------

config :esbuild,
  version: "0.25.4",
  eligenic_app: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.) ++
        ~w(--alias:phoenix-colocated=../lib/eligenic_app_web),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__)]}
  ]

config :tailwind,
  version: "4.1.12",
  eligenic_app: [
    args: ~w(
      --input=css/app.css
      --output=../priv/static/assets/css/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# -----------------------------------------------------------------------------
# 💎 Eligenic: AI Framework Pillars
# -----------------------------------------------------------------------------

config :eligenic,
  llm_adapter: Eligenic.Adapters.Gemini,
  instrumentation: [
    enabled: true,
    tracking: [:tool_calls, :errors, :latency]
  ],
  security: [
    filter_pii: true,
    authorization_required: true,
    auth_provider: Eligenic.Security.Default
  ],
  evals: [
    golden_set_path: "priv/eligenic/golden_set.json",
    scoring_model: "gemini-1.5-pro"
  ]

# -----------------------------------------------------------------------------
# ⚙️ Environment Overrides
# -----------------------------------------------------------------------------

import_config "#{config_env()}.exs"
