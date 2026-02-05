defmodule EligenicApp.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add(:title, :string, null: false)
      add(:content, :text, null: false)
      add(:tags, {:array, :string}, default: [])

      timestamps()
    end

    create(index(:documents, [:title]))
  end
end
