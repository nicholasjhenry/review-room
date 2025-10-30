<!--
Sync Impact Report
Version change: N/A -> 1.0.0
Modified principles: Initial set defined (Test-First Development, Explicit Over Implicit, Fail Fast, Fail Loud)
Added sections: Core Principles, Engineering Standards, Delivery Workflow & Tooling, Governance
Removed sections: Placeholder principle slots (IV, V)
Templates requiring updates:
- ✅ .specify/templates/plan-template.md
- ✅ .specify/templates/spec-template.md
- ✅ .specify/templates/tasks-template.md
Follow-up TODOs: None
-->

# ReviewRoom Constitution

## Core Principles

### Test-First Development (NON-NEGOTIABLE)
- Write failing automated tests and secure reviewer approval before implementing production code or refactors.
- Follow strict Red-Green-Refactor cycles; commit only the minimal code required to turn the suite green before refactoring.
- Provide integration tests for every cross-boundary pathway (database, external services, LiveView <-> context, background jobs).
- Block merges when required tests are missing or do not fail prior to implementation.

**Rationale**: Disciplined TDD prevents regressions, documents behaviour, and keeps the team aligned on intended outcomes before investing in implementation.

### Explicit Over Implicit
- Name modules, functions, and assigns to reveal intent; avoid convention-based magic or hidden side effects.
- Declare every dependency and contract through function signatures or explicit data structures; never rely on global state or the process dictionary.
- Validate configuration at boot with actionable error messages and document all settings in specs, plans, and README updates.
- Record dependency introductions and migrations in feature documents so reviewers can audit the blast radius.

**Rationale**: Explicit contracts make the system predictable, auditable, and safer to evolve under heavy review workloads.

### Fail Fast, Fail Loud
- Validate inputs at controllers, LiveViews, and contexts; refuse to proceed when data is invalid or stale.
- Instrument failure paths with structured logging and correlation or trace identifiers for each request or task.
- Wrap external calls in timeouts, retries, and circuit breakers so incidents surface immediately to operators.
- Codify failure expectations in automated tests, covering both success and error scenarios.

**Rationale**: Loud failures protect users from silent data loss, reduce mean time to recovery, and create confidence in continuous delivery.

## Engineering Standards

- Follow Phoenix phx.gen.auth routing guidance: place routes inside the correct pipeline and live_session, and explain scope choices in every review.
- Use Accounts.Scope for authorization and pass current_scope to context functions; templates must access @current_scope.user exclusively.
- Prefer the bundled Req client for HTTP calls; adding alternatives requires explicit approval and configuration documentation.
- Provide typespecs and typedocs for every public context module and Ecto schema using the mandated template that enumerates fields and associations.
- Extend priv/repo/seeds.exs (or dedicated seed modules) with representative demo data for each feature to enable manual verification.
- Run mix precommit prior to requesting review to guarantee formatting, credo, tests, dialyzer, and other linters pass locally.

## Delivery Workflow & Tooling

- Feature specs, plans, and task lists must enumerate the failing tests to be authored first, including unit and integration coverage.
- Researchers must consult `mix usage_rules.docs` and update documentation links before committing to an approach.
- Exercise new functionality through the shared `web` CLI profiles to capture end-to-end behaviour and document findings.
- Keep configuration, dependency, and data migration steps explicit in planning documents so no implicit work lands in implementation.
- Sync demo data, documentation, and test fixtures for every release to preserve reproducibility.

## Governance

- Amendments require a written proposal, maintainer approval, and synchronized updates to all dependent templates before merging.
- Versioning follows semantic rules: MAJOR for principle removals or incompatible governance, MINOR for new principles or material expansions, PATCH for clarifications.
- Compliance is reviewed in every pull request; merges are blocked until the Constitution Check passes and mandated tests exist and fail prior to implementation.
- Track ratification and amendment metadata in this document and reference the governing version in commit messages when altering process.

**Version**: 1.0.0 | **Ratified**: 2025-10-30 | **Last Amended**: 2025-10-30
