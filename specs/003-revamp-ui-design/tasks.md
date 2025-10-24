# Task Plan – World-Class UI Redesign

**Branch**: `003-revamp-ui-design`
**Spec**: [specs/003-revamp-ui-design/spec.md](./spec.md)
**Plan**: [specs/003-revamp-ui-design/plan.md](./plan.md)

## Phase 1 – Setup & Tooling

- [x] T001 Document Tailwind/DaisyUI customization approach in assets/css/design-system.css (create file)
- [x] T002 Update AGENTS.md with design-system summary reference (ensure context aligns with plan)

## Phase 2 – Foundational Work

- [x] T003 Create lib/review_room_web/components/design_system directory
- [x] T004 Add design system token module in lib/review_room_web/components/design_system/tokens.ex
- [x] T005 Update assets/css/app.css to import new design-system.css and DaisyUI theme overrides
- [x] T006 Add design-system CSS variables and theme definitions to assets/css/design-system.css
- [x] T007 Extend assets/js/app.js with hooks scaffold for micro-interactions (clipboard, filter panel)
- [x] T008 Seed test helpers for LazyHTML snapshots in test/support/design_system_case.ex

## Phase 3 – User Story 1 (Delightful Snippet Discovery, P1)

### Goal

Deliver a premium snippets gallery with responsive layouts, updated cards, and micro-interactions.

### Independent Test Criteria

- LiveView tests confirm gallery hero, filters, and cards render with new hierarchy across desktop, tablet, and mobile.
- Accessibility checks ensure contrast ratios and reduced-motion handling meet WCAG 2.1 AA.
- Interaction tests validate hover/tap states and skeleton loaders.

### Tasks

- [x] T009 [US1] Author failing LiveView tests for gallery layout and accessibility in test/review_room_web/live/snippet_gallery_live_test.exs
- [x] T010 [US1] Add gallery layout design components in lib/review_room_web/components/design_system/gallery_components.ex
- [x] T011 [US1] Update lib/review_room_web/live/snippet_gallery_live.ex to stream new component assigns (layout, filters, empty state flags)
- [x] T012 [US1] Rewrite lib/review_room_web/live/snippet_gallery_live.html.heex with new grid, hero, filter controls, and skeleton loaders
- [x] T013 [US1] Implement responsive card styling and DaisyUI theme classes in assets/css/design-system.css (gallery section)
- [x] T014 [US1] Extend assets/js/app.js with filter panel toggle hook (phx-update=ignore safety)
- [x] T015 [US1] Document gallery visual verification steps in specs/003-revamp-ui-design/quickstart.md (append testing notes)

## Phase 4 – User Story 2 (Confident Snippet Management, P2)

### Goal

Provide polished forms, previews, and feedback for snippet creation and management.

### Independent Test Criteria

- Form interactions display new labels, helper text, validation, and success states.
- Visibility toggles and destructive actions surface redesigned feedback components.
- Tests ensure responsiveness and accessibility across breakpoints.

### Tasks

- [ ] T016 [US2] Author failing LiveView tests for form validation, success feedback, and accessibility in test/review_room_web/live/snippet_form_live_test.exs
- [ ] T017 [US2] Create form component primitives in lib/review_room_web/components/design_system/form_components.ex
- [ ] T018 [US2] Update lib/review_room_web/live/snippet_form_live.ex to use new component assigns (form layout, status flags)
- [ ] T019 [US2] Redesign lib/review_room_web/live/snippet_form_live.html.heex with updated fields, helper text, validation states
- [ ] T020 [US2] Style form states and toasts in assets/css/design-system.css (form/feedback section)
- [ ] T021 [US2] Extend assets/js/app.js with clipboard success and reduced-motion handling for form confirmations
- [ ] T022 [US2] Update quickstart with form testing checklist and contrast ratios (append to specs/003-revamp-ui-design/quickstart.md)

## Phase 5 – User Story 3 (Oriented Application Navigation, P3)

### Goal

Ensure navigation, secondary menus, and empty/loading states reflect cohesive visual system.

### Independent Test Criteria

- Navigation components exhibit new typography, spacing, and active indicators.
- Empty/loading states use redesigned skeletons/illustrations and guide users effectively.
- Tests validate reduced-motion behavior and consistency across primary screens.

### Tasks

- [ ] T023 [US3] Author failing LiveView tests for navigation active states and empty/loading views in test/review_room_web/live/snippet_show_live_test.exs
- [ ] T024 [US3] Create navigation and chrome components in lib/review_room_web/components/design_system/navigation_components.ex
- [ ] T025 [US3] Apply navigation updates to layout modules (lib/review_room_web/components/layout_components.ex)
- [ ] T026 [US3] Update primary LiveView templates (snippet show, account, dashboard) to use new navigation components
- [ ] T027 [US3] Add skeleton and empty state components styling to assets/css/design-system.css (chrome section)
- [ ] T028 [US3] Update quickstart with navigation verification steps (append to specs/003-revamp-ui-design/quickstart.md)

## Phase 6 – Polish & Cross-Cutting

- [ ] T029 Perform accessibility regression sweep using existing helpers across gallery, form, navigation LiveViews
- [ ] T030 Run mix precommit and capture test artifacts/screenshots for review
- [ ] T031 Update documentation references (README snippets section, design notes) with highlights of redesign

## Dependencies

- Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
- Within user stories: layout components before template rewrites, templates before tests.

## Parallel Execution Opportunities

- [P] T003/T004/T005 can run alongside initial CSS token work (different files) once directory scaffold exists.
- [P] T010 (LiveView assigns) and T012 (CSS styling) can proceed in parallel after gallery components (T009) land.
- [P] T017 (LiveView logic) and T019 (CSS) parallel once form components (T016) complete.
- [P] T024 (layout module) and T026 (skeleton styling) parallel after navigation components (T023).

## Implementation Strategy

1. Establish design system tokens and shared components (Phases 1–2) to unblock all stories.
2. Deliver MVP by completing User Story 1 (gallery redesign) with full test coverage.
3. Iterate on User Story 2 (form experience) followed by User Story 3 (navigation), each shipped with independently verifiable tests.
4. Close with accessibility sweep, documentation updates, and `mix precommit`.
