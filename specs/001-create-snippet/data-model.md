# Data Model – Creating a Snippet

## Entities

### Snippet
- **id**: bigint (primary key)
- **title**: string (max 120 chars; presence required)
- **description**: string (max 500 chars; presence required)
- **body**: text (presence required; soft limit 10_000 chars)
- **syntax**: string (presence required; must match curated list key)
- **tags**: array of strings `[:tag_slugs]` (presence optional; max 10 entries; stored as `{:array, :string}`)
- **visibility**: enum (`personal`, `team`, `organization`) backed by string field `visibility` with constraint check
- **author_id**: bigint (FK → users.id)
- **buffer_token**: binary/UUID stored as string to correlate buffered submissions with persisted rows
- **queued_at**: utc_datetime (auto-filled when buffer enqueues item)
- **persisted_at**: utc_datetime (set on successful flush)
- **inserted_at** / **updated_at**: utc_datetime

**Relationships**:
- belongs to `author` (`ReviewRoom.Accounts.User`)

**Validations**:
- Title, description, body required; enforce length limits
- Syntax must exist in `ReviewRoom.Snippets.SyntaxRegistry`
- Visibility must be one of allowed enum values
- Tags array accepts up to 10 unique slug strings, trimmed and validated against curated list

**Indexes/Constraints**:
- Unique index on (`buffer_token`) to prevent duplicate flushes
- Index on (`author_id`, `visibility`) for query filtering
- Partial index on `persisted_at IS NULL` to inspect buffered but not yet persisted items (diagnostics only)
- Functional index on `tags` array using GIN for tag-based search (optional future optimization)

### Tag Catalog (reference data)
- Stored as curated list (in-memory or configuration) rather than relational table.
- Each entry provides slug, display label, optional color. Managed by product operations.

## State Transitions

Snippet lifecycle:
1. **Buffered** – submission accepted; data resides in buffer with `buffer_token`, `queued_at`; no DB row yet.
2. **Persisting** – buffer flush in progress; corresponding DB transaction opens; on success row inserted with `persisted_at` timestamp.
3. **Persisted** – snippet stored in DB; buffer entry removed.
4. **Retrying** – flush failed; buffer retains entry, increments attempt count (tracked in buffer metadata, not DB).

Transitions guarded by GenServer state machine; failures logged and retried with capped exponential backoff.

## Derived/Supporting Structures

- **ReviewRoom.Snippets.Buffer.State**: in-memory struct per process storing list of `%BufferedSnippet{buffer_token, payload, attempts, queued_at}` entries.
- **ReviewRoom.Snippets.SyntaxRegistry**: compile-time map of allowed syntax keys to display names, consumed by LiveView and validations.

## Demo Data Requirements

- Seed file adds at least three snippets (one per visibility) linked to demo users and populated with curated tag slugs.
- Maintain curated tag catalog in configuration (e.g., `config :review_room, :snippet_tags`) so demo data and validations share the same list.
