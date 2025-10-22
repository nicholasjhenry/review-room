# Quickstart Guide: Real-Time Code Snippet Sharing System

**Date**: 2025-10-21
**Feature**: Real-Time Code Snippet Sharing System
**Audience**: Developers implementing this feature

## Overview

This quickstart provides the implementation roadmap for the real-time code snippet sharing system. Follow this guide to understand the feature architecture, development workflow, and key implementation patterns.

**Feature Highlights**:
- Create and share code snippets with syntax highlighting
- Real-time collaborative viewing with cursor/selection tracking
- Public/private visibility controls with discoverable gallery
- Anonymous and authenticated user support

**Tech Stack**:
- **Backend**: Phoenix 1.8.1, Phoenix LiveView 1.1.0, Ecto 3.13+
- **Real-time**: Phoenix PubSub, Phoenix Tracker (distributed presence)
- **Frontend**: highlight.js (syntax highlighting), LiveView hooks (cursor tracking)
- **Database**: PostgreSQL with indexed queries
- **IDs**: 8-character nanoid for shareable URLs

---

## Architecture Overview

### High-Level Flow

```
┌─────────────┐
│   Browser   │
│             │
│  highlight  │  ← Syntax highlighting (client-side)
│    .js      │
│             │
│  LiveView   │  ← Real-time UI (WebSocket)
│   Hooks     │
└──────┬──────┘
       │ WebSocket
       ↓
┌──────────────────────────────────────┐
│     Phoenix LiveView (Server)        │
│                                      │
│  ┌────────────┐    ┌──────────────┐ │
│  │ SnippetLive│    │PresenceTracker│ │
│  │  .Show     │←──→│   (Tracker)   │ │
│  └────────────┘    └──────────────┘ │
│         │                  │         │
│         ↓                  ↓         │
│  ┌─────────────────────────────┐    │
│  │   Phoenix PubSub (Broadcast) │    │
│  │   Topic: "snippet:#{id}"     │    │
│  └─────────────────────────────┘    │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│       Snippets Context (Ecto)        │
│                                      │
│   ┌──────────┐      ┌────────────┐  │
│   │ Snippet  │      │   User     │  │
│   │ (schema) │──────│  (schema)  │  │
│   └──────────┘      └────────────┘  │
└──────────────┬───────────────────────┘
               │
               ↓
        ┌─────────────┐
        │ PostgreSQL  │
        │  (snippets) │
        └─────────────┘
```

### Component Responsibilities

**LiveView Modules** (lib/review_room_web/live/snippet_live/):
- `new.ex`: Snippet creation form
- `show.ex`: Snippet viewing + real-time collaboration
- `edit.ex`: Snippet editing (owner only)
- `index.ex`: Public gallery with search/filter

**Context Module** (lib/review_room/snippets.ex):
- CRUD operations (create, read, update, delete)
- Query functions (list, search, filter)
- Authorization (can_edit?, can_delete?)

**Schemas** (lib/review_room/snippets/):
- `snippet.ex`: Snippet entity (Ecto schema + changesets)
- `presence_tracker.ex`: Phoenix Tracker for real-time presence

**Client Hooks** (assets/js/hooks/):
- `syntax_highlight.js`: Apply highlight.js to code blocks
- `cursor_tracker.js`: Send cursor/selection updates to server
- `presence_renderer.js`: Render other users' cursors as overlays

---

## Development Workflow

### Phase 2: Task Generation (Next Step)

Run `/speckit.tasks` to generate the detailed task breakdown. This will create:
- `specs/002-realtime-snippet-sharing/tasks.md`
- Dependency-ordered tasks with test-first requirements
- Estimated effort and acceptance criteria per task

**Expected Tasks** (preview):
1. Database setup (migration, schema)
2. Context functions (CRUD operations)
3. LiveView pages (new, show, edit, index)
4. Real-time features (presence tracking, cursor sync)
5. Client-side integration (highlight.js, hooks)
6. Public gallery (search, filter, pagination)
7. Authorization (edit/delete permissions)

### Implementation Order (Test-First)

