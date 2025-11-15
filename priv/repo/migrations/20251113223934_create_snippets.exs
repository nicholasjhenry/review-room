defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false, size: 200
      add :description, :text
      add :code, :text, null: false
      add :language, :string
      add :visibility, :string, null: false, default: "private"
      add :tags, {:array, :string}, default: []
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:snippets, [:user_id])
    create index(:snippets, [:visibility])
    create index(:snippets, [:inserted_at])
    # GIN index for array queries
    create index(:snippets, [:tags], using: :gin)
  end
end
