This file contain TEMPLATE snippets containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`) and directives start with `//`.

## Project guidelines

- This is a web application written using the Phoenix web framework.
- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

## Demo data

Each new feature must include generated demo data to seed the database. This enables
manual verification of new features.

## Authorization

Always use the `Accounts.Scope` for authorization.
