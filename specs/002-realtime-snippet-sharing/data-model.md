# Data Model: Real-Time Code Snippet Sharing System

**Date**: 2025-10-21
**Feature**: Real-Time Code Snippet Sharing System
**Purpose**: Define Ecto schemas, database structure, and entity relationships

## Overview

This data model supports:
- Persistent snippet storage with metadata
- User ownership tracking (authenticated users)
- Public/private visibility controls
- Real-time presence tracking (ephemeral, not persisted)

**Key Design Decisions**:
- Snippet ID: 8-character nanoid (string primary key) for shareable URLs
- User relationship: Optional (supports anonymous snippets)
- Presence tracking: Ephemeral via Phoenix Tracker (no database table)
- Language codes: String enum validated at application layer

---

## Entities

### 1. Snippet (Persistent)

**Purpose**: Core entity representing a code snippet with metadata

**Ecto Schema**: `ReviewRoom.Snippets.Snippet`

**Fields**:

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `:string` | Primary key, unique, 8 chars | Nanoid-generated shareable ID |
| `code` | `:text` | Required | The actual code content |
| `title` | `:string` | Optional, max 200 chars | User-provided title |
| `description` | `:text` | Optional | User-provided description |
| `language` | `:string` | Optional, enum validation | Programming language code |
| `visibility` | `Ecto.Enum` | Required, default `:private` | `:public` or `:private` |
| `user_id` | `:binary_id` | Optional, foreign key | Owner (nil for anonymous) |
| `inserted_at` | `:utc_datetime` | Auto | Creation timestamp |
| `updated_at` | `:utc_datetime` | Auto | Last update timestamp |

**Relationships**:
- `belongs_to :user, ReviewRoom.Accounts.User` (optional)

**Indexes**:
- Primary: `id` (unique)
- Foreign key: `user_id`
- Query optimization: `visibility`, `language`, `inserted_at`
- Composite: `(visibility, inserted_at)` for public gallery queries

**Validations**:
- `code`: Required, non-empty
- `title`: Max 200 characters
- `language`: Must be in supported languages list or nil
- `visibility`: Must be `:public` or `:private`
- `id`: Auto-generated via nanoid in changeset if not present

**State Transitions**:
```
[New] --create--> [Private] --toggle_visibility--> [Public]
                     |                                |
                     +------ toggle_visibility -------+
                     |                                |
                  [Deleted] <---------------------- [*]
```

**Business Rules**:
- Anonymous snippets (user_id = nil) cannot be edited after creation
- Only snippet owner can edit/delete
- Public snippets appear in gallery immediately upon visibility change
- Deleted snippets: Hard delete (no soft delete for MVP)

---

### 2. User (Existing)

**Purpose**: User accounts (already implemented via phx.gen.auth)

**Ecto Schema**: `ReviewRoom.Accounts.User`

**Relevant Fields** (existing schema, no changes):
- `id`: `:binary_id` (UUID)
- `email`: `:string`
- `hashed_password`: `:string`
- `confirmed_at`: `:naive_datetime`

**Relationships** (new):
- `has_many :snippets, ReviewRoom.Snippets.Snippet`

**Note**: No database changes needed for User entity. Snippets migration adds foreign key to existing users table.

---

### 3. Presence Record (Ephemeral)

**Purpose**: Track active users viewing a snippet in real-time

**Storage**: Phoenix.Tracker (in-memory, distributed)
**No database table**: Presence is ephemeral and rebuilt on process restart

**Data Structure** (in-memory only):

```elixir
# Tracked per snippet topic: "snippet:#{snippet_id}"
%{
  user_id: "user_uuid" or "anon_session_id",
  metas: [
    %{
      cursor: %{line: 10, column: 5} | nil,
      selection: %{start: %{line: 10, col: 5}, end: %{line: 12, col: 10}} | nil,
      display_name: "Alice" | "Anonymous User 1",
      color: "#3B82F6",  # Assigned color for UI
      phx_ref: "ref_abc123",
      online_at: 1640000000
    }
  ]
}
```

**Lifecycle**:
- **Created**: When LiveView process mounts and joins snippet topic
- **Updated**: On cursor movement, text selection changes
- **Deleted**: When LiveView process terminates (user closes tab, navigates away)
- **Timeout**: Automatic cleanup after disconnect (5-10 second grace period)

