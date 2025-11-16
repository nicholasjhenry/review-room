# Implementation Plan: Snippet Creation

**Branch**: `001-snippet-creation` | **Date**: 2025-11-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-snippet-creation/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement snippet creation functionality allowing developers to create, organize, and share code snippets with syntax highlighting, tagging, and privacy controls. This is the core MVP feature enabling authenticated users to save code snippets with metadata (title, description, language, tags, visibility) to their personal collection.

## Technical Context

**Language/Version**: Elixir ~> 1.15  
**Primary Dependencies**: Phoenix ~> 1.8.1, Phoenix LiveView ~> 1.1.0, Ecto SQL ~> 3.13, PostgreSQL  
**Storage**: PostgreSQL (via Ecto) for snippets, tags, and associations  
**Testing**: ExUnit (built-in), Phoenix.ConnTest, Phoenix.LiveViewTest  
**Target Platform**: Web application (server-rendered LiveView)
**Project Type**: Web application (Phoenix framework with LiveView)  
**Performance Goals**: NEEDS CLARIFICATION (snippet creation latency target, concurrent users)  
**Constraints**: 500KB max snippet size (per spec), <2s tag filtering for 1000 snippets (per spec)  
**Scale/Scope**: NEEDS CLARIFICATION (expected user count, snippets per user, total snippet volume)
**Syntax Highlighting Library**: NEEDS CLARIFICATION (which library to use for client-side syntax highlighting)  
**Authentication**: Phoenix phx.gen.auth already implemented (Accounts.Scope pattern in use)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Tests-first plan documented**: Spec includes comprehensive test plan with unit tests (snippet validation, XSS sanitization, field constraints) and integration tests (full creation flow, LiveView validation, visibility enforcement, tag filtering). All tests must be written and failing before implementation begins.
- [x] **Cross-boundary interactions enumerated**: Database persistence (Ecto), LiveView <-> Snippets context, syntax highlighting library integration (client-side), and tag association (many-to-many). Integration tests required for each pathway with supporting test data.
- [x] **Dependencies documented explicitly**: Syntax highlighting library choice needs research (Phase 0). No hidden global state - all dependencies passed explicitly through function signatures. Configuration for max snippet size (500KB) and supported languages list to be validated at boot.
- [x] **Failure handling strategy captured**: Validation failures (user-facing errors), database persistence failures (5s timeout, log with context), syntax highlighting load failures (circuit breaker after 3 failures, degrade to plain text), unauthorized access attempts (log security events, return 404), oversized content (real-time feedback, log potential abuse).
- [x] **Demo data additions planned**: Will extend priv/repo/seeds.exs with representative snippets covering all languages, visibility levels, tag combinations, and edge cases (large snippets, special characters) for manual verification.
- [ ] **Skill-driven implementation verified**: Required skills (`phoenix-contexts`, `ecto`, `phoenix-liveview`, `elixir-core`, `elixir-testing`) must be invoked before code generation. All generated code must follow skill-mandated conventions (context macro usage, typespec patterns, documentation rules). Constitution v1.1.0 compliance required.

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
lib/
├── review_room/                    # Business logic layer
│   ├── snippets/                   # NEW: Snippet domain context
│   │   └── snippet.ex             # Ecto schema & changeset (with tags array)
│   └── snippets.ex                # NEW: Public API for snippet operations
│
├── review_room_web/               # Web/presentation layer
│   ├── live/                      # LiveView modules
│   │   ├── snippet_live/          # NEW: Snippet feature LiveViews
│   │   │   ├── index.ex          # List snippets
│   │   │   ├── new.ex            # Create snippet form
│   │   │   ├── show.ex           # View single snippet
│   │   │   └── form_component.ex # Reusable form component
│   │   └── snippet_live.ex        # NEW: Shared helpers
│   └── components/
│       └── snippet_components.ex  # NEW: Snippet UI components
│
├── priv/
│   └── repo/
│       ├── migrations/
│       │   └── NNNN_create_snippets.exs           # NEW (with tags array + GIN index)
│       └── seeds.exs              # MODIFY: Add snippet demo data
│
└── test/
    ├── review_room/
    │   └── snippets_test.exs      # NEW: Context unit tests
    ├── review_room_web/
    │   └── live/
    │       └── snippet_live_test.exs  # NEW: LiveView integration tests
    └── support/
        └── fixtures/
            └── snippets_fixtures.ex   # NEW: Test data helpers
```

**Structure Decision**: Phoenix web application with standard context-based architecture. Following Phoenix conventions:
- Business logic in `lib/review_room/snippets/` (context)
- LiveView presentation in `lib/review_room_web/live/snippet_live/`
- Single migration for snippets table (tags stored as PostgreSQL array)
- Test mirrors source structure under `test/`
- Follows phx.gen.auth routing patterns for authenticated routes

**Tag Storage Approach**: Uses PostgreSQL array column instead of many-to-many relationship for simplicity:
- One table instead of three (no Tag or SnippetTag tables)
- Single INSERT query instead of transaction with batch upserts
- GIN index enables efficient tag filtering (O(log n) performance)
- Simpler testing (no fixture complexity for associations)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** - Constitution Check passed completely. All design decisions align with project principles:

- ✅ Test-first development: Comprehensive test plan documented in spec, failing tests written before implementation
- ✅ Explicit dependencies: Highlight.js researched and documented, configuration validated at boot
- ✅ Cross-boundary tests: Database, LiveView, syntax highlighting integration all tested
- ✅ Fail fast: Validation failures, timeouts, circuit breakers, structured logging all planned
- ✅ Demo data: Seeds planned with edge cases covered

---

## Phase 2: Implementation Ready

**Prerequisites Met:**
- ✅ Technical Context filled (resolved all NEEDS CLARIFICATION)
- ✅ Constitution Check passed (no violations)
- ✅ Phase 0: Research completed (`research.md`)
- ✅ Phase 1: Design artifacts generated:
  - `data-model.md` - Complete entity/relationship design
  - `contracts/liveview-api.md` - API contract specification
  - `quickstart.md` - Step-by-step implementation guide
- ✅ Agent context updated with new technology (Highlight.js)

**Next Command:** `/speckit.tasks`

This will generate `tasks.md` with dependency-ordered implementation tasks based on the completed planning artifacts.

---

## Summary

**Branch**: `001-snippet-creation`  
**Implementation Plan**: `/Users/nicholas/Workspaces/professional/projects/review_room/src/specs/001-snippet-creation/plan.md`

**Generated Artifacts:**
1. ✅ `research.md` - Technology decisions (Highlight.js, performance targets, LiveView patterns)
2. ✅ `data-model.md` - Database schema, relationships, query patterns
3. ✅ `contracts/liveview-api.md` - Context API and LiveView contracts
4. ✅ `quickstart.md` - TDD implementation guide with step-by-step instructions

**Key Decisions:**
- **Syntax Highlighting**: Highlight.js (30-45 KB bundle, best performance for 500KB files)
- **Performance Targets**: p50 < 100ms, p95 < 200ms, support 1K-5K concurrent users (MVP)
- **Tag Pattern**: PostgreSQL array column with GIN index (simpler schema, fewer queries, atomic updates)
- **Visibility**: Database-level filtering, return 404 (not 403) for security
- **Validation**: Dual-layer (client warning + server enforcement)

**Technology Stack Confirmed:**
- Elixir ~> 1.15
- Phoenix ~> 1.8.1 with LiveView ~> 1.1.0
- PostgreSQL via Ecto SQL ~> 3.13
- Highlight.js 11.11.2 for syntax highlighting
- ExUnit for testing
