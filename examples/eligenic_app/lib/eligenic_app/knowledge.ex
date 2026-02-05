defmodule EligenicApp.Knowledge do
  @moduledoc """
  Internal API for managing persistent knowledge documents.
  Provides CRUD operations and full-text search capabilities.
  """
  import Ecto.Query, warn: false
  alias EligenicApp.Repo
  alias EligenicApp.Knowledge.Document

  # -----------------------------------------------------------------------------
  # 🍱 Data Access: CRUD
  # -----------------------------------------------------------------------------

  @doc "Lists all documents in the knowledge base."
  def list_documents do
    Repo.all(Document)
  end

  @doc "Retrieves a single document by its UUID."
  def get_document!(id), do: Repo.get!(Document, id)

  @doc "Persists a new document and its metadata."
  def create_document(attrs \\ %{}) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end

  # -----------------------------------------------------------------------------
  # 🔍 Discovery: Search
  # -----------------------------------------------------------------------------

  @doc "Searches documents by title or content using case-insensitive partial match."
  def search_documents(query) do
    search_term = "%#{query}%"

    from(d in Document,
      where: ilike(d.title, ^search_term) or ilike(d.content, ^search_term)
    )
    |> Repo.all()
  end
end
