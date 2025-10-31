# Quickstart Guide: Snippet Creation Feature

**Feature**: 001-snippet-creation  
**Date**: 2025-10-31  
**For**: Developers implementing this feature

## Overview

This guide provides the step-by-step implementation sequence for the snippet creation feature. Follow this order to ensure tests are written first and all dependencies are satisfied before writing production code.

## Prerequisites

- Phoenix application with phx.gen.auth already installed
- PostgreSQL database configured
- Elixir 1.19.1+ and Erlang/OTP installed
- Node.js for asset compilation (Highlight.js)

## Implementation Sequence

### Phase 1: Configuration & Setup (No Tests Required)

#### 1.1 Add Configuration

**File**: `config/config.exs`

```elixir
# Add after existing config
config :review_room, :snippet_languages, [
  %{name: "Elixir", code: "elixir"},
  %{name: "JavaScript", code: "javascript"},
  %{name: "TypeScript", code: "typescript"},
  %{name: "Python", code: "python"},
  %{name: "Java", code: "java"},
  %{name: "Go", code: "go"},
  %{name: "Ruby", code: "ruby"},
  %{name: "PHP", code: "php"},
  %{name: "C", code: "c"},
  %{name: "C++", code: "cpp"},
  %{name: "C#", code: "csharp"},
  %{name: "SQL", code: "sql"},
  %{name: "HTML", code: "html"},
  %{name: "CSS", code: "css"},
  %{name: "Shell/Bash", code: "bash"},
  %{name: "Markdown", code: "markdown"}
]

config :review_room, :snippet_max_size, 1_048_576  # 1MB
config :review_room, :snippet_max_tags, 10
```

#### 1.2 Add HtmlSanitizeEx Dependency

**File**: `mix.exs`

```elixir
defp deps do
  [
    # ... existing deps
    {:html_sanitize_ex, "~> 1.4"}
  ]
end
```

**Run**: `mix deps.get`

#### 1.3 Add Highlight.js (Client-Side)

**File**: `assets/js/app.js`

```javascript
// Add Highlight.js import (near other imports)
import hljs from 'highlight.js';
import 'highlight.js/styles/github-dark.css';

// Make available globally for hooks
window.hljs = hljs;

// Import syntax highlighter hook
import SyntaxHighlighter from './hooks/syntax_highlighter';

// Add to LiveSocket hooks
let Hooks = {
  SyntaxHighlighter: SyntaxHighlighter
};

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks  // Add this line
});
```

**Install Highlight.js**:
```bash
cd assets
npm install highlight.js
cd ..
```

---

### Phase 2: Database Schema (Migrations Only - No Tests)

#### 2.1 Generate Migration

```bash
mix ecto.gen.migration create_snippets
```

**Note**: Only one migration needed. Tags are stored as an array field on snippets table.

#### 2.2 Write Migration File

**File**: `priv/repo/migrations/YYYYMMDDHHMMSS_create_snippets.exs`

```elixir
defmodule ReviewRoom.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :code, :text, null: false
      add :language, :string, size: 50, null: false
      add :title, :string, size: 255
      add :description, :text
      add :visibility, :string, size: 20, null: false, default: "private"
      add :tags, {:array, :string}, null: false, default: []

      timestamps()
    end

    create index(:snippets, [:user_id])
    create index(:snippets, [:visibility])
    create index(:snippets, [:language])
    create index(:snippets, [:tags], using: :gin)
  end
end
```

**Run Migrations**:
```bash
mix ecto.migrate
```

---

### Phase 3: Schemas (No Direct Tests)

**Important**: Per Phoenix style guide, we do NOT test record functions directly. All validation will be tested through context module action functions in Phase 4.

#### 3.1 Implement Schema

**File**: `lib/review_room/snippets/snippet.ex`

