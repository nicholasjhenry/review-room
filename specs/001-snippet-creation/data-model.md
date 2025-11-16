# Data Model: Snippet Creation

**Feature**: Snippet Creation  
**Branch**: `001-snippet-creation`  
**Date**: 2025-11-16

## Overview

This document defines the data model for the snippet creation feature, including entities, relationships, validation rules, and state transitions.

---

## Entities

### 1. Snippet

Represents a code snippet created by a developer.

**Schema: `snippets`**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | Primary Key, Auto-increment | Internal identifier |
| `slug` | `string` | NOT NULL, UNIQUE | URL-friendly identifier (title-based + random suffix) |
| `title` | `string` | NOT NULL, 1-200 chars | Snippet title |
| `description` | `text` | NULL, max 2000 chars | Optional description |
| `code` | `text` | NOT NULL, max 500KB bytes | Code content |
| `language` | `string` | NULL, max 50 chars | Syntax highlighting language (from supported list) |
| `tags` | `text[]` | DEFAULT '{}' | Array of tag names (lowercase, normalized) |
| `visibility` | `enum` | NOT NULL, DEFAULT 'private' | Access control: private, public, unlisted |
| `user_id` | `bigint` | NOT NULL, Foreign Key → users.id | Creator of the snippet |
| `inserted_at` | `timestamp` | NOT NULL | Creation timestamp |
| `updated_at` | `timestamp` | NOT NULL | Last modification timestamp |

**Indexes:**
```sql
CREATE UNIQUE INDEX snippets_slug_index ON snippets (slug);
CREATE INDEX snippets_user_id_visibility_created_at_index ON snippets (user_id, visibility, created_at DESC);
CREATE INDEX snippets_visibility_created_at_index ON snippets (visibility, created_at DESC);
CREATE INDEX snippets_tags_index ON snippets USING GIN (tags);  -- GIN index for array queries
```

**Ecto Schema:**
```elixir
schema "snippets" do
  field :slug, :string
  field :title, :string
  field :description, :string
  field :code, :string
  field :language, :string
  field :tags, {:array, :string}, default: []
  field :visibility, Ecto.Enum, values: [:private, :public, :unlisted], default: :private
  
  belongs_to :user, ReviewRoom.Accounts.User
  
  timestamps()
end
```

**Validation Rules:**
- `title`: Required, 1-200 characters
- `code`: Required, 1-512,000 bytes (count bytes, not graphemes)
- `description`: Optional, max 2,000 characters
- `language`: Optional, must be from supported languages list if provided
- `tags`: Array of strings, each 1-50 characters, lowercase, alphanumeric + hyphens only
- `visibility`: Must be one of [:private, :public, :unlisted], defaults to :private
- `slug`: Generated automatically from title + random suffix
- `user_id`: Required, must reference existing user

**Changeset Example:**
```elixir
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
    nil -> changeset
    tags when is_list(tags) ->
      normalized = tags
        |> Enum.map(&String.downcase/1)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.uniq()
      
      put_change(changeset, :tags, normalized)
    _ -> changeset
  end
end

defp validate_tags(changeset) do
  case get_field(changeset, :tags) do
    nil -> changeset
    tags when is_list(tags) ->
      Enum.reduce(tags, changeset, fn tag, acc ->
        cond do
          String.length(tag) > 50 ->
            add_error(acc, :tags, "tag '#{tag}' is too long (max 50 characters)")
          !Regex.match?(~r/^[a-z0-9-]+$/, tag) ->
            add_error(acc, :tags, "tag '#{tag}' contains invalid characters (only lowercase letters, numbers, hyphens)")
          true ->
            acc
        end
      end)
    _ -> changeset
  end
end
```

---

## Relationships

### Snippet ↔ User (Many-to-One)

- **Cardinality**: Many snippets belong to one user
- **Foreign Key**: `snippets.user_id → users.id`
- **On Delete**: CASCADE (when user deleted, delete their snippets)
- **Rationale**: Each snippet has exactly one creator; snippets are personal assets

```elixir
# In Snippet schema
belongs_to :user, ReviewRoom.Accounts.User

# In User schema
has_many :snippets, ReviewRoom.Snippets.Snippet
```

**Migration:**
```elixir
alter table(:snippets) do
  add :user_id, references(:users, on_delete: :delete_all), null: false
end
```

---

### Tags (Array Column)

- **Storage**: PostgreSQL array column (`text[]`) on snippets table
- **Rationale**: Simpler data model, no join table needed, tags are always accessed with snippet
- **Benefits**: 
  - Fewer queries (no JOIN needed)
  - Atomic updates (tags updated with snippet)
  - Simpler code (no batch upsert logic)
  - GIN index enables efficient array queries

**Migration:**
```elixir
alter table(:snippets) do
  add :tags, {:array, :string}, default: []
end

create index(:snippets, [:tags], using: "GIN")
```

