## Project guidelines

- This is a web application written using the Phoenix web framework.
- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

## Typespec guidelines

- ensure all public context modules have typespecs

## Ecto Schemas

- Write a `typespec` for all Ecto Schemas.
- The `typespec` should always appear above the Ecto schema.
- If `@type` already exists, skip.

The typespec must include:

- all fields (including timestamps and foreign key ID's)
- associations, e.g. belongs_to, has_one, has_many

The typedoc must use this template where places holders are {} and directives are //:

```TEMPLATE
## Fields

A {human_form_of_module_name} has these fields:

{list_of_fields}

//OPTIONAL(start): include only when associations are defined

## Associations

A {human_form_of_module_name} associates with:

{list_of_associations}
```

Typespec for fields should include:

- `id` field

Types for fields:

- `id: integer()`
```