```elixir
defmodule ReviewRoom.Snippets.Snippet do
  use ReviewRoom, :record
  
  @max_code_size 1_048_576  # 1MB
  @max_tags 10
  @visibility_values ~w(private public)
  
  schema "snippets" do
    field :code, :string
    field :language, :string
    field :title, :string
    field :description, :string
    field :visibility, :string, default: "private"
    field :tags, {:array, :string}, default: []
    
    belongs_to :user, ReviewRoom.Accounts.User
    
    timestamps()
  end
  
  @doc false
  @spec changeset(t(), Attrs.t()) :: Ecto.Changeset.t(t())
  def changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:code, :language, :title, :description, :visibility, :tags])
    |> validate_required([:code, :language])
    |> validate_length(:code, max: @max_code_size, 
         message: "Snippet content is too large. Maximum size is 1MB.")
    |> validate_length(:title, max: 255)
    |> validate_inclusion(:visibility, @visibility_values)
    |> validate_language()
    |> sanitize_html_fields()
    |> normalize_tags()
    |> validate_tags_count()
  end
  
  defp validate_language(changeset) do
    supported_languages = Application.get_env(:review_room, :snippet_languages, [])
      |> Enum.map(& &1.code)
    
    validate_inclusion(changeset, :language, supported_languages,
      message: "Selected language is not supported.")
  end
  
  defp sanitize_html_fields(changeset) do
    changeset
    |> update_change(:title, &HtmlSanitizeEx.strip_tags/1)
    |> update_change(:description, &HtmlSanitizeEx.strip_tags/1)
  end
  
  defp normalize_tags(changeset) do
    case get_change(changeset, :tags) do
      nil -> 
        changeset
      tags when is_list(tags) ->
        normalized = tags
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.uniq()
        |> Enum.take(@max_tags)
        
        put_change(changeset, :tags, normalized)
      _ -> 
        changeset
    end
  end
  
  defp validate_tags_count(changeset) do
    case get_change(changeset, :tags) do
      tags when is_list(tags) and length(tags) > @max_tags ->
        add_error(changeset, :tags, "Maximum #{@max_tags} tags allowed")
      _ ->
        changeset
    end
  end
end
```

---

### Phase 4: Context Layer (WRITE TESTS FIRST)

**Note**: These tests will validate both context actions AND underlying record validation logic. This is the ONLY place we test validation behavior.

#### 4.1 Write Context Tests First

**File**: `test/review_room/snippets_test.exs`

```elixir
defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase
  
  alias ReviewRoom.Snippets
  alias ReviewRoom.Accounts.Scope
  
  describe "when creating a snippet" do
    test "given valid data then snippet is created" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{
        code: "console.log('test')",
        language: "javascript",
        title: "Test Snippet",
        visibility: "private"
      }
      
      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.code == attrs.code
      assert snippet.language == attrs.language
      assert snippet.user_id == user.id
    end
    
    test "given missing code then error is returned" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{language: "ruby"}
      
      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).code
    end
    
    test "given missing language then error is returned" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{code: "test"}
      
      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).language
    end
    
    test "given unsupported language then error is returned" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{code: "test", language: "invalid_lang"}
      
      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      refute changeset.valid?
      assert "Selected language is not supported" in errors_on(changeset).language
    end
    
    test "given code exceeding 1MB then error is returned" do
      user = insert(:user)
      scope = %Scope{user: user}
      large_code = String.duplicate("a", 1_048_577)  # 1MB + 1 byte
      attrs = %{code: large_code, language: "ruby"}
      
      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      refute changeset.valid?
      assert "Snippet content is too large" in errors_on(changeset).code
    end
    
    test "given title with HTML then HTML is stripped" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{
        code: "test",
        language: "ruby",
        title: "<script>alert('xss')</script>Safe Title"
      }
      
      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.title == "Safe Title"
    end
    
    test "given description with HTML then HTML is stripped" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{
        code: "test",
        language: "ruby",
        description: "<b>Bold</b> text"
      }
      
      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.description == "Bold text"
    end
    
    test "given no visibility then defaults to private" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{code: "test", language: "ruby"}
      
      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.visibility == "private"
    end
    
    test "given invalid visibility then error is returned" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{code: "test", language: "ruby", visibility: "team"}
      
      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      refute changeset.valid?
    end
    
    test "given tags then snippet is created with tags array" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{
        code: "test",
        language: "ruby",
        tags: ["ruby", "test"]
      }
      
      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert length(snippet.tags) == 2
      assert "ruby" in snippet.tags
      assert "test" in snippet.tags
    end
    
    test "given more than 10 tags then error is returned" do
      user = insert(:user)
      scope = %Scope{user: user}
      tags = Enum.map(1..11, &"tag#{&1}")
      attrs = %{code: "test", language: "ruby", tags: tags}
      
      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      refute changeset.valid?
      assert "Maximum 10 tags allowed" in errors_on(changeset).tags
    end
    
    test "given tags with whitespace and duplicates then tags are normalized" do
      user = insert(:user)
      scope = %Scope{user: user}
      attrs = %{code: "test", language: "ruby", tags: [" tag1 ", "tag2", "", "tag1", "tag3"]}
      
      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.tags == ["tag1", "tag2", "tag3"]
    end
  end
  
  describe "when getting a snippet" do
    test "given user is owner then snippet is returned" do
      user = insert(:user)
      scope = %Scope{user: user}
      snippet = insert(:snippet, user: user, visibility: "private")
      
      assert found = Snippets.get_snippet(scope, snippet.id)
      assert found.id == snippet.id
    end
    
    test "given public snippet then non-owner can view" do
      owner = insert(:user)
      viewer = insert(:user)
      scope = %Scope{user: viewer}
      snippet = insert(:snippet, user: owner, visibility: "public")
      
      assert found = Snippets.get_snippet(scope, snippet.id)
      assert found.id == snippet.id
    end
    
    test "given private snippet and non-owner then nil is returned" do
      owner = insert(:user)
      viewer = insert(:user)
      scope = %Scope{user: viewer}
      snippet = insert(:snippet, user: owner, visibility: "private")
      
      assert Snippets.get_snippet(scope, snippet.id) == nil
    end
  end
  
  describe "when listing snippets" do
    test "given user then user's snippets and public snippets are returned" do
      user = insert(:user)
      other_user = insert(:user)
      scope = %Scope{user: user}
      
      my_snippet = insert(:snippet, user: user, visibility: "private")
      public_snippet = insert(:snippet, user: other_user, visibility: "public")
      private_snippet = insert(:snippet, user: other_user, visibility: "private")
      
      snippets = Snippets.list_snippets(scope)
      snippet_ids = Enum.map(snippets, & &1.id)
      
      assert my_snippet.id in snippet_ids
      assert public_snippet.id in snippet_ids
      refute private_snippet.id in snippet_ids
    end
  end
  
  describe "when changing a snippet" do
    test "given snippet then changeset is returned" do
      changeset = Snippets.change_snippet(%Snippets.Snippet{})
      assert %Ecto.Changeset{} = changeset
    end
  end
end
```

