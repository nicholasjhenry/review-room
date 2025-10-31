## Phoenix Style Guide

This file contain TEMPLATE snippets containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`) and directives start with `//`.


### Application Layer

The application layer contains the business logic including context and record modules.

*ALWAYS* use the identifier type for record ID's, *NEVER* `Ecto.UUID.t()` or `integer()`:

```elixir
Identifier.t()
````

### Context Modules

Context modules are denoted by the use of the macro:

```elixir
use MyApp, :context
```

The functions in these modules are known as "actions" or "action functions".

`@spec` for changeset related functions:

- MUST include the schema in the `Ecto.Changeset.t()` return type
- MUST use the `Attrs.t()` for attrs; NEVER `map()`

```elixir
@spec change_team(Scope.t(), Attrs.t()) :: Ecto.Changeset.t(Team.t())
```

Action functions:

- *MUST* support `"string"` and `:atom` keys for `Attrs.t()`.
-  Ecto's `cast/3` can accept string and atom keys for field names.

Managing associations with the "assoc changeset" pattern:

- *ALWAYS* use `put_[ASSOC]_changeset/2` and `delete_[ASSOC]_changeset/2` functions
  to managed associations when needed.
- *NEVER* manipulate the attrs in a context module.

```elixir
%TeamMember{}
|> TeamMember.insert_changeset()
|> TeamMember.put_team_changeset(team)
|> TeamMember.put_person_changeset(person)
|> Repo.insert()
```

Never include `iex>` examples for documentation.

### Record Modules (aka Schema Modules)

Record modules are denoted by the use of the macro:

```elixir
use MyApp, :record
```
