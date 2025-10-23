# Tasks: Real-Time Code Snippet Sharing System

**Input**: Design documents from `/specs/002-realtime-snippet-sharing/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per Constitution Principle I (Test-First Development), tests are MANDATORY. All task phases below include test tasks that MUST be written first, verified to fail, then implemented (Red-Green-Refactor cycle).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story?] Description`

- **Checkbox**: `- [ ]` (markdown checkbox)
- **[ID]**: Task number (T001, T002, etc.)
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1, US2, etc.) - only for user story phases
- **Description**: Clear action with exact file path

## Path Conventions

**Phoenix Project Structure** (from plan.md):

- `lib/review_room/` - Context modules and schemas
- `lib/review_room_web/` - LiveView modules and controllers
- `test/review_room/` - Context tests
- `test/review_room_web/` - LiveView tests
- `priv/repo/migrations/` - Database migrations
- `assets/js/` - JavaScript hooks and libraries
- `assets/css/` - Stylesheets

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency setup

- [x] T001 Add nanoid dependency to mix.exs (research.md Decision 3)
- [x] T002 [P] Add highlight.js to assets/package.json (research.md Decision 1)
- [x] T003 [P] Run mix deps.get to install nanoid
- [x] T004 [P] Run npm install in assets/ to install highlight.js
- [x] T005 Import highlight.js in assets/js/app.js

**Checkpoint**: ✅ Dependencies installed, ready for database and code setup

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database Setup

- [x] T006 Create migration priv/repo/migrations/YYYYMMDDHHMMSS_create_snippets.exs (data-model.md)
- [x] T007 Run mix ecto.migrate to create snippets table

### Schema and Context Foundation

- [x] T008 Create Snippets context module lib/review_room/snippets.ex
- [x] T009 Create Snippet schema lib/review_room/snippets/snippet.ex (data-model.md)
- [x] T010 Add snippets relationship to User schema lib/review_room/accounts/user.ex

### Real-Time Infrastructure

- [x] T011 Create PresenceTracker module lib/review_room/snippets/presence_tracker.ex (research.md Decision 2)
- [x] T012 Add PresenceTracker to supervision tree in lib/review_room/application.ex
- [x] T013 [P] Create router routes in lib/review_room_web/router.ex (quickstart.md)

**Checkpoint**: ✅ Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Share Code Snippet (Priority: P1) 🎯 MVP

**Goal**: Users can create snippets and view them with syntax highlighting via shareable links

**Independent Test**: Create a snippet with code, get shareable link, visit link to see highlighted code

### Tests for User Story 1 (MANDATORY - Test-First) ⚠️

**CONSTITUTION REQUIREMENT: Write these tests FIRST, get approval, verify FAIL, then implement**

- [x] T014 [P] [US1] Schema tests in test/review_room/snippets/snippet_test.exs
  - Test create_changeset with valid attrs generates nanoid
  - Test code field is required
  - Test language validation
  - Test visibility enum validation
- [x] T015 [P] [US1] Context tests in test/review_room/snippets_test.exs
  - Test create_snippet/2 with valid attributes
  - Test create_snippet/2 with invalid attributes
  - Test get_snippet!/1 returns snippet
  - Test get_snippet!/1 raises on not found
- [x] T016 [P] [US1] LiveView test for New in test/review_room_web/live/snippet_live/new_test.exs
  - Test mount displays form
  - Test validate event updates changeset
  - Test save event creates snippet and redirects
  - Test save with errors shows validation messages
- [x] T017 [P] [US1] LiveView test for Show in test/review_room_web/live/snippet_live/show_test.exs
  - Test mount loads snippet by ID
  - Test displays code content
  - Test displays title and description
  - Test shows 404 for invalid ID
  - Test syntax highlighting hook is present

### Implementation for User Story 1

