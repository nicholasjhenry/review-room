# Quickstart – Creating a Snippet

## Prerequisites
- Elixir 1.15+, Erlang/OTP per project `mise.toml`
- PostgreSQL running locally (`mix setup` provisions schema)
- Seed demo users present (`mix run priv/repo/seeds.exs`)
- Logged-in session via `web http://localhost:4000` (shared CLI browser)

## Run the App
```bash
mix setup
mix phx.server
```

In another terminal, open the shared browser session:
```bash
web http://localhost:4000/snippets/new
```

## Buffered Persistence Demo
1. Fill the form with title, description, code, syntax, tags, and select visibility.
2. Submit; you should see immediate confirmation with the snippet summary and buffer position.
3. To observe batched flush, tail the dev logs while submitting multiple snippets:
   ```bash
   tail -f log/dev.log
   ```

## Test Suite
Run required tests before implementation work is considered complete:
```bash
mix test test/review_room/snippets/snippets_test.exs
mix test test/review_room_web/live/snippet_live_test.exs
```

## Telemetry & Observability
- Subscribe to `[:review_room, :snippets, :buffer, :flush]` events for metrics dashboards.
- Structured logs include `buffer_token`, `attempt`, and `visibility` fields.

## Demo Data Refresh
```bash
mix run priv/repo/seeds.exs
```
This seeds sample snippets for each visibility level with curated tags to support review sessions.
