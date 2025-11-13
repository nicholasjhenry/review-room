---
name: ecto-patterns
description: Ecto schema, changeset, and query best practices. Use when working with Ecto schemas, changesets, queries, associations, validations, or database operations.
version: 1.0.0
---

# Ecto Patterns and Best Practices

Essential patterns for working with Ecto schemas, changesets, and queries.

---

## Association Preloading

**ALWAYS preload associations when they'll be accessed in templates or views.**

### The Problem: N+1 Queries

```elixir
# ❌ BAD - N+1 query problem
def list_messages do
  Repo.all(Message)
end

# In template:
# <%= for message <- @messages do %>
#   <%= message.user.email %>  # Triggers a query for EACH message!
# <% end %>
# Result: 1 query for messages + N queries for users = N+1 queries
```

### The Solution: Preload

```elixir
# ✅ GOOD - preload associations
def list_messages do
  Message
  |> Repo.all()
  |> Repo.preload(:user)
end

# Or preload in the query
def list_messages do
  Message
  |> preload(:user)
  |> Repo.all()
end

# Result: 2 queries total (1 for messages, 1 for all users)
```

### Preloading Multiple Associations

```elixir
# Multiple associations
def list_messages do
  Message
  |> preload([:user, :room])
  |> Repo.all()
end

# Nested associations
def list_posts do
  Post
  |> preload([comments: :user])
  |> Repo.all()
end

# Multiple nested associations
def list_posts do
  Post
  |> preload([
    :author,
    comments: [:user, :likes]
  ])
  |> Repo.all()
end
```

### Custom Preload Queries

```elixir
# Preload with filtered associations
def list_posts do
  published_comments =
    from c in Comment,
      where: c.published == true,
      order_by: [desc: c.inserted_at]

  Post
  |> preload(comments: ^published_comments)
  |> Repo.all()
end
```

### When to Preload

**✅ Preload when:**
- Accessing associations in templates/views
- Iterating over collections and accessing associations
- You know you'll need the association data

**❌ Don't preload when:**
- Association won't be accessed
- Loading single records that won't use associations
- You need lazy loading for specific use cases

---

## Seeds and Migrations

### Import Required Modules in seeds.exs

**ALWAYS import Ecto.Query and other modules in `priv/repo/seeds.exs`:**

```elixir
# priv/repo/seeds.exs

# ✅ REQUIRED imports
import Ecto.Query
alias MyApp.Repo
alias MyApp.Accounts.User
alias MyApp.Content.Post

# Now you can use query syntax
Repo.delete_all(Post)
Repo.delete_all(User)

# Create seed data
user = Repo.insert!(%User{
  email: "admin@example.com",
  name: "Admin User"
})

Repo.insert!(%Post{
  title: "Welcome Post",
  body: "Welcome to our site!",
  user_id: user.id
})

# Query with imported functions
admin_posts =
  from(p in Post,
    join: u in assoc(p, :user),
    where: u.email == "admin@example.com",
    select: p
  )
  |> Repo.all()
```

**Common imports for seeds:**
```elixir
import Ecto.Query
import Ecto.Changeset  # If using changesets
alias MyApp.Repo
# Your schema aliases
```

---

## Schema Field Types

### CRITICAL: Always Use `:string` Type in Schemas

**Even for `:text` database columns, use `:string` in the schema:**

```elixir
# Migration (database)
def change do
  create table(:posts) do
    add :title, :string        # VARCHAR column
    add :body, :text           # TEXT column
    add :summary, :text        # TEXT column
    
    timestamps()
  end
end

# Schema (Ecto)
defmodule MyApp.Content.Post do
  use Ecto.Schema
  
  schema "posts" do
    # ✅ CORRECT - always use :string type
    field :title, :string
    field :body, :string      # Even though DB column is TEXT
    field :summary, :string   # Even though DB column is TEXT
    
    # ❌ WRONG - :text is not an Ecto type
    # field :body, :text      # This will cause errors
    
    timestamps()
  end
end
```

