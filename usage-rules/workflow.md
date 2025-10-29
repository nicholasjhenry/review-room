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
