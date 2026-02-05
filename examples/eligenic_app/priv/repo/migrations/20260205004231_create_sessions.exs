defmodule EligenicApp.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:user_id, :string)
      add(:agent_id, :string)
      add(:status, :string)
      add(:config, :map)
      add(:metadata, :map)

      timestamps(type: :utc_datetime)
    end

    create(index(:sessions, [:user_id]))
    create(index(:sessions, [:agent_id]))
  end
end
