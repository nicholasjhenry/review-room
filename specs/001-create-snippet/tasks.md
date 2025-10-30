---
description: "Task list template for feature implementation"
---

# Tasks: Creating a Snippet

**Input**: Design documents from `/specs/001-create-snippet/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/liveview.md, quickstart.md
**Tests**: Tests are REQUIRED for every user story. Start with context unit tests that fail, then cover LiveView flows and authorization regressions before implementing code.
**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., [US1], [US2], [US3])
- Include exact file paths in descriptions

## Path Conventions

- Phoenix context code lives under `lib/`
- LiveView modules & components live under `lib/review_room_web/`
- Tests live under `test/`
- Database migrations live under `priv/repo/migrations/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare configuration, supervision, and fixtures required for all snippet work.

- [ ] T001 Update config/config.exs to define snippet tag catalog entries and buffer thresholds for snippet batching.
- [ ] T002 [P] Register ReviewRoom.Snippets.Buffer as a supervised child in lib/review_room/application.ex.
- [ ] T003 [P] Create snippet fixture helpers for authenticated scopes in test/support/fixtures/snippets_fixtures.ex.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the Snippet data model and buffer infrastructure that every story relies on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T004 Create the snippets table migration with required columns, indexes, and visibility constraint in priv/repo/migrations/*_create_snippets.exs.
- [ ] T005 Define ReviewRoom.Snippets.Snippet schema with typedoc/typespec and base fields in lib/review_room/snippets/snippet.ex.
- [ ] T006 Author buffer behaviour tests for enqueue, flush triggers, and retry caps in test/review_room/snippets/buffer_test.exs.
- [ ] T007 Implement ReviewRoom.Snippets.Buffer GenServer with size/time flush triggers, retries, and telemetry in lib/review_room/snippets/buffer.ex.
- [ ] T008 Wire Accounts.Scope-aware enqueue/flush API surface for callers in lib/review_room/snippets.ex.

---

## Phase 3: User Story 1 - Compose and Save Snippet (Priority: P1) 🎯 MVP

**Goal**: Enable an authenticated developer to draft a snippet with required metadata and enqueue it for persistence with immediate confirmation.
**Independent Test**: Verify that a developer can submit a complete snippet form and see the snippet listed with all fields saved.

### Tests for User Story 1 (MANDATORY - write these first) ⚠️

- [ ] T009 [P] [US1] Add context tests covering required field validation and buffer enqueue failures in test/review_room/snippets/snippets_test.exs.
- [ ] T010 [P] [US1] Add LiveView tests for happy-path submission and inline error messaging in test/review_room_web/live/snippet_live_new_test.exs.

### Implementation for User Story 1

- [ ] T011 [US1] Implement required field validations and length guards in lib/review_room/snippets/snippet.ex.
- [ ] T012 [US1] Implement change_snippet/2 and enqueue/2 functions that accept Accounts.Scope and return buffer metadata in lib/review_room/snippets.ex.
- [ ] T013 [US1] Build ReviewRoomWeb.SnippetLive.New LiveView with validate/save handlers, buffer feedback assigns, and form markup in lib/review_room_web/live/snippet_live/new.ex.
- [ ] T014 [US1] Register the authenticated snippet creation route inside the :browser + :require_authenticated_user pipeline and live_session :require_authenticated_user in lib/review_room_web/router.ex to enforce login.

**Checkpoint**: User Story 1 complete delivers the MVP flow with buffered persistence feedback for authenticated developers.

---

## Phase 4: User Story 2 - Organize Snippet Metadata (Priority: P2)

**Goal**: Provide curated syntax options and tag selection so snippets are categorized for discovery.
**Independent Test**: Confirm tags and language selections persist and drive filtering in existing snippet listings without needing other new functionality.

### Tests for User Story 2 (MANDATORY - write these first) ⚠️

- [ ] T015 [P] [US2] Extend context tests to cover tag normalization, duplicate rejection, and syntax validation in test/review_room/snippets/snippets_test.exs.
- [ ] T016 [P] [US2] Extend LiveView tests to assert syntax dropdown rendering and tag persistence in test/review_room_web/live/snippet_live_new_test.exs.

### Implementation for User Story 2

- [ ] T017 [P] [US2] Implement ReviewRoom.Snippets.SyntaxRegistry backed by curated config in lib/review_room/snippets/syntax_registry.ex.
- [ ] T018 [P] [US2] Implement ReviewRoom.Snippets.TagCatalog loader that exposes options and validation helpers in lib/review_room/snippets/tag_catalog.ex.
- [ ] T019 [US2] Update Snippet changeset to normalize, deduplicate, and cap tags plus enforce allowed syntax values in lib/review_room/snippets/snippet.ex.
- [ ] T020 [US2] Update Snippets context to expose syntax_options/1 and tags_catalog/1 helpers consumed by the LiveView in lib/review_room/snippets.ex.
- [ ] T021 [US2] Update LiveView to load curated syntax/tag options and render multi-select inputs in lib/review_room_web/live/snippet_live/new.ex.
- [ ] T022 [P] [US2] Add reusable snippet form components for syntax select and tag chips in lib/review_room_web/components/snippet_form_components.ex.

**Checkpoint**: User Story 2 complete ensures snippets persist curated syntax and normalized tags for discovery.

---

## Phase 5: User Story 3 - Control Snippet Visibility (Priority: P3)

**Goal**: Allow developers to set snippet visibility with scope-aware enforcement before saving.
**Independent Test**: Validate visibility options and access rules without relying on future enhancements.

### Tests for User Story 3 (MANDATORY - write these first) ⚠️

- [ ] T023 [P] [US3] Extend context tests to cover default visibility, allowed values, and scope filtering in test/review_room/snippets/snippets_test.exs.
- [ ] T024 [P] [US3] Extend LiveView tests verifying visibility option filtering and default notices in test/review_room_web/live/snippet_live_new_test.exs.

### Implementation for User Story 3

- [ ] T025 [US3] Update Snippet changeset to enforce allowed visibility values and default to personal in lib/review_room/snippets/snippet.ex.
- [ ] T026 [US3] Implement scope-aware visibility guardrails and flush permission checks in lib/review_room/snippets.ex.
- [ ] T027 [US3] Update LiveView to filter visibility options via Accounts.Scope and surface defaulting notices in lib/review_room_web/live/snippet_live/new.ex.
- [ ] T028 [US3] Emit visibility audit telemetry/log fields for buffer enqueue events in lib/review_room/telemetry.ex.

**Checkpoint**: User Story 3 complete enforces visibility choices end-to-end and logs decisions for audit.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finalize demo data, documentation, and observability for the snippet creation feature.

- [ ] T029 Seed demo snippets for each visibility level with curated tags in priv/repo/seeds.exs.
- [ ] T030 [P] Document snippet creation workflow, manual flush, and metadata expectations in README.md.
- [ ] T031 [P] Update quickstart walkthrough with telemetry verification steps in specs/001-create-snippet/quickstart.md.

---

## Dependencies & Execution Order

- Setup (T001-T003) must finish before foundational work so config and supervision are in place.
- Foundational tasks (T004-T008) create the schema, buffer, and context surface that all user stories rely on.
- User Story 1 (T009-T014) depends on foundational tasks and delivers the MVP; complete it before starting User Story 2.
- User Story 2 (T015-T022) depends on User Story 1 because it extends the same LiveView and context but remains independently testable once US1 is merged.
- User Story 3 (T023-T028) depends on prior stories for shared modules yet should not regress earlier flows; tests guarantee independence.
- Polish (T029-T031) runs last to align docs, seeds, and telemetry with the finalized implementation.

## Parallel Opportunities

- T002 and T003 can run alongside T001 after config decisions are made.
- Within foundational work, T005 and T006 can begin once T004 defines the schema, while T007 follows failing tests in T006.
- Story tests tagged [P] (T009, T010, T015, T016, T023, T024) can be authored concurrently by different engineers to drive TDD.
- Component and helper implementations (T017, T018, T022) can proceed in parallel once interface contracts are agreed.
- Documentation updates (T030, T031) can happen concurrently with final verification once development stabilizes.

## Parallel Example: User Story 1

```
# In parallel, author failing tests before implementation
T009 [P] [US1] Add context tests covering required field validation and buffer enqueue failures in test/review_room/snippets/snippets_test.exs
T010 [P] [US1] Add LiveView tests for happy-path submission and inline error messaging in test/review_room_web/live/snippet_live_new_test.exs

# After tests exist, split implementation tasks
T011 [US1] Implement required field validations and length guards in lib/review_room/snippets/snippet.ex
T012 [US1] Implement change_snippet/2 and enqueue/2 functions that accept Accounts.Scope and return buffer metadata in lib/review_room/snippets.ex
```

## Implementation Strategy

- Deliver the MVP by completing Setup → Foundational → User Story 1 (T001-T014), then validate via quickstart and mix test.
- Iterate by layering metadata enhancements (T015-T022) and visibility enforcement (T023-T028), running targeted tests after each story.
- Reserve Polish tasks (T029-T031) for the end so documentation, seeds, and telemetry capture the final behaviour.
- Use the shared `web` CLI to exercise the LiveView after each story and confirm buffer flush telemetry before closing the feature.
