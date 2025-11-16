## Project guidelines

- This is a web application written using the Phoenix web framework.
- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

## Demo data

Each new feature must include generated demo data to seed the database. This enables
manual verification of new features.

## Authorization

Always use the `Accounts.Scope` for authorization.

## Your Workflow

You have the ability to browse the web with a full Chrome browser via the system shell to fulfill the user's needs, ie:

    $ web example.com
    $ web example.com --raw > output.html $ web example.com --raw > output.json
    $ web example.com output.md --truncate-after 123

**Always** use the built-in Bash CLI tool 'web' to interact and test the app as you build features. This should be your GOTO TOOL for verifying functionality, build status, etc:

By default the page is converted to markdown and displayed to stdout, but you can redirect to a file the user asks. **never** pass --raw or --truncate-after unless the user asks, or if it makes sense to do do, i.e. for fetching json data from an API.

_Note_: each invocation of the `web` uses a _shared session_ so cookie sessions and other state is preserved across separate invocations of the `web` command. This means you can log in to a site and then issue another `web` command. This means you can log in to a site and then issue another `web` command. This means you can log in to a site and then issue another `web` command to view of interact with a logged in page. You can also pass the optional `--profile` argument to `web` to browse under unique profiles, which is useful for testing multiple logins or sessions at, ie:

$ web http://localhost:4000 --profile "user1"
$ web http://localhost:4000 --profile "user2"

Example web browsing:

user:
This page shows the latest interfaces https://example.com
assistant:
Let me open the web page and see what I can find with the bash tool: web https://example.com

\*Note: The default markdown output also includes JS console logs/errors if any are present, ie:

==========================
JS Console Logs and Errors
==========================

    [log] phx mount: - {...}
    (error] unknown hook found for "StatsChart" JSHandle@node

### Executing JavaScript code on page visit

The web cli also has the ability to execute javascript code on page visit.
Use this to help diagnose issues, interact with the page to test actions for correctness, or to test real-time activity, on the page with the user.

<!-- usage-rules-start -->
<!-- usage-rules-header -->

# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below.
Before attempting to use any of these packages or to discover if you should use them, review their
usage rules to understand the correct patterns, conventions, and best practices.

<!-- usage-rules-header-end -->

<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```
<!-- usage_rules-end -->

<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->

<!-- usage-rules-end -->

## Active Technologies
- Elixir ~> 1.15 + Phoenix ~> 1.8.1, Phoenix LiveView ~> 1.1.0, Ecto SQL ~> 3.13, PostgreSQL (001-snippet-creation)
- PostgreSQL (via Ecto) for snippets, tags, and associations (001-snippet-creation)

## Recent Changes
- 001-snippet-creation: Added Elixir ~> 1.15 + Phoenix ~> 1.8.1, Phoenix LiveView ~> 1.1.0, Ecto SQL ~> 3.13, PostgreSQL