#### 4.2 Run Tests (Should Fail)

```bash
mix test test/review_room/snippets_test.exs
```

#### 4.3 Implement Context

**File**: `lib/review_room/snippets.ex`

```elixir
defmodule ReviewRoom.Snippets do
  @moduledoc """
  Context for managing code snippets.
  """
  
  use ReviewRoom, :context
  
  alias ReviewRoom.Snippets.Snippet
  
  @spec create_snippet(Scope.t(), Attrs.t()) :: {:ok, Snippet.t()} | {:error, Ecto.Changeset.t(Snippet.t())}
  def create_snippet(%Scope{user: user}, attrs) do
    %Snippet{}
    |> Snippet.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end
  
  @spec change_snippet(Snippet.t(), Attrs.t()) :: Ecto.Changeset.t(Snippet.t())
  def change_snippet(%Snippet{} = snippet, attrs \\ %{}) do
    Snippet.changeset(snippet, attrs)
  end
  
  @spec get_snippet(Scope.t(), Identifier.t()) :: Snippet.t() | nil
  def get_snippet(%Scope{user: user}, id) do
    Snippet
    |> where([s], s.id == ^id)
    |> where([s], s.user_id == ^user.id or s.visibility == "public")
    |> preload(:user)
    |> Repo.one()
  end
  
  @spec list_snippets(Scope.t()) :: [Snippet.t()]
  def list_snippets(%Scope{user: user}) do
    Snippet
    |> where([s], s.user_id == ^user.id or s.visibility == "public")
    |> order_by([s], desc: s.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end
  
  @spec list_my_snippets(Scope.t()) :: [Snippet.t()]
  def list_my_snippets(%Scope{user: user}) do
    Snippet
    |> where([s], s.user_id == ^user.id)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end
  
  @spec list_all_tags() :: [String.t()]
  def list_all_tags do
    query = from s in Snippet,
      select: fragment("unnest(?)", s.tags)
    
    Repo.all(query)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
```

#### 4.4 Run Tests Again (Should Pass)

```bash
mix test test/review_room/snippets_test.exs
```

---

### Phase 5: LiveView (WRITE TESTS FIRST)

#### 5.1 Create Syntax Highlighter Hook

**File**: `assets/js/hooks/syntax_highlighter.js`