---

## State Transitions

### Snippet Lifecycle

Snippets have a simple lifecycle with visibility states:

```
┌──────────┐
│  CREATE  │
└────┬─────┘
     │ (defaults to :private)
     ▼
┌──────────┐      UPDATE visibility      ┌──────────┐
│ PRIVATE  │ ◄───────────────────────► │  PUBLIC  │
└────┬─────┘                             └────┬─────┘
     │                                        │
     │    UPDATE visibility                   │
     └──────────► ┌──────────┐ ◄─────────────┘
                  │ UNLISTED │
                  └────┬─────┘
                       │
                       │ DELETE
                       ▼
                  ┌─────────┐
                  │ DELETED │
                  └─────────┘
```

**States:**

1. **Private** (default):
   - Only creator can view
   - Not visible in public listings
   - Not accessible by other users (returns 404)

2. **Public**:
   - Anyone can view (authenticated or not)
   - Visible in public listings
   - Searchable

3. **Unlisted**:
   - Anyone with URL can view
   - Not visible in public listings
   - Not searchable

4. **Deleted** (soft delete, future enhancement):
   - Currently: Hard delete (record removed)
   - Future: Soft delete with `deleted_at` timestamp

**Transitions:**
- CREATE → PRIVATE (automatic)
- PRIVATE ↔ PUBLIC (user action)
- PRIVATE ↔ UNLISTED (user action)
- PUBLIC ↔ UNLISTED (user action)
- Any state → DELETED (user action)

**No validation required for transitions** - all state changes are user-initiated and valid.

---

## Data Integrity Constraints

### Database-Level Constraints

1. **Uniqueness:**
   - `snippets.slug` UNIQUE
   - `tags.name` UNIQUE
   - `{snippet_tags.snippet_id, snippet_tags.tag_id}` UNIQUE

2. **Foreign Keys:**
   - `snippets.user_id → users.id` (CASCADE on delete)
   - `snippet_tags.snippet_id → snippets.id` (CASCADE on delete)
   - `snippet_tags.tag_id → tags.id` (CASCADE on delete)

3. **NOT NULL:**
   - `snippets.slug`, `snippets.title`, `snippets.code`, `snippets.visibility`, `snippets.user_id`
   - `tags.name`
   - `snippet_tags.snippet_id`, `snippet_tags.tag_id`

4. **Size Constraints:**
   - `snippets.code`: max 500KB (enforced at application layer)
   - PostgreSQL TEXT type supports up to 1GB with TOAST compression

### Application-Level Validation

1. **Input Sanitization:**
   - HTML escaping: Automatic via Phoenix HEEx templates
   - Never use `raw/1` on user input
   - Ecto changesets validate length and format

2. **XSS Prevention:**
   - Phoenix automatically escapes HTML
   - Trust default behavior
   - No additional sanitization needed

3. **Authorization:**
   - All queries filtered by `Accounts.Scope`
   - Visibility enforcement at database level
   - Return 404 (not 403) for unauthorized access

---

## Query Patterns

### Common Queries

**1. List user's snippets:**
```elixir
def list_snippets(scope) do
  Snippet
  |> where([s], s.user_id == ^scope.user.id)
  |> order_by([s], desc: s.created_at)
  |> preload(:tags)
  |> Repo.all()
end
```
*Uses index: `snippets_user_id_visibility_created_at_index`*

---

**2. Get snippet by slug (with visibility check):**
```elixir
def get_snippet(slug, scope) do
  Snippet
  |> where([s], s.slug == ^slug)
  |> where([s], 
    s.visibility == :public or
    s.visibility == :unlisted or
    (s.visibility == :private and s.user_id == ^scope.user.id)
  )
  |> preload(:tags)
  |> Repo.one()
  |> case do
    nil -> {:error, :not_found}
    snippet -> {:ok, snippet}
  end
end
```
*Uses index: `snippets_slug_index` (unique)*

---

**3. List public snippets:**
```elixir
def list_public_snippets do
  Snippet
  |> where([s], s.visibility == :public)
  |> order_by([s], desc: s.created_at)
  |> preload([:tags, :user])
  |> Repo.all()
end
```
*Uses index: `snippets_visibility_created_at_index`*

---

**4. Filter snippets by tag:**
```elixir
def list_snippets_by_tag(tag_name, scope) do
  Snippet
  |> where([s], ^tag_name in s.tags)
  |> where([s], s.user_id == ^scope.user.id)
  |> order_by([s], desc: s.created_at)
  |> Repo.all()
end
```
*Uses GIN index: `snippets_tags_index` for efficient array containment queries*

---

