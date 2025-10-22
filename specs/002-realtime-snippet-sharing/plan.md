# Implementation Plan: Real-Time Code Snippet Sharing System

**Branch**: `002-realtime-snippet-sharing` | **Date**: 2025-10-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-realtime-snippet-sharing/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature implements a real-time code snippet sharing system allowing developers to create, share, and collaboratively view code snippets with live cursor/selection tracking and user presence awareness. The system supports both anonymous and authenticated users, offers public/private visibility controls, and provides a discoverable gallery for public snippets. Technical approach leverages Phoenix LiveView for real-time collaboration, Phoenix PubSub for presence broadcasting, and PostgreSQL for persistent storage.

## Technical Context

**Language/Version**: Elixir 1.15+
**Primary Dependencies**: Phoenix 1.8.1, Phoenix LiveView 1.1.0, Ecto 3.13+, Phoenix PubSub
**Storage**: PostgreSQL (via Postgrex) for snippet persistence and metadata
**Testing**: ExUnit (built-in), Phoenix.LiveViewTest for LiveView testing, LazyHTML for assertions
**Target Platform**: Web application (server-rendered LiveView with real-time WebSocket communication)
**Project Type**: Phoenix web application (single monolith with lib/review_room and lib/review_room_web)
**Performance Goals**: <200ms cursor/selection update latency, 50+ concurrent users per snippet session, <2s page load
**Constraints**: WebSocket-based real-time sync required, syntax highlighting for 20+ languages, graceful reconnection handling
**Scale/Scope**: MVP targets ~100k snippets, 1000 concurrent users across all snippets, no size limit per snippet (reasonable code snippets ~1000 lines)

**Technical Decisions Resolved (Phase 0 - see research.md)**:

- ✅ Syntax highlighting library: Client-side highlight.js (190+ languages, 80KB bundle)
- ✅ Real-time cursor/selection state management: Phoenix Tracker + LiveView assigns
- ✅ Snippet ID generation strategy: 8-character nanoid (short, shareable URLs)
- ✅ Language detection approach: Manual selection with highlight.js auto-detect fallback
- ✅ Public gallery pagination/search strategy: PostgreSQL ILIKE + cursor pagination + streams

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Principle I: Test-First Development (NON-NEGOTIABLE)

**Status**: ✅ PASS - Planning phase, no code written yet
**Action Required**: All implementation phases MUST write tests first before any production code

### Principle II: Phoenix/LiveView Best Practices

**Status**: ✅ PASS - Plan adheres to Phoenix 1.8+ patterns
**Verification Points**:

- LiveView streams MUST be used for snippet lists (gallery, user history)
- Forms MUST use `to_form/2` and `<.form for={@form}>`
- Real-time cursor/selection updates MUST use Phoenix PubSub + LiveView assigns
- Templates MUST wrap with `<Layouts.app>`
- Unique DOM IDs required for all interactive elements

### Principle III: Type Safety & Compile-Time Guarantees

**Status**: ✅ PASS - Will enforce via precommit
**Action Required**:

- All public functions MUST have `@spec` annotations
- Pattern matching required for cursor position/selection data structures
- No `String.to_atom/1` on user input (snippet language codes)

### Principle IV: LiveView Streams for Collections

**Status**: ✅ PASS - Identified collections:

