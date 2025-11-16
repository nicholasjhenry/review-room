# Tasks: Snippet Creation

**Feature Branch**: `001-snippet-creation`  
**Input**: Design documents from `/specs/001-snippet-creation/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/liveview-api.md, quickstart.md

**Tests**: Tests are REQUIRED per constitution (Test-First Development). Write failing tests BEFORE implementing production code.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

Phoenix project structure (from plan.md):
- **Business logic**: `lib/review_room/`
- **Web layer**: `lib/review_room_web/`
- **Migrations**: `priv/repo/migrations/`
- **Tests**: `test/`
- **Seeds**: `priv/repo/seeds.exs`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Install dependencies and configure syntax highlighting

- [ ] T001 Install Highlight.js 11.11.2 via npm in assets/ directory
- [ ] T002 [P] Import Highlight.js core and 12 language modules in assets/js/app.js
- [ ] T003 [P] Add Highlight.js CSS theme to assets/css/app.css
- [ ] T004 Configure supported languages list in config/config.exs

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema and test infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Generate migration for snippets table with mix ecto.gen.migration create_snippets
- [ ] T006 Edit migration priv/repo/migrations/NNNN_create_snippets.exs with all fields (slug, title, description, code, language, tags array, visibility, user_id)
- [ ] T007 Add GIN index for tags array and composite indexes in migration
- [ ] T008 Run mix ecto.migrate to apply database changes
- [ ] T009 [P] Create test/support/fixtures/snippets_fixtures.ex with snippet_fixture, public_snippet_fixture, tagged_snippet_fixture helpers
- [ ] T010 [P] Create lib/review_room/snippets/ directory for context

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create Basic Snippet (Priority: P1) 🎯 MVP

**Goal**: Enable developers to save code snippets with title and content to their personal collection

**Independent Test**: Navigate to /snippets/new, enter title "Test Snippet" and code "defmodule Test do end", click save, verify snippet appears in /snippets list with correct content

### Tests for User Story 1 (MANDATORY - write these first) ⚠️

- [ ] T011 [P] [US1] Unit test: snippet creation with valid title and code succeeds in test/review_room/snippets_test.exs
- [ ] T012 [P] [US1] Unit test: snippet creation without title fails with validation error in test/review_room/snippets_test.exs
- [ ] T013 [P] [US1] Unit test: snippet creation without code fails with validation error in test/review_room/snippets_test.exs
- [ ] T014 [P] [US1] Unit test: snippet title length validation (max 200 chars) in test/review_room/snippets_test.exs
- [ ] T015 [P] [US1] Unit test: snippet code content size validation (max 500KB bytes) in test/review_room/snippets_test.exs
- [ ] T016 [P] [US1] Unit test: snippet defaults to private visibility in test/review_room/snippets_test.exs
- [ ] T017 [P] [US1] Unit test: snippet is associated with creating user in test/review_room/snippets_test.exs
- [ ] T018 [P] [US1] Unit test: slug is generated automatically from title in test/review_room/snippets_test.exs
- [ ] T019 [P] [US1] Integration test: full snippet creation flow in LiveView in test/review_room_web/live/snippet_live_test.exs
- [ ] T020 [P] [US1] Integration test: snippet appears in user's list after creation in test/review_room_web/live/snippet_live_test.exs
- [ ] T021 [P] [US1] Integration test: validation errors display in form in test/review_room_web/live/snippet_live_test.exs

**Run tests - verify all FAIL**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

### Implementation for User Story 1

- [ ] T022 [US1] Create Snippet schema in lib/review_room/snippets/snippet.ex with fields: slug, title, code, visibility, user_id, timestamps
- [ ] T023 [US1] Add slug generation logic (title-based + random suffix) in Snippet changeset
- [ ] T024 [US1] Add validation rules to Snippet changeset (required title/code, max lengths, byte count for code)
- [ ] T025 [US1] Create Snippets context in lib/review_room/snippets.ex with create_snippet/2 function
- [ ] T026 [US1] Add list_snippets/2 function to Snippets context with scope filtering
- [ ] T027 [US1] Add get_snippet/2 function to Snippets context with visibility enforcement
- [ ] T028 [US1] Add change_snippet/2 function for form changesets
- [ ] T029 [US1] Create SnippetLive.Index in lib/review_room_web/live/snippet_live/index.ex to list user snippets
- [ ] T030 [US1] Create SnippetLive.New in lib/review_room_web/live/snippet_live/new.ex with form for creating snippets
- [ ] T031 [US1] Create SnippetLive.Show in lib/review_room_web/live/snippet_live/show.ex to display single snippet
- [ ] T032 [US1] Add routes to lib/review_room_web/router.ex for /snippets, /snippets/new, /s/:slug
- [ ] T033 [US1] Configure live_session with authentication requirement for snippet management routes

**Run tests - verify all PASS**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

**Checkpoint**: User Story 1 complete - basic snippet creation works independently ✅

---

## Phase 4: User Story 2 - Set Syntax Highlighting Language (Priority: P2)

**Goal**: Enable developers to specify programming language for proper syntax highlighting

**Independent Test**: Create snippet, select "Elixir" from language dropdown, save, verify language is saved and code displays with syntax highlighting

### Tests for User Story 2 (MANDATORY - write these first) ⚠️

- [ ] T034 [P] [US2] Unit test: snippet creation with language saves correctly in test/review_room/snippets_test.exs
- [ ] T035 [P] [US2] Unit test: snippet creation without language defaults to nil in test/review_room/snippets_test.exs
- [ ] T036 [P] [US2] Unit test: language validation (must be from supported list) in test/review_room/snippets_test.exs
- [ ] T037 [P] [US2] Integration test: language selector displays in form in test/review_room_web/live/snippet_live_test.exs
- [ ] T038 [P] [US2] Integration test: syntax highlighting displays on snippet show page in test/review_room_web/live/snippet_live_test.exs

**Run tests - verify all FAIL**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

### Implementation for User Story 2

- [ ] T039 [US2] Add language field to Snippet changeset in lib/review_room/snippets/snippet.ex
- [ ] T040 [US2] Add supported_languages/0 function to Snippets context returning configured list
- [ ] T041 [US2] Add language validation to Snippet changeset (inclusion in supported list, allow nil)
- [ ] T042 [US2] Add language selector to SnippetLive.New form component
- [ ] T043 [US2] Create SyntaxHighlight LiveView hook in assets/js/app.js
- [ ] T044 [US2] Add phx-hook="SyntaxHighlight" to code display in SnippetLive.Show template
- [ ] T045 [US2] Register Highlight.js languages in assets/js/app.js hook

**Run tests - verify all PASS**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

**Checkpoint**: User Stories 1 AND 2 both work independently ✅

---

## Phase 5: User Story 3 - Add Description (Priority: P2)

**Goal**: Enable developers to add detailed description to snippets for context

**Independent Test**: Create snippet with multi-line description, save, verify description displays correctly when viewing snippet

### Tests for User Story 3 (MANDATORY - write these first) ⚠️

- [ ] T046 [P] [US3] Unit test: snippet creation with description saves correctly in test/review_room/snippets_test.exs
- [ ] T047 [P] [US3] Unit test: snippet creation without description succeeds in test/review_room/snippets_test.exs
- [ ] T048 [P] [US3] Unit test: description length validation (max 2000 chars) in test/review_room/snippets_test.exs
- [ ] T049 [P] [US3] Integration test: description field displays in form in test/review_room_web/live/snippet_live_test.exs
- [ ] T050 [P] [US3] Integration test: description displays on snippet show page in test/review_room_web/live/snippet_live_test.exs

**Run tests - verify all FAIL**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

### Implementation for User Story 3

- [ ] T051 [US3] Add description field to Snippet changeset in lib/review_room/snippets/snippet.ex
- [ ] T052 [US3] Add description length validation (max 2000) to Snippet changeset
- [ ] T053 [US3] Add description textarea to SnippetLive.New form
- [ ] T054 [US3] Display description in SnippetLive.Show template

**Run tests - verify all PASS**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

**Checkpoint**: User Stories 1, 2, AND 3 all work independently ✅

---

## Phase 6: User Story 4 - Organize with Tags (Priority: P3)

**Goal**: Enable developers to tag snippets with keywords for easy filtering and discovery

**Independent Test**: Create snippet with tags "elixir, phoenix, web", save, verify tags display and can filter snippet list by tag

### Tests for User Story 4 (MANDATORY - write these first) ⚠️

- [ ] T055 [P] [US4] Unit test: snippet creation with comma-separated tags in test/review_room/snippets_test.exs
- [ ] T056 [P] [US4] Unit test: tags are normalized (lowercase, trimmed, deduplicated) in test/review_room/snippets_test.exs
- [ ] T057 [P] [US4] Unit test: snippet creation without tags succeeds with empty array in test/review_room/snippets_test.exs
- [ ] T058 [P] [US4] Unit test: tag validation (max 50 chars per tag, alphanumeric + hyphens) in test/review_room/snippets_test.exs
- [ ] T059 [P] [US4] Unit test: list_snippets_by_tag filters correctly in test/review_room/snippets_test.exs
- [ ] T060 [P] [US4] Unit test: list_all_tags returns unique tags across snippets in test/review_room/snippets_test.exs
- [ ] T061 [P] [US4] Integration test: tag input displays in form in test/review_room_web/live/snippet_live_test.exs
- [ ] T062 [P] [US4] Integration test: tags display as badges on snippet in test/review_room_web/live/snippet_live_test.exs
- [ ] T063 [P] [US4] Integration test: clicking tag filters snippet list in test/review_room_web/live/snippet_live_test.exs

**Run tests - verify all FAIL**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

### Implementation for User Story 4

- [ ] T064 [US4] Add tags array field to Snippet changeset in lib/review_room/snippets/snippet.ex
- [ ] T065 [US4] Add normalize_tags/1 private function to Snippet module (lowercase, trim, uniq)
- [ ] T066 [US4] Add validate_tags/1 private function to Snippet module (length, format)
- [ ] T067 [US4] Add tag parsing logic to create_snippet/2 in Snippets context (comma-separated string → array)
- [ ] T068 [US4] Add list_snippets_by_tag/2 function to Snippets context with GIN index query
- [ ] T069 [US4] Add list_all_tags/0 function to Snippets context using PostgreSQL unnest
- [ ] T070 [US4] Add tags text input to SnippetLive.New form with placeholder
- [ ] T071 [US4] Display tags as clickable badges in SnippetLive.Show template
- [ ] T072 [US4] Add tag filter handling to SnippetLive.Index (handle "filter_tag" event)

**Run tests - verify all PASS**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

**Checkpoint**: User Stories 1, 2, 3, AND 4 all work independently ✅

---

## Phase 7: User Story 5 - Control Snippet Visibility (Priority: P3)

**Goal**: Enable developers to control who can view their snippets (Private/Public/Unlisted)

**Independent Test**: Create private snippet, verify other user cannot access it; create public snippet, verify unauthenticated user can view it

### Tests for User Story 5 (MANDATORY - write these first) ⚠️

- [ ] T073 [P] [US5] Unit test: snippet creation defaults to private visibility in test/review_room/snippets_test.exs
- [ ] T074 [P] [US5] Unit test: snippet creation with explicit visibility saves correctly in test/review_room/snippets_test.exs
- [ ] T075 [P] [US5] Unit test: get_snippet returns public snippet to any user in test/review_room/snippets_test.exs
- [ ] T076 [P] [US5] Unit test: get_snippet returns private snippet only to owner in test/review_room/snippets_test.exs
- [ ] T077 [P] [US5] Unit test: get_snippet returns unlisted snippet to anyone with link in test/review_room/snippets_test.exs
- [ ] T078 [P] [US5] Unit test: get_snippet returns :not_found (404) for unauthorized private snippet in test/review_room/snippets_test.exs
- [ ] T079 [P] [US5] Integration test: visibility selector displays in form in test/review_room_web/live/snippet_live_test.exs
- [ ] T080 [P] [US5] Integration test: public snippet accessible to unauthenticated user in test/review_room_web/live/snippet_live_test.exs
- [ ] T081 [P] [US5] Integration test: private snippet returns 404 to non-owner in test/review_room_web/live/snippet_live_test.exs

**Run tests - verify all FAIL**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

### Implementation for User Story 5

- [ ] T082 [US5] Add visibility enum field to Snippet schema (already exists, verify configuration)
- [ ] T083 [US5] Add visibility validation to Snippet changeset (inclusion in [:private, :public, :unlisted])
- [ ] T084 [US5] Update get_snippet/2 in Snippets context with visibility enforcement logic
- [ ] T085 [US5] Add list_public_snippets/1 function to Snippets context
- [ ] T086 [US5] Add visibility radio buttons/select to SnippetLive.New form
- [ ] T087 [US5] Update SnippetLive.Show mount to handle visibility checks and return 404
- [ ] T088 [US5] Add public snippet route outside authenticated pipeline in router

**Run tests - verify all PASS**: `mix test test/review_room/snippets_test.exs test/review_room_web/live/snippet_live_test.exs`

**Checkpoint**: All 5 user stories work independently ✅

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Enhancements that span multiple user stories

- [ ] T089 [P] Add CodeInput hook for real-time size validation in assets/js/app.js
- [ ] T090 [P] Add size counter display to code textarea in form component
- [ ] T091 [P] Create SnippetLive.Edit in lib/review_room_web/live/snippet_live/edit.ex for updating snippets
- [ ] T092 [P] Add update_snippet/3 function to Snippets context with authorization
- [ ] T093 [P] Add delete_snippet/2 function to Snippets context with authorization
- [ ] T094 [P] Add delete button to SnippetLive.Index with confirmation
- [ ] T095 Add demo data to priv/repo/seeds.exs (3+ snippets covering all features)
- [ ] T096 Run mix run priv/repo/seeds.exs to verify demo data
- [ ] T097 Add configuration validation at boot in lib/review_room/application.ex
- [ ] T098 Run mix precommit to verify formatting, credo, tests, dialyzer
- [ ] T099 Manual verification with web CLI per quickstart.md
- [ ] T100 [P] Add XSS sanitization tests for title and description fields in test/review_room/snippets_test.exs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - Can proceed in parallel (if multiple developers)
  - Or sequentially in priority order: US1 (P1) → US2 (P2) → US3 (P2) → US4 (P3) → US5 (P3)
- **Polish (Phase 8)**: Depends on desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent (adds to US1)
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Independent (adds to US1)
- **User Story 4 (P3)**: Can start after Foundational (Phase 2) - Independent (adds to US1)
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - Independent (adds to US1)

### Within Each User Story

1. **Tests FIRST** (T011-T021 for US1, etc.) - MUST fail before implementation
2. **Schema** (T022-T024) - Core data model
3. **Context** (T025-T028) - Business logic
4. **LiveView** (T029-T033) - Presentation layer
5. Verify tests PASS

### Parallel Opportunities

**Setup Phase (ALL can run in parallel):**
- T001, T002, T003, T004

**Foundational Phase (after T005-T008):**
- T009, T010

**Within Each User Story:**

**US1 Tests (ALL can run in parallel):**
- T011-T021

**US1 Implementation (after tests fail):**
- T022-T024 (schema work)
- T029, T030, T031 (separate LiveView files after context ready)

**US2 Tests (ALL can run in parallel):**
- T034-T038

**US2 Implementation:**
- T039-T041 (schema)
- T042, T044 (separate files after schema)
- T043, T045 (JS work)

**US3 Tests (ALL can run in parallel):**
- T046-T050

**US3 Implementation:**
- T051-T054 (simple additions, can be sequential)

**US4 Tests (ALL can run in parallel):**
- T055-T063

**US4 Implementation:**
- T064-T066 (schema)
- T070, T071, T072 (separate LiveView files after context ready)

**US5 Tests (ALL can run in parallel):**
- T073-T081

**US5 Implementation:**
- T082-T088 (mostly sequential due to auth logic)

**Polish Phase (many can run in parallel):**
- T089, T090, T091, T092, T093, T094, T100

**Different User Stories (if team capacity allows):**
- US1 (T011-T033), US2 (T034-T045), US3 (T046-T054), US4 (T055-T072), US5 (T073-T088) can ALL be worked on in parallel after Foundational phase completes

---

## Parallel Example: User Story 1

```bash
# Write ALL tests for US1 in parallel (different test files or test cases):
Task T011-T018: "Unit tests in test/review_room/snippets_test.exs"
Task T019-T021: "Integration tests in test/review_room_web/live/snippet_live_test.exs"

