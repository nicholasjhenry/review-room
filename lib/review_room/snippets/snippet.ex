defmodule ReviewRoom.Snippets.Snippet do
  @moduledoc """
  Ecto schema for persisted snippets staged through the buffer.
  """

  use ReviewRoom, :record

  alias ReviewRoom.Accounts.User
  alias ReviewRoom.Snippets.SyntaxRegistry
  alias ReviewRoom.Snippets.TagCatalog

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @typedoc """
  ## Fields

  A Snippet has these fields:

  - `:id`
  - `:title`
  - `:description`
  - `:body`
  - `:syntax`
  - `:tags`
  - `:visibility`
  - `:buffer_token`
  - `:queued_at`
  - `:persisted_at`
  - `:author_id`
  - `:inserted_at`
  - `:updated_at`

  ## Associations

  A Snippet associates with:

  - `:author`
  """
  @type t :: %__MODULE__{
          id: Identifier.t(),
          title: String.t(),
          description: String.t(),
          body: String.t(),
          syntax: String.t(),
          tags: [String.t()],
          visibility: String.t(),
          buffer_token: Identifier.t(),
          queued_at: DateTime.t(),
          persisted_at: DateTime.t() | nil,
          author_id: Identifier.t(),
          author: User.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "snippets" do
    field :title, :string
    field :description, :string
    field :body, :string
    field :syntax, :string
    field :tags, {:array, :string}, default: []
    field :visibility, :string
    field :buffer_token, :binary_id
    field :queued_at, :utc_datetime
    field :persisted_at, :utc_datetime

    belongs_to :author, User

    timestamps(type: :utc_datetime)
  end

  @title_max 120
  @description_max 500
  @body_max 10_000
  @tags_max 10
  @allowed_visibility_values ~w(personal team organization)

  @doc false
  def creation_changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:title, :description, :body, :syntax, :tags, :visibility])
    |> validate_required([:title, :description, :body])
    |> validate_length(:title, max: @title_max)
    |> validate_length(:description, max: @description_max)
    |> validate_length(:body, max: @body_max)
    |> put_default_syntax()
    |> validate_syntax()
    |> normalize_and_validate_tags()
    |> put_default_visibility()
  end

  @doc false
  def put_author_changeset(changeset, %User{} = author) do
    changeset
    |> put_assoc(:author, author)
  end

  @doc false
  def base_changeset(snippet, attrs) do
    snippet
    |> creation_changeset(attrs)
    |> cast(attrs, [:buffer_token, :queued_at, :persisted_at, :author_id])
    |> validate_required([:buffer_token, :queued_at, :author_id])
  end

  defp put_default_syntax(%Ecto.Changeset{} = changeset) do
    case fetch_change(changeset, :syntax) do
      :error -> put_change(changeset, :syntax, SyntaxRegistry.default())
      {:ok, nil} -> put_change(changeset, :syntax, SyntaxRegistry.default())
      {:ok, ""} -> put_change(changeset, :syntax, SyntaxRegistry.default())
      _ -> changeset
    end
  end

  defp validate_syntax(%Ecto.Changeset{} = changeset) do
    validate_change(changeset, :syntax, fn :syntax, syntax ->
      if SyntaxRegistry.supported?(syntax) do
        []
      else
        [syntax: "is not supported"]
      end
    end)
  end

  defp normalize_and_validate_tags(%Ecto.Changeset{} = changeset) do
    changeset
    |> normalize_tags()
    |> validate_tags_count()
  end

  defp normalize_tags(%Ecto.Changeset{} = changeset) do
    case fetch_change(changeset, :tags) do
      :error ->
        put_change(changeset, :tags, [])

      {:ok, nil} ->
        put_change(changeset, :tags, [])

      {:ok, tags} when is_list(tags) ->
        normalized = TagCatalog.normalize_list(tags)
        put_change(changeset, :tags, normalized)

      _ ->
        changeset
    end
  end

  defp validate_tags_count(%Ecto.Changeset{} = changeset) do
    validate_change(changeset, :tags, fn :tags, tags ->
      if length(tags) <= @tags_max do
        []
      else
        [tags: "cannot have more than #{@tags_max} tags"]
      end
    end)
  end

  defp put_default_visibility(%Ecto.Changeset{} = changeset) do
    changeset =
      case fetch_change(changeset, :visibility) do
        :error -> put_change(changeset, :visibility, "personal")
        {:ok, nil} -> put_change(changeset, :visibility, "personal")
        {:ok, ""} -> put_change(changeset, :visibility, "personal")
        _ -> changeset
      end

    validate_inclusion(changeset, :visibility, @allowed_visibility_values)
  end
end
