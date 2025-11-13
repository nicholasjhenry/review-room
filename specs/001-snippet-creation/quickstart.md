# Quickstart Guide: Snippet Creation

**Feature**: 001-snippet-creation  
**Date**: 2025-11-13

## Overview

This guide provides step-by-step instructions for implementing the snippet creation feature following Test-Driven Development (TDD) principles as required by the ReviewRoom Constitution.

## Prerequisites

- ReviewRoom development environment set up
- PostgreSQL running locally
- Familiarity with Phoenix LiveView and Ecto
- Read `research.md` and `data-model.md` in this spec directory

## Implementation Steps

### Step 1: Database Schema (TDD: Write Failing Tests First)

#### 1.1 Write Migration Tests

```elixir
# test/review_room/snippets_test.exs (create this file)
defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase
  
  describe "snippets table" do
    test "has required columns" do
      # This test will fail until migration is run
      assert_raise Postgrex.Error, fn ->
        Repo.query!("SELECT title, code, visibility, user_id FROM snippets LIMIT 1")
      end
    end
  end
end
```

**Run test**: `mix test test/review_room/snippets_test.exs`  
**Expected**: ❌ Fails (table doesn't exist)

#### 1.2 Create Migration

```bash
mix ecto.gen.migration create_snippets
```

Copy migration code from `data-model.md` into the generated migration file. Note: Only one migration is needed - tags are stored as an array column in the snippets table.

**Run migration**: `mix ecto.migrate`  
**Run test**: `mix test test/review_room/snippets_test.exs`  
**Expected**: ✅ Passes (table exists)

---

### Step 2: Ecto Schemas (TDD: Write Schema Tests First)

#### 2.1 Write Schema Tests

```elixir
# test/review_room/snippets/snippet_test.exs
defmodule ReviewRoom.Snippets.SnippetTest do
  use ReviewRoom.DataCase
  
  alias ReviewRoom.Snippets.Snippet
  
  describe "changeset/2" do
    test "requires title and code" do
      changeset = Snippet.changeset(%Snippet{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).code
    end
    
    test "validates title length" do
      long_title = String.duplicate("a", 201)
      changeset = Snippet.changeset(%Snippet{}, %{title: long_title, code: "code"})
      refute changeset.valid?
      assert "should be at most 200 character(s)" in errors_on(changeset).title
    end
    
    test "validates code size" do
      large_code = String.duplicate("a", 512_001)
      changeset = Snippet.changeset(%Snippet{}, %{title: "Title", code: large_code})
      refute changeset.valid?
    end
    
    test "defaults visibility to private" do
      changeset = Snippet.changeset(%Snippet{}, %{title: "Title", code: "code"})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :visibility) == :private
    end
  end
end
```

**Run test**: `mix test test/review_room/snippets/snippet_test.exs`  
**Expected**: ❌ Fails (schema doesn't exist)

#### 2.2 Create Schemas

```bash
mkdir -p lib/review_room/snippets
```

Create file:
- `lib/review_room/snippets/snippet.ex` - Copy from `data-model.md` (includes tags array field)

**Run test**: `mix test test/review_room/snippets/snippet_test.exs`  
**Expected**: ✅ Passes

---

### Step 3: Context Functions (TDD: Write Context Tests First)

#### 3.1 Write Context Tests

```elixir
# test/review_room/snippets_test.exs (add to existing file)
defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase
  
  alias ReviewRoom.Snippets
  alias ReviewRoom.AccountsFixtures
  
  describe "create_snippet/2" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = %ReviewRoom.Accounts.Scope{user: user}
      %{scope: scope, user: user}
    end
    
    test "creates snippet with valid data", %{scope: scope} do
      attrs = %{
        title: "Test Snippet",
        code: "def hello, do: :world",
        language: "elixir"
      }
      
      assert {:ok, snippet} = Snippets.create_snippet(attrs, scope)
      assert snippet.title == "Test Snippet"
      assert snippet.user_id == scope.user.id
    end
    
    test "returns error with invalid data", %{scope: scope} do
      assert {:error, changeset} = Snippets.create_snippet(%{}, scope)
      refute changeset.valid?
    end
  end
  
  describe "list_snippets/1" do
    test "returns only current user's snippets", %{scope: scope} do
      snippet1 = snippet_fixture(user_id: scope.user.id)
      other_user = AccountsFixtures.user_fixture()
      _snippet2 = snippet_fixture(user_id: other_user.id)
      
      snippets = Snippets.list_snippets(scope)
      assert length(snippets) == 1
      assert List.first(snippets).id == snippet1.id
    end
  end
  
  # Add more context function tests...
end
```

**Run test**: `mix test test/review_room/snippets_test.exs`  
**Expected**: ❌ Fails (context doesn't exist)

#### 3.2 Create Context Module

```bash
# Create context file
touch lib/review_room/snippets.ex
```

Copy context code from `data-model.md` into `lib/review_room/snippets.ex`.

**Run test**: `mix test test/review_room/snippets_test.exs`  
**Expected**: ✅ Passes

---

### Step 4: Test Fixtures

Create test fixture helpers:

```elixir
# test/support/fixtures/snippets_fixtures.ex
defmodule ReviewRoom.SnippetsFixtures do
  alias ReviewRoom.Repo
  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoom.AccountsFixtures
  
  def snippet_fixture(attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()
    
    attrs = 
      Enum.into(attrs, %{
        title: "Test Snippet",
        description: "A test code snippet",
        code: "def hello, do: :world",
        language: "elixir",
        visibility: :private,
        tags: ["test", "elixir"],
        user_id: user.id
      })
    
    {:ok, snippet} = 
      %Snippet{}
      |> Snippet.changeset(attrs)
      |> Repo.insert()
    
    snippet
  end
end
```

---

### Step 5: LiveView Tests (Write Before Implementation)

#### 5.1 Create LiveView Test Files

```elixir
# test/review_room_web/live/snippet_live_test.exs
defmodule ReviewRoomWeb.SnippetLiveTest do
  use ReviewRoomWeb.ConnCase
  import Phoenix.LiveViewTest
  
  alias ReviewRoom.SnippetsFixtures
  
  describe "Index (authenticated)" do
    setup :register_and_log_in_user
    
    test "lists all user snippets", %{conn: conn, user: user} do
      snippet = SnippetsFixtures.snippet_fixture(user_id: user.id)
      {:ok, _view, html} = live(conn, ~p"/snippets")
      assert html =~ snippet.title
    end
    
    test "deletes snippet", %{conn: conn, user: user} do
      snippet = SnippetsFixtures.snippet_fixture(user_id: user.id)
      {:ok, view, _html} = live(conn, ~p"/snippets")
      
      assert view
             |> element("#snippet-#{snippet.id} a", "Delete")
             |> render_click()
      
      refute has_element?(view, "#snippet-#{snippet.id}")
    end
  end
  
  describe "Form (new snippet)" do
    setup :register_and_log_in_user
    
    test "renders form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/snippets/new")
      assert html =~ "New Snippet"
      assert html =~ "Title"
      assert html =~ "Code"
    end
    
    test "creates snippet with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/snippets/new")
      
      assert view
             |> form("#snippet-form", snippet: %{
               title: "My Snippet",
               code: "def hello, do: :world",
               language: "elixir"
             })
             |> render_submit()
      
      assert_redirect(view, ~p"/snippets/")
    end
    
    test "shows validation errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/snippets/new")
      
      html = view
             |> form("#snippet-form", snippet: %{title: "", code: ""})
             |> render_submit()
      
      assert html =~ "can&#39;t be blank"
    end
  end
  
  describe "Show (public access)" do
    test "displays public snippet to guest", %{conn: conn} do
      snippet = SnippetsFixtures.snippet_fixture(visibility: :public)
      {:ok, _view, html} = live(conn, ~p"/snippets/#{snippet}")
      assert html =~ snippet.title
      assert html =~ snippet.code
    end
    
    test "denies access to private snippet", %{conn: conn} do
      snippet = SnippetsFixtures.snippet_fixture(visibility: :private)
      
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/snippets/#{snippet}")
      end
    end
  end
end
```

**Run test**: `mix test test/review_room_web/live/snippet_live_test.exs`  
**Expected**: ❌ Fails (LiveViews don't exist)

---

### Step 6: LiveView Implementation

#### 6.1 Create LiveView Files

```bash
mkdir -p lib/review_room_web/live/snippet_live
touch lib/review_room_web/live/snippet_live/index.ex
touch lib/review_room_web/live/snippet_live/show.ex
touch lib/review_room_web/live/snippet_live/form.ex
```

Copy LiveView code from `contracts/liveview-routes.md` (you'll need to write the actual LiveView modules based on the contracts).

#### 6.2 Add Routes

```elixir
# lib/review_room_web/router.ex

# Add to existing :require_authenticated_user live_session
live "/snippets", SnippetLive.Index, :index
live "/snippets/new", SnippetLive.Form, :new
live "/snippets/:id/edit", SnippetLive.Form, :edit

# Add to existing :current_user live_session  
live "/snippets/:id", SnippetLive.Show, :show
```

**Run test**: `mix test test/review_room_web/live/snippet_live_test.exs`  
**Expected**: ✅ Passes (after implementing LiveViews)

---

### Step 7: Syntax Highlighting Integration

#### 7.1 Add Autumn Dependency

```elixir
# mix.exs - Add to deps
{:autumn, "~> 0.1.0"}
```

Run: `mix deps.get`

#### 7.2 Generate Theme CSS

```bash
# Generate Autumn theme CSS file
mix autumn.gen.theme catppuccin_mocha

# This creates: priv/static/themes/catppuccin_mocha.css
```

#### 7.3 Configure Autumn

```elixir
# config/config.exs
config :autumn,
  theme: "catppuccin_mocha",
  formatter: :html_linked

# Add themes to static paths
config :review_room, ReviewRoomWeb.Endpoint,
  static_paths: ~w(assets fonts images favicon.ico robots.txt themes)
```

#### 7.4 Add Theme CSS to Layout

```heex
<!-- lib/review_room_web/components/layouts/root.html.heex -->
<head>
  <!-- ... existing head content ... -->
  <link rel="stylesheet" href={~p"/themes/catppuccin_mocha.css"}>
</head>
```

#### 7.5 Use in Templates

```elixir
# In LiveView module
highlighted_html = Autumn.highlight!(snippet.code, lang: snippet.language)

# In template
<div class="snippet-code">
  <%= Phoenix.HTML.raw(highlighted_html) %>
</div>
```

Or create a helper component (recommended):

```elixir
# lib/review_room_web/components/snippet_components.ex
defmodule ReviewRoomWeb.SnippetComponents do
  use Phoenix.Component
  
  attr :code, :string, required: true
  attr :language, :string, default: nil
  
  def code_snippet(assigns) do
    ~H"""
    <div class="code-snippet">
      <%= Phoenix.HTML.raw(Autumn.highlight!(@code, lang: @language)) %>
    </div>
    """
  end
end
```

---

### Step 8: Configuration

```elixir
# config/config.exs
config :review_room, :supported_languages, [
  {"elixir", "Elixir"},
  {"javascript", "JavaScript"},
  {"python", "Python"},
  # ... add more from research.md
]
```

---

### Step 9: Demo Data (Seeds)

```elixir
# priv/repo/seeds.exs
alias ReviewRoom.Repo
alias ReviewRoom.Accounts.User
alias ReviewRoom.Snippets.{Snippet, Tag}

# Create demo user if not exists
user = Repo.get_by(User, email: "demo@example.com") || 
  Repo.insert!(%User{
    email: "demo@example.com",
    hashed_password: Bcrypt.hash_pwd_salt("password123")
  })

# Create demo snippets
Repo.insert!(%Snippet{
  title: "Elixir Hello World",
  description: "Basic Elixir function",
  code: "def hello(name) do\n  \"Hello, \#{name}!\"\nend",
  language: "elixir",
  visibility: :public,
  user_id: user.id
})

# Add more demo snippets with tags...
```

**Run seeds**: `mix run priv/repo/seeds.exs`

---

### Step 10: Run Full Test Suite

```bash
# Run all tests
mix test

# Run with coverage (if configured)
mix test --cover

# Run precommit checks
mix precommit
```

**Expected**: ✅ All tests pass

---

## Verification Checklist

Before considering the feature complete:

- [ ] All migration files created and run successfully
- [ ] All schema validations tested and passing
- [ ] All context functions tested and passing  
- [ ] All LiveView integration tests passing
- [ ] Syntax highlighting works in browser
- [ ] Demo data seeded successfully
- [ ] Can create snippet via UI
- [ ] Can edit own snippet via UI
- [ ] Can delete own snippet via UI
- [ ] Can view public snippet as guest
- [ ] Cannot view private snippet as guest
- [ ] Tags display and filter correctly
- [ ] XSS prevention verified (HTML escaped)
- [ ] `mix precommit` passes (formatting, credo, dialyzer, tests)

---

## Common Issues & Solutions

**Issue**: Tests fail with "current_scope not found"  
**Solution**: Ensure test uses `setup :register_and_log_in_user` and LiveView has correct `on_mount` hook

**Issue**: Syntax highlighting doesn't display  
**Solution**: Verify Autumn dependency installed (`mix deps.get`), theme CSS generated and linked in layout, `Autumn.highlight!/2` called in LiveView

**Issue**: Tags not saving  
**Solution**: Ensure tags field is cast in changeset, check `normalize_tags/1` function processes both strings and arrays

**Issue**: Dialyzer errors on Scope type  
**Solution**: Add proper typespec to Scope module, use `@type t :: %__MODULE__{...}`

---

## Next Steps

After completing this quickstart:

1. Run the full test suite: `mix test`
2. Start the server: `mix phx.server`
3. Visit `http://localhost:4000/snippets/new`
4. Create your first snippet!
5. Review code with team
6. Address any code review feedback
7. Merge to main branch

---

## Resources

- Feature spec: `specs/001-snippet-creation/spec.md`
- Research decisions: `specs/001-snippet-creation/research.md`
- Data model: `specs/001-snippet-creation/data-model.md`
- Route contracts: `specs/001-snippet-creation/contracts/liveview-routes.md`
- Phoenix LiveView docs: https://hexdocs.pm/phoenix_live_view
- Ecto docs: https://hexdocs.pm/ecto
- Highlight.js docs: https://highlightjs.org/