# After schema (T022-T024), create LiveViews in parallel:
Task T029: "SnippetLive.Index in lib/review_room_web/live/snippet_live/index.ex"
Task T030: "SnippetLive.New in lib/review_room_web/live/snippet_live/new.ex"
Task T031: "SnippetLive.Show in lib/review_room_web/live/snippet_live/show.ex"
```

---

## Parallel Example: Multiple User Stories

```bash
# After Foundational phase (T005-T010), launch all user stories in parallel:
Developer A: User Story 1 (T011-T033) - MVP
Developer B: User Story 2 (T034-T045) - Syntax Highlighting
Developer C: User Story 4 (T055-T072) - Tags
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. **Complete Phase 1**: Setup (T001-T004)
2. **Complete Phase 2**: Foundational (T005-T010) - CRITICAL
3. **Complete Phase 3**: User Story 1 (T011-T033)
4. **STOP and VALIDATE**: Test US1 independently
   - Run: `mix test`
   - Manual: `mix phx.server` + `web http://localhost:4000/snippets/new`
5. **Deploy/demo if ready** ✅ MVP complete!

### Incremental Delivery

1. **Foundation** (Setup + Foundational) → T001-T010 complete
2. **MVP** (US1) → T011-T033 → Test → Deploy/Demo
3. **+Syntax Highlighting** (US2) → T034-T045 → Test → Deploy/Demo
4. **+Description** (US3) → T046-T054 → Test → Deploy/Demo
5. **+Tags** (US4) → T055-T072 → Test → Deploy/Demo
6. **+Visibility** (US5) → T073-T088 → Test → Deploy/Demo
7. **Polish** → T089-T100 → Final validation

