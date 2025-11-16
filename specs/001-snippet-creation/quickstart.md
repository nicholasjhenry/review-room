# Quickstart Guide: Snippet Creation

**Feature**: Snippet Creation  
**Branch**: `001-snippet-creation`  
**Date**: 2025-11-16

## Overview

This quickstart guide provides step-by-step instructions for implementing the snippet creation feature, following TDD principles and the project constitution.

---

## Prerequisites

- Elixir ~> 1.15 installed
- PostgreSQL running locally
- Phoenix application set up with phx.gen.auth
- Git branch `001-snippet-creation` checked out

---

## Implementation Steps

### Step 1: Install Dependencies

**Action:** Add Highlight.js for syntax highlighting

```bash
cd assets
npm install highlight.js@11.11.2 --save
```

**Verification:**
```bash
grep "highlight.js" assets/package.json
```

---

### Step 2: Write Failing Tests (TDD - Red Phase)

**Constitution Requirement:** Tests MUST be written before implementation.

#### 2.1 Context Unit Tests

Create: `test/review_room/snippets_test.exs`

```elixir
defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase
  alias ReviewRoom.Snippets
  import ReviewRoom.{AccountsFixtures, SnippetsFixtures}

  describe "create_snippet/2" do
    setup do
      user = user_fixture()
      scope = %{user: user}
      {:ok, scope: scope}
    end

    test "creates snippet with valid attributes", %{scope: scope} do
      attrs = %{
        "title" => "Test Snippet",
        "code" => "defmodule Test do\nend"
      }
      
      assert {:ok, snippet} = Snippets.create_snippet(attrs, scope)
      assert snippet.title == "Test Snippet"
      assert snippet.code == "defmodule Test do\nend"
      assert snippet.visibility == :private
      assert snippet.user_id == scope.user.id
      assert snippet.slug != nil
    end

    test "fails without title", %{scope: scope} do
      attrs = %{"code" => "test"}
      assert {:error, changeset} = Snippets.create_snippet(attrs, scope)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "fails without code", %{scope: scope} do
      attrs = %{"title" => "Test"}
      assert {:error, changeset} = Snippets.create_snippet(attrs, scope)
      assert %{code: ["can't be blank"]} = errors_on(changeset)
    end

    test "fails with title over 200 characters", %{scope: scope} do
      attrs = %{
        "title" => String.duplicate("a", 201),
        "code" => "test"
      }
      assert {:error, changeset} = Snippets.create_snippet(attrs, scope)
      assert %{title: ["should be at most 200 character(s)"]} = errors_on(changeset)
    end

    test "fails with code over 500KB", %{scope: scope} do
      attrs = %{
        "title" => "Large Snippet",
        "code" => String.duplicate("a", 512_001)
      }
      assert {:error, changeset} = Snippets.create_snippet(attrs, scope)
      assert %{code: ["should be at most 512000 byte(s)"]} = errors_on(changeset)
    end

    test "creates snippet with tags", %{scope: scope} do
      attrs = %{
        "title" => "Tagged Snippet",
        "code" => "test code",
        "tags" => "elixir, phoenix, web"
      }
      
      assert {:ok, snippet} = Snippets.create_snippet(attrs, scope)
      assert snippet.tags == ["elixir", "phoenix", "web"]
    end
    
    test "normalizes tags (lowercase, trim, dedup)", %{scope: scope} do
      attrs = %{
        "title" => "Tagged Snippet",
        "code" => "test code",
        "tags" => "Elixir, PHOENIX,  web , elixir"
      }
      
      assert {:ok, snippet} = Snippets.create_snippet(attrs, scope)
      assert snippet.tags == ["elixir", "phoenix", "web"]
    end

    test "sanitizes XSS in title", %{scope: scope} do
      attrs = %{
        "title" => "<script>alert('xss')</script>",
        "code" => "test"
      }
      
      # Phoenix auto-escapes in templates - just verify storage
      assert {:ok, snippet} = Snippets.create_snippet(attrs, scope)
      assert snippet.title == "<script>alert('xss')</script>"
      # XSS prevention happens at template level, not storage
    end
  end

  describe "get_snippet/2" do
    test "returns public snippet to any user" do
      snippet = public_snippet_fixture()
      other_user = user_fixture()
      scope = %{user: other_user}
      
      assert {:ok, found} = Snippets.get_snippet(snippet.slug, scope)
      assert found.id == snippet.id
    end

    test "returns private snippet to owner" do
      user = user_fixture()
      scope = %{user: user}
      snippet = snippet_fixture(user: user, visibility: :private)
      
      assert {:ok, found} = Snippets.get_snippet(snippet.slug, scope)
      assert found.id == snippet.id
    end

    test "returns not_found for private snippet to non-owner" do
      snippet = snippet_fixture(visibility: :private)
      other_user = user_fixture()
      scope = %{user: other_user}
      
      assert {:error, :not_found} = Snippets.get_snippet(snippet.slug, scope)
    end

    test "returns unlisted snippet to anyone with link" do
      snippet = snippet_fixture(visibility: :unlisted)
      other_user = user_fixture()
      scope = %{user: other_user}
      
      assert {:ok, found} = Snippets.get_snippet(snippet.slug, scope)
      assert found.id == snippet.id
    end
  end

  describe "list_snippets/2" do
    test "lists only user's snippets" do
      user = user_fixture()
      scope = %{user: user}
      
      _other_snippet = snippet_fixture()  # Different user
      my_snippet = snippet_fixture(user: user)
      
      snippets = Snippets.list_snippets(scope)
      assert length(snippets) == 1
      assert hd(snippets).id == my_snippet.id
    end

    test "filters by tag" do
      user = user_fixture()
      scope = %{user: user}
      
      {:ok, tagged} = Snippets.create_snippet(%{
        "title" => "Tagged",
        "code" => "test",
        "tags" => "elixir"
      }, scope)
      
      _untagged = snippet_fixture(user: user)
      
      snippets = Snippets.list_snippets(scope, tag: "elixir")
      assert length(snippets) == 1
      assert hd(snippets).id == tagged.id
    end
  end
end
```

