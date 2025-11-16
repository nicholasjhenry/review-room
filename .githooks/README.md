# Git Hooks

This directory contains git hooks that enforce code quality standards before commits.

## Setup

To enable these hooks, run:

```bash
git config core.hooksPath .githooks
```

This needs to be done once per developer when they clone the repository.

## Available Hooks

### pre-commit

Runs `mix precommit` before every commit to ensure:
- ✅ Code compiles without warnings
- ✅ All tests pass
- ✅ Code is properly formatted
- ✅ Dialyzer type checking passes
- ✅ No unused dependencies

**To bypass** (not recommended):
```bash
git commit --no-verify
```

## Adding to Developer Onboarding

Add this to your project's README or setup documentation:

```markdown
## Developer Setup

After cloning the repository, enable git hooks:

```bash
git config core.hooksPath .githooks
```

This ensures code quality checks run automatically before each commit.
```
