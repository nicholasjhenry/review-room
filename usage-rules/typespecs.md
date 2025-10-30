## Typespec guidelines

- ensure all public context modules have typespecs

### Ecto Schemas

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
