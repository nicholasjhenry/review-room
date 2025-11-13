# Data Model: Snippet Creation

**Feature**: 001-snippet-creation  
**Date**: 2025-11-13  
**Status**: Complete

## Entity Relationship Overview

```
User (existing)
  ↓ has many
Snippet (with tags array column)
```

## Entities

### Snippet

**Purpose**: Represents a code snippet created by a developer with metadata for organization and display.

**Schema Definition**:

```elixir
defmodule ReviewRoom.Snippets.Snippet do
  use Ecto.Schema
  import Ecto.Changeset
  
  @type t :: %__MODULE__{
    id: integer(),
    title: String.t(),
    description: String.t() | nil,
    code: String.t(),
    language: String.t() | nil,
    visibility: visibility_type(),
    tags: [String.t()],
    user_id: integer(),
    user: Ecto.Association.NotLoaded.t() | ReviewRoom.Accounts.User.t(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
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
    
    timestamps()
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
    |> validate_length(:code, min: 1, max: 512_000) # 500KB
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
```

**Database Migration**:

```elixir
defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets) do
      add :title, :string, null: false, size: 200
      add :description, :text
      add :code, :text, null: false
      add :language, :string
      add :visibility, :string, null: false, default: "private"
      add :tags, {:array, :string}, default: []
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:snippets, [:user_id])
    create index(:snippets, [:visibility])
    create index(:snippets, [:inserted_at])
    create index(:snippets, [:tags], using: :gin)  # GIN index for array queries
  end
end
```

**Validation Rules**:
- `title`: Required, 1-200 characters
- `description`: Optional, max 2000 characters
- `code`: Required, 1 character to 500KB (512,000 bytes)
- `language`: Optional, must be from configured supported languages list
- `visibility`: Required, defaults to `:private`, one of `:private`, `:public`, `:unlisted`
- `tags`: Optional array of strings, normalized to lowercase and trimmed, duplicates removed
- `user_id`: Required, foreign key to users table

**State Transitions**: None - snippets are created and updated directly

**Relationships**:
- `belongs_to :user` - Each snippet belongs to one user (creator)

---

## Context API

The `ReviewRoom.Snippets` context provides the public API for snippet operations:

```elixir
defmodule ReviewRoom.Snippets do
  @moduledoc """
  Context for managing code snippets and tags.
  """
  
  import Ecto.Query
  alias ReviewRoom.Repo
  alias ReviewRoom.Snippets.{Snippet, Tag}
  alias ReviewRoom.Accounts.Scope
  
  ## Snippet CRUD Operations
  
  @doc """
  Lists all snippets for the current user based on scope.
  """
  @spec list_snippets(Scope.t()) :: [Snippet.t()]
  def list_snippets(%Scope{user: user}) when not is_nil(user) do
    Snippet
    |> where([s], s.user_id == ^user.id)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end
  
  @doc """
  Lists snippets filtered by tag.
  Uses PostgreSQL array contains operator for efficient tag filtering.
  """
  @spec list_snippets_by_tag(String.t(), Scope.t()) :: [Snippet.t()]
  def list_snippets_by_tag(tag_name, %Scope{user: user}) when not is_nil(user) do
    normalized_tag = String.downcase(tag_name)
    
    Snippet
    |> where([s], s.user_id == ^user.id)
    |> where([s], fragment("? = ANY(?)", ^normalized_tag, s.tags))
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end
  
  @doc """
  Gets a single snippet, checking visibility permissions.
  Raises `Ecto.NoResultsError` if not found or not authorized.
  """
  @spec get_snippet!(integer(), Scope.t()) :: Snippet.t()
  def get_snippet!(id, scope) do
    Snippet
    |> Repo.get!(id)
    |> check_visibility(scope)
  end
  
  @doc """
  Creates a snippet for the current user.
  """
  @spec create_snippet(map(), Scope.t()) :: {:ok, Snippet.t()} | {:error, Ecto.Changeset.t()}
  def create_snippet(attrs, %Scope{user: user}) when not is_nil(user) do
    %Snippet{user_id: user.id}
    |> Snippet.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates a snippet owned by the current user.
  """
  @spec update_snippet(Snippet.t(), map(), Scope.t()) :: {:ok, Snippet.t()} | {:error, Ecto.Changeset.t()}
  def update_snippet(snippet, attrs, %Scope{user: user}) when not is_nil(user) do
    if snippet.user_id == user.id do
      snippet
      |> Snippet.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end
  
  @doc """
  Deletes a snippet owned by the current user.
  """
  @spec delete_snippet(Snippet.t(), Scope.t()) :: {:ok, Snippet.t()} | {:error, Ecto.Changeset.t()}
  def delete_snippet(snippet, %Scope{user: user}) when not is_nil(user) do
    if snippet.user_id == user.id do
      Repo.delete(snippet)
    else
      {:error, :unauthorized}
    end
  end
  
  ## Tag Operations
  
  @doc """
  Lists all unique tags used by the current user's snippets.
  Returns a sorted list of tag strings.
  """
  @spec list_user_tags(Scope.t()) :: [String.t()]
  def list_user_tags(%Scope{user: user}) when not is_nil(user) do
    Snippet
    |> where([s], s.user_id == ^user.id)
    |> select([s], s.tags)
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end
  
  ## Helpers
  
  @doc """
  Returns an empty changeset for a new snippet.
  """
  @spec change_snippet(Snippet.t(), map()) :: Ecto.Changeset.t()
  def change_snippet(snippet, attrs \\ %{}) do
    Snippet.changeset(snippet, attrs)
  end
  
  # Private Functions
  
  defp check_visibility(snippet, %Scope{user: user}) do
    cond do
      snippet.visibility == :public -> snippet
      snippet.visibility == :unlisted -> snippet
      user && snippet.user_id == user.id -> snippet
      true -> raise Ecto.NoResultsError, queryable: Snippet
    end
  end
end
```

