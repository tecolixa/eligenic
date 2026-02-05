defmodule EligenicApp.Knowledge.Document do
  @moduledoc """
  Ecto Schema for knowledge documents.
  """
  use Ecto.Schema
  import Ecto.Changeset

  # -----------------------------------------------------------------------------
  # 🍱 Schema: Data Model
  # -----------------------------------------------------------------------------

  schema "documents" do
    field(:title, :string)
    field(:content, :string)
    field(:tags, {:array, :string}, default: [])

    timestamps()
  end

  # -----------------------------------------------------------------------------
  # 📝 Persistence: Changesets
  # -----------------------------------------------------------------------------

  @doc "Builds a changeset for document persistence with validation."
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:title, :content, :tags])
    |> validate_required([:title, :content])
  end
end