```javascript
const SyntaxHighlighter = {
  mounted() {
    this.highlight();
  },
  
  updated() {
    this.highlight();
  },
  
  highlight() {
    const codeBlocks = this.el.querySelectorAll('pre code');
    codeBlocks.forEach((block) => {
      block.className = '';
      const language = block.dataset.language;
      if (language) {
        block.classList.add(`language-${language}`);
      }
      if (window.hljs) {
        window.hljs.highlightElement(block);
      }
    });
  }
};

export default SyntaxHighlighter;
```

#### 5.2 Write LiveView Tests First

**File**: `test/review_room_web/live/snippet_live_test.exs`

```elixir
defmodule ReviewRoomWeb.SnippetLiveTest do
  use ReviewRoomWeb.ConnCase
  
  import Phoenix.LiveViewTest
  
  describe "when creating a new snippet" do
    setup :register_and_log_in_user
    
    test "given user navigates to new snippet page then form is displayed", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/snippets/new")
      
      assert html =~ "Create Snippet"
      assert has_element?(lv, "#snippet-form")
    end
    
    test "given valid data then snippet is created successfully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")
      
      {:ok, conn} =
        lv
        |> form("#snippet-form", snippet: %{
            code: "puts 'hello'",
            language: "ruby",
            title: "Hello World",
            visibility: "private"
          })
        |> render_submit()
        |> follow_redirect(conn)
      
      assert html = html_response(conn, 200)
      assert html =~ "Snippet saved successfully"
      assert html =~ "Hello World"
    end
    
    test "given invalid data then validation errors are shown", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")
      
      result =
        lv
        |> form("#snippet-form", snippet: %{code: "", language: ""})
        |> render_submit()
      
      assert result =~ "can&#39;t be blank"
    end
    
    test "given user types in form then real-time validation occurs", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")
      
      result =
        lv
        |> form("#snippet-form", snippet: %{code: "", language: "ruby"})
        |> render_change()
      
      assert result =~ "can&#39;t be blank"
    end
  end
  
  describe "when viewing a snippet" do
    setup :register_and_log_in_user
    
    test "given valid snippet then displays with syntax highlighting", %{conn: conn, user: user} do
      snippet = insert(:snippet, user: user, code: "puts 'test'", language: "ruby")
      
      {:ok, _lv, html} = live(conn, ~p"/snippets/#{snippet}")
      
      assert html =~ "puts 'test'"
      assert html =~ "ruby"
    end
    
    test "given private snippet and owner then snippet is shown", %{conn: conn, user: user} do
      snippet = insert(:snippet, user: user, visibility: "private")
      
      {:ok, _lv, html} = live(conn, ~p"/snippets/#{snippet}")
      
      assert html =~ snippet.code
    end
    
    test "given private snippet and non-owner then access is denied", %{conn: conn} do
      other_user = insert(:user)
      snippet = insert(:snippet, user: other_user, visibility: "private")
      
      {:ok, conn} =
        conn
        |> live(~p"/snippets/#{snippet}")
        |> follow_redirect(conn)
      
      assert html = html_response(conn, 200)
      assert html =~ "You don&#39;t have permission"
    end
    
    test "given public snippet then any authenticated user can view", %{conn: conn} do
      other_user = insert(:user)
      snippet = insert(:snippet, user: other_user, visibility: "public")
      
      {:ok, _lv, html} = live(conn, ~p"/snippets/#{snippet}")
      
      assert html =~ snippet.code
    end
  end
end
```

#### 5.3 Run Tests (Should Fail)

```bash
mix test test/review_room_web/live/snippet_live_test.exs
```

#### 5.4 Implement LiveViews

**File**: `lib/review_room_web/live/snippet_live/new.ex`

