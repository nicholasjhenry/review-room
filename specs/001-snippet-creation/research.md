# Research: Snippet Creation

**Feature**: 001-snippet-creation  
**Date**: 2025-11-13  
**Status**: Complete

## Overview

This document resolves technical uncertainties identified during planning and establishes implementation patterns for the snippet creation feature.

## Research Tasks

### 1. Syntax Highlighting Library Selection

**Decision**: Autumn (Elixir library with Tree-sitter)

**Rationale**:
- **Server-Side Rendering**: Processes syntax highlighting on the server, eliminating JavaScript dependencies and client-side runtime overhead
- **Perfect LiveView Fit**: No client-side hooks needed - highlighted HTML is sent directly from the server, fully compatible with LiveView's server-rendered approach
- **Tree-sitter Accuracy**: Uses Tree-sitter parsers for precise, AST-based syntax highlighting (more accurate than regex-based highlighters)
- **Extensive Language Support**: 70+ languages with Tree-sitter parsing including Elixir, JavaScript, Python, Ruby, Go, Rust, SQL, HTML, CSS, JSON, YAML, Markdown
- **120+ Neovim Themes**: Rich theme library with customization options, can match application branding
- **Zero Client Payload**: No JavaScript or CSS sent to client for highlighting logic, only static CSS for themes
- **Handles Incomplete Code**: Gracefully processes malformed or partial code snippets
- **Elixir-Native**: Written in Elixir, integrates naturally with Phoenix/Ecto ecosystem
- **Performance**: Highlighting happens once during render, not on every client page load

**Alternatives Considered**:
- **Highlight.js** (client-side): Requires JavaScript execution in browser, phx-hooks, and CDN dependency. Less accurate regex-based parsing. More overhead for LiveView since highlighting happens client-side on every mount/update.
- **Prism.js** (client-side): Similar to Highlight.js but requires manual language registration. More complex setup with LiveView.
- **Monaco Editor** (client-side): Full-featured code editor (VS Code engine) but massive overkill for read-only display. Bundle size ~2MB.
- **CodeMirror 6** (client-side): Excellent editor but complex for simple syntax highlighting. Better suited for editing use cases.
- **Shiki** (server-side): Beautiful highlighting using VS Code themes, but Node.js-based requiring external runtime. Not Elixir-native.

**Implementation Pattern**:

**1. Add Autumn Dependency**:
```elixir
# mix.exs
defp deps do
  [
    {:autumn, "~> 0.1.0"}
    # ... other deps
  ]
end
```

**2. Configure Theme**:
```elixir
# config/config.exs
config :autumn,
  theme: "catppuccin_mocha",  # or any of 120+ themes
  formatter: :html_linked

# Generate CSS file during application setup
# Run: mix autumn.gen.theme catppuccin_mocha
# This creates: priv/static/themes/catppuccin_mocha.css
```

**3. Add Theme CSS to Layout**:
```heex
<!-- lib/review_room_web/components/layouts/root.html.heex -->
<head>
  <!-- ... existing head content ... -->
  <link rel="stylesheet" href={~p"/themes/catppuccin_mocha.css"}>
</head>
```

**4. Configure Static Assets**:
```elixir
# config/config.exs
config :review_room, ReviewRoomWeb.Endpoint,
  # Add themes directory to static paths
  static_paths: ~w(assets fonts images favicon.ico robots.txt themes)
```

**5. Highlight Code in Templates**:
```elixir
# In LiveView or Controller
highlighted_html = Autumn.highlight!(snippet.code, lang: snippet.language)

# In template
<div class="snippet-code">
  <%= Phoenix.HTML.raw(highlighted_html) %>
</div>
```

**6. Helper Function** (optional):
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

# Usage in templates:
# <.code_snippet code={@snippet.code} language={@snippet.language} />
```

**Language List Configuration**:
Autumn supports 70+ languages automatically. Store display names in config:
```elixir
# config/config.exs
config :review_room, :supported_languages, [
  {"elixir", "Elixir"},
  {"javascript", "JavaScript"},
  {"python", "Python"},
  {"ruby", "Ruby"},
  {"go", "Go"},
  {"rust", "Rust"},
  {"sql", "SQL"},
  {"html", "HTML"},
  {"css", "CSS"},
  {"json", "JSON"},
  {"yaml", "YAML"},
  {"markdown", "Markdown"},
  {"bash", "Bash"},
  {"typescript", "TypeScript"},
  {"java", "Java"},
  {"c", "C"},
  {"cpp", "C++"},
  {"csharp", "C#"},
  {"php", "PHP"},
  {"swift", "Swift"}
  # See Autumn docs for full list of supported languages
]
```

### 2. Tag Input UI Pattern

**Decision**: Simple comma-separated input stored as PostgreSQL array

**Rationale**:
- **MVP Simplicity**: Meets P3 priority requirements without complex JavaScript or join tables
- **Database Efficiency**: PostgreSQL array column with GIN index enables fast tag queries
- **No Normalization Overhead**: No separate tags table or many-to-many join table needed
- **Phoenix LiveView Friendly**: Works naturally with form inputs and changesets
- **User Familiarity**: Comma-separated tags are widely understood pattern
- **Accessibility**: Standard text input works with all assistive technologies
- **Mobile Friendly**: Easier to use on mobile than complex chip interfaces
- **Simplified Schema**: Single table design reduces complexity

**Alternatives Considered**:
- **Many-to-Many with Tags Table**: More normalized but adds complexity with join tables, separate tag management. Overkill for user-specific tags.
- **Tag Chips with Autocomplete**: Better UX but requires significant JavaScript, custom components, and more complex state management. Overkill for P3 feature.
- **Select Multiple**: Limited to pre-defined tags, doesn't allow user-created tags.
- **Separate Tag Manager**: Requires additional UI for creating/managing tags before use.

**Implementation Pattern**:

**Database Schema**:
```elixir
# In migration
add :tags, {:array, :string}, default: []
create index(:snippets, [:tags], using: :gin)  # For fast array queries
```

**Form Input** (in LiveView form):
```heex
<.input 
  field={@form[:tags]} 
  type="text" 
  label="Tags" 
  placeholder="e.g. authentication, database, api"
  help="Separate tags with commas"
