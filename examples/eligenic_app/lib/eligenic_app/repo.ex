defmodule EligenicApp.Repo do
  @moduledoc """
  Ecto Repository for the Eligenic reference implementation.
  """
  use Ecto.Repo,
    otp_app: :eligenic_app,
    adapter: Ecto.Adapters.Postgres
end
