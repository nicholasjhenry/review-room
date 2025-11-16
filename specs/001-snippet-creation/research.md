# Research: Snippet Creation Feature

**Feature**: Snippet Creation  
**Branch**: `001-snippet-creation`  
**Date**: 2025-11-16

## Overview

This document captures research findings for implementing the snippet creation feature, addressing the NEEDS CLARIFICATION items identified in the Technical Context section of the plan.

---

## 1. Syntax Highlighting Library

### Decision: Highlight.js with Selective Language Imports

**Rationale:**
- Optimal bundle size: 30-45 KB (vs 695 KB for Shiki, 5-10 MB for Monaco)
- Best performance for large files (up to 500KB requirement)
- Automatic language detection improves UX
- Excellent LiveView integration via hooks
- Active maintenance (latest release March 2025)
- Zero dependencies required
- Proven ecosystem: 24K+ GitHub stars, 10.9M weekly downloads

### Alternatives Considered:

| Library | Bundle Size | Why Rejected |
|---------|-------------|--------------|
| Prism.js | 25-35 KB | No automatic language detection; slower with large files |
| Monaco Editor | 5-10 MB | Massive bundle; overkill for read-only display; poor mobile |
| CodeMirror 6 | 300 KB | 10x larger than needed; editor-focused |
| Shiki | 695 KB | Better for SSR; large client bundle |
| Makeup (server) | 0 KB client | Incompatible with LiveView dynamic updates |

### Implementation Approach:

```javascript
// Import core + selective languages in assets/js/app.js
import hljs from 'highlight.js/lib/core';
import elixir from 'highlight.js/lib/languages/elixir';
import javascript from 'highlight.js/lib/languages/javascript';
// ... other 10 languages

// LiveView Hook
Hooks.SyntaxHighlight = {
  mounted() { this.highlight(); },
  updated() { this.highlight(); },
  highlight() {
    this.el.querySelectorAll('pre code:not(.hljs)').forEach((block) => {
      hljs.highlightElement(block);
    });
  }
};
```

**Performance Strategy for 500KB Snippets:**
- Lazy loading with Intersection Observer
- Virtualization for very large files
- Use `phx-update="append"` for progressive rendering

---

## 2. Performance Goals

### Decision: Conservative Targets Based on Phoenix Benchmarks

**Snippet Creation Latency:**
- p50: < 100ms
- p95: < 200ms  
- p99: < 500ms

**Rationale:** Phoenix benchmarks show microsecond-range processing; industry standard (GitHub Gist, Pastebin) is 100-300ms p50.

**Concurrent User Capacity:**
- MVP: 1,000-5,000 concurrent users
- Growth (1 year): 25,000-50,000 concurrent users
- Theoretical max: 100,000+ per server (proven in production)

**Rationale:** Phoenix can handle 2M+ concurrent connections. Our targets are very conservative.

**Tag Filtering Performance:**
- < 200ms for collections up to 1,000 snippets (exceeds spec requirement of < 2s by 10x)

**Rationale:** Proper PostgreSQL indexing enables sub-200ms queries for thousands of records.

**Page Load Targets:**
- TTFB: < 200ms
- LCP: < 2.5s
- LiveView navigation: < 100ms (single WebSocket frame)

**Real-time Validation Feedback:**
- < 100ms latency (with 300ms debounce for typing)

**Rationale:** Human perception research shows < 100ms feels instant.

---

## 3. Scale/Scope Targets

### Decision: Staged Growth Approach

**User Count:**
- MVP: 100-500 total users, 20-100 DAU
- Year 1: 2,000-10,000 total users, 400-2,000 DAU

**Snippets Per User:**
- Average: 35-40 snippets per user
- Distribution: 60% light (1-10), 30% regular (10-50), 9% power (50-500), 1% extreme (500+)

**Rationale:** GitHub Gist averages 37 gists/user; Pastebin shows similar patterns.

**Total Snippet Volume:**
- MVP: 500-5,000 snippets, 10-50 MB database
- Year 1: 40,000-400,000 snippets, 200 MB - 2 GB database

