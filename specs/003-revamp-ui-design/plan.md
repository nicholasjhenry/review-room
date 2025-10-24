# Implementation Plan: World-Class UI Redesign

**Branch**: `003-revamp-ui-design` | **Date**: 2025-10-24 | **Spec**: [specs/003-revamp-ui-design/spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-revamp-ui-design/spec.md`

## Summary

Deliver a comprehensive visual refresh for ReviewRoom that elevates the snippets gallery, management forms, and global navigation to a premium experience. We will establish a reusable design system, apply it across primary LiveViews, and enhance interaction details while preserving existing application flows. Tailwind CSS v4 and DaisyUI will be extended with custom tokens and components to avoid stock styling.

## Technical Context

**Language/Version**: Elixir 1.15 / Phoenix 1.8 / LiveView 1.1
**Primary Dependencies**: Tailwind CSS v4, DaisyUI component library, Phoenix LiveView core components
**Storage**: PostgreSQL via Ecto (no schema changes expected)
**Testing**: ExUnit, Phoenix.LiveViewTest, LazyHTML helpers
**Target Platform**: Responsive web (desktop, tablet, mobile) served via Phoenix LiveView
**Project Type**: Web application (server-rendered UI with LiveView)
**Performance Goals**: Maintain sub-2s first meaningful paint on broadband, interaction feedback within 150–250ms, smooth 60fps micro-interactions
**Constraints**: Must comply with WCAG 2.1 AA, continue using Tailwind & DaisyUI, avoid inline scripts, reuse LiveView stream patterns, align with Phoenix template guidelines
**Scale/Scope**: Primary focus on snippets gallery, snippet detail, creation/editing flows, and shared layout components impacting all authenticated/unauthenticated screens

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

- **Principle I (Test-First Development)**: Plan enforces writing LiveView tests and visual regression assertions prior to implementation. ✅
- **Principle II (Phoenix/LiveView Best Practices)**: All changes remain within LiveView guidelines (Layouts.app wrapper, component usage). DaisyUI usage conflicts with constitution’s “no pre-built component libraries” clause; user directive mandates DaisyUI retention. Violation documented in Complexity Tracking with mitigation plan. ⚠️
- **Principle III (Type Safety & Compile-Time Guarantees)**: No deviations; plan maintains compiler cleanliness and @spec usage. ✅
- **Principle IV (LiveView Streams)**: Existing stream-based collections remain intact; no new collection patterns introduced. ✅
- **Principle V (Quality Gates & Precommit)**: `mix precommit` enforced before integration. ✅

_Post-Phase 1 Re-evaluation_: Research and design artifacts maintain alignment with all principles except the documented DaisyUI exception; no additional violations introduced.

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/review_room_web/
├── components/
│   ├── core_components.ex         # Shared form/input components
│   ├── layout_components.ex       # Layout & navigation components
│   └── design_system/             # New design tokens & DaisyUI extensions
├── controllers/
├── live/
│   ├── snippet_gallery_live.ex    # Public gallery LiveView
│   ├── snippet_show_live.ex       # Real-time collaboration view
│   ├── snippet_form_live.ex       # Create/Edit LiveView
│   └── layout/
└── templates/

assets/
├── css/app.css                    # Tailwind/DaisyUI theme extensions
├── css/design-system.css          # Generated tokens (imported by app.css)
└── js/app.js                      # Hook registrations & interaction cues

test/review_room_web/
├── live/
│   ├── snippet_gallery_live_test.exs
│   ├── snippet_show_live_test.exs
│   └── snippet_form_live_test.exs
└── components/design_system_test.exs
```

**Structure Decision**: Maintain single Phoenix umbrella with focus on `lib/review_room_web` LiveViews and `assets/css/app.css`. Introduce `design_system/` component namespace for shared styling helpers and extend Tailwind/DaisyUI themes through dedicated CSS/JS assets. Tests live under `test/review_room_web` aligned with updated LiveViews and components.

## Complexity Tracking

_Fill ONLY if Constitution Check has violations that must be justified_

| Violation                                             | Why Needed                                                                               | Simpler Alternative Rejected Because                                                                                                        |
| ----------------------------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Continued DaisyUI usage (Constitution Tech Standards) | Product owner explicitly requires retaining DaisyUI alongside Tailwind for this redesign | Removing DaisyUI would contradict current stakeholder direction and delay delivery; plan customizes DaisyUI themes to avoid generic styling |
