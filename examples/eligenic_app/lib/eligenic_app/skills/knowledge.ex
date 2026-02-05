defmodule EligenicApp.Skills.Knowledge do
  @moduledoc """
  Skill for managing and searching the persistent knowledge base.
  """
  @behaviour Eligenic.Skill

  # -----------------------------------------------------------------------------
  # 🛠️ Definition: Skill Contract
  # -----------------------------------------------------------------------------

  @impl true
  def tools do
    [
      %{
        type: "function",
        function: %{
          name: "knowledge.store",
          description: "Stores a new piece of information or a note in the knowledge base.",
          parameters: %{
            type: "object",
            properties: %{
              title: %{type: "string", description: "The title of the note"},
              content: %{type: "string", description: "The main content of the note"},
              tags: %{type: "array", items: %{type: "string"}, description: "Optional tags"}
            },
            required: ["title", "content"]
          }
        }
      },
      %{
        type: "function",
        function: %{
          name: "knowledge.search",
          description: "Searches for information in the knowledge base.",
          parameters: %{
            type: "object",
            properties: %{
              query: %{type: "string", description: "The search query (title or content)"}
            },
            required: ["query"]
          }
        }
      }
    ]
  end

  # -----------------------------------------------------------------------------
  # ⚡ Execution: Tool Dispatch
  # -----------------------------------------------------------------------------

  @impl true
  def execute("knowledge.store", args) do
    case EligenicApp.Knowledge.create_document(args) do
      {:ok, doc} -> "Successfully stored document: #{doc.title}"
      {:error, changeset} -> "Failed to store document: #{inspect(changeset.errors)}"
    end
  end

  @impl true
  def execute("knowledge.search", %{"query" => query}) do
    docs = EligenicApp.Knowledge.search_documents(query)

    if Enum.empty?(docs) do
      "No matching documents found."
    else
      docs
      |> Enum.map(fn d -> "[#{d.title}] #{d.content}" end)
      |> Enum.join("\n\n")
    end
  end
end