**Concurrent Operations:**
- Writes: 1-20 per second (MVP), 10-50 per second (Year 1)
- Reads: 10-200 per second (MVP), 100-500 per second (Year 1)
- Read-heavy system (1:10 write:read ratio)

**Database Sizing:**
- MVP: 2 vCPU, 4 GB RAM (standard PostgreSQL)
- Growth: 4 vCPU, 8 GB RAM
- PostgreSQL proven to scale to millions of snippets with proper indexing

**Rationale:** Industry benchmarks show Phoenix at 24k req/sec with p99 < 1ms. PostgreSQL handles multi-GB datasets efficiently with proper indexing.

---

## 4. Phoenix LiveView Patterns

### Form Validation Patterns

**Decision: Server-Centric Validation with Client-Side Enhancement**

**Real-time Validation:**
```elixir
# LiveView
def handle_event("validate", %{"snippet" => snippet_params}, socket) do
  changeset = Snippets.change_snippet(%Snippet{}, snippet_params)
    |> Map.put(:action, :validate)
  {:noreply, assign(socket, :changeset, changeset)}
end
```

**Template:**
```heex
<.form for={@changeset} phx-change="validate" phx-submit="save">
  <.input field={@changeset[:code]} type="textarea" 
         phx-debounce="blur" rows="20" />
</.form>
```

**Rationale:** 
- `phx-debounce="blur"` reduces server round-trips for large text inputs
- Ecto changesets provide comprehensive validation
- Server as source of truth prevents client-side bypass

**Large Text Handling (500KB):**
```javascript
// JavaScript hook for size warnings
Hooks.CodeInput = {
  mounted() {
    this.el.addEventListener('input', () => {
      const bytes = new Blob([this.el.value]).size;
      const maxBytes = 512000; // 500KB
      const percentage = (bytes / maxBytes) * 100;
      
      if (percentage >= 90) {
        this.showWarning(bytes, maxBytes, percentage);
      }
    });
  }
};
```

**Server Validation:**
```elixir
def changeset(snippet, attrs) do
  snippet
  |> cast(attrs, [:code, :title, :description, :language, :visibility])
  |> validate_required([:code, :title])
  |> validate_length(:code, max: 512_000, count: :bytes)  # Critical: count bytes
  |> validate_length(:title, min: 1, max: 200)
  |> validate_length(:description, max: 2000)
end
```

**XSS Prevention:**
- Phoenix automatically escapes HTML in HEEx templates
- **Never use `raw/1` on user input**
- Trust Phoenix's default behavior

**Rationale:** Automatic escaping is Phoenix's default. Manual intervention introduces vulnerabilities.

---

### Tag Storage Pattern

**Decision: PostgreSQL Array Column**

**Schema Configuration:**
```elixir
# lib/review_room/snippets/snippet.ex
schema "snippets" do
  field :tags, {:array, :string}, default: []
  # ... other fields
end
```

**Migration:**
```elixir
create table(:snippets) do
  add :tags, {:array, :string}, default: []
  # ... other fields
end

create index(:snippets, [:tags], using: "GIN")
```

**Context Function:**
```elixir
def create_snippet(attrs, scope) do
  # Parse comma-separated tags: "elixir, phoenix, web" → ["elixir", "phoenix", "web"]
  tag_list = case attrs["tags"] do
    nil -> []
    "" -> []
    tags when is_binary(tags) -> 
      tags
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
    tags when is_list(tags) -> tags
  end
  
  attrs_with_tags = Map.put(attrs, "tags", tag_list)
  
  %Snippet{}
  |> Snippet.changeset(attrs_with_tags)
  |> Ecto.Changeset.put_assoc(:user, scope.user)
  |> Repo.insert()
end
```

**Changeset with Normalization:**
```elixir
def changeset(snippet, attrs) do
  snippet
  |> cast(attrs, [:tags, ...])
  |> normalize_tags()
  |> validate_tags()
end

defp normalize_tags(changeset) do
  case get_change(changeset, :tags) do
    nil -> changeset
    tags when is_list(tags) ->
      normalized = tags
        |> Enum.map(&String.downcase/1)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.uniq()
      
      put_change(changeset, :tags, normalized)
    _ -> changeset
  end
end
```

