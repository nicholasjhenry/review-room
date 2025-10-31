# Data Model: Developer Code Snippet Creation

**Feature**: 001-snippet-creation  
**Date**: 2025-10-31  
**Status**: Complete  
**Updated**: 2025-10-31 (Simplified to array-based tags)

## Overview

This document describes the database schema, Ecto schemas, and data relationships for the snippet creation feature. Based on research decisions, the "team" visibility option is deferred, supporting only "private" and "public" visibility for MVP.

**Design Decision**: Tags are stored as a simple PostgreSQL array field on the snippets table instead of a normalized many-to-many relationship. This simplifies the schema and is sufficient for the tagging use case.

## Entity Relationship Diagram

```
┌─────────────────┐
│     users       │ (existing from phx.gen.auth)
├─────────────────┤
│ id              │
│ email           │
│ ...             │
└─────────────────┘
        │
        │ 1:N (one user has many snippets)
        │
        ▼
┌─────────────────┐
│    snippets     │
├─────────────────┤
│ id              │
│ user_id         │◄─── FK to users.id
│ code            │
│ language        │
│ title           │
│ description     │
│ visibility      │
│ tags            │◄─── {:array, :string} - stored as PostgreSQL array
│ inserted_at     │
│ updated_at      │
└─────────────────┘
```

## Schema

### Snippets Table

**Table Name**: `snippets`

**Columns**:
| Column Name    | Type           | Constraints                     | Description                                    |
|----------------|----------------|---------------------------------|------------------------------------------------|
| id             | bigserial      | PRIMARY KEY                     | Unique identifier                              |
| user_id        | bigint         | NOT NULL, REFERENCES users(id)  | Owner of the snippet                           |
| code           | text           | NOT NULL                        | The code content (max 1MB enforced in app)     |
| language       | varchar(50)    | NOT NULL                        | Programming language identifier (e.g., "elixir")|
| title          | varchar(255)   | NULL                            | Optional title for the snippet                 |
| description    | text           | NULL                            | Optional description                           |
| visibility     | varchar(20)    | NOT NULL, DEFAULT 'private'     | Enum: 'private', 'public'                      |
| tags           | text[]         | NOT NULL, DEFAULT '{}'          | Array of tag names (max 10)                    |
| inserted_at    | timestamp      | NOT NULL                        | Creation timestamp                             |
| updated_at     | timestamp      | NOT NULL                        | Last modification timestamp                    |

**Indexes**:
- `CREATE INDEX idx_snippets_user_id ON snippets(user_id)` - Fast user snippet lookups
- `CREATE INDEX idx_snippets_visibility ON snippets(visibility)` - Fast public snippet queries
- `CREATE INDEX idx_snippets_language ON snippets(language)` - Optional: filter by language
- `CREATE INDEX idx_snippets_tags ON snippets USING GIN(tags)` - Fast tag-based queries using GIN index

**Record Schema** (`lib/review_room/snippets/snippet.ex`):
```elixir
defmodule ReviewRoom.Snippets.Snippet do
  use ReviewRoom, :record
  
  @max_code_size 1_048_576  # 1MB in bytes
  @max_tags 10
  @visibility_values ~w(private public)
  
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
    |> validate_length(:code, max: @max_code_size, 
         message: "Snippet content is too large. Maximum size is 1MB.")
    |> validate_length(:title, max: 255)
    |> validate_inclusion(:visibility, @visibility_values)
    |> validate_language()
    |> sanitize_html_fields()
    |> normalize_tags()
    |> validate_tags_count()
  end
  
  defp validate_language(changeset) do
    # Validate against configured language list
    supported_languages = Application.get_env(:review_room, :snippet_languages, [])
      |> Enum.map(& &1.code)
    
    validate_inclusion(changeset, :language, supported_languages,
      message: "Selected language is not supported.")
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
        normalized = tags
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.uniq()
        |> Enum.take(@max_tags)
        
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
```

## Context API

**Module**: `ReviewRoom.Snippets` (`lib/review_room/snippets.ex`)

### Public Functions

