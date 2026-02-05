defmodule EligenicAppWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This module centralizes imports, aliases, and common macro injections
  to keep web components lean and focused.
  """

  # -----------------------------------------------------------------------------
  # 🌐 Routing & Assets: Discovery
  # -----------------------------------------------------------------------------

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  # -----------------------------------------------------------------------------
  # 🏔️ LiveView & Components: UI Hierarchy
  # -----------------------------------------------------------------------------

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  # -----------------------------------------------------------------------------
  # 🎮 Controllers & Channels: Logic Flow
  # -----------------------------------------------------------------------------

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  # -----------------------------------------------------------------------------
  # 🛠️ Helpers: Internal Utilities
  # -----------------------------------------------------------------------------

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import EligenicAppWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias EligenicAppWeb.Layouts

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: EligenicAppWeb.Endpoint,
        router: EligenicAppWeb.Router,
        statics: EligenicAppWeb.static_paths()
    end
  end

  # -----------------------------------------------------------------------------
  # 🚀 Entry Hook: Activation
  # -----------------------------------------------------------------------------

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