**Run tests (should FAIL):**
```bash
mix test test/review_room/snippets_test.exs
```

Expected: All tests fail because `Snippets` module doesn't exist yet.

---

#### 2.2 LiveView Integration Tests

Create: `test/review_room_web/live/snippet_live_test.exs`

```elixir
defmodule ReviewRoomWeb.SnippetLiveTest do
  use ReviewRoomWeb.ConnCase
  import Phoenix.LiveViewTest
  import ReviewRoom.{AccountsFixtures, SnippetsFixtures}

  describe "Index (authenticated)" do
    setup :register_and_log_in_user

    test "lists all user snippets", %{conn: conn, user: user} do
      snippet = snippet_fixture(user: user)
      {:ok, _index_live, html} = live(conn, ~p"/snippets")
      
      assert html =~ "My Snippets"
      assert html =~ snippet.title
    end

    test "deletes snippet", %{conn: conn, user: user} do
      snippet = snippet_fixture(user: user)
      {:ok, index_live, _html} = live(conn, ~p"/snippets")
      
      assert index_live |> element("#snippet-#{snippet.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#snippet-#{snippet.id}")
    end
  end

  describe "New" do
    setup :register_and_log_in_user

    test "renders new snippet form", %{conn: conn} do
      {:ok, _new_live, html} = live(conn, ~p"/snippets/new")
      
      assert html =~ "New Snippet"
      assert html =~ "Title"
      assert html =~ "Code"
    end

    test "creates snippet with valid data", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/snippets/new")
      
      assert new_live
        |> form("#snippet-form", snippet: %{
          title: "Test Snippet",
          code: "defmodule Test do\nend",
          language: "elixir"
        })
        |> render_submit()
      
      assert_redirect(new_live, ~p"/s/test-snippet-")
    end

    test "shows validation errors", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/snippets/new")
      
      assert new_live
        |> form("#snippet-form", snippet: %{title: "", code: ""})
        |> render_change() =~ "can&#39;t be blank"
    end
  end

  describe "Show" do
    test "displays public snippet to unauthenticated user", %{conn: conn} do
      snippet = public_snippet_fixture()
      {:ok, _show_live, html} = live(conn, ~p"/s/#{snippet.slug}")
      
      assert html =~ snippet.title
      assert html =~ snippet.code
    end

    test "displays private snippet to owner", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      snippet = snippet_fixture(user: user, visibility: :private)
      
      {:ok, _show_live, html} = live(conn, ~p"/s/#{snippet.slug}")
      assert html =~ snippet.title
    end

    test "returns 404 for private snippet to non-owner", %{conn: conn} do
      snippet = snippet_fixture(visibility: :private)
      other_user = user_fixture()
      conn = log_in_user(conn, other_user)
      
      assert {:error, {:redirect, %{to: "/404"}}} = live(conn, ~p"/s/#{snippet.slug}")
    end

    test "displays syntax highlighting", %{conn: conn} do
      snippet = public_snippet_fixture(language: "elixir")
      {:ok, _show_live, html} = live(conn, ~p"/s/#{snippet.slug}")
      
      assert html =~ "language-elixir"
      assert html =~ ~s(phx-hook="SyntaxHighlight")
    end
  end

  describe "Edit" do
    setup :register_and_log_in_user

    test "updates snippet with valid data", %{conn: conn, user: user} do
      snippet = snippet_fixture(user: user)
      {:ok, edit_live, _html} = live(conn, ~p"/snippets/#{snippet.slug}/edit")
      
      assert edit_live
        |> form("#snippet-form", snippet: %{title: "Updated Title"})
        |> render_submit()
      
      assert_redirect(edit_live, ~p"/s/#{snippet.slug}")
    end

    test "denies access to non-owner", %{conn: conn} do
      snippet = snippet_fixture()
      
      assert {:error, {:redirect, %{to: "/403"}}} = live(conn, ~p"/snippets/#{snippet.slug}/edit")
    end
  end
end
```