```elixir
defmodule ReviewRoomWeb.SnippetLive.New do
  use ReviewRoomWeb, :live_view
  
  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet
  
  def mount(_params, _session, socket) do
    supported_languages = Application.get_env(:review_room, :snippet_languages, [])
      |> Enum.map(&{&1.name, &1.code})
    
    {:ok,
      socket
      |> assign(
          form: to_form(Snippets.change_snippet(%Snippet{})),
          snippet_params: %{},
          save_status: :unsaved,
          supported_languages: supported_languages
        )}
  end
  
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    changeset = Snippets.change_snippet(%Snippet{}, snippet_params)
    
    {:noreply,
      socket
      |> assign(
          form: to_form(changeset, action: :validate),
          snippet_params: snippet_params,
          save_status: :unsaved
        )}
  end
  
  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    socket = assign(socket, save_status: :saving)
    
    case Snippets.create_snippet(socket.assigns.current_scope, snippet_params) do
      {:ok, snippet} ->
        {:noreply,
          socket
          |> assign(save_status: :saved)
          |> put_flash(:info, "Snippet saved successfully")
          |> push_navigate(to: ~p"/snippets/#{snippet}")}
      
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(
              form: to_form(changeset, action: :validate),
              save_status: :unsaved
            )
          |> put_flash(:error, "Unable to save snippet. Please check errors below.")}
    end
  end
end
```

**File**: `lib/review_room_web/live/snippet_live/new.html.heex`

```heex
<div class="max-w-4xl mx-auto">
  <h1 class="text-2xl font-bold mb-4">Create Snippet</h1>
  
  <.form 
    for={@form} 
    id="snippet-form" 
    phx-change="validate" 
    phx-submit="save"
  >
    <.input 
      field={@form[:code]} 
      type="textarea" 
      label="Code" 
      placeholder="Paste your code here..."
      rows="20"
      required 
    />
    
    <.input 
      field={@form[:language]} 
      type="select" 
      label="Language" 
      options={@supported_languages}
      prompt="Select a language..."
      required 
    />
    
    <.input 
      field={@form[:title]} 
      type="text" 
      label="Title" 
      placeholder="Optional title for your snippet"
    />
    
    <.input 
      field={@form[:description]} 
      type="textarea" 
      label="Description" 
      placeholder="Optional description"
      rows="3"
    />
    
    <.input 
      field={@form[:visibility]} 
      type="select" 
      label="Visibility" 
      options={[{"Private (only you)", "private"}, {"Public (anyone can view)", "public"}]}
    />
    
    <%= if @save_status == :unsaved do %>
      <div class="text-yellow-600">Unsaved changes</div>
    <% end %>
    
    <%= if @save_status == :saving do %>
      <div class="text-blue-600">Saving...</div>
    <% end %>
    
    <div class="flex gap-2">
      <.button type="submit" disabled={@save_status == :saving}>
        <%= if @save_status == :saving, do: "Saving...", else: "Save Snippet" %>
      </.button>
      
      <.link navigate={~p"/snippets"} class="btn btn-secondary">
        Cancel
      </.link>
    </div>
  </.form>
</div>
```

**File**: `lib/review_room_web/live/snippet_live/show.ex`

```elixir
defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view
  
  alias ReviewRoom.Snippets
  
  def mount(%{"id" => id}, _session, socket) do
    case Snippets.get_snippet(socket.assigns.current_scope, id) do
      nil ->
        {:ok,
          socket
          |> put_flash(:error, "Snippet not found or you don't have permission to view it")
          |> push_navigate(to: ~p"/snippets")}
      
      snippet ->
        {:ok, assign(socket, snippet: snippet)}
    end
  end
end
```

**File**: `lib/review_room_web/live/snippet_live/show.html.heex`

```heex
<div class="max-w-4xl mx-auto">
  <div class="mb-4">
    <h1 class="text-2xl font-bold"><%= @snippet.title || "Untitled Snippet" %></h1>
    <div class="text-sm text-gray-600">
      By <%= @snippet.user.email %> • <%= @snippet.inserted_at %>
    </div>
  </div>
  
  <%= if @snippet.description do %>
    <p class="mb-4"><%= @snippet.description %></p>
  <% end %>
  
  <div id="snippet-display" phx-hook="SyntaxHighlighter" phx-update="ignore">
    <pre><code data-language={@snippet.language}><%= @snippet.code %></code></pre>
  </div>
  
  <%= if @snippet.tags != [] do %>
    <div class="mt-4">
      <span class="font-semibold">Tags:</span>
      <%= for tag <- @snippet.tags do %>
        <span class="inline-block bg-gray-200 rounded px-2 py-1 text-sm mr-2">
          <%= tag.name %>
        </span>
      <% end %>
    </div>
  <% end %>
  
  <div class="mt-4">
    <.link navigate={~p"/snippets"} class="text-blue-600 hover:underline">
      ← Back to Snippets
    </.link>
  </div>
</div>
```

#### 5.5 Add Routes

**File**: `lib/review_room_web/router.ex`

