<!--
Sync Impact Report (v1.0.0 - Initial Constitution Ratification)
================================================================================
Version Change: Template → 1.0.0
Status: Initial ratification for ReviewRoom Phoenix application
Ratification Date: 2025-10-20
Last Amended: 2025-10-20

Bump Rationale: MINOR version (1.0.0) - Initial constitution establishing
governance framework, development principles, and quality standards for the
ReviewRoom project. No prior version existed.

Principles Defined:
- I. Test-First Development (NON-NEGOTIABLE)
  * All code must have tests written first, approved, and verified to fail
  * Mandatory Red-Green-Refactor cycle using ExUnit
  * Derived from CLAUDE.local.md requirement and TDD best practices

- II. Phoenix/LiveView Best Practices
  * Phoenix 1.8+ patterns only (no deprecated APIs)
  * LiveView streams required for collections
  * Consistent HEEx interpolation patterns
  * Derived from comprehensive CLAUDE.md guidelines

- III. Type Safety & Compile-Time Guarantees
  * Compiler warnings treated as errors
  * @spec annotations required
  * Pattern matching over runtime checks
  * Enforced by mix precommit alias

- IV. LiveView Streams for Collections
  * Mandatory stream/3 and stream_delete/3 usage
  * Prevents memory issues in real-time UI
  * Specific Phoenix LiveView optimization

- V. Quality Gates & Precommit
  * mix precommit must pass before all commits
  * Includes: compile, format, deps check, tests
  * Zero-tolerance for warnings or test failures

Sections Defined:
- Core Principles (5 principles)
- Technology Standards (Elixir 1.15+, Phoenix 1.8.1, PostgreSQL, etc.)
- Development Workflow (feature dev process, code review, branching)
- Governance (amendment procedure, versioning, compliance review)

Templates Validated and Updated:
✅ .specify/templates/plan-template.md
   - Constitution Check section ready for gates
   - Complexity Tracking table for justified violations
   - No changes required

✅ .specify/templates/spec-template.md
   - User scenarios prioritized and testable (aligns with Principle I)
   - Acceptance criteria in Given/When/Then format
   - No changes required

✅ .specify/templates/tasks-template.md - UPDATED
   - Changed tests from "OPTIONAL" to "MANDATORY"
   - Updated language to reference Constitution Principle I
   - Changed all "OPTIONAL - only if tests requested" to "MANDATORY - Test-First"
   - Added explicit constitution requirement warnings
   - Path: .specify/templates/tasks-template.md (4 edits applied)

Command Templates:
⚠️  No command template files found in .specify/templates/commands/
   - This is acceptable for initial setup
   - Future commands should reference constitution principles

Runtime Guidance:
✅ CLAUDE.md - Comprehensive Phoenix/Elixir guidelines documented
   - Constitution principles derived from and reference CLAUDE.md
   - CLAUDE.md serves as detailed implementation guidance
   - Constitution provides governance layer above tactical guidelines

✅ CLAUDE.local.md - Test-first requirement documented
   - Constitution Principle I directly implements this requirement

Follow-up TODOs: None - All templates synchronized and consistent.
================================================================================
-->

# ReviewRoom Constitution

## Core Principles

### I. Test-First Development (NON-NEGOTIABLE)

All production code MUST have corresponding tests written before implementation.
Tests MUST be written first, reviewed, approved, and shown to fail before any
implementation work begins. This principle is absolute and cannot be bypassed.

**Rules:**

- Write tests → Get user approval → Verify tests fail → Then implement
- Follow Red-Green-Refactor cycle strictly
- ExUnit is the mandatory testing framework
- Tests MUST cover all public interfaces and critical paths
- Integration tests required for LiveView user journeys

**Rationale:** Test-first development prevents technical debt, ensures
requirements are understood before coding begins, and provides living
documentation of system behavior. Per CLAUDE.local.md: "All code must be
tested. Do not write production code without writing tests."

### II. Phoenix/LiveView Best Practices

All Phoenix and LiveView code MUST follow the documented guidelines in
CLAUDE.md. These are non-negotiable standards for framework usage.

**Rules:**

- Phoenix 1.8+ patterns only (no deprecated `Phoenix.View`, `live_redirect`, etc)
- LiveView templates MUST start with `<Layouts.app flash={@flash} ...>` wrapper
- Use `<.form for={@form}>` with `to_form/2` in LiveView (never `form_for`)
- HEEx interpolation: `{...}` for attributes/values, `<%= ... %>` for blocks
- Use `<.link navigate={}>` and `<.link patch={}>` (never `live_redirect/live_patch`)
- Import shared components via `my_app_web.ex` `html_helpers` block
- LiveView streams (`stream/3`, `stream_delete/3`) for all collections
- Unique DOM IDs required on all forms, buttons, and key interactive elements

**Rationale:** Consistent framework usage prevents bugs, improves
maintainability, and ensures compatibility with Phoenix ecosystem updates.
These patterns are battle-tested and documented in official Phoenix guides.

### III. Type Safety & Compile-Time Guarantees