- [x] T018 [US1] Implement Snippet schema in lib/review_room/snippets/snippet.ex
  - Primary key as :string (nanoid)
  - Fields: code, title, description, language, visibility
  - Belongs_to user relationship
  - create_changeset and update_changeset functions
  - generate_id/1 using Nanoid.generate(8)
  - supported_languages/0 validation list
- [x] T019 [US1] Implement Snippets context in lib/review_room/snippets.ex
  - create_snippet/2 function
  - get_snippet!/1 function
  - change_snippet/2 function for forms
- [x] T020 [US1] Create SnippetLive.New in lib/review_room_web/live/snippet_live/new.ex
  - mount/3 with form initialization using to_form/2
  - handle_event("validate", ...)
  - handle_event("save", ...) with redirect to show page
  - Language dropdown with 20+ languages
  - Visibility select (public/private)
- [x] T021 [US1] Create SnippetLive.Show in lib/review_room_web/live/snippet_live/show.ex
  - mount/3 loads snippet by ID
  - Display code in <pre><code> with language class
  - Display title and description
  - Add DOM ID "code-display" with phx-hook="SyntaxHighlight"
  - Add phx-update="ignore" to code container
- [x] T022 [P] [US1] Create SyntaxHighlight hook in assets/js/hooks/syntax_highlight.js
  - Export SyntaxHighlight with mounted() and updated() callbacks
  - Call hljs.highlightElement(codeBlock) in highlight()
- [x] T023 [P] [US1] Register SyntaxHighlight hook in assets/js/app.js
  - Import { SyntaxHighlight } from "./hooks/syntax_highlight"
  - Add to LiveSocket hooks: { SyntaxHighlight }
- [x] T024 [US1] Add snippet routes to lib/review_room_web/router.ex
  - Public: live "/s/:id", SnippetLive.Show, :show
  - Auth: live "/snippets/new", SnippetLive.New, :new

**Checkpoint**: ✅ MVP Complete - Users can create and view syntax-highlighted snippets

---

## Phase 4: User Story 2 - Real-Time Collaboration (Priority: P2)

**Goal**: Multiple users see each other's cursor positions and text selections in real-time

**Independent Test**: Open snippet in 2 browser windows, move cursor in one, see it update in the other within 200ms

### Tests for User Story 2 (MANDATORY - Test-First) ⚠️

- [x] T025 [P] [US2] PresenceTracker tests in test/review_room/snippets/presence_tracker_test.exs
  - Test track_user/3 adds user to topic
  - Test update_cursor/3 updates metadata
  - Test list/1 returns tracked presences
  - Test automatic cleanup on process death
- [x] T026 [P] [US2] LiveView cursor collaboration tests in test/review_room_web/live/snippet_live/show_test.exs
  - Test cursor_moved event updates tracker
  - Test text_selected event updates tracker
  - Test selection_cleared event clears selection
  - Test presence_diff broadcast updates assigns
  - Test multiple viewers receive updates

### Implementation for User Story 2

- [x] T027 [US2] Implement PresenceTracker in lib/review_room/snippets/presence_tracker.ex
  - use Phoenix.Tracker
  - start_link/1, init/1, handle_diff/2 callbacks
  - track_user/3 function
  - update_cursor/3 function
  - PubSub.broadcast on diff changes
- [x] T028 [US2] Update SnippetLive.Show for cursor tracking in lib/review_room_web/live/snippet_live/show.ex
  - Subscribe to "snippet:#{id}" topic in mount/3 (if connected)
  - Track user presence with PresenceTracker.track_user/3
  - Add @presences assign
  - handle_event("cursor_moved", %{"line" => ..., "column" => ...})
  - handle_event("text_selected", %{"start" => ..., "end" => ...})
  - handle*event("selection_cleared", *)
  - handle_info({:presence_diff, diff}, socket) to merge presences
