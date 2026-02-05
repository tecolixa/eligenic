defmodule Eligenic.Adapters.Gemini do
  @behaviour Eligenic.Adapter
  require Logger

  # -----------------------------------------------------------------------------
  # 🌐 Public API: Adapter Implementation
  # -----------------------------------------------------------------------------

  @doc """
  Performs chat completion using the Google Gemini API.
  Translates Eligenic's history into Gemini's 'contents' format.
  """
  @impl true
  def chat_completion(messages, opts \\ []) do
    api_key = Keyword.get(opts, :api_key) || Application.get_env(:eligenic, :gemini_api_key)

    model =
      Keyword.get(opts, :model) ||
        Application.get_env(:eligenic, :gemini_model, "gemini-1.5-flash")

    tools = Keyword.get(opts, :tools, [])

    if is_nil(api_key) or api_key == "" do
      Logger.error("Gemini API Key is missing! Please set GEMINI_API_KEY in your environment.")
      {:error, :missing_api_key}
    else
      url =
        "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}"

      body = %{
        contents: Enum.map(messages, &format_message/1),
        tools: format_tools(tools)
      }

      case Req.post(url, json: body) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          Logger.debug("Gemini API raw response: #{inspect(body)}")
          parse_response(body)

        {:ok, %Req.Response{status: status, body: body} = resp} ->
          Logger.error("Gemini API error (Status #{status}): #{inspect(body)}")
          Logger.debug("Full Gemini response object: #{inspect(resp)}")
          {:error, "Gemini API error: #{status}"}

        {:error, reason} ->
          Logger.error("Gemini request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @doc "Not implemented for Gemini yet."
  @impl true
  def structured_completion(_messages, _schema, _opts) do
    {:error, :not_implemented}
  end

  # -----------------------------------------------------------------------------
  # 📥 Message Formatting: API Translation
  # -----------------------------------------------------------------------------

  defp format_message(%{role: "user", content: content}) do
    %{role: "user", parts: [%{text: content}]}
  end

  defp format_message(%{role: "assistant", raw_parts: parts}) when is_list(parts) do
    # Perfect preservation: Use exactly what the model gave us during the initial turn
    %{role: "model", parts: parts}
  end

  defp format_message(%{role: "assistant", content: content, tool_calls: tool_calls})
       when not is_nil(tool_calls) do
    text_parts = if content && content != "", do: [%{text: content}], else: []

    tool_parts =
      Enum.map(tool_calls, fn call ->
        base = %{name: call.function.name, args: call.function.arguments}

        # Handling thought signatures with API-compatible camelCase
        call_map =
          if sig = call[:thought_signature],
            do: Map.put(base, :thoughtSignature, sig),
            else: base

        %{functionCall: call_map}
      end)

    %{role: "model", parts: text_parts ++ tool_parts}
  end

  defp format_message(%{role: "assistant", content: content}) do
    %{role: "model", parts: [%{text: content}]}
  end

  defp format_message(%{role: "assistant", tool_calls: tool_calls}) do
    %{
      role: "model",
      parts:
        Enum.map(tool_calls, fn call ->
          base = %{name: call.function.name, args: call.function.arguments}

          call_map =
            if sig = call[:thought_signature],
              do: Map.put(base, :thoughtSignature, sig),
              else: base

          %{functionCall: call_map}
        end)
    }
  end

  defp format_message(%{role: "tool", content: content, tool_call_id: id}) do
    %{
      role: "function",
      parts: [%{functionResponse: %{name: id, response: %{content: content}}}]
    }
  end

  # -----------------------------------------------------------------------------
  # 🛠️ Tool Formatting: Schema Translation
  # -----------------------------------------------------------------------------

  defp format_tools([]), do: nil

  defp format_tools(tools) do
    [
      %{
        functionDeclarations:
          Enum.map(tools, fn tool ->
            %{
              name: tool.function.name,
              description: tool.function.description,
              parameters: tool.function.parameters
            }
          end)
      }
    ]
  end

  # -----------------------------------------------------------------------------
  # 📤 Response Parsing: Internal Extraction
  # -----------------------------------------------------------------------------

  defp parse_response(%{"candidates" => [%{"content" => %{"parts" => parts}} | _]}) do
    text_part = Enum.find(parts, &Map.has_key?(&1, "text"))
    tool_parts = Enum.filter(parts, &Map.has_key?(&1, "functionCall"))

    content = if text_part, do: text_part["text"], else: nil

    tool_calls =
      if tool_parts != [] do
        Enum.map(tool_parts, fn %{"functionCall" => call} ->
          %{
            id: call["name"],
            type: "function",
            function: %{
              name: call["name"],
              arguments: call["args"]
            },
            # Support both camelCase from API and internal snake_case
            thought_signature: call["thoughtSignature"] || call["thought_signature"]
          }
        end)
      else
        nil
      end

    case {content, tool_calls} do
      {nil, nil} ->
        {:error, "Empty response from Gemini"}

      {text, nil} ->
        {:ok, %{role: "assistant", content: text, raw_parts: parts}}

      {text, tools} ->
        {:ok, %{role: "assistant", content: text, tool_calls: tools, raw_parts: parts}}
    end
  end

  defp parse_response(_) do
    {:error, "Empty or invalid response from Gemini"}
  end
end