Each increment is independently testable and adds value!

### Parallel Team Strategy (3+ developers)

1. **Together**: Complete Setup + Foundational (T001-T010)
2. **Once Foundational done**, split:
   - **Dev A**: User Story 1 (T011-T033) - MVP
   - **Dev B**: User Story 2 (T034-T045) - Syntax Highlighting
   - **Dev C**: User Story 4 (T055-T072) - Tags
3. Stories integrate naturally (all build on same Snippet schema)
4. **Validate each story independently** before moving to next priority

---

## Task Count Summary

- **Setup**: 4 tasks
- **Foundational**: 6 tasks (BLOCKS all stories)
- **User Story 1** (P1 - MVP): 22 tasks (11 tests + 11 implementation)
- **User Story 2** (P2): 12 tasks (5 tests + 7 implementation)
- **User Story 3** (P2): 9 tasks (5 tests + 4 implementation)
- **User Story 4** (P3): 18 tasks (9 tests + 9 implementation)
- **User Story 5** (P3): 16 tasks (9 tests + 7 implementation)
- **Polish**: 12 tasks

**Total**: 100 tasks

**Parallel opportunities**: 45 tasks marked [P] can run in parallel within their phases

**Test coverage**: 48 test tasks (48% of total) ensuring comprehensive TDD approach

---

## Suggested MVP Scope

**Minimum Viable Product** = Phase 1 + Phase 2 + Phase 3 (User Story 1 only)

This delivers:
- ✅ Basic snippet creation (title + code)
- ✅ Private visibility (default)
- ✅ List and view snippets
- ✅ User authentication and authorization
- ✅ Database persistence
- ✅ Full test coverage

**Tasks required**: T001-T033 (33 tasks total)
**Estimated time**: 6-8 hours (per quickstart.md)

**Value**: Developers can immediately start saving and organizing code snippets!

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label maps task to user story for traceability
- Each user story is independently completable and testable
- **Constitution compliance**: Tests written FIRST, must FAIL before implementation
- Verify `mix test` passes before marking story complete
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
- Use `mix precommit` before requesting review
- Manual verification with `web` CLI per quickstart.md
