defmodule EligenicAppWeb.Endpoint do
  @moduledoc """
  Phoenix Endpoint for the Eligenic reference implementation.
  Handles request piping, socket management, and static asset serving.
  """
  use Phoenix.Endpoint, otp_app: :eligenic_app

  # -----------------------------------------------------------------------------
  # 🔒 Security: Session Configuration
  # -----------------------------------------------------------------------------

  @session_options [
    store: :cookie,
    key: "_eligenic_app_key",
    signing_salt: "xB6Jue4R",
    same_site: "Lax"
  ]

  # -----------------------------------------------------------------------------
  # 🔌 Sockets: Real-time Communication
  # -----------------------------------------------------------------------------

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]
  )

  # -----------------------------------------------------------------------------
  # 📦 Assets: Static File Serving
  # -----------------------------------------------------------------------------

  plug(Plug.Static,
    at: "/",
    from: :eligenic_app,
    gzip: not code_reloading?,
    only: EligenicAppWeb.static_paths(),
    raise_on_missing_only: code_reloading?
  )

  # -----------------------------------------------------------------------------
  # 🛠️ Development: Live Reloading
  # -----------------------------------------------------------------------------

  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :eligenic_app)
  end

  # -----------------------------------------------------------------------------
  # ⛽ Pipeline: General Request Handling
  # -----------------------------------------------------------------------------

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(EligenicAppWeb.Router)
end
