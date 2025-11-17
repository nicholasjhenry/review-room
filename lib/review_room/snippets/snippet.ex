defmodule ReviewRoom.Snippets.Snippet do
  @moduledoc """
  Schema for code snippets created by users.
  """
  use ReviewRoom, :record

  import Ecto.Changeset

  @type id :: pos_integer()

  @typedoc """
  A code snippet with title, code content, optional description, language, tags, and visibility settings.
  """
  @type t :: %__MODULE__{
          id: id() | nil,
          slug: String.t() | nil,
          title: String.t() | nil,
          description: String.t() | nil,
          code: String.t() | nil,
          language: String.t() | nil,
          tags: [String.t()],
          visibility: :private | :public | :unlisted,
          user_id: binary() | nil,
          user: ReviewRoom.Accounts.User.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "snippets" do
    field :slug, :string
    field :title, :string
    field :description, :string
    field :code, :string
    field :language, :string
    field :tags, {:array, :string}, default: []
    field :visibility, Ecto.Enum, values: [:private, :public, :unlisted], default: :private

    belongs_to :user, ReviewRoom.Accounts.User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:title, :description, :code, :language, :visibility, :tags])
    |> validate_required([:title, :code])
    |> validate_length(:title, min: 1, max: 200)
    |> validate_length(:description, max: 2000)
    |> validate_length(:code, max: 512_000, count: :bytes)
    |> validate_inclusion(:language, supported_languages(), allow_nil: true)
    |> validate_inclusion(:visibility, [:private, :public, :unlisted])
    |> normalize_tags()
    |> validate_tags()
    |> put_slug()
    |> unique_constraint(:slug)
  end

  defp normalize_tags(changeset) do
    case get_change(changeset, :tags) do
      nil ->
        changeset

      tags when is_list(tags) ->
        normalized =
          tags
          |> Enum.map(&String.downcase/1)
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()

        put_change(changeset, :tags, normalized)

      _ ->
        changeset
    end
  end

  defp validate_tags(changeset) do
    case get_field(changeset, :tags) do
      nil ->
        changeset

      tags when is_list(tags) ->
        Enum.reduce(tags, changeset, fn tag, acc ->
          cond do
            String.length(tag) > 50 ->
              add_error(acc, :tags, "tag '#{tag}' is too long (max 50 characters)")

            !Regex.match?(~r/^[a-z0-9-]+$/, tag) ->
              add_error(
                acc,
                :tags,
                "tag '#{tag}' contains invalid characters (only lowercase letters, numbers, hyphens)"
              )

            true ->
              acc
          end
        end)

      _ ->
        changeset
    end
  end

  defp put_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        slug = generate_slug(title)
        put_change(changeset, :slug, slug)
    end
  end

  defp generate_slug(title) do
    base =
      title
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.replace(~r/\s+/, "-")
      |> String.slice(0, 50)

    random_suffix = :crypto.strong_rand_bytes(4) |> Base.url_encode64(padding: false)
    "#{base}-#{random_suffix}"
  end

  defp supported_languages do
    Application.get_env(:review_room, :supported_languages, [])
  end
end