Leverage Elixir's compile-time checks and pattern matching to catch errors
before runtime. Dialyzer and compiler warnings MUST NOT be ignored.

**Rules:**

- `mix precommit` alias MUST pass before any commit (includes `--warning-as-errors`)
- Use `@spec` type annotations for all public functions
- Pattern match exhaustively in function heads and case statements
- Never use `String.to_atom/1` on user input (memory leak risk)
- Predicate functions end in `?`, guards use `is_*` prefix
- Access structs via dot notation or `Ecto.Changeset.get_field/2` (never `[]`)

**Rationale:** Elixir provides powerful compile-time guarantees. Leveraging
these prevents entire classes of runtime errors and makes refactoring safe.
The `precommit` alias enforces quality gates automatically.

### IV. LiveView Streams for Collections

All collections rendered in LiveView templates MUST use LiveView streams to
prevent memory issues and enable efficient incremental updates.

**Rules:**

- Use `stream(socket, :items, items)` for initial load
- Use `stream(socket, :items, items, reset: true)` for filtering/replacement
- Use `stream_delete(socket, :items, item)` for removals
- Templates MUST use `phx-update="stream"` on parent element
- Templates MUST use `@streams.items` with `{id, item}` tuple destructuring
- Track empty states separately (streams are not enumerable)

**Rationale:** LiveView streams prevent memory ballooning by only sending diffs
over the wire. This is critical for real-time applications with dynamic lists.
Per Phoenix LiveView best practices, streams replace deprecated
`phx-update="append"` patterns.

### V. Quality Gates & Precommit

All changes MUST pass the `mix precommit` alias before being committed or
pushed. This gate ensures code quality, formatting, and test coverage.

**Rules:**

- `mix precommit` runs: compile with `--warning-as-errors`, `deps.unlock --unused`, `format`, `test`
- Zero compiler warnings allowed (enforced by `--warning-as-errors`)
- All tests MUST pass (no `@tag :skip` or `--exclude` allowed)
- Code MUST be formatted with `mix format`
- Unused dependencies MUST be removed

**Rationale:** Automated quality gates prevent technical debt from accumulating.
Requiring this gate before commit ensures the main branch is always in a
deployable state and prevents "fix later" antipatterns.

## Technology Standards

**Language/Framework:** Elixir 1.15+, Phoenix 1.8.1, Phoenix LiveView 1.1.0

**Data Layer:** Ecto 3.13+, PostgreSQL (via Postgrex)

**Frontend:** Phoenix LiveView (server-rendered), Tailwind CSS v4 (new `@import "tailwindcss"` syntax), esbuild for JS bundling

**HTTP Client:** Req library (`:req` package) - MUST be used for all HTTP requests. Avoid `:httpoison`, `:tesla`, `:httpc`.

**Testing:** ExUnit (built-in), LazyHTML for test assertions, Phoenix.LiveViewTest for LiveView testing

**Deployment:** Bandit web server (production), Phoenix LiveReload (dev only)

**Constraints:**

- No inline `<script>` tags in templates (use `assets/js/app.js` imports)
- No `@apply` directive in CSS (use Tailwind classes or write full CSS rules)
- No daisyUI or pre-built component libraries (build custom Tailwind components)
- No nested modules in same file (causes cyclic dependency compilation errors)

## Development Workflow

**Feature Development:**

1. Write specification using `/speckit.specify` command
2. Generate implementation plan using `/speckit.plan` command
3. Generate task breakdown using `/speckit.tasks` command
4. **Write tests first** for each task (mandatory)
5. Implement feature following task order
6. Run `mix precommit` before commit
7. Review against constitution using `/speckit.analyze` if needed

**Code Review Requirements:**

- All PRs MUST pass `mix precommit` in CI
- Tests MUST cover new functionality
- Constitution compliance MUST be verified
- Phoenix/LiveView guidelines from CLAUDE.md MUST be followed

**Branching:**

- Feature branches named `###-feature-name` format
- Documentation stored in `specs/###-feature/` directory structure
- Main branch MUST always be deployable

## Governance

This constitution supersedes all other development practices. Any deviation
MUST be explicitly justified and documented in the Complexity Tracking section
of the implementation plan.

**Amendment Procedure:**

- Proposed changes MUST be documented with rationale
- Use `/speckit.constitution` command to update
- Amendments require documentation of affected templates and code
- Migration plan MUST be provided for breaking changes
- Version incremented per semantic versioning rules (see below)

**Versioning Policy:**

- **MAJOR**: Backward incompatible governance/principle removals or redefinitions
- **MINOR**: New principle/section added or materially expanded guidance
- **PATCH**: Clarifications, wording, typo fixes, non-semantic refinements

**Compliance Review:**

- All PRs MUST verify compliance with current constitution version
- `/speckit.analyze` command performs automated cross-artifact consistency checks
- Complexity violations MUST be justified in plan.md Complexity Tracking table
- CLAUDE.md serves as runtime development guidance for AI-assisted development

**Version**: 1.0.0 | **Ratified**: 2025-10-20 | **Last Amended**: 2025-10-20
