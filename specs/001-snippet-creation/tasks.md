# Tasks: Developer Code Snippet Creation

**Feature**: 001-snippet-creation  
**Branch**: `001-snippet-creation`  
**Input**: Design documents from `/specs/001-snippet-creation/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/liveview-events.md

**Tests**: ALL code MUST be tested. Per CLAUDE.local.md: "All code must be tested. Do not write production code without writing tests."

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and configuration

- [ ] T001 [P] Add snippet language configuration to config/config.exs
- [ ] T002 [P] Add html_sanitize_ex dependency to mix.exs
- [ ] T003 [P] Install Highlight.js via npm in assets/
- [ ] T004 [P] Configure Highlight.js import in assets/js/app.js
- [ ] T005 [P] Create syntax highlighter hook in assets/js/hooks/syntax_highlighter.js
- [ ] T006 Run mix deps.get to install Elixir dependencies
- [ ] T007 Run cd assets && npm install to install JS dependencies

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema and core infrastructure that MUST be complete before ANY user story

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T008 Generate migration with mix ecto.gen.migration create_snippets
- [ ] T009 Implement CreateSnippets migration in priv/repo/migrations/YYYYMMDDHHMMSS_create_snippets.exs
- [ ] T010 Run mix ecto.migrate to create snippets table
- [ ] T011 Create Snippet schema in lib/review_room/snippets/snippet.ex with validations
- [ ] T012 Create Snippets context module stub in lib/review_room/snippets.ex

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create Basic Snippet (Priority: P1) 🎯 MVP

**Goal**: Allow developers to save a code snippet with syntax highlighting so they can reference it later or share it with their team.

**Independent Test**: Create a new snippet with code content and selected language, verify it's stored and displays with proper syntax highlighting.

### Tests for User Story 1 (Write these FIRST) ⚠️

- [ ] T013 [P] [US1] Write unit test: create_snippet with valid data in test/review_room/snippets_test.exs
- [ ] T014 [P] [US1] Write unit test: create_snippet with missing code returns error in test/review_room/snippets_test.exs
- [ ] T015 [P] [US1] Write unit test: create_snippet with missing language returns error in test/review_room/snippets_test.exs
- [ ] T016 [P] [US1] Write unit test: create_snippet with unsupported language returns error in test/review_room/snippets_test.exs
- [ ] T017 [P] [US1] Write unit test: get_snippet for owner returns snippet in test/review_room/snippets_test.exs
- [ ] T018 [P] [US1] Write integration test: LiveView displays snippet creation form in test/review_room_web/live/snippet_live_test.exs
- [ ] T019 [P] [US1] Write integration test: Submit valid snippet form creates snippet in test/review_room_web/live/snippet_live_test.exs
- [ ] T020 [P] [US1] Write integration test: Submit invalid snippet form shows validation errors in test/review_room_web/live/snippet_live_test.exs
- [ ] T021 [P] [US1] Write integration test: View snippet displays code with syntax highlighting in test/review_room_web/live/snippet_live_test.exs
- [ ] T022 Run mix test to verify all US1 tests FAIL before implementation

### Implementation for User Story 1

- [ ] T023 [P] [US1] Implement create_snippet/2 function in lib/review_room/snippets.ex
- [ ] T024 [P] [US1] Implement change_snippet/2 function in lib/review_room/snippets.ex
- [ ] T025 [P] [US1] Implement get_snippet/2 function with authorization in lib/review_room/snippets.ex
- [ ] T026 [US1] Create SnippetLive.New LiveView in lib/review_room_web/live/snippet_live/new.ex
- [ ] T027 [US1] Create new.html.heex template for snippet creation in lib/review_room_web/live/snippet_live/new.html.heex
- [ ] T028 [US1] Create SnippetLive.Show LiveView in lib/review_room_web/live/snippet_live/show.ex
- [ ] T029 [US1] Create show.html.heex template for snippet display in lib/review_room_web/live/snippet_live/show.html.heex
- [ ] T030 [US1] Add snippet routes to lib/review_room_web/router.ex in :require_authenticated_user scope
- [ ] T031 Run mix test test/review_room/snippets_test.exs to verify US1 unit tests PASS
- [ ] T032 Run mix test test/review_room_web/live/snippet_live_test.exs to verify US1 integration tests PASS

**Checkpoint**: User Story 1 complete - developers can create and view basic snippets with syntax highlighting

---

## Phase 4: User Story 2 - Add Metadata (Title & Description) (Priority: P2)

**Goal**: Allow developers to add title and description to snippets for better organization and context.

**Independent Test**: Create snippet with title and description, verify both display correctly when viewing snippet.

### Tests for User Story 2 (Write these FIRST) ⚠️

- [ ] T033 [P] [US2] Write unit test: create_snippet with title and description in test/review_room/snippets_test.exs
- [ ] T034 [P] [US2] Write unit test: create_snippet without title defaults gracefully in test/review_room/snippets_test.exs
- [ ] T035 [P] [US2] Write unit test: create_snippet with HTML in title/description sanitizes in test/review_room/snippets_test.exs
- [ ] T036 [P] [US2] Write unit test: create_snippet with title exceeding 255 chars returns error in test/review_room/snippets_test.exs
- [ ] T037 [P] [US2] Write integration test: Submit snippet with title and description saves both in test/review_room_web/live/snippet_live_test.exs
- [ ] T038 [P] [US2] Write integration test: View snippet displays title and description in test/review_room_web/live/snippet_live_test.exs
- [ ] T039 Run mix test to verify all US2 tests FAIL before implementation

### Implementation for User Story 2

- [ ] T040 [US2] Update new.html.heex template to include title and description fields in lib/review_room_web/live/snippet_live/new.html.heex
- [ ] T041 [US2] Update show.html.heex template to display title and description in lib/review_room_web/live/snippet_live/show.html.heex
- [ ] T042 Run mix test test/review_room/snippets_test.exs to verify US2 unit tests PASS
- [ ] T043 Run mix test test/review_room_web/live/snippet_live_test.exs to verify US2 integration tests PASS

**Checkpoint**: User Story 2 complete - snippets now support title and description metadata

---

## Phase 5: User Story 3 - Organize with Tags (Priority: P3)

**Goal**: Allow developers to add tags to snippets for categorization and filtering.

**Independent Test**: Create snippets with various tags, verify tags display and can be used to filter snippets.

### Tests for User Story 3 (Write these FIRST) ⚠️

- [ ] T044 [P] [US3] Write unit test: create_snippet with tags array stores all tags in test/review_room/snippets_test.exs
- [ ] T045 [P] [US3] Write unit test: create_snippet with more than 10 tags returns error in test/review_room/snippets_test.exs
- [ ] T046 [P] [US3] Write unit test: create_snippet with whitespace and duplicate tags normalizes in test/review_room/snippets_test.exs
- [ ] T047 [P] [US3] Write unit test: create_snippet without tags succeeds in test/review_room/snippets_test.exs
- [ ] T048 [P] [US3] Write unit test: list_all_tags returns unique tags in test/review_room/snippets_test.exs
- [ ] T049 [P] [US3] Write unit test: list_snippets_by_tag filters correctly in test/review_room/snippets_test.exs
- [ ] T050 [P] [US3] Write integration test: Submit snippet with tags saves tag array in test/review_room_web/live/snippet_live_test.exs
- [ ] T051 [P] [US3] Write integration test: View snippet displays tags in test/review_room_web/live/snippet_live_test.exs
- [ ] T052 Run mix test to verify all US3 tests FAIL before implementation

### Implementation for User Story 3

- [ ] T053 [P] [US3] Implement list_all_tags/0 function in lib/review_room/snippets.ex
- [ ] T054 [P] [US3] Implement list_snippets_by_tag/2 function in lib/review_room/snippets.ex
- [ ] T055 [US3] Update new.html.heex template to include tags input field in lib/review_room_web/live/snippet_live/new.html.heex
- [ ] T056 [US3] Update show.html.heex template to display tags in lib/review_room_web/live/snippet_live/show.html.heex
- [ ] T057 Run mix test test/review_room/snippets_test.exs to verify US3 unit tests PASS
- [ ] T058 Run mix test test/review_room_web/live/snippet_live_test.exs to verify US3 integration tests PASS

**Checkpoint**: User Story 3 complete - snippets support tagging for organization

---

## Phase 6: User Story 4 - Control Visibility/Privacy (Priority: P2)

**Goal**: Allow developers to control who can view their snippets (private or public).

**Independent Test**: Create snippets with different visibility settings, verify access permissions are correctly enforced.

### Tests for User Story 4 (Write these FIRST) ⚠️

- [ ] T059 [P] [US4] Write unit test: create_snippet without visibility defaults to private in test/review_room/snippets_test.exs
- [ ] T060 [P] [US4] Write unit test: create_snippet with invalid visibility returns error in test/review_room/snippets_test.exs
- [ ] T061 [P] [US4] Write unit test: get_snippet for public snippet allows non-owner access in test/review_room/snippets_test.exs
- [ ] T062 [P] [US4] Write unit test: get_snippet for private snippet denies non-owner access in test/review_room/snippets_test.exs
- [ ] T063 [P] [US4] Write unit test: list_snippets includes own private and others' public snippets in test/review_room/snippets_test.exs
- [ ] T064 [P] [US4] Write integration test: Create private snippet and verify non-owner cannot access in test/review_room_web/live/snippet_live_test.exs
- [ ] T065 [P] [US4] Write integration test: Create public snippet and verify non-owner can access in test/review_room_web/live/snippet_live_test.exs
- [ ] T066 Run mix test to verify all US4 tests FAIL before implementation

### Implementation for User Story 4

- [ ] T067 [P] [US4] Implement list_snippets/1 function in lib/review_room/snippets.ex
- [ ] T068 [P] [US4] Implement list_my_snippets/1 function in lib/review_room/snippets.ex
- [ ] T069 [US4] Update new.html.heex template to include visibility selector in lib/review_room_web/live/snippet_live/new.html.heex
- [ ] T070 [US4] Update show.html.heex template to display visibility indicator in lib/review_room_web/live/snippet_live/show.html.heex
- [ ] T071 Run mix test test/review_room/snippets_test.exs to verify US4 unit tests PASS
- [ ] T072 Run mix test test/review_room_web/live/snippet_live_test.exs to verify US4 integration tests PASS

**Checkpoint**: User Story 4 complete - snippets support privacy controls

---

## Phase 7: Edge Cases & Validation

**Purpose**: Handle edge cases and additional validation requirements

### Tests for Edge Cases (Write these FIRST) ⚠️

- [ ] T073 [P] Write unit test: create_snippet with code exceeding 1MB returns error in test/review_room/snippets_test.exs
- [ ] T074 [P] Write unit test: create_snippet with XSS attempt in title sanitizes in test/review_room/snippets_test.exs
- [ ] T075 [P] Write unit test: create_snippet with XSS attempt in description sanitizes in test/review_room/snippets_test.exs
- [ ] T076 [P] Write integration test: Submit snippet without code shows validation error in test/review_room_web/live/snippet_live_test.exs
- [ ] T077 [P] Write integration test: Real-time validation on form change in test/review_room_web/live/snippet_live_test.exs
- [ ] T078 Run mix test to verify all edge case tests FAIL before implementation

### Implementation for Edge Cases

- [ ] T079 Verify all validation logic handles edge cases correctly (already implemented in schema)
- [ ] T080 Run mix test test/review_room/snippets_test.exs to verify edge case tests PASS
- [ ] T081 Run mix test test/review_room_web/live/snippet_live_test.exs to verify edge case tests PASS

**Checkpoint**: All edge cases handled correctly

---

## Phase 8: Demo Data & Polish

**Purpose**: Add demo data and final improvements

- [ ] T082 [P] Add demo snippet data to priv/repo/seeds.exs
- [ ] T083 Run mix ecto.reset to recreate database with seed data
- [ ] T084 [P] Add factory definitions for snippets in test/support/factories.ex (if not exists)
- [ ] T085 Manual test: Navigate to /snippets/new and create snippet via UI
- [ ] T086 Manual test: Verify syntax highlighting renders correctly
- [ ] T087 Manual test: Test privacy enforcement with two different users
- [ ] T088 Manual test: Verify tag filtering works correctly
- [ ] T089 Run mix format to format all code
- [ ] T090 Run mix credo --strict for code quality check
- [ ] T091 Run mix dialyzer for type checking
- [ ] T092 Run mix test --cover for test coverage report
- [ ] T093 Verify all quickstart.md scenarios work end-to-end
- [ ] T094 Update CHANGELOG.md with feature details

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (P1): Create Basic Snippet - HIGHEST priority, MVP core
  - US2 (P2): Add Metadata - Enhances US1, can run in parallel with US4
  - US4 (P2): Privacy Controls - Security feature, can run in parallel with US2
  - US3 (P3): Tags - Organization feature, lowest priority
- **Edge Cases (Phase 7)**: Depends on core user stories (US1-US4)
- **Demo Data & Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational - No dependencies on other stories
- **US2 (P2)**: Can start after Foundational - Builds on US1 schema/context but independent
- **US4 (P2)**: Can start after Foundational - Builds on US1 schema/context but independent
- **US3 (P3)**: Can start after Foundational - Completely independent (tags array field)

### Within Each User Story

1. **Tests FIRST**: Write all tests for the story, verify they FAIL
2. **Context layer**: Implement business logic functions
3. **LiveView layer**: Implement UI and event handlers
4. **Verify tests PASS**: Run tests to ensure implementation is correct

### Parallel Opportunities

#### Setup Phase (Phase 1)
All tasks T001-T005 can run in parallel (different files):
```bash
# Configure dependencies in parallel
T001: config/config.exs
T002: mix.exs
T003: assets/package.json
T004: assets/js/app.js
T005: assets/js/hooks/syntax_highlighter.js
```

#### Foundational Phase (Phase 2)
Tasks T008-T010 sequential (database), T011-T012 can run in parallel:
```bash
# After migration runs
T011: lib/review_room/snippets/snippet.ex
T012: lib/review_room/snippets.ex
```

#### User Story Tests
All test tasks within a user story marked [P] can run in parallel:
```bash
# US1 tests (T013-T021) can all be written in parallel by different devs
# US2 tests (T033-T038) can all be written in parallel
# US3 tests (T044-T051) can all be written in parallel
# US4 tests (T059-T065) can all be written in parallel
```

#### User Story Implementation
After Foundational (Phase 2), different team members can work on different stories:
```bash
# Developer A: US1 (T023-T032) - MVP core
# Developer B: US4 (T067-T072) - Privacy (high priority)
# Developer C: US2 (T040-T043) - Metadata
# Developer D: US3 (T053-T058) - Tags
```

---

## Parallel Example: Multiple User Stories

```bash
# After completing Setup + Foundational phases:

# Team Member 1: Implements US1 (MVP)
$ git checkout -b feature/us1-basic-snippet
# Work on T013-T032

# Team Member 2: Implements US4 (Privacy - P2)
$ git checkout -b feature/us4-privacy
# Work on T059-T072

# Team Member 3: Implements US2 (Metadata - P2)
$ git checkout -b feature/us2-metadata
# Work on T033-T043

# All merge independently when complete
```

---

## Implementation Strategy

### MVP First (Recommended - US1 Only)

1. Complete Phase 1: Setup (T001-T007)
2. Complete Phase 2: Foundational (T008-T012) ⚠️ CRITICAL BLOCKER
3. Complete Phase 3: User Story 1 (T013-T032)
4. **STOP and VALIDATE**: Test US1 independently
5. Deploy/demo MVP with basic snippet creation

**Deliverable**: Developers can create and view code snippets with syntax highlighting

### Incremental Delivery (Recommended)

1. MVP (US1) → Test → Deploy 🎯
2. Add US4 (Privacy) → Test → Deploy
3. Add US2 (Metadata) → Test → Deploy
4. Add US3 (Tags) → Test → Deploy
5. Polish → Final deploy

Each increment adds value without breaking previous functionality.

### Parallel Team Strategy

With 4 developers after foundational phase:

1. **All together**: Phase 1 + Phase 2 (Setup + Foundational)
2. **After Phase 2 completes**:
   - Dev A: US1 (T013-T032) - Must complete first (MVP)
   - Dev B: US4 tests (T059-T066) - Can prepare in parallel
   - Dev C: US2 tests (T033-T039) - Can prepare in parallel
   - Dev D: US3 tests (T044-T052) - Can prepare in parallel
3. **After US1 completes**:
   - Dev B: US4 implementation (T067-T072)
   - Dev C: US2 implementation (T040-T043)
   - Dev D: US3 implementation (T053-T058)
4. **All together**: Phase 7 + Phase 8 (Edge cases + Polish)

---

## Task Summary

**Total Tasks**: 94

**By Phase**:
- Phase 1 (Setup): 7 tasks
- Phase 2 (Foundational): 5 tasks
- Phase 3 (US1 - Basic Snippet): 20 tasks (10 tests + 10 implementation)
- Phase 4 (US2 - Metadata): 11 tasks (7 tests + 4 implementation)
- Phase 5 (US3 - Tags): 15 tasks (9 tests + 6 implementation)
- Phase 6 (US4 - Privacy): 14 tasks (8 tests + 6 implementation)
- Phase 7 (Edge Cases): 9 tasks (6 tests + 3 implementation)
- Phase 8 (Demo & Polish): 13 tasks

**Test Coverage**:
- Unit tests: 30+ tests across all user stories
- Integration tests: 20+ tests across all LiveView flows
- Edge case tests: 6 tests
- **Total test tasks**: 56+ tests (59% of all tasks)

**Parallel Opportunities**:
- Setup phase: 5 tasks can run in parallel
- User story tests: All test tasks within each story can run in parallel
- User stories: After foundational phase, all 4 user stories can be worked on in parallel
- Implementation within stories: Context and schema work can parallelize

**Independent Test Criteria**:
- US1: Create snippet with code and language, verify storage and syntax highlighting
- US2: Create snippet with title/description, verify display
- US3: Create snippet with tags, verify filtering
- US4: Create private/public snippets, verify access control

**Suggested MVP Scope**: Phase 1 + Phase 2 + Phase 3 (US1 only) = 32 tasks

---

## Notes

- ✅ All tasks follow required checklist format: `- [ ] [ID] [P?] [Story?] Description with file path`
- ✅ Tasks organized by user story for independent implementation
- ✅ Tests are REQUIRED first for every user story (per CLAUDE.local.md)
- ✅ Each phase has clear checkpoints for validation
- ✅ File paths included in all implementation tasks
- ✅ [P] marker indicates parallelizable tasks (different files)
- ✅ [Story] marker tracks tasks to user stories for traceability
- ✅ MVP scope clearly identified (US1 = 32 tasks total)
- ✅ Dependency graph shows user story independence
- ✅ Parallel execution opportunities documented