**Why?** 
- Ecto doesn't have a `:text` type
- `:string` is the Ecto type for all string data
- The migration defines the database column type (`:text`, `:string`, `:varchar`)
- The schema defines the Elixir type (`:string`)

### Common Ecto Field Types

```elixir
schema "examples" do
  field :name, :string           # Strings (VARCHAR, TEXT in DB)
  field :age, :integer           # Integers
  field :price, :decimal         # Decimals
  field :active, :boolean        # Booleans
  field :metadata, :map          # JSON/JSONB
  field :tags, {:array, :string} # Arrays
  field :birth_date, :date       # Dates
  field :start_time, :time       # Times
  field :inserted_at, :naive_datetime      # DateTime without timezone
  field :confirmed_at, :utc_datetime       # DateTime with timezone
  field :data, :binary           # Binary data
  field :count, :float           # Floats
end
```

---

## Changeset Validations

### validate_number Does Not Support :allow_nil

**`validate_number/3` does NOT accept `:allow_nil` option:**

```elixir
# ❌ WRONG - :allow_nil is not supported
def changeset(post, attrs) do
  post
  |> cast(attrs, [:view_count])
  |> validate_number(:view_count, greater_than: 0, allow_nil: true)
end

# ✅ CORRECT - validations automatically skip nil values
def changeset(post, attrs) do
  post
  |> cast(attrs, [:view_count])
  |> validate_number(:view_count, greater_than: 0)
  # If :view_count is nil or not in attrs, validation is skipped
end
```

**Key principle:** Ecto validations only run when:
1. The field has a change (was included in `cast`)
2. The change value is not `nil`

**If you need to require the field:**

```elixir
def changeset(post, attrs) do
  post
  |> cast(attrs, [:view_count])
  |> validate_required([:view_count])  # Makes it required
  |> validate_number(:view_count, greater_than: 0)
end
```

**Handling optional numbers with constraints:**

```elixir
# Optional field, but if present must be positive
def changeset(product, attrs) do
  product
  |> cast(attrs, [:discount_percent])
  # No validate_required, so it's optional
  |> validate_number(:discount_percent, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  # Validation only runs if discount_percent is present and not nil
end
```

---

## Accessing Changeset Fields

### MUST Use get_field/3 to Access Changeset Fields

**Never access changeset struct fields directly:**

```elixir
# ❌ WRONG - direct access
def process_changeset(changeset) do
  email = changeset.changes[:email]  # May not exist
  user_id = changeset.data.user_id   # Gets old value, not new
end

# ✅ CORRECT - use Ecto.Changeset functions
def process_changeset(changeset) do
  import Ecto.Changeset
  
  # Get current value (change if exists, otherwise original)
  email = get_field(changeset, :email)
  
  # Get only if changed
  email_change = get_change(changeset, :email)  # nil if not changed
  
  # Check if field changed
  if changed?(changeset, :email) do
    # email was modified
  end
end
```

### Changeset Access Functions

```elixir
import Ecto.Changeset

# get_field/3 - returns current value (change or original)
email = get_field(changeset, :email)
email = get_field(changeset, :email, "default@example.com")

# get_change/3 - returns change value or nil/default
new_email = get_change(changeset, :email)
new_email = get_change(changeset, :email, "no-change")

# fetch_field/2 - returns {:changes | :data, value} or :error
case fetch_field(changeset, :email) do
  {:changes, email} -> "Changed to #{email}"
  {:data, email} -> "Unchanged: #{email}"
  :error -> "Field doesn't exist"
end

# fetch_change/2 - returns {:ok, value} or :error
case fetch_change(changeset, :email) do
  {:ok, email} -> "Changed to #{email}"
  :error -> "Not changed"
end

# changed?/2 - returns boolean
if changed?(changeset, :email) do
  # email was modified
end
```

### Common Use Cases

