# ReviewRoom

A collaborative code snippet management application built with Phoenix and LiveView.

## Getting Started

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Features

### Snippet Creation

ReviewRoom provides a buffered snippet creation workflow that captures metadata immediately while deferring database writes for efficiency.

#### Creating a Snippet

1. Navigate to `/snippets/new` (requires authentication)
2. Fill in the required fields:
   - **Title**: Brief name for your snippet (max 120 characters)
   - **Description**: What the snippet does (max 500 characters)  
   - **Code/Body**: The actual code content (max 10,000 characters)
   - **Language**: Select from curated syntax options (defaults to plaintext)
   - **Visibility**: Choose snippet access level
     - `personal`: Only visible to you
     - `team`: Visible to your team members
     - `organization`: Visible across the organization
   - **Tags**: Comma-separated tags for categorization (max 10 tags)
3. Submit the form - snippet is queued immediately with position feedback
4. Snippets are automatically flushed to the database when either:
   - Buffer reaches 10 pending snippets, or
   - 5 seconds of inactivity passes

#### Tag Normalization

Tags are automatically normalized:
- Converted to lowercase
- Whitespace trimmed
- Duplicates removed
- Limited to 10 tags per snippet

Example: `"  Elixir  , TESTING, elixir"` becomes `["elixir", "testing"]`

#### Manual Flush

Administrators can manually flush pending snippets if needed. In IEx:

```elixir
# Flush all pending snippets for a scope
ReviewRoom.Snippets.flush_now(scope)
```

#### Demo Data

Load demo snippets with various visibility levels and tags:

```bash
mix run priv/repo/seeds.exs
```

This creates sample snippets demonstrating different languages, tags, and visibility settings.

## Development

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