- [x] T029 [P] [US2] Create CursorTracker hook in assets/js/hooks/cursor_tracker.js
  - mousemove listener with throttle (100ms)
  - mouseup listener for selection
  - pushEvent("cursor_moved", {line, column})
  - pushEvent("text_selected", {start, end})
  - pushEvent("selection_cleared", {})
  - getLineColumn(event) helper
  - getSelectionRange(selection) helper
- [x] T030 [P] [US2] Register CursorTracker hook in assets/js/app.js
- [x] T031 [US2] Add cursor tracking div to Show template with phx-hook="CursorTracker"

**Checkpoint**: ✅ Real-time cursor/selection sharing works between multiple viewers

---

## Phase 5: User Story 3 - User Presence Awareness (Priority: P2)

**Goal**: Users see who else is viewing the snippet with names/identifiers and visual indicators

**Independent Test**: Open snippet in 2 sessions with different users, verify presence list shows both users

### Tests for User Story 3 (MANDATORY - Test-First) ⚠️

- [x] T032 [P] [US3] Presence display tests in test/review_room_web/live/snippet_live/show_test.exs
  - Test presence list displays viewer count
  - Test authenticated user shows profile name
  - Test anonymous user shows generic name
  - Test user leaves, presence list updates within 5 seconds
  - Test hovering cursor shows username tooltip

### Implementation for User Story 3

- [x] T033 [US3] Update SnippetLive.Show presence tracking in lib/review_room_web/live/snippet_live/show.ex
  - Assign display_name (user.email or "Anonymous User #{session_id}")
  - Assign random color for user (assign_random_color/0 helper)
  - Include display_name and color in track_user metadata
  - Add get_user_id/2 helper (user_id or session_id)
- [x] T034 [P] [US3] Create PresenceRenderer hook in assets/js/hooks/presence_renderer.js
  - updated() callback to render cursors and selections
  - renderCursors() - create cursor divs at positions
  - renderSelections() - highlight selected ranges
  - Apply user colors to cursors/selections
  - Show username tooltip on cursor hover
- [x] T035 [P] [US3] Register PresenceRenderer hook in assets/js/app.js
- [x] T036 [US3] Add presence overlay div to Show template
  - DOM ID "presence-overlay" with phx-hook="PresenceRenderer"
  - data-presences attribute with Jason.encode!(@presences)
- [x] T037 [US3] Add presence list UI to Show template
  - Display count: "#{map_size(@presences)} viewers"
  - List each viewer with name and color indicator
  - Style with Tailwind classes

**Checkpoint**: ✅ Presence awareness complete - users see who's viewing with cursor/selection overlays

---

## Phase 6: User Story 4 - Snippet Management (Priority: P3)

**Goal**: Authenticated users can edit, delete, and view history of their snippets

**Independent Test**: Create snippets as authenticated user, navigate to history, edit and delete snippets

### Tests for User Story 4 (MANDATORY - Test-First) ⚠️

- [x] T038 [P] [US4] Context authorization tests in test/review_room/snippets_test.exs
  - Test update_snippet/3 allows owner
  - Test update_snippet/3 blocks non-owner
  - Test delete_snippet/2 allows owner
  - Test delete_snippet/2 blocks non-owner
  - Test list_user_snippets/2 returns user's snippets only
- [x] T039 [P] [US4] LiveView Edit tests in test/review_room_web/live/snippet_live/edit_test.exs
  - Test mount blocks non-owner
  - Test save updates snippet
  - Test save with errors shows messages
  - Test save broadcasts update to viewers
- [x] T040 [P] [US4] LiveView user history tests in test/review_room_web/live/user_snippet_live/index_test.exs
  - Test mount requires authentication
  - Test displays user's snippets as stream
  - Test delete event removes from stream
  - Test toggle_visibility event updates snippet

### Implementation for User Story 4