```elixir
# Conditional validation based on other field
def changeset(user, attrs) do
  user
  |> cast(attrs, [:type, :company_name])
  |> validate_required([:type])
  |> maybe_require_company_name()
end

defp maybe_require_company_name(changeset) do
  case get_field(changeset, :type) do
    :business -> validate_required(changeset, [:company_name])
    _ -> changeset
  end
end

# Setting computed fields
def changeset(post, attrs) do
  post
  |> cast(attrs, [:title, :body])
  |> put_slug()
end

defp put_slug(changeset) do
  case get_change(changeset, :title) do
    nil -> changeset
    title -> put_change(changeset, :slug, slugify(title))
  end
end
```

---

## Security: Programmatically Set Fields

### CRITICAL: Never Cast Fields Set Programmatically

**Fields set programmatically MUST NOT be in `cast/3`:**

```elixir
# ❌ DANGEROUS - user_id in cast allows user to set any user_id
def changeset(post, attrs) do
  post
  |> cast(attrs, [:title, :body, :user_id])  # SECURITY HOLE!
  |> validate_required([:title, :user_id])
end

# Attacker can submit: %{"title" => "Hacked", "user_id" => admin_user_id}

# ✅ SECURE - user_id set explicitly, not from attrs
def changeset(post, attrs) do
  post
  |> cast(attrs, [:title, :body])  # user_id NOT in cast
  |> validate_required([:title])
end

def create_post(attrs, current_user) do
  # Set user_id explicitly when building struct
  %Post{user_id: current_user.id}
  |> Post.changeset(attrs)
  |> Repo.insert()
end
```

### Secure Patterns

**Pattern 1: Set on struct before changeset**
```elixir
def create_post(attrs, current_user) do
  %Post{user_id: current_user.id}
  |> Post.changeset(attrs)
  |> Repo.insert()
end
```

**Pattern 2: Use put_change/3 after cast**
```elixir
def changeset(post, attrs, current_user) do
  post
  |> cast(attrs, [:title, :body])
  |> put_change(:user_id, current_user.id)  # Set programmatically
  |> validate_required([:title, :user_id])
end

# Usage
Post.changeset(%Post{}, attrs, current_user)
```

**Pattern 3: Use put_assoc/3 for associations**
```elixir
def changeset(post, attrs, current_user) do
  post
  |> cast(attrs, [:title, :body])
  |> put_assoc(:user, current_user)
  |> validate_required([:title])
end
```

### Fields That Should NEVER Be Cast

**Never include these in `cast/3`:**
- `user_id` (or any foreign key set from current user)
- `organization_id` (or any multi-tenancy scope)
- `inserted_at`, `updated_at` (handled by timestamps)
- `id` (primary key)
- Computed fields (`slug` derived from `title`)
- Status fields controlled by state machine
- Authorization/permission fields

**Example of multiple secure fields:**
```elixir
def changeset(document, attrs, current_user, organization) do
  document
  |> cast(attrs, [:title, :content, :category])
  # ✅ Security: set programmatically
  |> put_change(:user_id, current_user.id)
  |> put_change(:organization_id, organization.id)
  |> put_change(:status, :draft)
  |> validate_required([:title, :content])
end
```

---

## Common Patterns

### Conditional Changesets

```elixir
# Different changesets for different operations
def registration_changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :password])
  |> validate_required([:email, :password])
  |> validate_length(:password, min: 8)
  |> hash_password()
end

def update_changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :name, :bio])
  |> validate_required([:email])
  # No password handling
end

def admin_changeset(user, attrs) do
  user
  |> update_changeset(attrs)
  |> cast(attrs, [:role, :verified])  # Admin-only fields
end
```

### Virtual Fields for User Input

```elixir
schema "users" do
  field :email, :string
  field :hashed_password, :string
  
  # Virtual fields not persisted to DB
  field :password, :string, virtual: true
  field :password_confirmation, :string, virtual: true
  
  timestamps()
end

def changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :password, :password_confirmation])
  |> validate_required([:email, :password])
  |> validate_confirmation(:password)  # Checks password_confirmation matches
  |> validate_length(:password, min: 8)
  |> hash_password()
end

defp hash_password(changeset) do
  case get_change(changeset, :password) do
    nil -> changeset
    password ->
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)  # Remove virtual field
  end
end
```

### Embedded Schemas