- Snippet gallery (public snippets list)
- User snippet history (authenticated user's snippets)
- Presence list (active viewers in a snippet session)

**Action Required**: All three collections MUST use `stream/3` and `stream_delete/3`

### Principle V: Quality Gates & Precommit

**Status**: ✅ PASS - `mix precommit` alias exists and will be enforced
**Action Required**: Run `mix precommit` before all commits during implementation

**Constitution Check Result**: ✅ ALL GATES PASSED - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```
specs/002-realtime-snippet-sharing/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── liveview-events.md  # LiveView event contracts (not REST/GraphQL)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/review_room/
├── snippets/                    # Snippet context (new)
│   ├── snippet.ex               # Snippet schema
│   ├── presence_tracker.ex      # Phoenix Tracker for user presence
│   └── syntax_highlighter.ex    # Syntax highlighting service
├── accounts/                    # Existing user authentication context
│   └── user.ex                  # User schema (existing)
└── repo.ex                      # Ecto repo (existing)

lib/review_room_web/
├── live/                        # LiveView modules (new)
│   ├── snippet_live/
│   │   ├── index.ex             # Snippet gallery (public snippets)
│   │   ├── new.ex               # Create new snippet
│   │   ├── show.ex              # View/collaborate on snippet
│   │   ├── edit.ex              # Edit snippet (owner only)
│   │   └── components.ex        # Snippet-specific components
│   └── user_snippet_live/
│       └── index.ex             # User's snippet history (authenticated)
├── components/                  # Shared components (existing)
│   └── core_components.ex       # Core UI components (existing)
├── controllers/                 # Existing
└── router.ex                    # Routes (existing, will be modified)

test/review_room/
└── snippets/                    # Snippet context tests (new)

test/review_room_web/
└── live/                        # LiveView tests (new)
    └── snippet_live/

priv/repo/migrations/            # Database migrations (new)
└── XXXXXX_create_snippets.exs
```

**Structure Decision**: Standard Phoenix 1.8 monolith structure with context-driven design. Snippets context encapsulates all snippet-related business logic and schemas. LiveView modules handle real-time UI. Phoenix Tracker manages distributed presence state across nodes.

## Complexity Tracking

_Fill ONLY if Constitution Check has violations that must be justified_

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| N/A       | N/A        | N/A                                  |

No constitution violations identified in planning phase.

---

## Post-Design Constitution Check

**Date**: 2025-10-21 (After Phase 0 Research + Phase 1 Design)

### Principle I: Test-First Development (NON-NEGOTIABLE)
**Status**: ✅ PASS - Ready for implementation  
**Verification**: Design artifacts (data-model.md, contracts) define testable interfaces  
**Next Steps**: Tasks phase MUST enforce test-first for all implementation work

### Principle II: Phoenix/LiveView Best Practices
**Status**: ✅ PASS - Design follows Phoenix 1.8+ patterns  
**Verification**:
- ✅ LiveView streams specified for all collections (gallery, user snippets)
- ✅ Forms use `to_form/2` pattern (see contracts/liveview-events.md)
- ✅ Real-time uses Phoenix Tracker + PubSub (see research.md Decision 2)
- ✅ Client hooks properly use `phx-update="ignore"` (see quickstart.md)
- ✅ All forms have unique DOM IDs specified

### Principle III: Type Safety & Compile-Time Guarantees
**Status**: ✅ PASS - Design enables type safety  
**Verification**:
- ✅ Schema fields use proper Ecto types (`:string`, `Ecto.Enum`, `:binary_id`)
- ✅ Language validation uses whitelist (no `String.to_atom/1` on user input)
- ✅ Presence metadata uses structured maps (enables pattern matching)
- ✅ `@spec` annotations required in implementation (enforced by precommit)

### Principle IV: LiveView Streams for Collections
**Status**: ✅ PASS - All collections use streams  
**Verification**:
- ✅ Public gallery: `stream(socket, :snippets, snippets, reset: true)` for filters
- ✅ User history: `stream(socket, :snippets, user_snippets)`
- ✅ Presence data: Uses assigns (map-based real-time state, not append/delete)

### Principle V: Quality Gates & Precommit
**Status**: ✅ PASS - Dependencies and workflow ready  
**Verification**:
- ✅ New dependency: `nanoid` (will be added to mix.exs)
- ✅ JS dependency: `highlight.js` (will be added to package.json)
- ✅ All dependencies are MIT licensed (no licensing issues)
- ✅ Workflow documented in quickstart.md

**Final Constitution Check Result**: ✅ ALL GATES PASSED - Ready for Phase 2 (Tasks)

**Design Artifacts Complete**:
- ✅ research.md (5 technical decisions resolved)
- ✅ data-model.md (schemas, migrations, queries)
- ✅ contracts/liveview-events.md (event interfaces)
- ✅ quickstart.md (implementation guide)
- ✅ CLAUDE.md updated (agent context)