Per **Constitution Principle I** (Test-First Development), follow this workflow for each task:

```
1. Write failing tests (ExUnit)
2. Get user approval for tests
3. Run tests → verify RED ❌
4. Implement minimum code to pass
5. Run tests → verify GREEN ✅
6. Refactor if needed
7. Run `mix precommit` before commit
```

**Example** (Task: "Create snippet schema"):

```elixir
# Step 1: Write test FIRST (test/review_room/snippets_test.exs)
defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase, async: true
  alias ReviewRoom.Snippets

  describe "create_snippet/2" do
    test "creates snippet with valid attributes" do
      attrs = %{code: "def hello, do: :world", language: "elixir"}

      assert {:ok, snippet} = Snippets.create_snippet(attrs)
      assert snippet.code == "def hello, do: :world"
      assert snippet.language == "elixir"
      assert String.length(snippet.id) == 8  # nanoid
    end

    test "requires code" do
      attrs = %{title: "No code"}

      assert {:error, changeset} = Snippets.create_snippet(attrs)
      assert "can't be blank" in errors_on(changeset).code
    end
  end
end

# Step 2: User approves tests ✓
# Step 3: Run tests → RED ❌ (Snippets module doesn't exist yet)
# Step 4: Implement minimum code (schema, context function)
# Step 5: Run tests → GREEN ✅
# Step 6: Refactor if needed
# Step 7: mix precommit → commit
```

---

## Key Implementation Patterns

### 1. LiveView Streams (Constitution Principle IV)

**Required for all collections**:
- Public gallery (snippets list)
- User snippet history
- Presence list (active viewers)

**Pattern**:
```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    snippets = Snippets.list_public_snippets(limit: 20)
    {:ok, stream(socket, :snippets, snippets)}
  else
    {:ok, stream(socket, :snippets, [])}
  end
end

def handle_event("load_more", %{"cursor" => cursor}, socket) do
  snippets = Snippets.list_public_snippets(cursor: cursor, limit: 20)
  {:noreply, stream(socket, :snippets, snippets)}  # Append
end

def handle_event("filter", %{"language" => lang}, socket) do
  snippets = Snippets.list_public_snippets(language: lang, limit: 20)
  {:noreply, stream(socket, :snippets, snippets, reset: true)}  # Reset
end
```

**Template**:
```heex
<div id="snippets" phx-update="stream">
  <div :for={{id, snippet} <- @streams.snippets} id={id}>
    <!-- Snippet card -->
  </div>
</div>
```

### 2. Phoenix Tracker for Presence

**Setup** (lib/review_room/application.ex):
```elixir
children = [
  # ... existing children ...
  ReviewRoom.Snippets.PresenceTracker
]
```

**Track User** (in LiveView mount):
```elixir
def mount(%{"id" => snippet_id}, session, socket) do
  if connected?(socket) do
    topic = "snippet:#{snippet_id}"
    Phoenix.PubSub.subscribe(ReviewRoom.PubSub, topic)

    user_id = get_user_id(socket, session)
    PresenceTracker.track_user(snippet_id, user_id, %{
      cursor: nil,
      display_name: get_display_name(socket),
      color: assign_random_color()
    })
  end

  {:ok, assign(socket, snippet_id: snippet_id, presences: %{})}
end
```

**Update Cursor**:
```elixir
def handle_event("cursor_moved", %{"line" => line, "column" => col}, socket) do
  user_id = get_user_id(socket)
  PresenceTracker.update_cursor(socket.assigns.snippet_id, user_id, %{
    cursor: %{line: line, column: col}
  })
  {:noreply, socket}
end
```

**Receive Updates**:
```elixir
def handle_info({:presence_diff, diff}, socket) do
  presences = merge_presence_diff(socket.assigns.presences, diff)
  {:noreply, assign(socket, presences: presences)}
end
```

### 3. Client-Side Hooks

**Register Hooks** (assets/js/app.js):
```javascript
import { SyntaxHighlight } from "./hooks/syntax_highlight"
import { CursorTracker } from "./hooks/cursor_tracker"
import { PresenceRenderer } from "./hooks/presence_renderer"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { SyntaxHighlight, CursorTracker, PresenceRenderer },
  params: {_csrf_token: csrfToken}
})
```

