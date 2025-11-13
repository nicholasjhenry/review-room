---
name: phoenix-contexts
description: Phoenix context design and Ecto patterns. Use when creating contexts, schemas, changesets, queries, or working with the database layer.
version: 1.0.0
---

# Phoenix Context and Ecto Patterns

Comprehensive guide to designing clean domain boundaries and robust data layers.

## Context Design Principles

### What is a Context?

A context is a boundary around related functionality. It's the public API your application uses to interact with a domain.

**Good context names:**
- `Accounts` (users, sessions, authentication)
- `Content` (posts, comments, media)
- `Billing` (invoices, payments, subscriptions)
- `Analytics` (events, metrics, reports)

**Avoid:**
- Generic names like `Users`, `Data`, `Helpers`
- Technical terms like `Repo`, `Database`, `Tables`

### Context Structure