**Run tests (should FAIL):**
```bash
mix test test/review_room_web/live/snippet_live_test.exs
```

---

### Step 3: Create Database Migration

```bash
mix ecto.gen.migration create_snippets
```

Edit migration file to add all snippet fields including tags array:

```elixir
defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets) do
      add :slug, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :code, :text, null: false
      add :language, :string
      add :tags, {:array, :string}, default: []
      add :visibility, :string, null: false, default: "private"
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:snippets, [:slug])
    create index(:snippets, [:user_id, :visibility, :created_at])
    create index(:snippets, [:visibility, :created_at])
    create index(:snippets, [:tags], using: "GIN")
  end
end
```

**Run migration:**
```bash
mix ecto.migrate
```

---

### Step 4: Implement Ecto Schema (Green Phase)

Create schema file to make tests pass:

- `lib/review_room/snippets/snippet.ex`

Key points from `data-model.md`:

```elixir
schema "snippets" do
  field :slug, :string
  field :title, :string
  field :description, :string
  field :code, :string
  field :language, :string
  field :tags, {:array, :string}, default: []
  field :visibility, Ecto.Enum, values: [:private, :public, :unlisted], default: :private
  
  belongs_to :user, ReviewRoom.Accounts.User
  
  timestamps()
end

def changeset(snippet, attrs) do
  snippet
  |> cast(attrs, [:title, :description, :code, :language, :visibility, :tags])
  |> validate_required([:title, :code])
  |> validate_length(:title, min: 1, max: 200)
  |> validate_length(:description, max: 2000)
  |> validate_length(:code, max: 512_000, count: :bytes)
  |> validate_inclusion(:language, supported_languages(), allow_nil: true)
  |> validate_inclusion(:visibility, [:private, :public, :unlisted])
  |> normalize_tags()
  |> validate_tags()
  |> put_slug()
  |> unique_constraint(:slug)
end
```

See `data-model.md` for `normalize_tags/1` and `validate_tags/1` implementations.

---

### Step 5: Implement Context API

Create: `lib/review_room/snippets.ex`

Implement all functions from `contracts/liveview-api.md`:
- `list_snippets/2`
- `get_snippet/2`
- `create_snippet/2`
- `update_snippet/3`
- `delete_snippet/2`
- `change_snippet/2`
- `list_tags/0`
- `supported_languages/0`

**Run context tests (should PASS):**
```bash
mix test test/review_room/snippets_test.exs
```

---

### Step 6: Implement LiveView Modules

Create LiveView files:

- `lib/review_room_web/live/snippet_live/index.ex`
- `lib/review_room_web/live/snippet_live/new.ex`
- `lib/review_room_web/live/snippet_live/show.ex`
- `lib/review_room_web/live/snippet_live/edit.ex`
- `lib/review_room_web/live/snippet_live/form_component.ex`

**Add routes** to `lib/review_room_web/router.ex` (see `contracts/liveview-api.md`)

**Run LiveView tests (should PASS):**
```bash
mix test test/review_room_web/live/snippet_live_test.exs
```

---

### Step 7: Add Syntax Highlighting

#### 7.1 Configure Highlight.js

Edit: `assets/js/app.js`

