# LiveView Contract – Snippet Creation

## Overview
The snippet creation experience runs entirely within a Phoenix LiveView. Client interactions emit events that update assigns locally and enqueue snippet metadata for deferred persistence. No REST API endpoints are needed.

## Events & Payloads

### `validate`
- **Triggered by**: `phx-change` on the snippet form.
- **Payload**:
  ```json
  {
    "snippet": {
      "title": "string",
      "description": "string",
      "body": "string",
      "syntax": "string",
      "tags": ["string", ...],
      "visibility": "personal|team|organization"
    }
  }
  ```
- **Behaviour**: Applies `ReviewRoom.Snippets.change_snippet/2`, returning validation errors without enqueueing. Keeps buffered values in form assigns.

### `save`
- **Triggered by**: `phx-submit` on the snippet form.
- **Payload**: Same shape as `validate` event.
- **Behaviour**:
  1. Validates inputs via context changeset.
  2. On success, calls `ReviewRoom.Snippets.enqueue/2` to stash the snippet in the in-memory buffer.
  3. Updates assigns with confirmation message, buffer position, and estimated flush time.
  4. On failure, surfaces changeset errors inline.

### `flush`
- **Triggered by**: Operator-only button rendered when user has appropriate role.
- **Behaviour**: Invokes `ReviewRoom.Snippets.flush_now/1` to force persistence. Resulting message indicates number of snippets persisted and any retry scheduling. No external HTTP call is made.

## Assigns Contract
- `@form`: Form struct built from changeset for rendering inputs and errors.
- `@buffer_position`: Optional integer indicating current queue position after enqueue.
- `@estimated_flush_at`: Optional `DateTime` computed from buffer policy (queue size threshold or idle timeout).
- `@syntax_options`: List of `{label, value}` pairs sourced from `ReviewRoom.Snippets.SyntaxRegistry`.
- `@visibility_options`: Static trio matching `personal|team|organization`.
- `@tags_catalog`: List of tag maps `{label, value}` to drive multi-select UI.

## Success & Failure Messaging
- Successful save emits flash: "Snippet queued (position N). We'll persist within 5 seconds or when 10 snippets accumulate."
- Validation errors remain on the form without clearing user input.
- Flush failures trigger flash error with retry notice and log correlation ID.

## Security
- LiveView mounted inside `:require_authenticated_user` scope, ensuring only authorized developers interact with snippet creation.
- Visibility choices filtered based on `@current_scope` (e.g., restrict `team`/`organization` if not permitted).

## Telemetry
- `[:review_room, :snippets, :buffer, :enqueue]` – emitted on successful queue entry with fields: `buffer_token`, `visibility`, `tag_count`.
- `[:review_room, :snippets, :buffer, :flush]` – emitted after persistence attempt with fields: `result`, `duration_ms`, `queued_count`, `attempt`.
