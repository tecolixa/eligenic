defmodule Eligenic.Adapters.Mock do
  @moduledoc """
  Mock adapter for testing and local development without LLM access.
  """
  @behaviour Eligenic.Adapter

  # -----------------------------------------------------------------------------
  # 🛠️ Implementation: Chat & Structure
  # -----------------------------------------------------------------------------

  @impl true
  def chat_completion(messages, _opts) do
    last_msg = List.last(messages)

    cond do
      last_msg && String.contains?(last_msg.content || "", "hello") ->
        {:ok, %{role: "assistant", content: "Hello! How can I help you?", tool_calls: nil}}

      true ->
        {:ok, %{role: "assistant", content: "I am a mock AI.", tool_calls: nil}}
    end
  end

  @impl true
  def structured_completion(_messages, _schema, _opts) do
    {:ok, %{}}
  end
end
