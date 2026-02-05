defmodule EligenicAppWeb.PageController do
  use EligenicAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