/>
```

**Changeset Processing**:
```elixir
# In Snippets.Snippet schema
schema "snippets" do
  field :tags, {:array, :string}, default: []
  # ... other fields
end

def changeset(snippet, attrs) do
  snippet
  |> cast(attrs, [:title, :description, :code, :language, :visibility, :tags])
  |> validate_required([:title, :code])
  |> normalize_tags()
end

defp normalize_tags(changeset) do
  case get_change(changeset, :tags) do
    nil -> 
      changeset
    tags when is_list(tags) ->
      normalized =
        tags
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.downcase/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.uniq()
      put_change(changeset, :tags, normalized)
    tags_string when is_binary(tags_string) ->
      # Support comma-separated string input from forms
      normalized =
        tags_string
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.downcase/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.uniq()
      put_change(changeset, :tags, normalized)
  end
end
```

**Display Pattern**:
```heex
<div class="tags">
  <%= for tag <- @snippet.tags do %>
    <.link 
      patch={~p"/snippets?tag=#{tag}"} 
      class="inline-block px-2 py-1 text-sm bg-gray-200 rounded"
    >
      {tag}
    </.link>
  <% end %>
</div>
```

**Tag Filtering Query**:
```elixir
# Find snippets with specific tag (uses GIN index)
Snippet
|> where([s], fragment("? = ANY(?)", ^tag_name, s.tags))
|> Repo.all()

# Get all unique tags for a user
Snippet
|> where([s], s.user_id == ^user_id)
|> select([s], s.tags)
|> Repo.all()
|> List.flatten()
|> Enum.uniq()
|> Enum.sort()
```

**Progressive Enhancement Path**:
Future enhancement could add autocomplete using a phx-hook that fetches existing tags from the user's snippets and provides suggestions, without changing the data model.

### 3. Phoenix LiveView Best Practices for This Feature

**Pattern**: Separate LiveViews for each action (index, show, form) with shared components

**Key Decisions**:

**Routing Strategy**:
```elixir
# In router.ex
scope "/", ReviewRoomWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{ReviewRoomWeb.UserAuth, :require_authenticated}] do
    # Authenticated snippet management
    live "/snippets", SnippetLive.Index, :index
    live "/snippets/new", SnippetLive.Form, :new
    live "/snippets/:id/edit", SnippetLive.Form, :edit
  end
end

scope "/", ReviewRoomWeb do
  pipe_through [:browser]
  
  live_session :current_user,
    on_mount: [{ReviewRoomWeb.UserAuth, :mount_current_scope}] do
    # Public/unlisted snippet viewing (checks visibility in mount)
    live "/snippets/:id", SnippetLive.Show, :show
  end
end
```

**Authorization Pattern**:
```elixir
# In Snippets context
def get_snippet!(id, %Scope{} = scope) do
  Snippet
  |> Repo.get!(id)
  |> check_visibility(scope)
end

defp check_visibility(snippet, %Scope{user: user}) do
  cond do
    snippet.visibility == :public -> snippet
    snippet.visibility == :unlisted -> snippet
    user && snippet.user_id == user.id -> snippet
    true -> raise Ecto.NoResultsError
  end
end
```

**Stream Usage for Snippet Lists**:
```elixir
# In SnippetLive.Index
def mount(_params, _session, socket) do
  snippets = Snippets.list_snippets(socket.assigns.current_scope)
  
  {:ok,
   socket
   |> assign(:snippets_empty?, snippets == [])
   |> stream(:snippets, snippets)}
end

def handle_event("delete", %{"id" => id}, socket) do
  snippet = Snippets.get_snippet!(id, socket.assigns.current_scope)
  {:ok, _} = Snippets.delete_snippet(snippet)
  
  {:noreply, stream_delete(socket, :snippets, snippet)}