```elixir
defmodule ReviewRoom.Snippets do
  @moduledoc """
  Context for managing code snippets.
  """
  
  use ReviewRoom, :context
  
  alias ReviewRoom.Snippets.Snippet
  
  ## Snippet Creation & Updates
  
  @doc """
  Creates a new snippet for the given user scope.
  """
  @spec create_snippet(Scope.t(), Attrs.t()) :: {:ok, Snippet.t()} | {:error, Ecto.Changeset.t(Snippet.t())}
  def create_snippet(%Scope{user: user}, attrs) do
    %Snippet{}
    |> Snippet.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end
  
  @doc """
  Returns a changeset for tracking snippet changes (validation only, no DB).
  Used by LiveView for real-time validation without persistence.
  """
  @spec change_snippet(Snippet.t(), Attrs.t()) :: Ecto.Changeset.t(Snippet.t())
  def change_snippet(%Snippet{} = snippet, attrs \\ %{}) do
    Snippet.changeset(snippet, attrs)
  end
  
  ## Snippet Retrieval
  
  @doc """
  Gets a single snippet by ID with authorization check.
  Returns the snippet if the current user is authorized to view it.
  Returns nil if not found or not authorized.
  """
  @spec get_snippet(Scope.t(), Identifier.t()) :: Snippet.t() | nil
  def get_snippet(%Scope{user: user}, id) do
    Snippet
    |> where([s], s.id == ^id)
    |> where([s], s.user_id == ^user.id or s.visibility == "public")
    |> preload(:user)
    |> Repo.one()
  end
  
  @doc """
  Lists all snippets accessible to the current user.
  Includes user's own snippets and public snippets from others.
  """
  @spec list_snippets(Scope.t()) :: [Snippet.t()]
  def list_snippets(%Scope{user: user}) do
    Snippet
    |> where([s], s.user_id == ^user.id or s.visibility == "public")
    |> order_by([s], desc: s.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end
  
  @doc """
  Lists snippets for the current user only.
  """
  @spec list_my_snippets(Scope.t()) :: [Snippet.t()]
  def list_my_snippets(%Scope{user: user}) do
    Snippet
    |> where([s], s.user_id == ^user.id)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end
  
  @doc """
  Lists all unique tags used across all snippets.
  """
  @spec list_all_tags() :: [String.t()]
  def list_all_tags do
    query = from s in Snippet,
      select: fragment("unnest(?)", s.tags)
    
    Repo.all(query)
    |> Enum.uniq()
    |> Enum.sort()
  end
  
  @doc """
  Lists snippets that have a specific tag.
  """
  @spec list_snippets_by_tag(Scope.t(), String.t()) :: [Snippet.t()]
  def list_snippets_by_tag(%Scope{user: user}, tag_name) do
    Snippet
    |> where([s], s.user_id == ^user.id or s.visibility == "public")
    |> where([s], fragment("? = ANY(?)", ^tag_name, s.tags))
    |> order_by([s], desc: s.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end
end
```

## Migration

### Create Snippets Table

**Filename**: `priv/repo/migrations/YYYYMMDDHHMMSS_create_snippets.exs`

```elixir
defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
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
```

## State Transitions

Snippets follow a simple lifecycle:

```
┌─────────────┐
│   Draft     │  (exists only in LiveView socket assigns)
│ (in-memory) │
└─────────────┘
       │
       │ User clicks "Save"
       │ handle_event("save", ...)
       ▼
┌─────────────┐
│   Persisted │  (row in snippets table)
│     State   │  - visibility: private or public
│             │  - tags: array of strings
└─────────────┘
       │
       │ User edits snippet (future feature)
       │ handle_event("update", ...)
       ▼
┌─────────────┐
│   Updated   │  (updated_at timestamp changes)
│     State   │
└─────────────┘
```

**No Draft State**: Per research decision, snippets exist only in memory until explicit save. No intermediate "draft" status in database.

## Validation Rules

### Snippet Validation

1. **Required Fields**: code, language
2. **Code Size**: Maximum 1MB (1,048,576 bytes)
3. **Title**: Maximum 255 characters, HTML stripped
4. **Description**: Unlimited length, HTML stripped
5. **Language**: Must be in configured supported languages list
6. **Visibility**: Must be "private" or "public"
7. **Tags**: 
   - Array of strings
   - Maximum 10 tags per snippet
   - Trimmed and deduplicated automatically
   - Empty strings removed
   - No special validation on tag content (just strings)
8. **User Association**: Must have valid user_id (enforced by foreign key)

### Authorization Rules

1. **View Private Snippet**: `snippet.user_id == current_user.id`
2. **View Public Snippet**: Always allowed (if authenticated)
3. **Create Snippet**: Must be authenticated (current_scope.user present)
4. **Update Snippet**: Must own snippet (future feature)
5. **Delete Snippet**: Must own snippet (future feature)

## Configuration

### Application Config

**File**: `config/config.exs`

```elixir
config :review_room, :snippet_languages, [
  %{name: "Elixir", code: "elixir"},
  %{name: "JavaScript", code: "javascript"},
  %{name: "TypeScript", code: "typescript"},
  %{name: "Python", code: "python"},
  %{name: "Java", code: "java"},
  %{name: "Go", code: "go"},
  %{name: "Ruby", code: "ruby"},
  %{name: "PHP", code: "php"},
  %{name: "C", code: "c"},
  %{name: "C++", code: "cpp"},
  %{name: "C#", code: "csharp"},
  %{name: "SQL", code: "sql"},
  %{name: "HTML", code: "html"},
  %{name: "CSS", code: "css"},
  %{name: "Shell/Bash", code: "bash"},
  %{name: "Markdown", code: "markdown"}
]

config :review_room, :snippet_max_size, 1_048_576  # 1MB
config :review_room, :snippet_max_tags, 10
```

## Demo Data

### Seed Data

**File**: `priv/repo/seeds.exs` (additions)

