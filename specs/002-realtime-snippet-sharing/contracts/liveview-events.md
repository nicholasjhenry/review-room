# LiveView Event Contracts: Real-Time Code Snippet Sharing

**Date**: 2025-10-21
**Feature**: Real-Time Code Snippet Sharing System
**Purpose**: Define client-server event contracts for LiveView interactions

## Overview

This document specifies the event interface between LiveView client (JavaScript) and server (Elixir). Unlike REST APIs, Phoenix LiveView uses bidirectional event messaging over WebSocket.

**Event Flow**:
- **Client → Server**: `phx-*` bindings trigger `handle_event/3` callbacks
- **Server → Client**: `push_event/3` sends events to client hooks
- **Server → Server**: PubSub messages handled by `handle_info/2`

---

## Snippet Creation (New Snippet)

### LiveView: `SnippetLive.New`

**Route**: `GET /snippets/new`

**Mount Parameters**: None

**Assigns**:
```elixir
%{
  form: Phoenix.Component.form(%Ecto.Changeset{}),
  current_user: %User{} | nil
}
```

### Event: `validate`

**Trigger**: `phx-change="validate"` on form

**Payload** (client → server):
```elixir
%{
  "snippet" => %{
    "code" => "def hello, do: :world",
    "title" => "Example Elixir Function",
    "description" => "A simple hello world function",
    "language" => "elixir",
    "visibility" => "private"  # "public" | "private"
  }
}
```

**Response** (server → client):
- Updates `@form` assign with validation errors
- Re-renders form with error messages

**Validation Rules**:
- `code`: Required, non-empty string
- `title`: Optional, max 200 characters
- `description`: Optional string
- `language`: Optional, must be in supported languages list
- `visibility`: Required, must be "public" or "private"

### Event: `save`

**Trigger**: `phx-submit="save"` on form

**Payload** (client → server):
```elixir
%{
  "snippet" => %{
    "code" => "def hello, do: :world",
    "title" => "Example Elixir Function",
    "description" => "A simple hello world function",
    "language" => "elixir",
    "visibility" => "private"
  }
}
```

**Success Response**:
- Creates snippet in database
- Redirects to snippet show page: `push_navigate(socket, to: ~p"/s/#{snippet.id}")`

**Error Response**:
- Updates `@form` with errors
- Shows flash message: `put_flash(socket, :error, "Unable to create snippet")`

---

## Snippet Viewing (Real-Time Collaboration)

### LiveView: `SnippetLive.Show`

**Route**: `GET /s/:id`

**Mount Parameters**:
```elixir
%{"id" => "aB3dE5fG"}  # 8-character snippet ID
```

**Initial Assigns**:
```elixir
%{
  snippet: %Snippet{},
  current_user: %User{} | nil,
  presences: %{},  # Map of user_id => presence metadata
  viewer_id: "user_uuid" | "anon_#{session_id}",
  viewer_color: "#3B82F6"
}
```

**PubSub Subscription**:
- Topic: `"snippet:#{snippet_id}"`
- Receives presence updates from other viewers

### Event: `cursor_moved`

**Trigger**: JavaScript hook on mousemove in code area

**Payload** (client → server):
```elixir
%{
  "line" => 10,
  "column" => 5
}
```

**Server Action**:
1. Update Phoenix.Tracker with new cursor position
2. Broadcast to other viewers via PubSub (automatic via Tracker)

**Broadcast** (server → all clients except sender):
```elixir
{:presence_diff, %{
  joins: %{},
  leaves: %{},
  updates: %{
    "user_uuid" => %{
      cursor: %{line: 10, column: 5},
      selection: nil
    }
  }
}}
```

**Rate Limiting**: Throttle to max 10 updates/second per user (client-side)

### Event: `text_selected`

**Trigger**: JavaScript hook on text selection change

**Payload** (client → server):
```elixir
%{
  "start" => %{"line" => 10, "column" => 5},
  "end" => %{"line" => 12, "column" => 15}
}
```

**Server Action**:
1. Update Phoenix.Tracker with selection range
2. Broadcast to other viewers

**Broadcast** (server → all clients):
```elixir
{:presence_diff, %{
  updates: %{
    "user_uuid" => %{
      cursor: %{line: 12, column: 15},
      selection: %{
        start: %{line: 10, column: 5},
        end: %{line: 12, column: 15}
      }
    }
  }
}}
```

### Event: `selection_cleared`

**Trigger**: JavaScript hook when selection is cleared (click without drag)

**Payload** (client → server):
```elixir
%{}  # Empty payload
```

**Server Action**:
1. Update Phoenix.Tracker with `selection: nil`
2. Broadcast clearance

### PubSub Message: `presence_diff`

**Source**: Phoenix.Tracker broadcasts to all subscribers

**Payload** (server → client via `handle_info/2`):
```elixir
{:presence_diff, %{
  joins: %{
    "user_abc" => %{
      cursor: nil,
      selection: nil,
      display_name: "Alice",
      color: "#3B82F6",
      joined_at: 1640000000
    }
  },
  leaves: %{
    "user_xyz" => %{...}
  }
}}
```

