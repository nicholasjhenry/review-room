defmodule ReviewRoom.Snippets.Snippet do
  @moduledoc """
  Schema for code snippets.
  """
  use ReviewRoom, :record

  @typedoc """
  ## Fields

  A snippet has these fields:

  - `id` - unique identifier
  - `code` - the code content (max 1MB)
  - `language` - programming language identifier
  - `title` - optional title for the snippet
  - `description` - optional description
  - `visibility` - privacy level (private or public)
  - `tags` - array of tag names (max 10)
  - `user_id` - foreign key to the owning user
  - `inserted_at` - creation timestamp
  - `updated_at` - last modification timestamp

  ## Associations

  A snippet associates with:

  - `user` - belongs to a User (owner)
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          code: String.t() | nil,
          language: String.t() | nil,
          title: String.t() | nil,
          description: String.t() | nil,
          visibility: String.t(),
          tags: [String.t()],
          user_id: Ecto.UUID.t() | nil,
          user: ReviewRoom.Accounts.User.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  # Values configured via config/config.exs
  @max_code_size Application.compile_env(:review_room, :snippet_max_size, 1_048_576)
  @max_tags Application.compile_env(:review_room, :snippet_max_tags, 10)
  @visibility_values ~w(private public)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "snippets" do
    field :code, :string
    field :language, :string
    field :title, :string
    field :description, :string
    field :visibility, :string, default: "private"
    field :tags, {:array, :string}, default: []

    belongs_to :user, ReviewRoom.Accounts.User

    timestamps()
  end

  @doc false
  @spec changeset(t(), Attrs.t()) :: Ecto.Changeset.t(t())
  def changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:code, :language, :title, :description, :visibility, :tags])
    |> validate_required([:code, :language])
    |> validate_length(:code,
      max: @max_code_size,
      message: "Snippet content is too large. Maximum size is 1MB."
    )
    |> validate_length(:title, max: 255)
    |> validate_inclusion(:visibility, @visibility_values)
    |> validate_language()
    |> sanitize_html_fields()
    |> normalize_tags()
    |> validate_tags_count()
  end

  defp validate_language(changeset) do
    # Validate against configured language list
    supported_languages =
      Application.get_env(:review_room, :snippet_languages, [])
      |> Enum.map(& &1.code)

    validate_inclusion(changeset, :language, supported_languages,
      message: "Selected language is not supported."
    )
  end

  defp sanitize_html_fields(changeset) do
    changeset
    |> update_change(:title, &HtmlSanitizeEx.strip_tags/1)
    |> update_change(:description, &HtmlSanitizeEx.strip_tags/1)
  end

  defp normalize_tags(changeset) do
    case get_change(changeset, :tags) do
      nil ->
        changeset

      tags when is_list(tags) ->
        normalized =
          tags
          |> Enum.reduce([], fn tag, acc ->
            trimmed =
              tag
              |> to_string()
              |> String.trim()

            cond do
              trimmed == "" -> acc
              trimmed in acc -> acc
              true -> [trimmed | acc]
            end
          end)
          |> Enum.reverse()

        put_change(changeset, :tags, normalized)

      _ ->
        changeset
    end
  end

  defp validate_tags_count(changeset) do
    case get_change(changeset, :tags) do
      tags when is_list(tags) and length(tags) > @max_tags ->
        add_error(changeset, :tags, "Maximum #{@max_tags} tags allowed")

      _ ->
        changeset
    end
  end
end
