# ReviewRoom

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment
guides](https://hexdocs.pm/phoenix/deployment.html).

## Real-Time Snippet Sharing

ReviewRoom now includes a polished real-time code snippet experience:

- **Create & share** snippets at `/snippets/new` with language selection, visibility controls, and
  responsive form interactions.
- **Collaborate live** on `/s/:id` with syntax highlighting, cursor/selection presence, reconnection
  safeguards, and one-click clipboard copy.
- **Browse the gallery** on `/snippets` with instant filters, search, skeleton loading states, and
  tailored cards for public snippets.
- **Manage your work** on `/snippets/my` where owners can toggle visibility or delete snippets with
  inline feedback.

All views are styled with Tailwind and integrate subtle micro-interactions so the experience stays
fast, modern, and delightful.

## Experimental Agentic Coding

This is an experiment using GitHub Spec Kit and Coding Agents (Claude Code, Codex) inside the Zed
Editor. Warning: this code may not be exemplary as there was minimal developer interaction.

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