**Client Action**:
1. Merge joins/leaves into `@presences` assign
2. Re-render presence list UI
3. Update cursor/selection overlays

---

## Snippet Editing

### LiveView: `SnippetLive.Edit`

**Route**: `GET /s/:id/edit`

**Authorization**: Only snippet owner can access

**Mount Parameters**:
```elixir
%{"id" => "aB3dE5fG"}
```

**Assigns**:
```elixir
%{
  snippet: %Snippet{},
  form: Phoenix.Component.form(%Ecto.Changeset{}),
  current_user: %User{}
}
```

### Event: `validate`

**Same as creation** (see Snippet Creation section)

### Event: `save`

**Trigger**: `phx-submit="save"` on form

**Payload** (client → server):
```elixir
%{
  "snippet" => %{
    "code" => "def hello(name), do: \"Hello, #{name}!\"",
    "title" => "Updated Function",
    "description" => "Now accepts a parameter",
    "language" => "elixir",
    "visibility" => "public"
  }
}
```

**Success Response**:
1. Update snippet in database
2. Broadcast update to all viewers (if any are connected)
3. Redirect to show page: `push_navigate(socket, to: ~p"/s/#{snippet.id}")`

**Broadcast** (via PubSub to active viewers):
```elixir
{:snippet_updated, %{
  snippet_id: "aB3dE5fG",
  code: "new code content",
  title: "Updated Function",
  language: "elixir"
}}
```

**Error Response**:
- Update `@form` with errors
- Show flash error

### Event: `delete`

**Trigger**: `phx-click="delete"` on delete button (with confirmation)

**Payload** (client → server):
```elixir
%{"id" => "aB3dE5fG"}
```

**Success Response**:
1. Delete snippet from database
2. Broadcast deletion to active viewers
3. Redirect to home: `push_navigate(socket, to: ~p"/")`

**Broadcast** (to active viewers):
```elixir
{:snippet_deleted, %{snippet_id: "aB3dE5fG"}}
```

**Active viewers receive**:
- Flash message: "This snippet has been deleted"
- Redirect to home page

---

## Public Gallery

### LiveView: `SnippetLive.Index`

**Route**: `GET /snippets`

**Mount Parameters**: None

**Initial Assigns**:
```elixir
%{
  snippets: [],  # Empty initially, populated on connect
  streams: %{snippets: []},  # LiveView stream
  filter_language: nil,
  search_query: nil
}
```

**On Connect** (`connected?/1 == true`):
- Load first page of public snippets (20 items)
- Initialize stream: `stream(socket, :snippets, snippets)`

### Event: `load_more`

**Trigger**: `phx-click="load_more"` on "Load More" button or infinite scroll

**Payload** (client → server):
```elixir
%{
  "cursor" => "2025-10-21T10:30:00Z"  # inserted_at of last loaded snippet
}
```

**Response**:
- Load next 20 snippets after cursor
- Append to stream: `stream(socket, :snippets, new_snippets)`

### Event: `filter`

**Trigger**: `phx-change="filter"` on language dropdown

**Payload** (client → server):
```elixir
%{
  "language" => "elixir"  # or nil for "All Languages"
}
```

**Response**:
- Query filtered snippets
- Reset stream: `stream(socket, :snippets, filtered_snippets, reset: true)`

### Event: `search`

**Trigger**: `phx-submit="search"` on search form

**Payload** (client → server):
```elixir
%{
  "query" => "hello world"
}
```

**Response**:
- Search snippets by title/description
- Reset stream with results: `stream(socket, :snippets, results, reset: true)`

### Event: `clear_search`

**Trigger**: `phx-click="clear_search"` on clear button

**Payload** (client → server):
```elixir
%{}
```

**Response**:
- Reset to unfiltered gallery
- Reset stream: `stream(socket, :snippets, all_public_snippets, reset: true)`

---

## User Snippet History

### LiveView: `UserSnippetLive.Index`

**Route**: `GET /snippets/my`

**Authorization**: Requires authenticated user

**Mount Parameters**: None

**Assigns**:
```elixir
%{
  current_user: %User{},
  streams: %{snippets: []}
}
```

**On Connect**:
- Load user's snippets: `list_user_snippets(user.id)`
- Initialize stream

### Event: `toggle_visibility`

**Trigger**: `phx-click="toggle_visibility"` on visibility toggle button

**Payload** (client → server):
```elixir
%{
  "id" => "aB3dE5fG"
}
```

**Response**:
1. Toggle snippet visibility (private ↔ public)
2. Update snippet in stream: `stream_insert(socket, :snippets, updated_snippet)`
3. Show flash: "Snippet is now public/private"

### Event: `delete`

**Trigger**: `phx-click="delete"` with confirmation

**Payload** (client → server):
```elixir
%{
  "id" => "aB3dE5fG"
}
```

**Response**:
1. Delete snippet
2. Remove from stream: `stream_delete(socket, :snippets, snippet)`
3. Show flash: "Snippet deleted"

---

## Client-Side Hooks

### `SyntaxHighlight` Hook

**Purpose**: Apply highlight.js to code blocks