end
```

**Form Component Pattern**:
```elixir
# Use LiveView (not LiveComponent) for form
# LiveComponent adds unnecessary complexity for this use case
# See Phoenix LiveView best practices - prefer LiveViews over LiveComponents

defmodule ReviewRoomWeb.SnippetLive.Form do
  use ReviewRoomWeb, :live_view
  
  def mount(params, _session, socket) do
    # Handle both :new and :edit
  end
  
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    # Real-time validation
  end
  
  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    # Save and redirect
  end
end
```

### 4. XSS Prevention Strategy

**Decision**: Use Phoenix.HTML.html_escape/1 and HEEx's automatic escaping

**Rationale**:
- **Built-in Protection**: HEEx automatically escapes all interpolated values by default
- **Standard Practice**: Phoenix best practice for user content
- **Code Content**: Wrap code in `<pre><code>` tags which are escaped by default
- **No Raw HTML**: Never use `raw/1` or `{:safe, ...}` on user input

**Implementation Pattern**:

**Schema Validation**:
```elixir
def changeset(snippet, attrs) do
  snippet
  |> cast(attrs, [:title, :description, :code, :language, :visibility])
  |> validate_required([:title, :code])
  |> validate_length(:title, min: 1, max: 200)
  |> validate_length(:description, max: 2000)
  |> validate_length(:code, min: 1, max: 512_000) # 500KB in bytes
  # No need for special XSS sanitization - HEEx handles escaping
end
```

**Template Pattern**:
```heex
<%!-- All user content automatically escaped by HEEx --%>
<h1>{@snippet.title}</h1>
<p>{@snippet.description}</p>

<%!-- Code content wrapped in pre/code tags --%>
<div phx-hook="SyntaxHighlighter" phx-update="ignore">
  <pre><code class={"language-#{@snippet.language}"}>
{@snippet.code}
  </code></pre>
</div>
```

**Security Tests**:
```elixir
test "escapes HTML in title" do
  snippet = snippet_fixture(title: "<script>alert('xss')</script>")
  {:ok, view, html} = live(conn, ~p"/snippets/#{snippet}")
  
  refute html =~ "<script>"
  assert html =~ "&lt;script&gt;"
end

test "escapes HTML in code content" do
  snippet = snippet_fixture(code: "<img src=x onerror=alert('xss')>")
  {:ok, view, html} = live(conn, ~p"/snippets/#{snippet}")
  
  refute html =~ "<img src=x"
  assert html =~ "&lt;img src=x"
end
```

### 5. Database Schema Design

**Decision**: Single table with PostgreSQL array column for tags

**Schema Design**:

```elixir
# Snippets table (only table needed)
create table(:snippets) do
  add :title, :string, null: false, size: 200
  add :description, :text
  add :code, :text, null: false
  add :language, :string
  add :visibility, :string, null: false, default: "private"
  add :tags, {:array, :string}, default: []
  add :user_id, references(:users, on_delete: :delete_all), null: false
  
  timestamps()
end

create index(:snippets, [:user_id])
create index(:snippets, [:visibility])
create index(:snippets, [:inserted_at])
create index(:snippets, [:tags], using: :gin)  # For array containment queries
```

**Rationale**:
- **Simplified Schema**: Single table instead of three tables (snippets, tags, snippet_tags)
- **No Join Overhead**: Array column eliminates need for join queries
- **GIN Index Performance**: PostgreSQL GIN index enables fast array containment searches
- **User-Specific Tags**: Each user manages their own tags without global tag namespace conflicts
- **Cascading Deletes**: When snippet deleted, tags are automatically deleted (part of row)
- **Atomic Updates**: Tag changes are atomic within the snippet record
- **Simpler Migrations**: Only one migration file needed instead of three
- **Less Code**: No Tag schema or join table schema required

## Summary of Decisions

| Area | Decision | Priority |
|------|----------|----------|
| Syntax Highlighting | Autumn (server-side, Tree-sitter) | P2 |
| Tag Input | Comma-separated string → array | P3 |
| Tag Storage | PostgreSQL array column | P3 |
| LiveView Structure | Separate LiveViews per action | P1 |
| Authorization | Scope-based with visibility check | P2 |
| XSS Prevention | HEEx automatic escaping | P1 |
| Database Design | Single table with arrays | P1 |
| Snippet Lists | LiveView streams | P1 |

## Key Benefits of Autumn Choice

- **Zero JavaScript**: Eliminates client-side dependencies and phx-hooks complexity
- **Server-Side Only**: Highlighting happens once during render, cached by LiveView
- **Elixir-Native**: No CDN dependencies, works offline, integrates with Phoenix patterns
- **More Accurate**: Tree-sitter AST parsing vs regex patterns
- **120+ Themes**: Easy to customize appearance and match branding
- **LiveView Optimized**: Pre-rendered HTML sent from server, no client-side processing

## Next Phase

All technical uncertainties resolved. Ready to proceed to Phase 1: Data Model and Contracts.
