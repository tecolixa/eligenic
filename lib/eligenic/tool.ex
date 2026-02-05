defmodule Eligenic.Tool do
  @moduledoc """
  Engine for introspecting Elixir functions and generating LLM-compatible tool definitions (JSON Schema).
  """

  # -----------------------------------------------------------------------------
  # 🕵️ Introspection: Public API
  # -----------------------------------------------------------------------------

  @doc """
  Introspects a module and function to build a complete JSON schema description for an LLM.
  """
  def introspect(module, function_name) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        find_function_doc(docs, function_name)
        |> build_tool_definition(module, function_name)

      {:error, _} = err ->
        err
    end
  end

  # -----------------------------------------------------------------------------
  # 🏗️ Definition Builders: Internal
  # -----------------------------------------------------------------------------

  defp find_function_doc(docs, function_name) do
    Enum.find(docs, fn
      {{:function, name, _arity}, _, _, _, _} when name == function_name -> true
      _ -> false
    end)
  end

  defp build_tool_definition(nil, module, function_name) do
    {:error, "Function #{function_name} not found or has no docs in #{inspect(module)}"}
  end

  defp build_tool_definition({{:function, name, arity}, _, _, doc_content, _}, module, _) do
    description = extract_description(doc_content)
    params = get_params_from_spec(module, name, arity)

    {:ok,
     %{
       type: "function",
       function: %{
         name: "#{inspect(module)}.#{name}",
         description: description,
         parameters: %{
           type: "object",
           properties: params.properties,
           required: params.required
         }
       }
     }}
  end

  # -----------------------------------------------------------------------------
  # 🔍 Spec Parsing: Type Extraction
  # -----------------------------------------------------------------------------

  defp get_params_from_spec(module, name, arity) do
    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} ->
        spec = Enum.find(specs, fn {{n, a}, _} -> n == name and a == arity end)
        parse_spec(spec, arity)

      _ ->
        default_params(arity)
    end
  end

  defp parse_spec({_, [spec_content]}, _arity) do
    # Resilient extraction of argument types from @spec
    case spec_content do
      {_ret_type, args_types} when is_list(args_types) ->
        properties =
          for {type, i} <- Enum.with_index(args_types, 1), into: %{} do
            {"arg#{i}", %{type: map_type(type), description: "Argument #{i}"}}
          end

        %{properties: properties, required: Map.keys(properties)}

      _ ->
        %{properties: %{}, required: []}
    end
  end

  defp parse_spec(nil, arity), do: default_params(arity)

  # Type mapping for JSON Schema compatibility
  defp map_type({:integer, _, _}), do: "integer"
  defp map_type({:string, _, _}), do: "string"
  defp map_type({:boolean, _, _}), do: "boolean"
  defp map_type({:remote_type, _, [{:atom, _, String}, {:atom, _, :t}, []]}), do: "string"
  defp map_type({:ann_type, _, [_, type]}), do: map_type(type)
  defp map_type(_), do: "string"

  defp default_params(arity) do
    properties =
      for i <- 1..arity, into: %{} do
        {"arg#{i}", %{type: "string", description: "Argument #{i}"}}
      end

    %{properties: properties, required: Map.keys(properties)}
  end

  defp extract_description(%{"en" => doc}), do: doc
  defp extract_description(_), do: "No description provided."

  # -----------------------------------------------------------------------------
  # ⚡ Execution: Tool Dispatch
  # -----------------------------------------------------------------------------

  @doc """
  Executes a tool call by mapping map-based arguments to positional Elixir calls.
  """
  def execute(module, function, args) when is_map(args) do
    arg_list = Map.values(args)
    apply(module, function, arg_list)
  rescue
    e -> {:error, Exception.message(e)}
  end
end