**Use in Templates**:
```heex
<!-- Syntax highlighting -->
<div id="code-display" phx-hook="SyntaxHighlight" phx-update="ignore">
  <pre><code class="language-{@snippet.language}">{@snippet.code}</code></pre>
</div>

<!-- Cursor tracking (send events to server) -->
<div id="code-area" phx-hook="CursorTracker">
  <!-- Interactive code area -->
</div>

<!-- Presence rendering (display other users' cursors) -->
<div id="presence-overlay" phx-hook="PresenceRenderer" data-presences={Jason.encode!(@presences)}>
  <!-- Cursor overlays rendered here -->
</div>
```

### 4. Form Handling (Phoenix Guidelines)

**LiveView**:
```elixir
def mount(_params, _session, socket) do
  changeset = Snippets.change_snippet(%Snippet{})
  {:ok, assign(socket, form: to_form(changeset))}
end

def handle_event("validate", %{"snippet" => params}, socket) do
  changeset =
    %Snippet{}
    |> Snippets.change_snippet(params)
    |> Map.put(:action, :validate)

  {:noreply, assign(socket, form: to_form(changeset))}
end

def handle_event("save", %{"snippet" => params}, socket) do
  case Snippets.create_snippet(params, socket.assigns.current_user) do
    {:ok, snippet} ->
      {:noreply, push_navigate(socket, to: ~p"/s/#{snippet.id}")}

    {:error, changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

**Template**:
```heex
<.form for={@form} id="snippet-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:code]} type="textarea" label="Code" required />
  <.input field={@form[:title]} type="text" label="Title" />
  <.input field={@form[:language]} type="select" label="Language"
          options={language_options()} />
  <.input field={@form[:visibility]} type="select" label="Visibility"
          options={[{"Private", "private"}, {"Public", "public"}]} />

  <.button type="submit">Create Snippet</.button>
</.form>
```

---

## Testing Strategy

### Test Pyramid

```
        ┌───────────────┐
        │  LiveView     │  ← 20% (user journeys)
        │  Integration  │
        └───────────────┘
       ┌─────────────────┐
       │   Context       │  ← 30% (business logic)
       │   Functions     │
       └─────────────────┘
      ┌───────────────────┐
      │   Schema/         │  ← 50% (data validation)
      │   Changesets      │
      └───────────────────┘
```

### Test Files

```
test/review_room/
└── snippets/
    ├── snippet_test.exs          # Schema and changeset tests
    └── presence_tracker_test.exs # Tracker behavior tests

test/review_room/
└── snippets_test.exs             # Context function tests

test/review_room_web/
└── live/
    └── snippet_live/
        ├── new_test.exs          # Creation form tests
        ├── show_test.exs         # Viewing + collaboration tests
        ├── edit_test.exs         # Editing tests
        └── index_test.exs        # Gallery tests
