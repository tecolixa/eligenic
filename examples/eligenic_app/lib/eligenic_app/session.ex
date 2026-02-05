defmodule EligenicApp.Session do
  @moduledoc """
  Ecto-backed implementation of Eligenic.Session for the reference app.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @behaviour Eligenic.Session
  alias EligenicApp.Repo

  # -----------------------------------------------------------------------------
  # 🏔️ Schema: Data Model
  # -----------------------------------------------------------------------------

  @primary_key {:id, :string, autogenerate: false}
  schema "sessions" do
    field(:user_id, :string)
    field(:agent_id, :string)
    field(:status, :string, default: "active")
    field(:config, :map, default: %{})
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  # -----------------------------------------------------------------------------
  # 🏗️ Persistence: Changesets
  # -----------------------------------------------------------------------------

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:id, :user_id, :agent_id, :status, :config, :metadata])
    |> validate_required([:id, :agent_id])
  end

  # -----------------------------------------------------------------------------
  # 📜 Callbacks: Eligenic.Session Behavior
  # -----------------------------------------------------------------------------

  @impl true
  def get_session(id) do
    case Repo.get(__MODULE__, id) do
      nil -> {:error, :not_found}
      session -> {:ok, session}
    end
  end

  @impl true
  def create_session(attrs) do
    # Auto-generate IDs if missing
    attrs = Map.put_new(attrs, :id, "sess_" <> MnemonicSlugs.generate())
    attrs = Map.put_new(attrs, :agent_id, "agent_" <> MnemonicSlugs.generate())

    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @impl true
  def update_session(session, attrs) do
    session
    |> changeset(attrs)
    |> Repo.update()
  end

  @impl true
  def list_sessions(user_id) do
    query = from(s in __MODULE__, where: s.user_id == ^user_id)
    {:ok, Repo.all(query)}
  end
end

defmodule MnemonicSlugs do
  @moduledoc false
  def generate do
    :erlang.unique_integer([:positive]) |> Integer.to_string(36) |> String.downcase()
  end
end
