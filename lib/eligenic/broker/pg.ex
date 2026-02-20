defmodule Eligenic.Broker.PG do
  @moduledoc """
  The default `Eligenic.Broker` implementation utilizing native Erlang `:pg`.

  `:pg` (Process Groups) natively clusters processes and automatically manages
  subscriptions without needing an external dependency like `Phoenix.PubSub`.
  This enables out-of-the-box swarm topologies for Agents.
  """
  @behaviour Eligenic.Broker

  # Use a specific scope to isolate Eligenic events from other app groups
  @pg_scope :eligenic_broker_scope

  @impl true
  def request(target_id, message) do
    # Direct requests fallback to Eligenic's established Point-to-Point lookup via Registry
    Eligenic.Agent.call(target_id, message)
  end

  @impl true
  def publish(topic, event) do
    # Ensure the group exists
    :pg.join(@pg_scope, topic, [])

    # Broadcast to all pids in the group
    for pid <- :pg.get_members(@pg_scope, topic) do
      send(pid, {:eligenic_pubsub, topic, event})
    end

    :ok
  end

  @impl true
  def subscribe(topic) do
    :ok = :pg.join(@pg_scope, topic, self())
    :ok
  end

  @impl true
  def unsubscribe(topic) do
    :ok = :pg.leave(@pg_scope, topic, self())
    :ok
  end
end
