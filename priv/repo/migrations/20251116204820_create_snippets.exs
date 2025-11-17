defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets) do
      add :slug, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :code, :text, null: false
      add :language, :string
      add :tags, {:array, :string}, default: []
      add :visibility, :string, null: false, default: "private"
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:snippets, [:slug])
    create index(:snippets, [:user_id, :visibility, :inserted_at])
    create index(:snippets, [:visibility, :inserted_at])
    create index(:snippets, [:tags], using: "GIN")
  end
end