```javascript
// Import Highlight.js
import hljs from 'highlight.js/lib/core';

// Import languages
import elixir from 'highlight.js/lib/languages/elixir';
import javascript from 'highlight.js/lib/languages/javascript';
import python from 'highlight.js/lib/languages/python';
import ruby from 'highlight.js/lib/languages/ruby';
import go from 'highlight.js/lib/languages/go';
import rust from 'highlight.js/lib/languages/rust';
import sql from 'highlight.js/lib/languages/sql';
import xml from 'highlight.js/lib/languages/xml';
import css from 'highlight.js/lib/languages/css';
import json from 'highlight.js/lib/languages/json';
import yaml from 'highlight.js/lib/languages/yaml';
import markdown from 'highlight.js/lib/languages/markdown';

// Register languages
hljs.registerLanguage('elixir', elixir);
hljs.registerLanguage('javascript', javascript);
hljs.registerLanguage('python', python);
hljs.registerLanguage('ruby', ruby);
hljs.registerLanguage('go', go);
hljs.registerLanguage('rust', rust);
hljs.registerLanguage('sql', sql);
hljs.registerLanguage('xml', xml);
hljs.registerLanguage('html', xml);
hljs.registerLanguage('css', css);
hljs.registerLanguage('json', json);
hljs.registerLanguage('yaml', yaml);
hljs.registerLanguage('markdown', markdown);

// Add hooks
let Hooks = {};

Hooks.SyntaxHighlight = {
  mounted() {
    this.highlight();
  },
  updated() {
    this.highlight();
  },
  highlight() {
    this.el.querySelectorAll('pre code:not(.hljs)').forEach((block) => {
      hljs.highlightElement(block);
    });
  }
};

Hooks.CodeInput = {
  mounted() {
    this.updateCounter();
    this.el.addEventListener('input', () => this.updateCounter());
  },
  updateCounter() {
    const bytes = new Blob([this.el.value]).size;
    const maxBytes = 512000;
    const percentage = (bytes / maxBytes) * 100;
    
    const counter = document.getElementById('size-counter');
    if (counter) {
      counter.textContent = `${this.formatBytes(bytes)} / 500 KB`;
      counter.className = percentage >= 100 ? 'text-red-600' : 
                          percentage >= 90 ? 'text-yellow-600' : 'text-gray-600';
    }
  },
  formatBytes(bytes) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  }
};

// Update LiveSocket
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
});
```

#### 7.2 Add CSS Theme

Edit: `assets/css/app.css`

```css
/* Import Highlight.js theme */
@import "highlight.js/styles/github-dark.css";
```

---

### Step 8: Add Demo Data

Edit: `priv/repo/seeds.exs`

```elixir
# Seed snippets for manual testing
alias ReviewRoom.{Repo, Accounts, Snippets}

# Get or create demo user
demo_user = 
  case Accounts.get_user_by_email("demo@example.com") do
    nil ->
      {:ok, user} = Accounts.register_user(%{
        email: "demo@example.com",
        password: "password123password123"
      })
      user
    user -> user
  end

scope = %{user: demo_user}

# Create demo snippets
{:ok, _} = Snippets.create_snippet(%{
  "title" => "Elixir Pattern Matching",
  "description" => "Examples of pattern matching in Elixir",
  "code" => """
  # Pattern matching in function heads
  defmodule Math do
    def zero?(0), do: true
    def zero?(_), do: false
  end
  
  # Pattern matching in case
  case {1, 2, 3} do
    {1, x, 3} -> "Matched! x = #{x}"
    _ -> "No match"
  end
  """,
  "language" => "elixir",
  "visibility" => "public",
  "tags" => "elixir, pattern-matching, tutorial"
}, scope)

{:ok, _} = Snippets.create_snippet(%{
  "title" => "Phoenix Authentication Helper",
  "description" => "Helper function for checking authentication",
  "code" => """
  defmodule MyAppWeb.AuthHelpers do
    def require_authenticated_user(conn, _opts) do
      if conn.assigns[:current_user] do
        conn
      else
        conn
        |> put_flash(:error, "You must log in to access this page.")
        |> redirect(to: ~p"/login")
        |> halt()
      end
    end
  end
  """,
  "language" => "elixir",
  "visibility" => "private",
  "tags" => "phoenix, authentication, plug"
}, scope)

{:ok, _} = Snippets.create_snippet(%{
  "title" => "JavaScript Array Methods",
  "description" => "Cheat sheet for common array methods",
  "code" => """
  const numbers = [1, 2, 3, 4, 5];
  
  // Map: transform each element
  const doubled = numbers.map(n => n * 2);
  
  // Filter: select elements matching condition
  const evens = numbers.filter(n => n % 2 === 0);
  
  // Reduce: accumulate into single value
  const sum = numbers.reduce((acc, n) => acc + n, 0);
  
  // Find: get first matching element
  const first_even = numbers.find(n => n % 2 === 0);
  """,
  "language" => "javascript",
  "visibility" => "unlisted",
  "tags" => "javascript, arrays, cheat-sheet"
}, scope)

IO.puts("✅ Created demo snippets for #{demo_user.email}")
```