## Query Patterns

### Common Queries

**1. Get user's snippets**:
```elixir
Snippet
|> where([s], s.user_id == ^user_id)
|> order_by([s], desc: s.inserted_at)
|> Repo.all()
```

**2. Search snippets by tag** (using PostgreSQL array operators):
```elixir
# Single tag
Snippet
|> where([s], s.user_id == ^user_id)
|> where([s], fragment("? = ANY(?)", ^tag_name, s.tags))
|> Repo.all()

# Multiple tags (snippet must have ALL tags)
Snippet
|> where([s], s.user_id == ^user_id)
|> where([s], fragment("? @> ?", s.tags, ^tag_list))
|> Repo.all()

# Multiple tags (snippet must have ANY tag)
Snippet
|> where([s], s.user_id == ^user_id)
|> where([s], fragment("? && ?", s.tags, ^tag_list))
|> Repo.all()
```

**3. Get public snippets**:
```elixir
Snippet
|> where([s], s.visibility == :public)
|> order_by([s], desc: s.inserted_at)
|> preload(:user)
|> Repo.all()
```

**4. Get snippet with authorization check**:
```elixir
snippet = Repo.get!(Snippet, id)

authorized? = 
  snippet.visibility == :public or
  snippet.visibility == :unlisted or
  (user && snippet.user_id == user.id)
```

**5. Get all unique tags for a user**:
```elixir
Snippet
|> where([s], s.user_id == ^user_id)
|> select([s], s.tags)
|> Repo.all()
|> List.flatten()
|> Enum.uniq()
|> Enum.sort()
```

## Test Fixtures

```elixir
defmodule ReviewRoom.SnippetsFixtures do
  @moduledoc """
  Test fixtures for Snippets context.
  """
  
  alias ReviewRoom.Repo
  alias ReviewRoom.Snippets.Snippet
  
  def snippet_fixture(attrs \\ %{}) do
    user = attrs[:user] || ReviewRoom.AccountsFixtures.user_fixture()
    
    attrs = 
      Enum.into(attrs, %{
        title: "Test Snippet",
        description: "A test code snippet",
        code: "def hello, do: :world",
        language: "elixir",
        visibility: :private,
        tags: ["test", "elixir"],
        user_id: user.id
      })
    
    {:ok, snippet} = 
      %Snippet{}
      |> Snippet.changeset(attrs)
      |> Repo.insert()
    
    snippet
  end
end
```

## Configuration

**Supported Languages** (in `config/config.exs`):

```elixir
config :review_room, :supported_languages, [
  {"elixir", "Elixir"},
  {"javascript", "JavaScript"},
  {"python", "Python"},
  {"ruby", "Ruby"},
  {"go", "Go"},
  {"rust", "Rust"},
  {"sql", "SQL"},
  {"html", "HTML"},
  {"css", "CSS"},
  {"json", "JSON"},
  {"yaml", "YAML"},
  {"markdown", "Markdown"},
  {"bash", "Bash/Shell"},
  {"typescript", "TypeScript"},
  {"java", "Java"},
  {"c", "C"},
  {"cpp", "C++"},
  {"csharp", "C#"},
  {"php", "PHP"},
  {"swift", "Swift"}
]
```

## Indexes and Performance

**Primary Indexes**:
- `snippets.user_id` - Fast lookup of user's snippets
- `snippets.visibility` - Filter public/private snippets
- `snippets.inserted_at` - Chronological ordering
- `snippets.tags` (GIN index) - Fast array containment queries for tag filtering

**Expected Query Performance**:
- List user's snippets: O(1) index lookup + O(n) scan
- Filter by tag: O(log n) GIN index lookup for array containment
- Check visibility: O(1) direct comparison
- Get all user tags: O(n) scan + flatten (acceptable for moderate snippet counts)

**PostgreSQL Array Operators**:
- `? = ANY(?)` - Check if value exists in array
- `? @> ?` - Check if array contains all elements (AND logic)
- `? && ?` - Check if arrays have any common elements (OR logic)

## Migration Order

1. `create_snippets.exs` - Must run after users table exists (includes tags array column)

## Summary

The data model supports all functional requirements with:
- **Single-table design**: Simplified schema with tags as PostgreSQL array column
- **Efficient queries**: GIN index on tags array enables fast containment searches
- **Data integrity**: Constraints and validations at schema and database levels
- **Flexible tagging**: Array column allows arbitrary tags without separate tables
- **Privacy controls**: Visibility enum with database-level default
- **User ownership**: Foreign key with cascading deletes for data cleanup
- **Normalization**: Tags automatically lowercased, trimmed, and deduplicated in changeset