- [x] T041 [US4] Add context functions to lib/review_room/snippets.ex
  - update_snippet/3 (snippet, attrs, user)
  - delete_snippet/2 (snippet, user)
  - list_user_snippets/2 (user_id, opts)
  - can_edit?/2 (snippet, user)
  - can_delete?/2 (snippet, user)
  - toggle_visibility/2 (snippet, user)
- [x] T042 [US4] Create SnippetLive.Edit in lib/review_room_web/live/snippet_live/edit.ex
  - mount/3 with authorization check (can_edit?)
  - Form with to_form/2 from existing snippet
  - handle_event("validate", ...)
  - handle_event("save", ...) updates snippet
  - handle_event("delete", ...) with confirmation
  - Broadcast snippet_updated via PubSub on save
  - Broadcast snippet_deleted via PubSub on delete
- [x] T043 [US4] Update SnippetLive.Show for edit broadcasts in lib/review_room_web/live/snippet_live/show.ex
  - handle_info({:snippet_updated, data}, socket) - reload snippet
  - handle*info({:snippet_deleted, *}, socket) - redirect with flash
- [x] T044 [US4] Create UserSnippetLive.Index in lib/review_room_web/live/user_snippet_live/index.ex
  - mount/3 requires authentication
  - Load user snippets with stream/3
  - handle_event("delete", %{"id" => id}) - stream_delete
  - handle_event("toggle_visibility", %{"id" => id}) - stream_insert
  - Display snippets with creation date, title, visibility
- [x] T045 [US4] Add edit and user history routes to lib/review_room_web/router.ex
  - Auth: live "/s/:id/edit", SnippetLive.Edit, :edit
  - Auth: live "/snippets/my", UserSnippetLive.Index, :index
- [x] T046 [US4] Add "Edit" link to Show template (only for owner)
  - :if={can_edit?(@snippet, @current_user)}

**Checkpoint**: Snippet management complete - users can edit, delete, view history

---

## Phase 7: User Story 5 - Anonymous and Authenticated Sharing (Priority: P3)

**Goal**: Support both anonymous snippet creation and authenticated users with persistent identity

**Independent Test**: Create snippet without login (anonymous), then login and create another (authenticated)

### Tests for User Story 5 (MANDATORY - Test-First) ⚠️

- [ ] T047 [P] [US5] Anonymous creation tests in test/review_room_web/live/snippet_live/new_test.exs
  - Test unauthenticated user can create snippet
  - Test snippet.user_id is nil for anonymous
- [ ] T048 [P] [US5] Identity tests in test/review_room_web/live/snippet_live/show_test.exs
  - Test anonymous user shows as "Anonymous User {N}"
  - Test authenticated user shows email/name
  - Test anonymous snippets cannot be edited

### Implementation for User Story 5

- [ ] T049 [US5] Update SnippetLive.New for anonymous users in lib/review_room_web/live/snippet_live/new.ex
  - Pass current_user (may be nil) to create_snippet/2
  - Handle both authenticated and anonymous sessions
- [ ] T050 [US5] Update context create_snippet/2 in lib/review_room/snippets.ex
  - Accept user parameter (User struct or nil)
  - Set user_id only if user provided
  - Anonymous snippets have user_id = nil
- [ ] T051 [US5] Update presence display names in lib/review_room_web/live/snippet_live/show.ex
  - For authenticated: use user.email or user name
  - For anonymous: generate "Anonymous User #{unique_id}"
  - Use session ID for anonymous identity tracking
- [ ] T052 [US5] Update authorization helpers in lib/review_room/snippets.ex
  - can_edit?/2 returns false if snippet.user_id is nil
  - can_delete?/2 returns false if snippet.user_id is nil
  - Only owned snippets (non-nil user_id) can be managed
- [ ] T053 [US5] Move /snippets/new route to public scope in lib/review_room_web/router.ex
  - Allow unauthenticated access to creation page

**Checkpoint**: Anonymous and authenticated workflows both supported

---

## Phase 8: User Story 6 - Public Snippet Discovery (Priority: P3)