**Run seeds:**
```bash
mix run priv/repo/seeds.exs
```

---

### Step 9: Run All Tests

**Constitution requirement:** All tests must pass before requesting review.

```bash
mix test
```

**Expected:** All tests pass (green phase complete).

---

### Step 10: Run Pre-commit Checks

```bash
mix precommit
```

This runs:
- Formatter check
- Credo (code analysis)
- Tests
- Dialyzer (type checking)

**Fix any issues** reported by pre-commit checks.

---

### Step 11: Manual Verification

**Start the development server:**
```bash
mix phx.server
```

**Use the `web` CLI to test the feature:**

```bash
# List snippets page
web http://localhost:4000/snippets

# Create new snippet
web http://localhost:4000/snippets/new

# View public snippet (from seeds)
web http://localhost:4000/s/elixir-pattern-matching-[slug-suffix]

# Test as different user profile
web http://localhost:4000/snippets --profile user2
```

**Verify:**
- ✅ Syntax highlighting displays correctly
- ✅ Form validation works in real-time
- ✅ Size counter updates as you type
- ✅ Tags are created and associated properly
- ✅ Visibility controls work (private/public/unlisted)
- ✅ Authorization prevents unauthorized access
- ✅ Demo snippets display correctly

---

## Common Issues & Solutions

### Issue: Highlight.js not applying styles

**Solution:** Check that CSS theme is imported in `assets/css/app.css`:
```css
@import "highlight.js/styles/github-dark.css";
```

Rebuild assets:
```bash
cd assets && npm run build
```

---

### Issue: Tests fail with "module not found"

**Solution:** Ensure you created the test fixtures file:
```bash
mkdir -p test/support/fixtures
touch test/support/fixtures/snippets_fixtures.exs
```

---

### Issue: Migration fails with constraint error

**Solution:** Drop database and recreate:
```bash
mix ecto.drop
mix ecto.create
mix ecto.migrate
```

---

### Issue: Size validation not working

**Solution:** Ensure you're counting **bytes**, not characters:
```elixir
validate_length(:code, max: 512_000, count: :bytes)  # Correct
validate_length(:code, max: 512_000)  # Wrong - counts graphemes
```

---

## Next Steps After Implementation

1. **Code Review:** Request review from team member
2. **Performance Testing:** Test with 500KB snippets
3. **Security Audit:** Verify XSS protection and authorization
4. **Documentation:** Update README with snippet feature info
5. **Deployment:** Deploy to staging for QA testing

---

## Success Criteria Checklist

Before considering this feature complete, verify:

- ✅ All unit tests pass
- ✅ All integration tests pass
- ✅ `mix precommit` passes with no warnings
- ✅ Demo data seeds successfully
- ✅ Manual testing via `web` CLI confirms functionality
- ✅ Syntax highlighting works for all 12 supported languages
- ✅ Real-time validation provides immediate feedback
- ✅ Visibility controls enforce access properly (returns 404, not 403)
- ✅ XSS protection verified (templates auto-escape)
- ✅ 500KB snippet handling tested and performant
- ✅ Tag filtering returns correct results
- ✅ Constitution compliance verified (TDD, explicit dependencies, fail-fast)

---

## Time Estimate

**Total:** 8-12 hours for initial implementation

- Step 1: Install dependencies (15 min)
- Step 2: Write failing tests (2 hours)
- Step 3: Create migrations (30 min)
- Step 4: Implement schemas (1 hour)
- Step 5: Implement context (2 hours)
- Step 6: Implement LiveView (3 hours)
- Step 7: Add syntax highlighting (1 hour)
- Step 8: Add demo data (30 min)
- Step 9-11: Testing & verification (1.5 hours)

---

## References

- Feature Spec: `specs/001-snippet-creation/spec.md`
- Data Model: `specs/001-snippet-creation/data-model.md`
- API Contracts: `specs/001-snippet-creation/contracts/liveview-api.md`
- Research: `specs/001-snippet-creation/research.md`
- Implementation Plan: `specs/001-snippet-creation/plan.md`