**5. Create snippet with tags:**
```elixir
def create_snippet(attrs, scope) do
  # Parse comma-separated tags: "elixir, phoenix, web" → ["elixir", "phoenix", "web"]
  tag_list = case attrs["tags"] do
    nil -> []
    "" -> []
    tags when is_binary(tags) -> 
      tags
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
    tags when is_list(tags) -> tags
  end
  
  attrs_with_tags = Map.put(attrs, "tags", tag_list)
  
  %Snippet{}
  |> Snippet.changeset(attrs_with_tags)
  |> Ecto.Changeset.put_assoc(:user, scope.user)
  |> Repo.insert()
end
```
*Single insert query - tags are stored directly in array column*

---

**6. Get all unique tags across all snippets:**
```elixir
def list_all_tags do
  Snippet
  |> select([s], fragment("unnest(?)", s.tags))
  |> distinct(true)
  |> order_by(asc: fragment("unnest(?)", field(^Snippet, :tags)))
  |> Repo.all()
end
```
*Uses PostgreSQL's `unnest` function to extract unique tags from all arrays*

---

## Performance Considerations

### Index Strategy

1. **Unique indexes** for lookups:
   - `snippets.slug` (primary access pattern)

2. **Composite indexes** for common queries:
   - `{snippets.user_id, visibility, created_at}` (user snippet listing)
   - `{snippets.visibility, created_at}` (public listing)

3. **GIN index** for array queries:
   - `snippets.tags` (enables efficient tag filtering with `@>` and `&&` operators)

### Query Optimization

1. **No preloading needed** for tags:
   - Tags are already in the snippet row (array column)
   - Preload only `:user` if needed

2. **Array queries use GIN index**:
   - `WHERE 'elixir' = ANY(tags)` or `WHERE tags @> ARRAY['elixir']`
   - PostgreSQL GIN index provides O(log n) performance

3. **Limit results** for listings:
   ```elixir
   query |> limit(100) |> Repo.all()
   ```

4. **Pagination** for large result sets:
   ```elixir
   query |> offset(^offset) |> limit(^page_size) |> Repo.all()
   ```

### Storage Estimates

- **Average snippet size**: 5 KB (code + metadata)
- **MVP (1,000 snippets)**: ~5 MB
- **Year 1 (100,000 snippets)**: ~500 MB
- **PostgreSQL TEXT** with TOAST compression handles large snippets efficiently

---

## Migration Files

### 1. Create Snippets

```elixir
defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets) do
      add :slug, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :code, :text, null: false
      add :language, :string
      add :tags, {:array, :string}, default: []
      add :visibility, :string, null: false, default: "private"
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:snippets, [:slug])
    create index(:snippets, [:user_id, :visibility, :created_at])
    create index(:snippets, [:visibility, :created_at])
    create index(:snippets, [:tags], using: "GIN")
  end
end
```

---

## Test Data Fixtures

### Snippet Fixtures

```elixir
defmodule ReviewRoom.SnippetsFixtures do
  alias ReviewRoom.{Repo, Snippets}
  alias ReviewRoom.Snippets.Snippet

  def snippet_fixture(attrs \\ %{}) do
    user = attrs[:user] || ReviewRoom.AccountsFixtures.user_fixture()
    
    {:ok, snippet} =
      attrs
      |> Enum.into(%{
        title: "Test Snippet #{System.unique_integer()}",
        code: "defmodule Test do\n  def hello, do: :world\nend",
        language: "elixir",
        tags: [],
        visibility: :private
      })
      |> then(&Snippets.create_snippet(&1, %{user: user}))
    
    snippet
  end

  def public_snippet_fixture(attrs \\ %{}) do
    attrs
    |> Map.put(:visibility, :public)
    |> snippet_fixture()
  end

  def tagged_snippet_fixture(attrs \\ %{}) do
    attrs
    |> Map.put(:tags, ["elixir", "test"])
    |> snippet_fixture()
  end
end
```

---

## Summary

**Entities:**
- Snippet (code content with metadata and tags array)

**Key Constraints:**
- Unique slugs for URL access
- Required fields: title, code, visibility, user_id
- Size limits: 500KB code, 200 char title, 2000 char description
- Tag validation: 1-50 chars, lowercase, alphanumeric + hyphens
- Visibility enforcement at database level

**Relationships:**
- User → Snippets (one-to-many)
- Tags stored as PostgreSQL array column (no separate table)

**Performance:**
- Composite indexes for common queries
- GIN index for efficient tag filtering
- No JOINs needed (tags are denormalized)
- Single query for snippet creation

**Benefits of Array Column Approach:**
- **Simpler schema**: One table instead of three
- **Fewer queries**: No JOIN needed for tags
- **Atomic updates**: Tags updated with snippet
- **Better performance**: GIN index provides O(log n) array queries
- **Easier testing**: No fixture complexity for associations

**Next Steps:**
- Create single migration for snippets table
- Implement Snippet schema with tag validation
- Write failing tests for tag normalization
- Extend seeds.exs with demo data
