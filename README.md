# ReviewRoom

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment
guides](https://hexdocs.pm/phoenix/deployment.html).

## Real-Time Snippet Sharing

ReviewRoom delivers a world-class real-time code snippet experience with a comprehensive design system:

- **Create & share** snippets at `/snippets/new` with enhanced form accessibility (WCAG 2.1 AA compliant),
  inline helper text, real-time validation feedback, and polished success/error states.
- **Collaborate live** on `/s/:id` with premium syntax highlighting, cursor/selection presence indicators,
  reconnection safeguards, clipboard success micro-interactions, and workspace-oriented navigation chrome.
- **Browse the gallery** on `/snippets` with redesigned responsive grid layouts, instant filter panels,
  skeleton loading states, premium card designs featuring owner badges and activity micro-copy, and
  smooth transitions honoring reduced-motion preferences.
- **Manage your work** on `/snippets/my` where owners can toggle visibility or delete snippets with
  refined feedback toasts and accessible confirmation flows.

**Design System Highlights:**

- Custom Tailwind v4 theme with 8px spacing scale, premium color palette, and refined typography
- DaisyUI component extensions avoiding generic styling through custom tokens
- Comprehensive accessibility including 4.5:1 text contrast ratios, reduced-motion support, and
  ARIA landmarks throughout
- Micro-interactions with 180ms standard timing for delightful yet responsive feedback
- 205 passing tests including dedicated accessibility regression checks

## Experimental Agentic Coding

This is an experiment using GitHub Spec Kit and Coding Agents (Claude Code, Codex) inside the Zed
Editor. Warning: this code may not be exemplary as there was minimal developer interaction.

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
