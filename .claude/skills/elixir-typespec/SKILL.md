---
name: elixir-typespecs
description: Elixir typespec conventions and Dialyzer best practices. Use when writing @spec, @type, @opaque annotations or working with type specifications.
version: 1.0.0
---

# Elixir Typespec Best Practices

This skill teaches comprehensive typespec conventions for Elixir code. Always reference the project's CLAUDE.md for any project-specific overrides.

## Core Principles

1. **Favor specificity over any()**: Use union types to be precise
2. **Document custom types**: Always add @typedoc for complex types
3. **Use t() convention**: Primary module type should be `t()`
4. **Align guards with specs**: If you have `when is_integer(id)`, spec should use `integer()`
5. **Handle error tuples**: Context functions should spec both `{:ok, result}` and `{:error, reason}`

## Common Patterns

### Context Functions
```elixir
@type user_attrs :: %{optional(atom()) => any()}
@type error_reason :: :not_found | :unauthorized | :invalid_params

@spec create_user(user_attrs()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
@spec get_user(pos_integer()) :: {:ok, User.t()} | {:error, error_reason()}
@spec list_users() :: [User.t()]
```

### Schema Types
```elixir
defmodule MyApp.Accounts.User do
  @type t :: %__MODULE__{
    id: integer() | nil,
    email: String.t(),
    role: :admin | :user,
    inserted_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  schema "users" do
    # fields...
  end
end
```

### GenServer State
```elixir
@type state :: %{
  queue: [job()],
  processing: MapSet.t(job_id()),
  config: config()
}

@type job :: %{id: String.t(), type: job_type(), payload: map()}
@type job_type :: :email | :webhook | :report
```

### Callbacks
```elixir
@callback handle_event(event :: map()) :: :ok | {:error, term()}
```

## Guidelines

**When to use @opaque:**
- For types that are implementation details
- Example: `@opaque token :: String.t()` when token structure shouldn't be relied upon

**When to use union types:**
- Error reasons: `:not_found | :unauthorized | :rate_limited`
- Status enums: `:pending | :processing | :completed | :failed`
- Avoid `:ok | :error` alone—use `{:ok, result} | {:error, reason}`

**Avoid:**
- `any()` unless truly any value is acceptable
- Over-specifying (don't write specs for private functions unless they're complex)
- Inconsistent error tuple shapes within a context

## Validation Process

After adding typespecs:
1. Run `mix dialyzer` to check for inconsistencies
2. Fix any warnings about type mismatches
3. Ensure all public API functions have specs
4. Document any intentional use of `any()` or `term()`

## Integration with CLAUDE.md

Check CLAUDE.md for:
- Project-specific type aliases
- Custom error reason conventions
- Opaque type usage patterns
- Multi-tenancy type annotations