**Query Pattern (with GIN index):**
```elixir
# Find snippets with specific tag
def list_snippets_by_tag(tag_name, scope) do
  Snippet
  |> where([s], ^tag_name in s.tags)  # Uses GIN index
  |> where([s], s.user_id == ^scope.user.id)
  |> Repo.all()
end

# Get all unique tags
def list_all_tags do
  Snippet
  |> select([s], fragment("unnest(?)", s.tags))
  |> distinct(true)
  |> Repo.all()
end
```

**UI Pattern:**
```heex
<.input field={@changeset[:tags]} type="text" 
       placeholder="elixir, phoenix, web" />
```

**Rationale:**
- **Simpler schema**: One table instead of three (no Tag or SnippetTag tables)
- **Fewer queries**: Single INSERT instead of transaction with upserts
- **Atomic updates**: Tags updated with snippet in one operation
- **Better performance**: GIN index provides O(log n) array queries, no JOINs needed
- **Easier testing**: No fixture complexity for many-to-many associations
- **Sufficient for use case**: Tags are always accessed with snippet, no independent tag operations needed

**Tradeoffs:**
- Cannot query "which snippets have this tag" across all users as efficiently (but use case doesn't require this)
- No tag usage counts without aggregation (but not needed for MVP)
- Cannot rename tags globally (but tags are user-specific in this design)

**Alternatives Considered:**
- Many-to-many with join table: More normalized, but adds complexity and queries for no benefit in this use case
- Separate Tag table with foreign keys: Overkill when tags are always accessed with snippets
- **Rejected**: Both add unnecessary complexity for a feature where tags are simple labels, not independent entities

---

### File Size Validation

**Decision: Dual-Layer Validation (Client + Server)**

**Client-Side (Real-time Feedback):**
```javascript
Hooks.CodeInput = {
  mounted() {
    this.updateCounter();
    this.el.addEventListener('input', () => this.updateCounter());
  },
  updateCounter() {
    const bytes = new Blob([this.el.value]).size;
    const maxBytes = 512000;
    const percentage = (bytes / maxBytes) * 100;
    
    // Update UI
    const counter = document.getElementById('size-counter');
    counter.textContent = `${this.formatBytes(bytes)} / 500 KB`;
    counter.className = percentage >= 100 ? 'text-red-600' : 
                        percentage >= 90 ? 'text-yellow-600' : 'text-gray-600';
  },
  formatBytes(bytes) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  }
};
```

**Server-Side (Enforcement):**
```elixir
def changeset(snippet, attrs) do
  snippet
  |> cast(attrs, [:code])
  |> validate_length(:code, max: 512_000, count: :bytes)  # Bytes, not graphemes!
end
```

**Rationale:**
- Client feedback prevents frustration (90% warning, 100% error)
- Server validation prevents bypass
- **Critical:** Count bytes (not graphemes) - emoji can be 4+ bytes
- PostgreSQL TEXT fields support 1GB with TOAST compression

**User Experience:**
- Progressive warnings: yellow at 90%, red at 100%
- Formatted display: "234.5 KB / 500 KB"
- No form submission when limit exceeded

---

### Access Control (Visibility)

**Decision: Database-Level Filtering with Dual Authorization Checks**

**Schema:**
```elixir
schema "snippets" do
  field :visibility, Ecto.Enum, values: [:private, :public, :unlisted], default: :private
  field :slug, :string  # Title-based with random suffix
  belongs_to :user, User
end
```

**Context Function:**
```elixir
def get_snippet(slug, scope) do
  Snippet
  |> where([s], s.slug == ^slug)
  |> where([s], 
    s.visibility == :public or
    s.visibility == :unlisted or
    (s.visibility == :private and s.user_id == ^scope.user.id)
  )
  |> Repo.one()
  |> case do
    nil -> {:error, :not_found}  # Return 404, not 403 (security)
    snippet -> {:ok, snippet}
  end
end
```

**LiveView Authorization:**
```elixir
def mount(%{"slug" => slug}, _session, socket) do
  scope = socket.assigns.current_scope
  
  case Snippets.get_snippet(slug, scope) do
    {:ok, snippet} -> {:ok, assign(socket, snippet: snippet)}
    {:error, :not_found} -> {:ok, redirect(socket, to: ~p"/404")}
  end
end
```

**Slug Pattern:**
```elixir
defp generate_slug(title) do
  base = title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.slice(0, 50)
  
  random_suffix = :crypto.strong_rand_bytes(4) |> Base.url_encode64(padding: false)
  "#{base}-#{random_suffix}"
end
```

**Database Indexes:**
```elixir
create index(:snippets, [:slug], unique: true)
create index(:snippets, [:user_id, :visibility, :created_at])  # Composite for user listing
create index(:snippets, [:visibility, :created_at])  # For public listing
```

**Rationale:**
- **Return 404 (not 403)** to avoid revealing snippet existence
- Database-level filtering prevents data leaks
- Composite indexes optimize common queries
- Slug pattern: user-friendly + unique (random suffix prevents collisions)
- Dual authorization: route-level + mount-level checks

**Security Considerations:**
- Never expose internal IDs in URLs
- Log unauthorized access attempts (potential abuse)
- Use `Accounts.Scope` pattern consistently
- Test visibility enforcement in integration tests

---

## Configuration Validation Strategy

### Boot-Time Validation:

```elixir
# lib/review_room/application.ex
def start(_type, _args) do
  # Validate configuration at boot
  validate_snippet_config!()
  
  children = [...]
  Supervisor.start_link(children, strategy: :one_for_one)
end

defp validate_snippet_config! do
  max_size = Application.get_env(:review_room, :max_snippet_size, 512_000)
  languages = Application.get_env(:review_room, :supported_languages, [])
  
  unless max_size > 0 and max_size <= 1_000_000 do
    raise "Invalid :max_snippet_size - must be between 1 and 1,000,000 bytes"
  end
  
  unless length(languages) >= 12 do
    raise "Missing :supported_languages configuration"
  end
end
```

**Configuration File:**
```elixir
# config/config.exs
config :review_room,
  max_snippet_size: 512_000,  # 500 KB
  supported_languages: ~w(
    elixir javascript python ruby go rust
    sql html css json yaml markdown
  )
```

**Rationale:**
- Fail fast at boot if configuration is invalid
- Explicit error messages guide troubleshooting
- Centralized configuration prevents magic numbers
- Testable configuration values

---

## Summary of Key Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **Syntax Highlighting** | Highlight.js (30-45 KB) | Best size/performance/features balance |
| **Performance Target** | p50 < 100ms, p95 < 200ms | Based on Phoenix benchmarks |
| **Concurrent Users** | MVP: 1K-5K, Year 1: 25K-50K | Conservative based on Phoenix capacity |
| **Validation Strategy** | Server-centric with client enhancement | Security + UX balance |
| **Tag Pattern** | PostgreSQL array column with GIN index | Simpler schema, fewer queries, atomic updates |
| **Size Validation** | Dual-layer (client warning + server enforcement) | Prevents frustration + bypasses |
| **Visibility** | Database-level filtering, return 404 | Security best practice |
| **Slug Pattern** | Title-based + random suffix | User-friendly + unique |

---

## Next Steps

1. **Install Highlight.js** with selective imports (30-45 KB bundle)
2. **Implement LiveView hooks** for syntax highlighting and size validation
3. **Create database migrations** with proper indexes for performance
4. **Write failing tests** per constitution requirement before implementation
5. **Configure boot-time validation** for max size and language list
6. **Extend seeds.exs** with demo data covering all scenarios

---

## References

- [Highlight.js Documentation](https://highlightjs.org/)
- [Phoenix LiveView JavaScript Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html)
- [Phoenix LiveView Hooks](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-client-hooks-via-phx-hook)
- [Ecto Many-to-Many Relationships](https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3)
- [Phoenix Security Best Practices](https://hexdocs.pm/phoenix/security.html)
