defmodule EligenicAppWeb.Router do
  @moduledoc """
  Router for the Eligenic reference implementation.
  """
  use EligenicAppWeb, :router

  # -----------------------------------------------------------------------------
  # ⛽ Pipelines: Request Processing
  # -----------------------------------------------------------------------------

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {EligenicAppWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # -----------------------------------------------------------------------------
  # 🏔️ Scopes: User Interface
  # -----------------------------------------------------------------------------

  scope "/", EligenicAppWeb do
    pipe_through(:browser)

    live("/", AgentLive, :home)
  end
end
