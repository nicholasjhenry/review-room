# Research: Developer Code Snippet Creation

**Feature**: 001-snippet-creation  
**Date**: 2025-10-31  
**Status**: Complete

## Research Questions

### 1. Syntax Highlighting: Client-Side vs Server-Side Rendering

**Question**: Should syntax highlighting be performed client-side (JavaScript) or server-side (Elixir)?

**Decision**: Client-side syntax highlighting using Highlight.js

**Rationale**:
- **Performance**: Avoids server CPU usage for syntax parsing; scales better with many concurrent users
- **User Experience**: Immediate visual feedback as users type in the code editor
- **Bundle Size**: Highlight.js supports selective language loading (~5KB per language vs ~200KB for all)
- **Phoenix Integration**: Works seamlessly with LiveView via phx-hook for real-time updates
- **Maintenance**: Well-established library (11M+ weekly npm downloads) with active community
- **LiveView Compatibility**: Can be integrated as a client hook that runs on phx-update events

**Alternatives Considered**:
1. **Server-side with Elixir library (makeup)**: 
   - Pros: No client JavaScript, consistent rendering
   - Cons: Increases server load, slower initial render, no real-time preview during typing
   - Rejected: Poor UX for editing experience, unnecessary server burden for presentation logic

2. **Hybrid approach (server for initial, client for editing)**:
   - Pros: Fast initial page load, interactive editing
   - Cons: Complexity maintaining two highlighting implementations, potential visual inconsistencies
   - Rejected: Over-engineered for this use case

**Implementation Notes**:
- Use Highlight.js CDN or npm package in assets/js
- Create Phoenix LiveView hook to initialize highlighting on mount and re-highlight on content changes
- Language selector in form drives which highlighter language pack to load
- Store language choice in snippet schema for consistent rendering on view

**References**:
- Highlight.js: https://highlightjs.org/
- Phoenix LiveView hooks: https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks
- Elixir makeup (alternative): https://github.com/elixir-makeup/makeup

---

### 2. Auto-Save Strategy: Periodic vs Manual-Only

**Question**: Should snippets auto-save periodically or only on explicit user action?

**Decision**: Manual-only save (explicit form submission)

**Rationale**:
- **User Control**: Developers expect explicit save actions for code; auto-save can be disruptive when experimenting
- **Simplicity**: No background timers or processes needed; aligns with "event-triggered persistence" requirement
- **Data Integrity**: Users confirm they want to save before persisting, reducing accidental saves of incomplete/broken code
- **Phoenix Patterns**: Standard form submission pattern is well-tested and familiar
- **LiveView Benefits**: In-memory editing gives instant feedback; database write only happens once on submit
- **Privacy**: Users may want to discard sensitive code without it being saved; manual save respects this

**Alternatives Considered**:
1. **Auto-save every N seconds**:
   - Pros: No data loss on browser crash, familiar from modern editors
   - Cons: Unwanted database writes, user confusion about save state, violates "event-triggered" requirement
   - Rejected: Contradicts stated requirement for "event-triggered persistence to Postgres instead of immediate writes"

2. **Auto-save on idle (debounced)**:
   - Pros: Balances safety with user control
   - Cons: Still periodic writes, complexity determining "idle", ambiguous user intent
   - Rejected: Doesn't align with explicit event-triggered approach

3. **Draft system (auto-save drafts + explicit publish)**:
   - Pros: Best of both worlds, common pattern in CMS
   - Cons: Significant added complexity (draft table, state machine, UI for drafts vs published)
   - Rejected: Over-engineered for MVP; can be added later if user research indicates need

**Implementation Notes**:
- LiveView maintains all snippet data in socket assigns (code, title, description, tags, language, visibility)
- `phx-change` events validate in real-time and update socket state without DB writes
- `phx-submit` event is the only trigger for database persistence via context call
- Show clear save status: "Unsaved changes" indicator, success flash message on save
- Consider browser beforeunload warning if unsaved changes exist (optional enhancement)

**References**:
- Phoenix form handling: https://hexdocs.pm/phoenix_live_view/form-bindings.html
- LiveView assigns: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#assign/3

---

### 3. Syntax Highlighting Language Support

**Research**: Which programming languages must be supported based on FR-014?

**Decision**: Support the following 15 languages initially (extensible via configuration)

**Supported Languages**:
1. JavaScript
2. TypeScript
3. Python
4. Java
5. Go
6. Ruby
7. PHP
8. C
9. C++
10. C#
11. SQL
12. HTML
13. CSS
14. Shell/Bash
15. Markdown
16. **Elixir** (added given this is an Elixir project)

**Rationale**:
- Covers FR-014 requirements plus Elixir for project relevance
- Highlight.js supports all these languages in its common distribution
- Represents most popular languages according to Stack Overflow survey 2024
- Easily extensible - adding more languages is configuration change only

**Implementation Notes**:
- Store supported languages as application configuration in config/config.exs
- Create dropdown/select input with language names (human-readable)
- Map display names to Highlight.js language identifiers (e.g., "Shell/Bash" -> "bash")
- Validate selected language against supported list in changeset
- Store language identifier in snippet schema as string

**Configuration Example**:
```elixir
config :review_room, :snippet_languages, [
  %{name: "JavaScript", code: "javascript"},
  %{name: "TypeScript", code: "typescript"},
  %{name: "Python", code: "python"},
  # ... etc
]
```

---

### 4. Team Visibility: Team Membership Determination

**Research**: How to determine "team" membership for team-only snippet visibility?

**Decision**: Defer team implementation; support only "private" and "public" for MVP

