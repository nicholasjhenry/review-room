defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  @visibility_values ~w(personal team organization)

  def change do
    create table(:snippets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false, size: 120
      add :description, :string, null: false, size: 500
      add :body, :text, null: false
      add :syntax, :string, null: false
      add :tags, {:array, :string}, default: [], null: false
      add :visibility, :string, null: false
      add :buffer_token, :binary_id, null: false
      add :queued_at, :utc_datetime, null: false
      add :persisted_at, :utc_datetime
      add :author_id, references(:users, type: :binary_id, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:snippets, [:buffer_token])
    create index(:snippets, [:author_id, :visibility])
    create index(:snippets, [:tags], using: :gin)
    create index(:snippets, [:persisted_at], where: "persisted_at IS NULL")

    execute(
      visibility_constraint(),
      "ALTER TABLE snippets DROP CONSTRAINT IF EXISTS snippets_visibility_check"
    )
  end

  defp visibility_constraint do
    values =
      @visibility_values
      |> Enum.map(&"'#{&1}'")
      |> Enum.join(", ")

    """
    ALTER TABLE snippets
    ADD CONSTRAINT snippets_visibility_check
    CHECK (visibility IN (#{values}))
    """
  end
end
