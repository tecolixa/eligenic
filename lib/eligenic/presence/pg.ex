defmodule Eligenic.Presence.PG do
  @moduledoc """
  The default `Eligenic.Presence` implementation utilizing native Erlang `:pg`.

  `:pg` (Process Groups) natively tracks processes across the Erlang cluster mesh,
  ensuring PIDs are broadcasted globally.
  """
  @behaviour Eligenic.Presence

  @pg_scope :eligenic_cluster
  @pg_group :active_agents

  @impl true
  def track(pid, _metadata \\ %{}) do
    :ok = :pg.join(@pg_scope, @pg_group, pid)
    :ok
  end

  @impl true
  def list_active do
    :pg.get_members(@pg_scope, @pg_group)
  end
end
