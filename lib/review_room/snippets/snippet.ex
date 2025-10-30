defmodule ReviewRoom.Snippets.Snippet do
  @moduledoc """
  Ecto schema for persisted snippets staged through the buffer.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ReviewRoom.Accounts.User

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
          id: Ecto.UUID.t(),
          title: String.t(),
          description: String.t(),
          body: String.t(),
          syntax: String.t(),
          tags: [String.t()],
          visibility: String.t(),
          buffer_token: Ecto.UUID.t(),
          queued_at: DateTime.t(),
          persisted_at: DateTime.t() | nil,
          author_id: Ecto.UUID.t(),
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

  @doc false
  def creation_changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:title, :description, :body, :syntax, :tags, :visibility, :author_id])
    |> validate_required([:title, :description, :body, :syntax, :visibility, :author_id])
    |> validate_length(:title, max: @title_max)
    |> validate_length(:description, max: @description_max)
    |> validate_length(:body, max: @body_max)
    |> put_default_tags()
  end

  @doc false
  def base_changeset(snippet, attrs) do
    snippet
    |> creation_changeset(attrs)
    |> cast(attrs, [:buffer_token, :queued_at, :persisted_at])
    |> validate_required([:buffer_token, :queued_at])
  end

  defp put_default_tags(%Ecto.Changeset{} = changeset) do
    case fetch_change(changeset, :tags) do
      :error -> put_change(changeset, :tags, [])
      {:ok, nil} -> put_change(changeset, :tags, [])
      _ -> changeset
    end
  end
end