**Goal**: Browse, search, and filter public snippets in a gallery

**Independent Test**: Mark snippet public, navigate to gallery, see it appear; filter by language

### Tests for User Story 6 (MANDATORY - Test-First) ⚠️

- [ ] T054 [P] [US6] Context gallery tests in test/review_room/snippets_test.exs
  - Test list_public_snippets/1 returns only public snippets
  - Test list_public_snippets with language filter
  - Test list_public_snippets with cursor pagination
  - Test search_snippets/2 matches title and description
- [ ] T055 [P] [US6] LiveView gallery tests in test/review_room_web/live/snippet_live/index_test.exs
  - Test mount loads public snippets as stream
  - Test filter event resets stream with filtered results
  - Test search event resets stream with search results
  - Test load_more appends to stream
  - Test private snippets not shown

### Implementation for User Story 6

- [ ] T056 [US6] Add gallery context functions to lib/review_room/snippets.ex
  - list_public_snippets/1 (opts: language, cursor, limit)
  - search_snippets/2 (query_string, opts)
  - Query with WHERE visibility = :public
  - ILIKE search on title and description
  - Cursor-based pagination using inserted_at
  - Preload :user for display
- [ ] T057 [US6] Create SnippetLive.Index in lib/review_room_web/live/snippet_live/index.ex
  - mount/3 initializes empty stream
  - Load first 20 snippets on connected?/1
  - stream(socket, :snippets, snippets)
  - handle_event("load_more", %{"cursor" => cursor})
  - handle_event("filter", %{"language" => lang}) with reset: true
  - handle_event("search", %{"query" => q}) with reset: true
  - handle*event("clear_search", *) resets to all public
- [ ] T058 [US6] Create gallery template with stream rendering
  - div id="snippets" phx-update="stream"
  - :for={{id, snippet} <- @streams.snippets}
  - Display title, language, created_at, author
  - Link to snippet show page
  - Filter dropdown for languages
  - Search form
  - "Load More" button with cursor
- [ ] T059 [US6] Update UserSnippetLive.Index to support visibility toggle in lib/review_room_web/live/user_snippet_live/index.ex
  - handle_event("toggle_visibility", %{"id" => id})
  - Call toggle_visibility/2 context function
  - Update stream with stream_insert/3
  - Show flash message on toggle
- [ ] T060 [US6] Add gallery route to lib/review_room_web/router.ex
  - Public: live "/snippets", SnippetLive.Index, :index
- [ ] T061 [US6] Add navigation link to gallery in layouts template
  - Link in header/nav to browse public snippets

**Checkpoint**: Public gallery complete - users can discover, search, and filter snippets

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements and features that affect multiple user stories

### Additional Features

- [ ] T062 [P] Add line numbers to code display in SnippetLive.Show template
  - CSS for line number column
  - Generate line numbers from code content
- [ ] T063 [P] Add copy-to-clipboard button in SnippetLive.Show template
  - Button with clipboard icon
  - JavaScript to copy code content
  - Show "Copied!" feedback message
- [ ] T064 [P] Implement graceful reconnection handling in SnippetLive.Show
  - handle_info after disconnect restores presence
  - Show "Reconnecting..." UI during disconnect
  - Restore cursor/selection state after reconnect

### Error Handling & Edge Cases

- [ ] T065 [P] Add error handling for large snippets (>10,000 lines)
  - Validation in changeset
  - User-friendly error message
  - Suggest splitting into multiple snippets
- [ ] T066 [P] Handle special characters and unicode in code content
  - Test with unicode characters
  - Test with special HTML characters (<, >, &)
  - Ensure proper escaping in templates
- [ ] T067 [P] Add rate limiting to cursor updates
  - Client-side throttle already at 100ms (T029)
  - Optional server-side rate limit if needed

### UI/UX Polish