```

### Example LiveView Test

```elixir
defmodule ReviewRoomWeb.SnippetLive.ShowTest do
  use ReviewRoomWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "snippet viewing" do
    setup do
      snippet = snippet_fixture(%{
        code: "def hello, do: :world",
        language: "elixir",
        visibility: :public
      })

      %{snippet: snippet}
    end

    test "displays snippet with syntax highlighting", %{conn: conn, snippet: snippet} do
      {:ok, view, html} = live(conn, ~p"/s/#{snippet.id}")

      assert html =~ snippet.code
      assert has_element?(view, "#code-display[phx-hook='SyntaxHighlight']")
    end

    test "shows presence list when multiple users connect", %{conn: conn, snippet: snippet} do
      # User 1 connects
      {:ok, view1, _html} = live(conn, ~p"/s/#{snippet.id}")

      # User 2 connects
      {:ok, view2, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Both should see 2 users in presence list
      assert view1 |> element("#presence-list") |> render() =~ "2 viewers"
      assert view2 |> element("#presence-list") |> render() =~ "2 viewers"
    end

    test "broadcasts cursor movements to other users", %{conn: conn, snippet: snippet} do
      {:ok, view1, _html} = live(conn, ~p"/s/#{snippet.id}")
      {:ok, view2, _html} = live(conn, ~p"/s/#{snippet.id}")

      # User 1 moves cursor
      view1 |> element("#code-area")
            |> render_hook("cursor_moved", %{"line" => 5, "column" => 10})

      # User 2 should see the cursor position update
      # (verify via assigns or rendered presence overlay)
      assert view2.assigns.presences
             |> Map.values()
             |> Enum.any?(fn p -> p.cursor == %{line: 5, column: 10} end)
    end
  end
end
```

---

## Dependencies to Add

### Elixir Dependencies

Add to `mix.exs`:

```elixir
defp deps do
  [
    # ... existing deps ...
    {:nanoid, "~> 2.0"}  # Short ID generation
  ]
end
```

Run:
```bash
mix deps.get
```

### JavaScript Dependencies

Add to `package.json` (assets/):

```json
{
  "dependencies": {
    "highlight.js": "^11.9.0"
  }
}
```

Run:
```bash
cd assets && npm install
```

---

## Configuration

### Router Updates (lib/review_room_web/router.ex)

```elixir
scope "/", ReviewRoomWeb do
  pipe_through :browser

  # Public routes
  live "/", PageLive, :index
  live "/snippets", SnippetLive.Index, :index
  live "/s/:id", SnippetLive.Show, :show
end

scope "/", ReviewRoomWeb do
  pipe_through [:browser, :require_authenticated_user]

  # Authenticated routes
  live "/snippets/new", SnippetLive.New, :new
  live "/snippets/my", UserSnippetLive.Index, :index
  live "/s/:id/edit", SnippetLive.Edit, :edit
end
```

### Application Supervision Tree

Add PresenceTracker to `lib/review_room/application.ex`:

```elixir
def start(_type, _args) do
  children = [
    # ... existing children ...
    ReviewRoom.Snippets.PresenceTracker
  ]

  opts = [strategy: :one_for_one, name: ReviewRoom.Supervisor]
  Supervisor.start_link(children, opts)
end
```

---

## Next Steps

1. **Run `/speckit.tasks`** to generate detailed task breakdown
2. **Review tasks.md** for implementation order and estimates
3. **Start with database setup** (migration, schema, tests)
4. **Follow test-first workflow** for each task
5. **Run `mix precommit`** before all commits
6. **Use `/speckit.analyze`** to verify cross-artifact consistency

---

## Success Criteria Verification

After implementation, verify these acceptance criteria from spec.md:

✅ **SC-001**: Users can create and share a snippet in under 30 seconds
✅ **SC-002**: Cursor/selection updates appear within 200ms
✅ **SC-003**: Presence list updates within 5 seconds on join/leave
✅ **SC-004**: Supports 50+ concurrent users per snippet
✅ **SC-005**: Syntax highlighting renders correctly (95%+ accuracy)
✅ **SC-006**: One-click copy to clipboard
✅ **SC-007**: Network reconnection restores state within 3 seconds
✅ **SC-008**: Anonymous users can create snippets without auth
✅ **SC-009**: 90% first-time success rate for snippet sharing
✅ **SC-010**: Page load time under 2 seconds

---

## Reference Documentation

- [Phoenix LiveView Guide](https://hexdocs.pm/phoenix_live_view/)
- [Phoenix Tracker Documentation](https://hexdocs.pm/phoenix/Phoenix.Tracker.html)
- [Phoenix PubSub Guide](https://hexdocs.pm/phoenix_pubsub/)
- [highlight.js Documentation](https://highlightjs.org/)
- [Ecto Schema Guide](https://hexdocs.pm/ecto/Ecto.Schema.html)
- [Project CLAUDE.md](../../../CLAUDE.md) - Phoenix/LiveView guidelines
- [Constitution](../../../.specify/memory/constitution.md) - Development principles

---

**Feature Ready for Implementation** → Run `/speckit.tasks` to begin