```elixir
scope "/", ReviewRoomWeb do
  pipe_through [:browser, :require_authenticated_user]
  
  live_session :require_authenticated_user,
    on_mount: [{ReviewRoomWeb.UserAuth, :require_authenticated}] do
    # ... existing routes
    
    # Snippet routes
    live "/snippets/new", SnippetLive.New, :new
    live "/snippets/:id", SnippetLive.Show, :show
  end
end
```

#### 5.6 Run Tests (Should Pass)

```bash
mix test test/review_room_web/live/snippet_live_test.exs
```

---

### Phase 6: Demo Data

**File**: `priv/repo/seeds.exs`

Add to existing seed file:

```elixir
# Snippet demo data
alias ReviewRoom.Repo
alias ReviewRoom.Snippets.{Snippet, Tag}

# Assuming users exist from phx.gen.auth seeds
user1 = Repo.get_by!(User, email: "test@example.com")

# Create tags
elixir_tag = Repo.insert!(%Tag{name: "elixir"}, on_conflict: :nothing)
web_tag = Repo.insert!(%Tag{name: "web"}, on_conflict: :nothing)

# Create demo snippets
Repo.insert!(%Snippet{
  user_id: user1.id,
  code: """
  defmodule HelloWorld do
    def greet(name) do
      "Hello, \#{name}!"
    end
  end
  """,
  language: "elixir",
  title: "Simple Elixir Greeting",
  description: "A basic function to demonstrate Elixir string interpolation",
  visibility: "public"
})
|> Repo.preload(:tags)
|> Ecto.Changeset.change()
|> Ecto.Changeset.put_assoc(:tags, [elixir_tag])
|> Repo.update!()
```

**Run Seeds**:
```bash
mix ecto.reset  # Drops, creates, migrates, and seeds
# OR
mix run priv/repo/seeds.exs  # Just runs seeds
```

---

### Phase 7: Manual Testing

#### 7.1 Start Server

```bash
mix phx.server
```

#### 7.2 Test Workflow

1. Navigate to `http://localhost:4000`
2. Sign up or log in
3. Navigate to `/snippets/new`
4. Create a snippet:
   - Paste code
   - Select language
   - Add title/description
   - Add tags
   - Select visibility
   - Click "Save"
5. Verify redirect to snippet show page
6. Verify syntax highlighting applies
7. Test viewing another user's public snippet
8. Test that private snippets are not accessible

#### 7.3 Test with `web` CLI

```bash
# From project root
web http://localhost:4000/snippets/new

# Should show login page if not authenticated
# After login, should show snippet creation form
```

---

### Phase 8: Precommit Checks

Run all checks:

```bash
mix precommit
```

This runs:
- Code formatting (`mix format`)
- Credo linting (`mix credo`)
- All tests (`mix test`)
- Dialyzer type checking (`mix dialyzer`)

Fix any issues that arise.

---

## Troubleshooting

### Common Issues

1. **Migration fails**: Check that users table exists (phx.gen.auth)
2. **Tests fail with Repo errors**: Run `MIX_ENV=test mix ecto.migrate`
3. **Highlight.js not working**: Check browser console for JS errors
4. **XSS sanitization not working**: Ensure HtmlSanitizeEx is installed
5. **Authorization failing**: Verify `current_scope` is available in LiveView

### Debug Tools

```elixir
# In IEx
iex> user = ReviewRoom.Repo.get!(ReviewRoom.Accounts.User, 1)
iex> scope = %ReviewRoom.Accounts.Scope{user: user}
iex> ReviewRoom.Snippets.create_snippet(scope, %{code: "test", language: "ruby"})

# Check configuration
iex> Application.get_env(:review_room, :snippet_languages)
```

---

## Next Steps

After completing this quickstart:

1. Run `/speckit.tasks` to generate detailed task breakdown
2. Review generated tasks and adjust priorities
3. Begin implementation following task order
4. Use `web` CLI for manual testing throughout
5. Run `mix precommit` before each commit

## Summary

**Implementation Order**:
1. ✅ Configuration & dependencies
2. ✅ Migrations (DB schema)
3. ✅ Tests → Schemas → Tests pass
4. ✅ Tests → Context → Tests pass
5. ✅ Tests → LiveView → Tests pass
6. ✅ Demo data
7. ✅ Manual testing
8. ✅ Precommit checks

**Key Principle**: Write failing tests first, then implement to make them pass. Never write production code without a failing test.