- [ ] T068 [P] Style all LiveView pages with Tailwind CSS
  - Forms with proper spacing and labels
  - Buttons with hover states
  - Cards for snippet display
  - Responsive design for mobile
- [ ] T069 [P] Add loading states to LiveViews
  - Skeleton loaders during initial mount
  - Spinner for save/delete operations
  - Disabled buttons during submission
- [ ] T070 [P] Add flash messages for all operations
  - Success: "Snippet created", "Snippet updated", etc.
  - Errors: "Unable to create snippet", etc.
  - Info: "Snippet deleted by owner"

### Testing & Validation

- [ ] T071 [P] Run all tests with mix test
  - Verify all tests pass
  - Check coverage with mix test --cover
- [ ] T072 [P] Run mix precommit (Constitution Principle V)
  - Compile with --warning-as-errors
  - Format code with mix format
  - Check unused dependencies
  - Run all tests
- [ ] T073 Validate quickstart.md scenarios
  - Create snippet and share link (US1)
  - Open in 2 browsers, verify cursor sync (US2)
  - Verify presence list updates (US3)
  - Edit and delete snippet as owner (US4)
  - Create snippet anonymously (US5)
  - Browse public gallery (US6)

### Documentation

- [ ] T074 [P] Add inline documentation to modules
  - @moduledoc for all public modules
  - @doc for all public functions
  - @spec for all public functions (Constitution Principle III)
- [ ] T075 [P] Update README.md with feature description
  - How to create snippets
  - How to collaborate in real-time
  - How to browse public gallery

**Checkpoint**: Feature complete with polish and documentation

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Setup (Phase 1)**: No dependencies - can start immediately
2. **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
3. **User Story 1 (Phase 3)**: Depends on Foundational - MVP baseline
4. **User Story 2 (Phase 4)**: Depends on Foundational - Can start in parallel with US1
5. **User Story 3 (Phase 5)**: Depends on US2 (needs cursor tracking) - Sequential after US2
6. **User Story 4 (Phase 6)**: Depends on US1 (needs snippet CRUD) - Can start after US1
7. **User Story 5 (Phase 7)**: Depends on US1 and US4 - Modifies creation and ownership
8. **User Story 6 (Phase 8)**: Depends on US1 - Can start after US1
9. **Polish (Phase 9)**: Depends on desired user stories completion

### User Story Dependencies

```
Foundational (Phase 2) ─┬─→ US1 (P1) ─┬─→ US4 (P3) ─→ US5 (P3)
                        │             │
                        │             └─→ US6 (P3)
                        │
                        └─→ US2 (P2) ─→ US3 (P2)
```

**Independence**:

- US1, US2 can start in parallel after Foundational
- US4, US6 can start in parallel after US1
- US3 requires US2 (cursor tracking infrastructure)
- US5 modifies US1 and US4 (run after both)

### Critical Path (MVP - Just US1)

```
Setup → Foundational → US1 Tests → US1 Implementation → MVP Complete
```

**Estimated time**: ~8-12 hours for experienced Phoenix developer

### Full Feature Critical Path

```
Setup → Foundational → US1 → US2 → US3 → US4 → US5 → US6 → Polish
```

**Estimated time**: ~40-60 hours total

### Parallel Opportunities

**Within Foundational Phase (T006-T013)**:

- T006-T007 (database) sequential
- T008-T010 (schemas) after database
- T011-T013 (presence, routes) in parallel with schemas

**Within US1 (T014-T024)**:

- T014-T017 (all tests) in parallel
- T018-T019 (schema, context) in parallel after tests
- T020-T021 (New, Show LiveViews) in parallel after context
- T022-T023 (SyntaxHighlight hook, registration) in parallel
- T024 (routes) after LiveViews

**Within US2 (T025-T031)**:

- T025-T026 (tests) in parallel
- T027 (PresenceTracker) after tests
- T028 (Show updates) after PresenceTracker
- T029-T030 (CursorTracker hook, registration) in parallel
- T031 (template update) after all

