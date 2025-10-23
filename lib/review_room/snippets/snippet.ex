defmodule ReviewRoom.Snippets.Snippet do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: String.t() | nil,
          code: String.t() | nil,
          title: String.t() | nil,
          description: String.t() | nil,
          language: String.t() | nil,
          visibility: :public | :private,
          user_id: binary() | nil,
          user: ReviewRoom.Accounts.User.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :binary_id

  @supported_languages [
    nil,
    "elixir",
    "erlang",
    "javascript",
    "typescript",
    "python",
    "ruby",
    "go",
    "rust",
    "java",
    "kotlin",
    "swift",
    "c",
    "cpp",
    "csharp",
    "php",
    "sql",
    "html",
    "css",
    "scss",
    "json",
    "yaml",
    "markdown",
    "shell",
    "bash",
    "dockerfile",
    "xml",
    "plaintext"
  ]

  schema "snippets" do
    field :code, :string
    field :title, :string
    field :description, :string
    field :language, :string
    field :visibility, Ecto.Enum, values: [:public, :private], default: :private

    belongs_to :user, ReviewRoom.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new snippet.
  """
  @spec create_changeset(t(), map(), ReviewRoom.Accounts.User.t() | nil) :: Ecto.Changeset.t()
  def create_changeset(snippet, attrs, user \\ nil) do
    snippet
    |> cast(attrs, [:code, :title, :description, :language, :visibility])
    |> validate_required([:code])
    |> validate_length(:title, max: 200)
    |> validate_inclusion(:language, supported_languages())
    |> validate_inclusion(:visibility, [:public, :private])
    |> put_user(user)
    |> generate_id()
    |> unique_constraint(:id)
  end

  @doc """
  Changeset for updating an existing snippet.
  Only owner can update. Anonymous snippets cannot be updated.
  """
  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:code, :title, :description, :language, :visibility])
    |> validate_required([:code])
    |> validate_length(:title, max: 200)
    |> validate_inclusion(:language, supported_languages())
    |> validate_inclusion(:visibility, [:public, :private])
  end

  defp generate_id(changeset) do
    case get_field(changeset, :id) do
      nil -> put_change(changeset, :id, Nanoid.generate(8))
      _id -> changeset
    end
  end

  defp put_user(changeset, nil), do: changeset
  defp put_user(changeset, user), do: put_assoc(changeset, :user, user)

  @doc "Supported language identifiers for snippets."
  @spec supported_languages() :: [String.t() | nil]
  def supported_languages, do: @supported_languages
end
