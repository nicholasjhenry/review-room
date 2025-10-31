defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    # Drop existing snippets table if it exists
    drop_if_exists table(:snippets)

    create table(:snippets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :code, :text, null: false
      add :language, :string, size: 50, null: false
      add :title, :string, size: 255
      add :description, :text
      add :visibility, :string, size: 20, null: false, default: "private"
      add :tags, {:array, :string}, null: false, default: []

      timestamps()
    end

    create index(:snippets, [:user_id])
    create index(:snippets, [:visibility])
    create index(:snippets, [:language])
    create index(:snippets, [:tags], using: :gin)
  end
end