**Rationale**:
- **No existing team model**: Project uses phx.gen.auth which provides user accounts but not teams/organizations
- **Scope creep risk**: Implementing teams requires significant additional work:
  - Team schema and migrations
  - Team membership management
  - Authorization logic for team-based access
  - UI for team management
  - Tests for all team interactions
- **MVP focus**: Private and public visibility covers primary use cases:
  - Private: Personal code snippets, sensitive information
  - Public: Shared examples, open-source snippets
- **Future extensibility**: Can add team visibility in future iteration when team model exists

**Alternatives Considered**:
1. **Implement basic team model now**:
   - Pros: Feature complete per spec
   - Cons: Large scope increase, delays MVP, requires designing entire team subsystem
   - Rejected: Out of scope for snippet creation feature

2. **Use existing organization/scope concept**:
   - Pros: Might leverage existing auth constructs
   - Cons: Would need to investigate if such construct exists; still requires integration work
   - Rejected: No evidence of existing team/org model in project structure

**Specification Impact**:
- User Story 4 (Privacy Controls) modified to support private/public only
- FR-007 modified: "set visibility/privacy level for their snippet (private, public)"
- Team-only tests moved to future backlog
- Success criteria SC-005 updated to reflect private/public enforcement only

**Implementation Notes**:
- Snippet schema visibility field: enum of [:private, :public]
- Default to :private per FR-008
- Authorization logic:
  - Private: snippet.user_id == current_user.id
  - Public: always accessible
- Database query scoping based on visibility and current user
- UI shows "Private" and "Public" options in radio buttons or dropdown

**Future Work**:
When team feature is added:
- Add :team visibility option to enum
- Add team_id foreign key to snippets table
- Add team authorization check
- Update UI with team option

---

### 5. In-Memory State Management Pattern

**Research**: Best practices for in-memory editing with LiveView socket assigns

**Decision**: Use LiveView socket assigns as single source of truth during editing session

**Pattern**:
```elixir
# Mount: Initialize empty form
def mount(_params, _session, socket) do
  {:ok, assign(socket, 
    form: to_form(Snippets.change_snippet(%Snippet{})),
    snippet_params: %{},
    save_status: :unsaved
  )}
end

# Change event: Update in-memory state only
def handle_event("validate", %{"snippet" => snippet_params}, socket) do
  changeset = Snippets.change_snippet(%Snippet{}, snippet_params)
  {:noreply, assign(socket, 
    form: to_form(changeset, action: :validate),
    snippet_params: snippet_params,
    save_status: :unsaved
  )}
end

# Submit event: Persist to database
def handle_event("save", %{"snippet" => snippet_params}, socket) do
  case Snippets.create_snippet(socket.assigns.current_scope, snippet_params) do
    {:ok, snippet} ->
      {:noreply, 
        socket
        |> assign(save_status: :saved)
        |> put_flash(:info, "Snippet saved successfully")
        |> push_navigate(to: ~p"/snippets/#{snippet}")}
    {:error, changeset} ->
      {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end
end
```

**Rationale**:
- **Standard LiveView pattern**: Assigns as component state is idiomatic
- **Real-time validation**: Changeset validates on every change without DB hits
- **Memory efficiency**: Socket assigns cleaned up when connection closes
- **Concurrent editing**: Each user's edits isolated to their socket; no locking needed
- **Error handling**: Validation errors display immediately; DB errors caught on save

**Best Practices**:
- Use `change_snippet/2` for validation-only changesets (no DB interaction)
- Use `create_snippet/2` for persistence (includes DB transaction if needed)
- Pass `current_scope` to context functions per phx.gen.auth patterns
- Clear save status on any subsequent change to show "unsaved" again
- Consider max socket assign size (default 10MB sufficient for 1MB max snippet)

**References**:
- Phoenix LiveView form docs: https://hexdocs.pm/phoenix_live_view/form-bindings.html
- Ecto changeset validation: https://hexdocs.pm/ecto/Ecto.Changeset.html

---

## Technology Stack Summary

**Client-Side**:
- Highlight.js for syntax highlighting (via CDN or npm)
- Phoenix LiveView hooks for integration
- Standard HTML forms with phx-change/phx-submit events

**Server-Side**:
- Phoenix LiveView for real-time UI
- Ecto for database modeling and persistence
- PostgreSQL for storage
- ExUnit + Phoenix.LiveViewTest for testing

**Configuration**:
- Application config for supported languages list
- Runtime config for max snippet size, max tags
- Environment variables for database connection (existing)

**No Additional Dependencies Required**:
- Highlight.js is client-side only (no Hex package needed)
- All other requirements met by existing Phoenix/Ecto stack

---

## Risk Analysis

### Identified Risks

1. **XSS via code content**: 
   - Mitigation: Phoenix auto-escapes by default; code displayed in `<pre><code>` blocks
   - Additional: Content-Security-Policy headers, no eval() of snippet content

2. **Large snippet performance**:
   - Mitigation: 1MB limit enforced at validation; Highlight.js handles large files well
   - Monitoring: Log snippet sizes, alert if many near limit

3. **Highlight.js CDN failure**:
   - Mitigation: Graceful degradation to unstyled code block
   - Alternative: Bundle Highlight.js locally in assets (increases bundle size)

4. **Memory usage with many concurrent editors**:
   - Mitigation: LiveView assigns cleared on disconnect; 1MB per user negligible
   - Monitoring: Track socket count and memory usage

### No Significant Blockers

All NEEDS CLARIFICATION items resolved with clear implementation paths. No external service dependencies beyond CDN (optional). Standard Phoenix patterns throughout.
