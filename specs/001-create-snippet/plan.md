# Implementation Plan: Creating a Snippet

**Branch**: `001-create-snippet` | **Date**: 2025-10-30 | **Spec**: specs/001-create-snippet/spec.md
**Input**: Feature specification from `/specs/001-create-snippet/spec.md`

## Summary

Enable authenticated developers to compose, tag, and control the visibility of reusable code snippets. The UI will capture snippet metadata immediately, stage submissions in an in-memory buffer for low-latency feedback, and flush batches to PostgreSQL when triggered by either a queue size threshold or a short idle timeout. Tag selection is backed by a curated configuration list and stored as a string array directly on the snippet record, eliminating the need for a join table. The plan covers validation, authorization, observability, and demo data updates.

## Technical Context

**Language/Version**: Elixir ~> 1.15, Phoenix ~> 1.8.1
**Primary Dependencies**: Phoenix LiveView/UI components, Ecto (Repo), Req (existing), Phoenix PubSub for notifications
**Storage**: PostgreSQL (durable) plus supervised `ReviewRoom.Snippets.Buffer` GenServer maintaining in-memory queue per scope
**Testing**: ExUnit, Phoenix.LiveViewTest, Ecto SQL Sandbox
**Target Platform**: Phoenix web app deployed on Linux/Bandit
**Project Type**: Web application (monolith)
**Performance Goals**: Snippet creation confirmation under 2 seconds; batched persistence flush completes within 5 seconds of trigger
**Constraints**: Enforce eventual write queue honoring transaction boundaries; flush on queue size ≥ 10 or idle timeout (5s) with exponential-backoff retries max 3 attempts
**Scale/Scope**: Internal developer teams (tens to low hundreds of active users) with concurrent snippet drafts under 100 per hour

## Constitution Check

- [x] Tests-first plan documented: unit tests for field validation, tag normalization, visibility defaults; integration tests for LiveView flow, authorization redirect, visibility enforcement, and failure handling
- [x] Cross-boundary interactions enumerated with required integration tests and supporting data setup (LiveView ↔ context, Repo batched writes, authorization checks)
- [x] Dependencies, configuration changes, and feature contracts documented explicitly; no hidden coupling (buffer process, Repo, tag taxonomy)
- [x] Failure handling strategy captured for each external dependency (Repo failures, tag taxonomy fetch, buffer flush retries with structured logging)
- [x] Demo data additions planned for `priv/repo/seeds.exs` to include representative tagged snippets at each visibility level

## Project Structure

### Documentation (this feature)

```text
specs/001-create-snippet/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md (Phase 2)
```

### Source Code (repository root)

```text
lib/
├── review_room/
│   ├── accounts/
│   ├── snippets/            # context for snippet domain (to be expanded)
│   └── repo.ex
└── review_room_web/
    ├── components/
    ├── controllers/
    ├── live/
    │   └── snippet_live/    # new LiveView + components for creation form
    └── templates/

priv/
├── repo/
│   ├── migrations/
│   └── seeds.exs            # demo snippet records

assets/
└── js/                      # LiveView hooks if needed for client preview

test/
├── review_room/
│   └── snippets/            # context unit tests (new)
└── review_room_web/
    └── live/                # LiveView integration tests
```

**Structure Decision**: Extend the existing monolithic Phoenix structure by adding a `ReviewRoom.Snippets` context, accompanying LiveView modules under `lib/review_room_web/live/snippet_live`, and test directories mirroring those namespaces. Leverage existing `priv/repo/seeds.exs` for demo data and keep assets aligned with current Phoenix build pipeline.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
