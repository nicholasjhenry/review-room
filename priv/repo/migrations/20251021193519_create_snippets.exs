defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :code, :text, null: false
      add :title, :string, size: 200
      add :description, :text
      add :language, :string, size: 50
      add :visibility, :string, null: false, default: "private"
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:snippets, [:id])
    create index(:snippets, [:user_id])
    create index(:snippets, [:visibility])
    create index(:snippets, [:language])
    create index(:snippets, [:inserted_at])
    create index(:snippets, [:visibility, :inserted_at])
  end
end
