defmodule Eligenic.Broker do
  @moduledoc """
  The communication behaviour for Agent-to-Agent interaction in Eligenic.

  By abstracting the broker, Eligenic can run highly decoupled pub/sub
  swarms using native Erlang `:pg` (Process Groups) by default, or connect safely
  to enterprise event buses like Kafka, Redis, or RabbitMQ without altering
  the core Agent logic.
  """

  @doc """
  Sends a directed synchronous message to a specific agent identity.
  """
  @callback request(target_id :: String.t(), message :: any()) ::
              {:ok, result :: any()} | {:error, reason :: any()}

  @doc """
  Broadcasts an asynchronous event to a specific topic for any subscribed agents.
  """
  @callback publish(topic :: String.t(), event :: any()) :: :ok | {:error, reason :: any()}

  @doc """
  Subscribes the current agent process to a specific topic.
  """
  @callback subscribe(topic :: String.t()) :: :ok | {:error, reason :: any()}

  @doc """
  Unsubscribes the current agent process from a specific topic.
  """
  @callback unsubscribe(topic :: String.t()) :: :ok | {:error, reason :: any()}
end
