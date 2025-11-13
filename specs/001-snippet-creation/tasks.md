# Tasks: Snippet Creation

**Input**: Design documents from `/specs/001-snippet-creation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are REQUIRED (per ReviewRoom Constitution). All tests must be written FIRST and FAIL before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Phoenix monolith structure:
- `lib/review_room/` - Business logic contexts
- `lib/review_room_web/` - Web interface (LiveViews, components)
- `test/` - All test files
- `priv/repo/migrations/` - Database migrations
- `priv/repo/seeds.exs` - Demo data

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependencies

- [ ] T001 [P] Add Autumn dependency to mix.exs (~> 0.1.0)
- [ ] T002 [P] Configure supported languages list in config/config.exs
- [ ] T003 [P] Generate Autumn theme CSS file (mix autumn.gen.theme catppuccin_mocha)
- [ ] T004 [P] Add themes directory to static paths in config/config.exs
- [ ] T005 [P] Add theme CSS link to lib/review_room_web/components/layouts/root.html.heex
- [ ] T006 Run mix deps.get to install dependencies

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T007 Create database migration for snippets table in priv/repo/migrations/YYYYMMDDHHMMSS_create_snippets.exs
- [ ] T008 Run mix ecto.migrate to apply schema changes
- [ ] T009 Create Snippet schema in lib/review_room/snippets/snippet.ex with tags array field
- [ ] T010 Create Snippets context module in lib/review_room/snippets.ex with placeholder functions
- [ ] T011 Create test fixtures module in test/support/fixtures/snippets_fixtures.ex
- [ ] T012 [P] Add router scopes for authenticated and public snippet routes in lib/review_room_web/router.ex

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create Basic Snippet with Title/Description (Priority: P1) 🎯 MVP

**Goal**: Enable developers to create, view, and list basic code snippets with title, optional description, and code content

**Independent Test**: Create a snippet with title and code, save it, view it in the list, click to see details - complete workflow works

### Tests for User Story 1 (MANDATORY - write these FIRST) ⚠️

> **Write these tests FIRST, ensure they FAIL, then implement**

- [ ] T013 [P] [US1] Unit test: snippet changeset requires title and code in test/review_room/snippets/snippet_test.exs
- [ ] T014 [P] [US1] Unit test: snippet changeset validates title length (1-200 chars) in test/review_room/snippets/snippet_test.exs
- [ ] T015 [P] [US1] Unit test: snippet changeset validates code size (max 500KB) in test/review_room/snippets/snippet_test.exs
- [ ] T016 [P] [US1] Unit test: snippet changeset accepts optional description (max 2000 chars) in test/review_room/snippets/snippet_test.exs
- [ ] T017 [P] [US1] Unit test: snippet changeset defaults visibility to :private in test/review_room/snippets/snippet_test.exs
- [ ] T018 [P] [US1] Context test: create_snippet/2 with valid data succeeds in test/review_room/snippets_test.exs
- [ ] T019 [P] [US1] Context test: create_snippet/2 with invalid data returns error in test/review_room/snippets_test.exs
- [ ] T020 [P] [US1] Context test: list_snippets/1 returns only current user's snippets in test/review_room/snippets_test.exs
- [ ] T021 [P] [US1] Context test: get_snippet!/2 retrieves snippet with visibility check in test/review_room/snippets_test.exs
- [ ] T022 [P] [US1] LiveView test: form renders with title and code fields in test/review_room_web/live/snippet_live_test.exs
- [ ] T023 [P] [US1] LiveView test: form submission with valid data creates snippet in test/review_room_web/live/snippet_live_test.exs
- [ ] T024 [P] [US1] LiveView test: form submission without title shows validation error in test/review_room_web/live/snippet_live_test.exs
- [ ] T025 [P] [US1] LiveView test: index page lists user's snippets in test/review_room_web/live/snippet_live_test.exs
- [ ] T026 [P] [US1] LiveView test: show page displays snippet title, description, and code in test/review_room_web/live/snippet_live_test.exs

### Implementation for User Story 1

- [ ] T027 [US1] Implement Snippet changeset validation in lib/review_room/snippets/snippet.ex
- [ ] T028 [US1] Implement create_snippet/2 function in lib/review_room/snippets.ex
- [ ] T029 [US1] Implement list_snippets/1 function in lib/review_room/snippets.ex
- [ ] T030 [US1] Implement get_snippet!/2 function with visibility check in lib/review_room/snippets.ex
- [ ] T031 [US1] Implement change_snippet/2 helper function in lib/review_room/snippets.ex
- [ ] T032 [P] [US1] Create SnippetLive.Index module in lib/review_room_web/live/snippet_live/index.ex
- [ ] T033 [P] [US1] Create SnippetLive.Form module in lib/review_room_web/live/snippet_live/form.ex
- [ ] T034 [P] [US1] Create SnippetLive.Show module in lib/review_room_web/live/snippet_live/show.ex
- [ ] T035 [US1] Add authenticated routes for snippet management in lib/review_room_web/router.ex
- [ ] T036 [US1] Add public route for snippet viewing in lib/review_room_web/router.ex
- [ ] T037 [US1] Implement form validation and error handling in SnippetLive.Form
- [ ] T038 [US1] Implement stream-based snippet list in SnippetLive.Index

**Checkpoint**: User Story 1 complete - can create, list, and view basic snippets with title/description

---

## Phase 4: User Story 4 - Set Snippet Visibility (Priority: P2)

**Goal**: Enable developers to control snippet privacy (Private/Public/Unlisted)

**Independent Test**: Create snippets with different visibility settings, verify private snippets are not accessible to other users, public snippets are accessible to all

### Tests for User Story 4 (MANDATORY - write these FIRST) ⚠️

- [ ] T039 [P] [US4] Unit test: snippet changeset accepts visibility enum values in test/review_room/snippets/snippet_test.exs
- [ ] T040 [P] [US4] Context test: get_snippet!/2 raises error for unauthorized private snippet access in test/review_room/snippets_test.exs
- [ ] T041 [P] [US4] Context test: get_snippet!/2 allows access to public snippets for any user in test/review_room/snippets_test.exs
- [ ] T042 [P] [US4] Context test: get_snippet!/2 allows access to unlisted snippets with direct URL in test/review_room/snippets_test.exs
- [ ] T043 [P] [US4] LiveView test: form includes visibility selector in test/review_room_web/live/snippet_live_test.exs
- [ ] T044 [P] [US4] LiveView test: guest user can view public snippet in test/review_room_web/live/snippet_live_test.exs
- [ ] T045 [P] [US4] LiveView test: guest user cannot view private snippet (404) in test/review_room_web/live/snippet_live_test.exs

### Implementation for User Story 4

- [ ] T046 [US4] Add visibility dropdown to snippet form in lib/review_room_web/live/snippet_live/form.ex
- [ ] T047 [US4] Implement check_visibility/2 helper in lib/review_room/snippets.ex
- [ ] T048 [US4] Update get_snippet!/2 to enforce visibility rules in lib/review_room/snippets.ex
- [ ] T049 [US4] Add visibility badge/indicator to index and show templates

**Checkpoint**: User Story 4 complete - snippet privacy controls working

---

## Phase 5: User Story 2 - Add Syntax Highlighting (Priority: P2)

**Goal**: Display code snippets with syntax highlighting based on selected programming language

**Independent Test**: Create snippet with language selection, verify highlighting displays correctly when viewing

### Tests for User Story 2 (MANDATORY - write these FIRST) ⚠️

- [ ] T050 [P] [US2] Unit test: snippet changeset accepts language from supported list in test/review_room/snippets/snippet_test.exs
- [ ] T051 [P] [US2] Unit test: snippet changeset allows nil language in test/review_room/snippets/snippet_test.exs
- [ ] T052 [P] [US2] Unit test: snippet changeset rejects unsupported language in test/review_room/snippets/snippet_test.exs
- [ ] T053 [P] [US2] LiveView test: form includes language selector dropdown in test/review_room_web/live/snippet_live_test.exs
- [ ] T054 [P] [US2] LiveView test: show page displays highlighted code for selected language in test/review_room_web/live/snippet_live_test.exs
- [ ] T055 [P] [US2] LiveView test: show page displays plain text when no language selected in test/review_room_web/live/snippet_live_test.exs

### Implementation for User Story 2

- [ ] T056 [US2] Add language validation to Snippet changeset in lib/review_room/snippets/snippet.ex
- [ ] T057 [US2] Add language selector to snippet form in lib/review_room_web/live/snippet_live/form.ex
- [ ] T058 [P] [US2] Create code_snippet component in lib/review_room_web/components/snippet_components.ex
- [ ] T059 [US2] Integrate Autumn.highlight!/2 in code_snippet component
- [ ] T060 [US2] Use code_snippet component in SnippetLive.Show template
- [ ] T061 [US2] Add supported languages to form assigns from config

**Checkpoint**: User Story 2 complete - syntax highlighting working for all supported languages

---

## Phase 6: User Story 3 - Organize with Tags (Priority: P3)

**Goal**: Enable developers to add tags to snippets and filter snippets by tag

**Independent Test**: Create snippets with different tags, filter by tag, verify only matching snippets appear

### Tests for User Story 3 (MANDATORY - write these FIRST) ⚠️

- [ ] T062 [P] [US3] Unit test: snippet changeset accepts tags array in test/review_room/snippets/snippet_test.exs
- [ ] T063 [P] [US3] Unit test: snippet changeset normalizes tags (lowercase, trim, unique) in test/review_room/snippets/snippet_test.exs
- [ ] T064 [P] [US3] Unit test: snippet changeset accepts comma-separated string and converts to array in test/review_room/snippets/snippet_test.exs
- [ ] T065 [P] [US3] Context test: list_snippets_by_tag/2 returns only snippets with specified tag in test/review_room/snippets_test.exs
- [ ] T066 [P] [US3] Context test: list_user_tags/1 returns unique sorted list of user's tags in test/review_room/snippets_test.exs
- [ ] T067 [P] [US3] LiveView test: form includes tags input field in test/review_room_web/live/snippet_live_test.exs
- [ ] T068 [P] [US3] LiveView test: index page can filter by tag via query param in test/review_room_web/live/snippet_live_test.exs
- [ ] T069 [P] [US3] LiveView test: show page displays tags as clickable links in test/review_room_web/live/snippet_live_test.exs

### Implementation for User Story 3

- [ ] T070 [US3] Add normalize_tags/1 helper to Snippet changeset in lib/review_room/snippets/snippet.ex
- [ ] T071 [US3] Implement list_snippets_by_tag/2 with PostgreSQL array query in lib/review_room/snippets.ex
- [ ] T072 [US3] Implement list_user_tags/1 function in lib/review_room/snippets.ex
- [ ] T073 [US3] Add tags input field to snippet form in lib/review_room_web/live/snippet_live/form.ex
- [ ] T074 [US3] Add tag filtering logic to SnippetLive.Index (handle ?tag= query param)
- [ ] T075 [US3] Display tags as clickable filter links in SnippetLive.Show template
- [ ] T076 [US3] Display tags as clickable filter links in SnippetLive.Index list items

**Checkpoint**: User Story 3 complete - tag organization and filtering working

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Finalize the feature with demo data, security, and validation

- [ ] T077 [P] Add XSS sanitization verification tests in test/review_room_web/live/snippet_live_test.exs
- [ ] T078 [P] Add demo snippets to priv/repo/seeds.exs with various languages, tags, and visibility
- [ ] T079 Run mix run priv/repo/seeds.exs to populate demo data
- [ ] T080 Add snippet creation, update, delete to Snippets context (update_snippet/3, delete_snippet/2)
- [ ] T081 [P] Add edit and delete actions to SnippetLive.Index
- [ ] T082 Run mix precommit to verify formatting, credo, tests, dialyzer
- [ ] T083 Verify quickstart.md validation steps manually
- [ ] T084 [P] Add typespecs to all public Snippets context functions
- [ ] T085 [P] Add error logging for snippet operations per Failure Modes spec

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories  
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (US1 → US4 → US2 → US3)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories ✅ INDEPENDENT
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Extends US1 form but independently testable ✅ INDEPENDENT
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Extends US1 display but independently testable ✅ INDEPENDENT
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Extends US1 form/display but independently testable ✅ INDEPENDENT

### Within Each User Story

1. Tests MUST be written first and fail before implementation (ReviewRoom Constitution)
2. Schema/changeset tests before context tests
3. Context tests before LiveView tests
4. All tests passing before moving to implementation
5. Models/schemas before contexts
6. Contexts before LiveViews
7. Core implementation before polish

### Parallel Opportunities

- **Phase 1 (Setup)**: All 6 tasks can run in parallel [P]
- **Phase 2 (Foundational)**: T009-T012 can run in parallel after T007-T008 complete
- **Within User Stories**: All tests for a story can run in parallel (all marked [P])
- **Across User Stories**: Once Foundational completes:
  - US1, US2, US3, US4 can ALL run in parallel by different developers
  - Each story is completely independent

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (T013-T026):
Task: "Unit test: snippet changeset requires title and code"
Task: "Unit test: snippet changeset validates title length"
Task: "Context test: create_snippet/2 with valid data succeeds"
Task: "LiveView test: form renders with title and code fields"
# ... all 14 tests can run in parallel

# Launch all LiveView modules together (T032-T034):
Task: "Create SnippetLive.Index module"
Task: "Create SnippetLive.Form module"
Task: "Create SnippetLive.Show module"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T012) - BLOCKS everything
3. Complete Phase 3: User Story 1 (T013-T038)
4. **STOP and VALIDATE**: Test US1 independently with `mix test`
5. **DEMO**: Show working snippet creation, list, and view
6. Deploy if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Test independently → Demo (MVP! ✅ Can create/view snippets)
3. Add US4 → Test independently → Demo (Privacy controls added)
4. Add US2 → Test independently → Demo (Syntax highlighting added)
5. Add US3 → Test independently → Demo (Tag organization added)
6. Polish → Complete feature

Each story adds value without breaking previous stories!

### Parallel Team Strategy

With 4 developers after Foundational phase completes:
- **Dev A**: User Story 1 (T013-T038) - Core creation
- **Dev B**: User Story 4 (T039-T049) - Visibility controls
- **Dev C**: User Story 2 (T050-T061) - Syntax highlighting
- **Dev D**: User Story 3 (T062-T076) - Tags

Stories complete and integrate independently.

---

## Task Summary

- **Total Tasks**: 85 tasks
- **Setup Tasks**: 6 tasks (T001-T006)
- **Foundational Tasks**: 6 tasks (T007-T012)
- **User Story 1 Tasks**: 26 tasks (14 tests + 12 implementation) [T013-T038]
- **User Story 4 Tasks**: 11 tasks (7 tests + 4 implementation) [T039-T049]
- **User Story 2 Tasks**: 12 tasks (6 tests + 6 implementation) [T050-T061]
- **User Story 3 Tasks**: 16 tasks (8 tests + 8 implementation) [T062-T076]
- **Polish Tasks**: 9 tasks (T077-T085)

**Parallel Tasks**: 43 tasks marked [P] (51% can run in parallel within their phase)

**Independent Stories**: All 4 user stories are independently testable and deployable

**MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1) = 38 tasks for working MVP

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label (US1/US2/US3/US4) maps task to specific user story for traceability
- Each user story is independently completable and testable per TDD principles
- All tests MUST fail before implementing (ReviewRoom Constitution requirement)
- Run `mix precommit` before requesting code review
- Commit after each completed task or logical group
- PostgreSQL array operators used for tag queries (simpler than many-to-many)
- Autumn provides server-side syntax highlighting (no JavaScript needed)
