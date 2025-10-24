# Research Notes – World-Class UI Redesign

## Decision 1: Tailwind & DaisyUI Theming Strategy

- **Decision**: Extend Tailwind v4 configuration via CSS `@theme` directives and DaisyUI custom theme tokens to deliver a bespoke visual identity while keeping existing utility workflows.
- **Rationale**: The product owner requires continuing DaisyUI; layering custom tokens and per-component classes lets us leverage DaisyUI component structure without inheriting stock styling. Tailwind v4’s native design tokens keep values consistent between CSS and LiveView component classes.
- **Alternatives Considered**:
  - **Pure Tailwind Utilities Only**: Rejected because it would require rebuilding form/feedback primitives, slowing delivery.
  - **Replacing DaisyUI with Headless UI**: Conflicts with stakeholder directive and introduces additional JS dependencies.
  - **Using CSS frameworks (Bootstrap/Chakra)**: Violates Phoenix/Tailwind standards and would bloat bundle size.

## Decision 2: Interaction & Motion Guidelines

- **Decision**: Standardize micro-interactions at 180ms easing with Tailwind’s `transition` utilities and lightweight LiveView hooks for focus/hover states that need JS (e.g., clipboard successes).
- **Rationale**: Keeps interactions perceptibly responsive (<250ms) and aligns with spec requirement for subtle motion. Pure CSS transitions suffice for most states; LiveView hooks only for real-time updates to avoid heavy JS.
- **Alternatives Considered**:
  - **Relying entirely on DaisyUI defaults**: Feels generic and does not meet “world-class” expectation.
  - **Heavy GSAP/Framer Motion integration**: Overkill for the scope, increases bundle size, and complicates testing.

## Decision 3: Accessibility & Contrast Assurance

- **Decision**: Adopt a color palette with minimum 4.5:1 contrast for text and 3:1 for UI controls, verified using Tailwind color tokens plus automated checks in LiveView tests (axe-core via Wallaby not needed—use `assert_accessible/2` helper already present).
- **Rationale**: Meets WCAG 2.1 AA as mandated in spec. Automated assertions support Principle I by keeping tests enforceable.
- **Alternatives Considered**:
  - **Manual QA only**: Risky; lacks repeatability.
  - **Third-party accessibility SaaS**: Adds cost and integration work without immediate need.

## Decision 4: Layout & Grid System

- **Decision**: Implement an 8px spacing scale with responsive CSS Grid layouts for galleries (auto-fit minmax cards) and Flexbox for forms/navigation. Maintain LiveView stream containers with `phx-update="stream"` to prevent regressions.
- **Rationale**: Supports premium visual rhythm and responsive requirements (mobile, tablet, desktop) while keeping HTML semantics familiar to existing tests.
- **Alternatives Considered**:
  - **Bootstrap-style 12-column grid**: Adds complexity and duplicates Tailwind utilities.
  - **CSS framework swap**: Conflicts with Tailwind commitment, risks regressions.

## Decision 5: Testing Approach

- **Decision**: Add LiveView snapshot assertions using LazyHTML selectors and simulated interactions (hover, form submissions) to validate new states before implementation.
- **Rationale**: Aligns with Test-First principle and ensures visual/interaction polish is enforced without relying on manual review.
- **Alternatives Considered**:
  - **Visual diff tooling (Percy/Chromatic)**: Not currently integrated; setup would delay delivery.
  - **Manual verification**: Insufficient for regression prevention.
