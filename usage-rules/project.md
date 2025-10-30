This file contain TEMPLATE snippets containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`) and directives start with `//`.

## Project guidelines

- This is a web application written using the Phoenix web framework.
- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

## Testing guidelines

- All code **MUST** be tested. Do not write production code without writing tests.
- Do not write docstrings for test using function names, e.g. `enqueue/2`

The template for tests is:

```TEMPLATE
describe "when [USE_CASE_AS_A_GERUND]" do
  test "given [INITIAL_STATE] then [EXPECTED_STATE]" do
    // Add test code
  end
end
```

## Typespec guidelines

- ensure all public context modules have typespecs

## Ecto Schemas

- Write a `typespec` for all Ecto Schemas.
- The `typespec` should always appear above the Ecto schema.
- If `@type` already exists, skip.

The typespec must include:

- all fields (including timestamps and foreign key ID's)
- associations, e.g. belongs_to, has_one, has_many

The typedoc **MUST** use this template:

```TEMPLATE
## Fields

A [HUMAN_FORM_OF_MODULE_NAME] has these fields:

[LIST_OF_FIELDS]

//OPTIONAL(start): include only when associations are defined

## Associations

A [HUMAN_FORM_OF_MODULE_NAME] associates with:

[LIST_OF_ASSOCIATIONS]
```

Typespec for fields should include:

- `id` field

Types for fields:

- `id: integer()`

## Demo data

Each new feature must include generated demo data to seed the database. This enables
manual verification of new features.

## Authorization

Always use the `Accounts.Scope` for authorization.