```elixir
# Snippet demo data
alias ReviewRoom.Repo
alias ReviewRoom.Accounts.User
alias ReviewRoom.Snippets.Snippet

# Get or create demo users (assuming existing seed data)
user1 = Repo.get_by(User, email: "user1@example.com")
user2 = Repo.get_by(User, email: "user2@example.com")

# Create demo snippets with tags as arrays
Repo.insert!(%Snippet{
  user_id: user1.id,
  code: """
  defmodule HelloWorld do
    def greet(name) do
      "Hello, \#{name}!"
    end
  end
  """,
  language: "elixir",
  title: "Simple Elixir Greeting",
  description: "A basic function to demonstrate Elixir string interpolation",
  visibility: "public",
  tags: ["elixir", "tutorial"]
})

Repo.insert!(%Snippet{
  user_id: user1.id,
  code: """
  function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
  }
  """,
  language: "javascript",
  title: "Fibonacci Recursive",
  description: "Classic recursive Fibonacci implementation in JavaScript",
  visibility: "public",
  tags: ["algorithm", "tutorial", "javascript"]
})

Repo.insert!(%Snippet{
  user_id: user2.id,
  code: """
  SELECT users.name, COUNT(orders.id) as order_count
  FROM users
  LEFT JOIN orders ON users.id = orders.user_id
  GROUP BY users.id, users.name
  HAVING COUNT(orders.id) > 5;
  """,
  language: "sql",
  title: "Find Active Customers",
  description: "SQL query to find users with more than 5 orders",
  visibility: "private",
  tags: []
})

# Large snippet (near 1MB limit) for testing
large_code = String.duplicate("# This is a comment line\n", 40_000)
Repo.insert!(%Snippet{
  user_id: user1.id,
  code: large_code,
  language: "python",
  title: "Large Test Snippet",
  description: "For testing large snippet handling",
  visibility: "private",
  tags: ["test", "performance"]
})

# Snippet with maximum tags
Repo.insert!(%Snippet{
  user_id: user1.id,
  code: "console.log('testing tags');",
  language: "javascript",
  title: "Tag Limit Test",
  description: "Tests maximum tag count",
  visibility: "private",
  tags: ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6", "tag7", "tag8", "tag9", "tag10"]
})
```

## Database Indexes Rationale

1. **snippets(user_id)**: Fast queries for "show my snippets", most common operation
2. **snippets(visibility)**: Fast public snippet queries for browse/discover features
3. **snippets(language)**: Optional filter by language in browse UI
4. **snippets(tags) using GIN**: PostgreSQL GIN index enables fast array containment queries (e.g., finding snippets with specific tags)

## Advantages of Array-Based Tags

### Simplicity
- Single table instead of three (snippets, tags, snippet_tags)
- Fewer joins required for queries
- Simpler migrations and schema management
- No orphaned tag records to manage

### Performance
- GIN index provides fast tag searches
- No join table overhead
- Single database row contains all snippet data including tags
- Faster writes (one INSERT vs INSERT + multiple join table INSERTs)

### Developer Experience
- Easier to understand and maintain
- Tags are just a list field on the snippet
- No need to preload associations
- Simpler test fixtures

### Sufficient for Use Case
- Tags are simple labels, not complex entities
- No need for tag metadata (created_at, usage counts, etc.)
- No need for tag-specific operations
- User just needs to filter by tag name

## Query Examples

### Find Snippets with Specific Tag
```elixir
from s in Snippet,
  where: fragment("? = ANY(?)", "elixir", s.tags)
```

### Find Snippets with Any of Multiple Tags
```elixir
tags = ["elixir", "tutorial"]
from s in Snippet,
  where: fragment("? && ?", s.tags, ^tags)
```

### Get All Unique Tags
```elixir
from s in Snippet,
  select: fragment("unnest(?)", s.tags)
```

## Future Considerations

### When Team Feature Is Added

1. Add `teams` table with team metadata
2. Add `team_memberships` join table (users ↔ teams)
3. Add `team_id` column to snippets (nullable)
4. Update visibility enum to include "team"
5. Update authorization logic to check team membership
6. Update context queries to include team snippets
7. Migration to add team_id column (nullable for backwards compatibility)

### If Tag Complexity Grows

If tags need additional metadata (e.g., descriptions, colors, usage statistics), consider migrating to normalized schema:
- Create `tags` table
- Create `snippet_tags` join table
- Migrate existing tag arrays to normalized structure
- Update queries to use joins

However, this should only be done if actual requirements demand it. The array approach is sufficient for simple tagging.

### Potential Optimizations

1. **Snippet Versioning**: Add `snippet_versions` table for edit history
2. **Soft Deletes**: Add `deleted_at` column instead of hard deletes
3. **Full-Text Search**: Add `tsvector` column for full-text search on code/title/description
4. **Tag Popularity**: Materialized view or query to show most-used tags
5. **Snippet Analytics**: Separate table for view counts, likes, etc.