**Across User Stories** (if team has capacity):

- After Foundational: US1 and US2 in parallel
- After US1: US4 and US6 in parallel
- US3 waits for US2
- US5 waits for US1 and US4

**Polish Phase (T062-T075)**:

- Most tasks marked [P] can run in parallel
- T071-T073 (testing) sequential at end
- T074-T075 (docs) in parallel

---

## Parallel Example: User Story 1

```bash
# 1. Write all tests in parallel (after Foundational complete):
mix test test/review_room/snippets/snippet_test.exs &       # T014
mix test test/review_room/snippets_test.exs &                # T015
mix test test/review_room_web/live/snippet_live/new_test.exs &  # T016
mix test test/review_room_web/live/snippet_live/show_test.exs & # T017
wait  # All tests FAIL (RED) ✅

# 2. Implement schema and context in parallel:
# Developer A: T018 (Snippet schema)
# Developer B: T019 (Snippets context)

# 3. Implement LiveViews in parallel:
# Developer A: T020 (SnippetLive.New)
# Developer B: T021 (SnippetLive.Show)

# 4. Implement client hooks in parallel:
# Developer A: T022 (SyntaxHighlight hook)
# Developer B: T023 (Register hook)

# 5. Add routes:
# T024 (routes)

# 6. Run tests (GREEN) ✅
mix test
```

---

## Task Summary

**Total Tasks**: 75
**Phases**: 9 (Setup, Foundational, 6 User Stories, Polish)

**Breakdown by Phase**:

- Phase 1 (Setup): 5 tasks
- Phase 2 (Foundational): 8 tasks
- Phase 3 (US1 - MVP): 11 tasks
- Phase 4 (US2): 7 tasks
- Phase 5 (US3): 5 tasks
- Phase 6 (US4): 9 tasks
- Phase 7 (US5): 5 tasks
- Phase 8 (US6): 6 tasks
- Phase 9 (Polish): 14 tasks

**Parallelizable Tasks**: 46 (marked with [P])
**Sequential Tasks**: 29

**MVP Scope (US1 only)**: 24 tasks (Phase 1 + Phase 2 + Phase 3)
**Full Feature**: All 75 tasks

**Independent Test Criteria**:

- ✅ US1: Create snippet → get link → view with highlighting
- ✅ US2: Open 2 browsers → move cursor → see update <200ms
- ✅ US3: Open 2 sessions → verify presence list shows both
- ✅ US4: Create snippets → view history → edit/delete
- ✅ US5: Create without login → create with login → compare features
- ✅ US6: Mark public → browse gallery → search/filter

**Format Validation**: ✅ All tasks follow `- [ ] [ID] [P?] [Story?] Description with path` format

---

## Implementation Strategy

**Recommended Approach**:

1. **MVP First (US1)**: Complete Phase 1 → Phase 2 → Phase 3 (24 tasks)
   - Deploy and validate with real users
   - Delivers core value: snippet sharing with syntax highlighting
   - ~8-12 hours for experienced developer

2. **Add Collaboration (US2 + US3)**: Phase 4 → Phase 5 (12 tasks)
   - Real-time cursor/selection tracking
   - Presence awareness
   - ~8-10 hours

3. **Add Management (US4 + US5)**: Phase 6 → Phase 7 (14 tasks)
   - Edit/delete/history
   - Anonymous support
   - ~8-10 hours

4. **Add Discovery (US6)**: Phase 8 (6 tasks)
   - Public gallery
   - Search/filter
   - ~4-6 hours

5. **Polish**: Phase 9 (14 tasks)
   - Cross-cutting concerns
   - Final QA
   - ~6-8 hours

**Total Estimated Time**: 40-60 hours (experienced Phoenix/LiveView developer)

**Test-First Workflow**: For EVERY task phase, write tests first (RED), get approval, implement (GREEN), refactor, run precommit before commit.