```elixir
# For JSON fields
defmodule MyApp.Accounts.UserPreferences do
  use Ecto.Schema
  import Ecto.Changeset
  
  @primary_key false
  embedded_schema do
    field :theme, :string, default: "light"
    field :notifications, :boolean, default: true
    field :language, :string, default: "en"
  end
  
  def changeset(prefs, attrs) do
    prefs
    |> cast(attrs, [:theme, :notifications, :language])
    |> validate_inclusion(:theme, ["light", "dark"])
  end
end

# In parent schema
schema "users" do
  field :email, :string
  embeds_one :preferences, UserPreferences
  timestamps()
end

def changeset(user, attrs) do
  user
  |> cast(attrs, [:email])
  |> cast_embed(:preferences)
end
```

---

## Query Best Practices

### Use Named Bindings

```elixir
# ✅ Good - named bindings are clear
def list_published_posts_with_author do
  from(p in Post,
    as: :post,
    join: u in assoc(p, :user),
    as: :user,
    where: as(:post).published == true,
    preload: [user: u],
    select: p
  )
  |> Repo.all()
end

# ❌ Harder to read - positional bindings
def list_published_posts_with_author do
  from(p in Post,
    join: u in assoc(p, :user),
    where: p.published == true,
    preload: [user: u],
    select: p
  )
  |> Repo.all()
end
```

### Build Queries Dynamically

```elixir
def list_posts(filters \\ %{}) do
  Post
  |> filter_by_published(filters)
  |> filter_by_category(filters)
  |> order_posts(filters)
  |> Repo.all()
end

defp filter_by_published(query, %{published: true}) do
  where(query, [p], p.published == true)
end
defp filter_by_published(query, _), do: query

defp filter_by_category(query, %{category: category}) when is_binary(category) do
  where(query, [p], p.category == ^category)
end
defp filter_by_category(query, _), do: query

defp order_posts(query, %{order: "recent"}) do
  order_by(query, [p], desc: p.inserted_at)
end
defp order_posts(query, _), do: query
```

---

## Quick Reference

### Preloading Checklist
- ✅ Preload when accessing associations in templates
- ✅ Use `preload/2` or `Repo.preload/2`
- ✅ Preload nested associations with list syntax
- ❌ Never iterate and access associations without preloading (N+1)

### Schema Checklist
- ✅ Always use `:string` type for text fields
- ✅ Import `Ecto.Query` in seeds.exs
- ✅ Import required modules in seeds
- ❌ Never use `:text` as Ecto schema type

### Changeset Checklist
- ✅ Use `get_field/3` to access changeset fields
- ✅ Use `get_change/3` to access only changed fields
- ❌ Never access `changeset.changes[:field]` directly
- ❌ Never use `:allow_nil` with `validate_number/3`
- ✅ Validations automatically skip nil values

### Security Checklist
- ✅ Set `user_id` and similar fields programmatically
- ✅ Use `put_change/3` or set on struct before changeset
- ❌ NEVER include `user_id` in `cast/3`
- ❌ NEVER cast authorization/permission fields
- ❌ NEVER cast computed fields

---

## Integration with CLAUDE.md

Check CLAUDE.md for:
- Project-specific preloading patterns
- Multi-tenancy field handling (organization_id, account_id)
- Custom changeset functions and validations
- Query conventions and helper functions
- Schema naming patterns

---

## Summary

**Core Ecto Principles:**
1. **Preload associations** before accessing in templates
2. **Use `:string` type** in schemas for all text (even DB TEXT columns)
3. **Import modules** in seeds.exs (Ecto.Query, etc.)
4. **Use `get_field/3`** to access changeset fields
5. **Never cast** fields set programmatically (user_id, etc.)
6. **`validate_number/3`** doesn't need `:allow_nil` (automatic)

**Security First:**
- Always set foreign keys and scope fields programmatically
- Never trust user input for `user_id`, `organization_id`, etc.
- Use `put_change/3` or set on struct before changeset

**Performance:**
- Preload associations to avoid N+1 queries
- Use named bindings in complex queries
- Build queries dynamically for flexibility
