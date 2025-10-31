# Implementation Plan: Developer Code Snippet Creation

**Branch**: `001-snippet-creation` | **Date**: 2025-10-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-snippet-creation/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a developer code snippet creation system with in-memory state management and event-triggered persistence. Developers can create, edit, and manage code snippets with syntax highlighting, tags, metadata (title/description), and privacy controls. The system will hold snippet data in LiveView socket state during editing, persisting to PostgreSQL only on explicit save/submit events. This approach enables real-time editing without database writes and simplifies concurrent edit handling.

## Technical Context

**Language/Version**: Elixir 1.19.1 with Erlang/OTP  
**Primary Dependencies**: Phoenix LiveView (real-time UI), Ecto (database), NEEDS CLARIFICATION: Syntax highlighting library (client-side vs server-side rendering)  
**Storage**: PostgreSQL (persistent storage via Ecto), LiveView socket assigns (in-memory state during editing)  
**Testing**: ExUnit (unit tests), Phoenix.LiveViewTest (integration tests)  
**Target Platform**: Web application (Phoenix)  
**Project Type**: Web application with Phoenix LiveView frontend and Ecto backend  
**Performance Goals**: 
- Snippet creation/editing interactions respond in <100ms (in-memory updates)
- Database persistence completes in <500ms
- Syntax highlighting renders immediately on page load
- Support up to 1MB snippet size without degradation  
**Constraints**: 
- In-memory editing: No database writes until explicit save event
- Event-triggered persistence: Save on form submit, auto-save on NEEDS CLARIFICATION: timer interval or never
- Must work within authenticated user session (phx.gen.auth)
- Maximum 10 tags per snippet
- Privacy enforcement must be foolproof (no data leaks)  
**Scale/Scope**: 
- Multi-user system with privacy controls
- Support 14+ programming languages for syntax highlighting
- Handle concurrent users creating snippets independently
- NEEDS CLARIFICATION: Auto-save strategy (periodic vs manual-only)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Tests-first plan documented: Feature spec includes 11 unit tests and 11 integration tests to be written before implementation. Unit tests cover changeset validation, authorization logic. Integration tests cover LiveView flows, database interactions, form submissions, privacy enforcement.
- [x] Cross-boundary interactions enumerated with required integration tests and supporting data setup:
  - LiveView <-> Snippets context: Integration tests for snippet creation/viewing with user authentication
  - Database <-> Ecto schemas: Tests for snippet storage, tag associations, user relationships
  - Authentication <-> Authorization: Tests for privacy enforcement (private/team/public access)
  - Syntax highlighting library <-> Frontend: Tests for CSS class application and rendering
  - Form validation <-> Changesets: Tests for XSS sanitization, size limits, required fields
- [x] Dependencies, configuration changes, and feature contracts documented explicitly:
  - Syntax highlighting library (client or server-side - to be decided in research)
  - Authentication system (phx.gen.auth - already in place, verified via current_scope)
  - Configuration: MAX_SNIPPET_SIZE (1MB), MAX_TAGS_PER_SNIPPET (10), SUPPORTED_LANGUAGES (14+ languages)
  - No hidden coupling: All data flows through LiveView socket assigns -> form submission -> context -> database
- [x] Failure handling strategy captured for each external dependency:
  - Database failures: User-friendly error messages, error-level logging with user/timestamp, alerts at 1% failure rate
  - Syntax highlighting library load failures: Graceful degradation to plain text, warning logs, user notification
  - Authentication failures: Redirect to login, error logging, circuit breaker for repeated failures
  - Tag association failures: Partial save with warning message, retry capability
  - All failures include structured logging with trace IDs for correlation
- [x] Demo data additions planned: Will extend priv/repo/seeds.exs with sample snippets covering:
  - Multiple languages (JavaScript, Python, Elixir, etc.)
  - Different privacy levels (private, team, public)
  - Various tag combinations
  - Edge cases (large snippets, many tags, no title/description)

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/review_room/
├── snippets/
│   └── snippet.ex                 # Ecto schema (includes tags as array field)
└── snippets.ex                    # Public context API

lib/review_room_web/
├── live/
│   └── snippet_live/
│       ├── new.ex                 # Snippet creation LiveView
│       ├── new.html.heex          # Creation form template
│       ├── show.ex                # Snippet display LiveView
│       └── show.html.heex         # Display template
└── router.ex                      # Route definitions

priv/repo/
├── migrations/
│   └── [timestamp]_create_snippets.exs
└── seeds.exs                      # Demo data additions

test/review_room/
└── snippets_test.exs              # Context unit tests

test/review_room_web/live/
└── snippet_live_test.exs          # LiveView integration tests

assets/js/
└── hooks/                         # Client-side syntax highlighting (if needed)
    └── syntax_highlighter.js
```

**Structure Decision**: Phoenix web application following standard Phoenix conventions:
- Business logic in `lib/review_room/snippets/` context
- Single Snippet schema with PostgreSQL array field for tags (no join table needed)
- LiveView UI in `lib/review_room_web/live/snippet_live/`
- Database schema and migration in standard Ecto locations
- Tests mirror source structure under `test/`
- Client-side assets in `assets/` if syntax highlighting is client-side

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations detected. All Constitution Check items passed. Feature follows standard Phoenix patterns with in-memory editing via LiveView socket assigns and event-triggered persistence to PostgreSQL.
