defmodule ReviewRoom.Snippets.Snippet do
  @moduledoc """
  Schema for code snippets created by developers.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          title: String.t(),
          description: String.t() | nil,
          code: String.t(),
          language: String.t() | nil,
          visibility: visibility_type(),
          tags: [String.t()],
          user_id: Ecto.UUID.t(),
          user: Ecto.Association.NotLoaded.t() | ReviewRoom.Accounts.User.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type visibility_type :: :private | :public | :unlisted

  schema "snippets" do
    field :title, :string
    field :description, :string
    field :code, :string
    field :language, :string
    field :visibility, Ecto.Enum, values: [:private, :public, :unlisted], default: :private
    field :tags, {:array, :string}, default: []

    belongs_to :user, ReviewRoom.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating a snippet.

  ## Fields
  - `title` (required): 1-200 characters
  - `description` (optional): max 2000 characters
  - `code` (required): 1 character to 500KB
  - `language` (optional): must be from supported languages list
  - `visibility` (optional): defaults to :private
  - `tags` (optional): array of tag strings, defaults to empty array

  ## Examples

      iex> changeset(%Snippet{}, %{title: "Auth Helper", code: "def authenticate...", tags: ["elixir", "auth"]})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Snippet{}, %{title: "", code: ""})
      %Ecto.Changeset{valid?: false}
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:title, :description, :code, :language, :visibility, :tags])
    |> validate_required([:title, :code])
    |> validate_length(:title, min: 1, max: 200)
    |> validate_length(:description, max: 2000)
    |> validate_length(:code, min: 1, max: 512_000)
    |> validate_inclusion(:language, supported_languages(), allow_nil: true)
    |> normalize_tags()
  end

  defp normalize_tags(changeset) do
    case get_change(changeset, :tags) do
      nil ->
        changeset

      tags when is_list(tags) ->
        normalized =
          tags
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.downcase/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()

        put_change(changeset, :tags, normalized)

      tags_string when is_binary(tags_string) ->
        # Support comma-separated string input from forms
        normalized =
          tags_string
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.downcase/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()

        put_change(changeset, :tags, normalized)
    end
  end

  defp supported_languages do
    Application.get_env(:review_room, :supported_languages, [])
    |> Enum.map(fn {code, _name} -> code end)
  end
end