**Phoenix Tracker guarantees**:
- Eventual consistency across distributed nodes
- Automatic conflict resolution (CRDT)
- Duplicate detection (same process can't be tracked twice)

---

## Database Schema

### Migration: Create Snippets Table

```elixir
# priv/repo/migrations/XXXXXX_create_snippets.exs
defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :code, :text, null: false
      add :title, :string, size: 200
      add :description, :text
      add :language, :string, size: 50
      add :visibility, :string, null: false, default: "private"
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:snippets, [:id])
    create index(:snippets, [:user_id])
    create index(:snippets, [:visibility])
    create index(:snippets, [:language])
    create index(:snippets, [:inserted_at])
    create index(:snippets, [:visibility, :inserted_at])
  end
end
```

**Notes**:
- `on_delete: :nilify_all`: If user deleted, snippets become anonymous (preserve content)
- `visibility` stored as string for Ecto.Enum compatibility
- Composite index `(visibility, inserted_at)` optimizes public gallery queries

---

## Ecto Schema Implementations

### Snippet Schema

```elixir
# lib/review_room/snippets/snippet.ex
defmodule ReviewRoom.Snippets.Snippet do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :binary_id

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

  defp supported_languages do
    [
      nil,  # Auto-detect
      "elixir", "erlang", "javascript", "typescript", "python", "ruby",
      "go", "rust", "java", "kotlin", "swift", "c", "cpp", "csharp",
      "php", "sql", "html", "css", "scss", "json", "yaml", "markdown",
      "shell", "bash", "dockerfile", "xml", "plaintext"
    ]
  end
end
```

### User Schema Update

```elixir
# lib/review_room/accounts/user.ex (add relationship)
defmodule ReviewRoom.Accounts.User do
  use Ecto.Schema
  # ... existing schema fields ...

  schema "users" do
    # ... existing fields ...
    has_many :snippets, ReviewRoom.Snippets.Snippet
    # ... timestamps ...
  end

  # ... existing functions unchanged ...
end
```

---

## Context Functions

Key context functions needed (implementation in tasks phase):

```elixir
# lib/review_room/snippets.ex (context module)
defmodule ReviewRoom.Snippets do
  @moduledoc """
  The Snippets context - boundary for snippet operations.
  """

  # Queries
  def get_snippet!(id)
  def list_public_snippets(opts \\ [])
  def list_user_snippets(user_id, opts \\ [])
  def search_snippets(query, opts \\ [])

  # Commands
  def create_snippet(attrs, user \\ nil)
  def update_snippet(snippet, attrs, user)
  def delete_snippet(snippet, user)
  def toggle_visibility(snippet, user)

  # Authorization
  def can_edit?(snippet, user)
  def can_delete?(snippet, user)
end
```

---

## Query Patterns

### Public Gallery (with filters)

```elixir
def list_public_snippets(opts \\ []) do
  language = Keyword.get(opts, :language)
  limit = Keyword.get(opts, :limit, 20)
  cursor = Keyword.get(opts, :cursor)  # inserted_at for pagination

  query =
    from s in Snippet,
      where: s.visibility == :public,
      order_by: [desc: s.inserted_at],
      limit: ^limit,
      preload: [:user]

  query =
    if language do
      from s in query, where: s.language == ^language
    else
      query
    end

  query =
    if cursor do
      from s in query, where: s.inserted_at < ^cursor
    else
      query
    end

  Repo.all(query)
end
```

### User's Snippets

```elixir
def list_user_snippets(user_id, opts \\ []) do
  limit = Keyword.get(opts, :limit, 20)

  from(s in Snippet,
    where: s.user_id == ^user_id,
    order_by: [desc: s.inserted_at],
    limit: ^limit
  )
  |> Repo.all()
end
```

### Search

```elixir
def search_snippets(query_string, opts \\ []) do
  limit = Keyword.get(opts, :limit, 20)
  pattern = "%#{query_string}%"

  from(s in Snippet,
    where: s.visibility == :public,
    where: ilike(s.title, ^pattern) or ilike(s.description, ^pattern),
    order_by: [desc: s.inserted_at],
    limit: ^limit,
    preload: [:user]
  )
  |> Repo.all()
end
```

---

## Data Model Summary

**Persistent Entities**: 1 new (Snippet), 1 existing (User)
**Ephemeral State**: Presence tracking via Phoenix.Tracker
**Relationships**: Snippet belongs_to User (optional)
**Indexes**: 6 total (1 unique, 1 foreign key, 4 query optimization)

**Next Phase**: API contracts (LiveView events) and quickstart guide