**Lifecycle**:
- `mounted()`: Highlight code on initial render
- `updated()`: Re-highlight if code changes

**JavaScript**:
```javascript
export const SyntaxHighlight = {
  mounted() {
    this.highlight();
  },
  updated() {
    this.highlight();
  },
  highlight() {
    const codeBlock = this.el.querySelector('code');
    if (codeBlock) {
      hljs.highlightElement(codeBlock);
    }
  }
};
```

**HEEx Usage**:
```heex
<div id="code-container" phx-hook="SyntaxHighlight" phx-update="ignore">
  <pre><code class="language-{@snippet.language}">{@snippet.code}</code></pre>
</div>
```

### `CursorTracker` Hook

**Purpose**: Track mouse position and send cursor updates to server

**Events Sent**:
- `cursor_moved`: On mousemove (throttled to 10/sec)
- `text_selected`: On selection change
- `selection_cleared`: On click without selection

**JavaScript**:
```javascript
export const CursorTracker = {
  mounted() {
    this.el.addEventListener('mousemove', throttle(this.handleMouseMove.bind(this), 100));
    this.el.addEventListener('mouseup', this.handleSelection.bind(this));
  },
  handleMouseMove(event) {
    const position = this.getLineColumn(event);
    this.pushEvent('cursor_moved', position);
  },
  handleSelection(event) {
    const selection = window.getSelection();
    if (selection.toString().length > 0) {
      const range = this.getSelectionRange(selection);
      this.pushEvent('text_selected', range);
    } else {
      this.pushEvent('selection_cleared', {});
    }
  },
  getLineColumn(event) {
    // Calculate line/column from mouse position
    // Returns: {line: 10, column: 5}
  },
  getSelectionRange(selection) {
    // Calculate start/end positions from Selection API
    // Returns: {start: {line, column}, end: {line, column}}
  }
};
```

### `PresenceRenderer` Hook

**Purpose**: Render other users' cursors and selections as overlays

**Receives**: Updates to `@presences` assign

**JavaScript**:
```javascript
export const PresenceRenderer = {
  updated() {
    this.renderCursors();
    this.renderSelections();
  },
  renderCursors() {
    // For each presence in @presences:
    // - Create/update cursor div at position
    // - Style with user's color
    // - Show username tooltip
  },
  renderSelections() {
    // For each presence with selection:
    // - Highlight selected range with user's color (low opacity)
  }
};
```

---

## Error Handling

### Client Disconnection

**Server Detection**: Phoenix.Tracker automatically detects process termination

**Server Action**:
1. Remove user from tracker
2. Broadcast `leave` event to remaining viewers

**Client Reconnection**:
1. LiveView automatically reconnects
2. `mount/3` called again
3. User re-joins presence tracker
4. Cursor position reset to nil

### Snippet Not Found

**Mount Response**:
```elixir
def mount(%{"id" => id}, _session, socket) do
  case Snippets.get_snippet(id) do
    nil ->
      socket
      |> put_flash(:error, "Snippet not found")
      |> push_navigate(to: ~p"/")

    snippet ->
      {:ok, assign(socket, snippet: snippet)}
  end
end
```

### Unauthorized Edit/Delete

**Mount Response** (edit page):
```elixir
def mount(%{"id" => id}, _session, socket) do
  snippet = Snippets.get_snippet!(id)

  if Snippets.can_edit?(snippet, socket.assigns.current_user) do
    {:ok, assign(socket, snippet: snippet)}
  else
    socket
    |> put_flash(:error, "You don't have permission to edit this snippet")
    |> push_navigate(to: ~p"/s/#{id}")
  end
end
```

---

## Performance Considerations

**Cursor Update Throttling**:
- Client-side: Max 10 updates/second (100ms throttle)
- Prevents overwhelming server with mousemove events

**Presence Broadcast Batching**:
- Phoenix.Tracker automatically batches updates
- Diffs sent every ~1 second (configurable)

**Stream Pagination**:
- Load 20 snippets per page
- Append on scroll (no re-fetching)
- Reset on filter/search changes

**Code Highlighting**:
- Client-side only (no server CPU usage)
- `phx-update="ignore"` prevents unnecessary re-renders

---

## Contract Summary

**LiveViews**: 4 total
- `SnippetLive.New` (create)
- `SnippetLive.Show` (view/collaborate)
- `SnippetLive.Edit` (update)
- `SnippetLive.Index` (gallery)
- `UserSnippetLive.Index` (user history)

**Client Events**: 10 total
- `validate`, `save`, `delete`
- `cursor_moved`, `text_selected`, `selection_cleared`
- `load_more`, `filter`, `search`, `clear_search`, `toggle_visibility`

**Server Broadcasts**: 3 total
- `presence_diff` (cursor/selection updates)
- `snippet_updated` (edit propagation)
- `snippet_deleted` (deletion notification)

**Client Hooks**: 3 total
- `SyntaxHighlight` (highlight.js integration)
- `CursorTracker` (mouse tracking)
- `PresenceRenderer` (cursor/selection overlays)

**Next Phase**: Quickstart guide
