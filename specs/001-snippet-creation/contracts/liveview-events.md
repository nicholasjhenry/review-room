# LiveView Event Contracts: Snippet Creation

**Feature**: 001-snippet-creation  
**Date**: 2025-10-31  
**Updated**: 2025-10-31 (Updated for Phoenix style guide compliance)

## Overview

This document defines the Phoenix LiveView event contracts for snippet creation and management. These events form the interface between the client UI and server-side business logic.

**Note**: All context module calls follow the Phoenix style guide:
- Context modules use `use ReviewRoom, :context`
- Record modules use `use ReviewRoom, :record`
- Type specs use `Attrs.t()` for attributes and `Identifier.t()` for IDs
- Tags are stored as PostgreSQL array field (no separate Tag schema)

## LiveView: SnippetLive.New

**Path**: `/snippets/new`  
**Module**: `ReviewRoomWeb.SnippetLive.New`  
**Purpose**: Create a new code snippet with in-memory editing and event-triggered persistence

### Mount Event

**Event**: `mount/3`  
**Trigger**: User navigates to snippet creation page  
**Authorization**: Requires authenticated user (`current_scope.user` must be present)

**Socket Assigns (Initial State)**:
```elixir
%{
  current_scope: %Scope{user: %User{}},  # From on_mount hook
  form: %Phoenix.HTML.Form{},             # Empty form via to_form()
  snippet_params: %{},                    # In-memory snippet data
  save_status: :unsaved,                  # :unsaved | :saving | :saved
  supported_languages: [...]              # From application config
}
```

**Success Response**:
```elixir
{:ok, socket, temporary_assigns: []}
```

**Error Response** (not authenticated):
```elixir
# Handled by router live_session :require_authenticated_user
# Redirects to login page
```

---

### Validate Event

**Event**: `handle_event("validate", params, socket)`  
**Trigger**: User types in form fields (`phx-change` on form)  
**Purpose**: Real-time validation without database writes

**Parameters**:
```elixir
%{
  "snippet" => %{
    "code" => string(),           # Required, max 1MB
    "language" => string(),       # Required, must be in supported list
    "title" => string() | nil,    # Optional, max 255 chars
    "description" => string() | nil,  # Optional
    "visibility" => "private" | "public",  # Defaults to "private"
    "tags" => [string()]          # Optional, max 10 tags
  }
}
```

**Processing**:
1. Extract snippet params from `params["snippet"]`
2. Call `Snippets.change_snippet(%Snippet{}, snippet_params)` to get validation changeset
3. Update socket assigns:
   - `form`: to_form(changeset, action: :validate)
   - `snippet_params`: Store params in memory
   - `save_status`: :unsaved

**Socket Assigns (Updated)**:
```elixir
%{
  form: %Phoenix.HTML.Form{},     # With validation errors if any
  snippet_params: %{...},         # In-memory state
  save_status: :unsaved
}
```

**Response**:
```elixir
{:noreply, socket}
```

**Template Impact**:
- Form displays validation errors via `<.error>` component
- Save button remains enabled
- "Unsaved changes" indicator shows

**Validation Rules Applied**:
- Code: required, max 1MB
- Language: required, must be in supported languages
- Title: max 255 chars, HTML stripped
- Description: HTML stripped
- Visibility: must be "private" or "public"
- Tags: max 10, creates/finds existing tags

---

### Save Event

**Event**: `handle_event("save", params, socket)`  
**Trigger**: User clicks "Save" button (`phx-submit` on form)  
**Purpose**: Persist snippet to database

**Parameters**:
```elixir
%{
  "snippet" => %{
    "code" => string(),
    "language" => string(),
    "title" => string() | nil,
    "description" => string() | nil,
    "visibility" => "private" | "public",
    "tags" => [string()]
  }
}
```

**Processing**:
1. Extract snippet params
2. Update save_status to :saving
3. Call `Snippets.create_snippet(current_scope, snippet_params)`
4. Handle result:
   - Success: Flash message, navigate to snippet show page
   - Error: Display validation errors

**Success Response**:
```elixir
{:noreply,
  socket
  |> assign(save_status: :saved)
  |> put_flash(:info, "Snippet saved successfully")
  |> push_navigate(to: ~p"/snippets/#{snippet}")}
```

**Error Response**:
```elixir
{:noreply,
  socket
  |> assign(
      form: to_form(changeset, action: :validate),
      save_status: :unsaved
    )
  |> put_flash(:error, "Unable to save snippet. Please check errors below.")}
```

**Database Operations**:
- INSERT into snippets table
- INSERT or SELECT existing tags
- INSERT into snippet_tags join table

**Error Cases**:
1. **Validation Failure**: 
   - Show errors in form
   - Keep user on page
   - Preserve in-memory data

2. **Database Error**:
   - Log error with trace ID
   - Show generic error message to user
   - Keep user on page
   - Preserve in-memory data

3. **Authorization Failure** (missing current_scope):
   - Redirect to login
   - Log security event

---

### Cancel Event (Optional)

**Event**: `handle_event("cancel", _params, socket)`  
**Trigger**: User clicks "Cancel" button or navigates away  
**Purpose**: Discard unsaved changes and return to previous page

**Processing**:
1. Clear socket assigns
2. Navigate back or to snippets list

**Response**:
```elixir
{:noreply, push_navigate(socket, to: ~p"/snippets")}
```

**Note**: Browser may show "unsaved changes" warning via `beforeunload` event (client-side)

---

## LiveView: SnippetLive.Show

**Path**: `/snippets/:id`  
**Module**: `ReviewRoomWeb.SnippetLive.Show`  
**Purpose**: Display a code snippet with syntax highlighting

### Mount Event

**Event**: `mount/3`  
**Trigger**: User navigates to snippet display page  
**Authorization**: Requires authenticated user; privacy rules apply

**Parameters**:
```elixir
%{"id" => snippet_id}  # From URL params
```

**Processing**:
1. Extract snippet_id from params
2. Call `Snippets.get_snippet(current_scope, snippet_id)`
3. Handle result:
   - Found and authorized: Display snippet
   - Not found or unauthorized: 404 or unauthorized page

**Socket Assigns**:
```elixir
%{
  current_scope: %Scope{user: %User{}},
  snippet: %Snippet{
    id: integer(),
    code: string(),
    language: string(),
    title: string() | nil,
    description: string() | nil,
    visibility: "private" | "public",
    user: %User{},
    tags: [%Tag{}],
    inserted_at: ~N[...],
    updated_at: ~N[...]
  }
}
```

**Success Response**:
```elixir
{:ok, socket, temporary_assigns: []}
```

**Not Found Response**:
```elixir
{:ok,
  socket
  |> put_flash(:error, "Snippet not found")
  |> push_navigate(to: ~p"/snippets")}
```

**Unauthorized Response**:
```elixir
{:ok,
  socket
  |> put_flash(:error, "You don't have permission to view this snippet")
  |> push_navigate(to: ~p"/snippets")}
```

**Template Rendering**:
- Display code in `<pre><code>` block with language class
- Client-side Highlight.js hook applies syntax highlighting
- Show title, description, tags, author, timestamps
- Show visibility indicator (private/public)
- Show "Edit" button if current user owns snippet (future feature)

---

## Client-Side Hooks

### SyntaxHighlighter Hook

**Purpose**: Apply Highlight.js syntax highlighting to code blocks

**Hook Name**: `SyntaxHighlighter`  
**Trigger**: On mount and on update

**JavaScript** (`assets/js/hooks/syntax_highlighter.js`):
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
      // Remove existing highlighting classes
      block.className = '';
      
      // Get language from data attribute
      const language = block.dataset.language;
      if (language) {
        block.classList.add(`language-${language}`);
      }
      
      // Apply Highlight.js
      if (window.hljs) {
        window.hljs.highlightElement(block);
      }
    });
  }
};

export default SyntaxHighlighter;
```

**Template Usage**:
```heex
<div id="snippet-display" phx-hook="SyntaxHighlighter" phx-update="ignore">
  <pre><code data-language={@snippet.language}>{@snippet.code}</code></pre>
</div>
```

**Note**: `phx-update="ignore"` prevents LiveView from re-rendering the highlighted code

---

## Form Structure

### Snippet Creation Form

**Template** (`new.html.heex`):
```heex
<.form 
  for={@form} 
  id="snippet-form" 
  phx-change="validate" 
  phx-submit="save"
>
  <%!-- Code Editor --%>
  <.input 
    field={@form[:code]} 
    type="textarea" 
    label="Code" 
    placeholder="Paste your code here..."
    rows="20"
    required 
  />
  
  <%!-- Language Selector --%>
  <.input 
    field={@form[:language]} 
    type="select" 
    label="Language" 
    options={@supported_languages}
    prompt="Select a language..."
    required 
  />
  
  <%!-- Title --%>
  <.input 
    field={@form[:title]} 
    type="text" 
    label="Title" 
    placeholder="Optional title for your snippet"
  />
  
  <%!-- Description --%>
  <.input 
    field={@form[:description]} 
    type="textarea" 
    label="Description" 
    placeholder="Optional description"
    rows="3"
  />
  
  <%!-- Tags --%>
  <.input 
    field={@form[:tags]} 
    type="text" 
    label="Tags" 
    placeholder="Comma-separated tags (max 10)"
    phx-debounce="300"
  />
  
  <%!-- Visibility --%>
  <.input 
    field={@form[:visibility]} 
    type="select" 
    label="Visibility" 
    options={[{"Private (only you)", "private"}, {"Public (anyone can view)", "public"}]}
  />
  
  <%!-- Save Status Indicator --%>
  <%= if @save_status == :unsaved do %>
    <div class="text-yellow-600">Unsaved changes</div>
  <% end %>
  
  <%= if @save_status == :saving do %>
    <div class="text-blue-600">Saving...</div>
  <% end %>
  
  <%!-- Actions --%>
  <div class="flex gap-2">
    <.button type="submit" disabled={@save_status == :saving}>
      <%= if @save_status == :saving, do: "Saving...", else: "Save Snippet" %>
    </.button>
    
    <.link navigate={~p"/snippets"} class="btn btn-secondary">
      Cancel
    </.link>
  </div>
</.form>
```

---

## Error Handling

### Validation Errors

**Display**: Inline with form fields via Phoenix.Component.error/1
**Format**: List of error messages per field
**Example**:
```
Code
[code input field]
• Code can't be blank
• Snippet content is too large. Maximum size is 1MB.
```

### Database Errors

**User Message**: Generic error message  
**Logging**: Full error details with trace ID  
**Example User Message**: "Unable to save snippet at this time. Please try again."

### Authorization Errors

**Private Snippet Access**: "You don't have permission to view this snippet"  
**Not Found**: "Snippet not found"  
**Not Authenticated**: Redirect to login page with return_to parameter

### Network Errors

**Handled By**: LiveView automatic reconnection  
**User Experience**: Connection status indicator in UI  
**No Special Handling Required**: LiveView maintains socket state

---

## Performance Characteristics

### In-Memory Editing

- **Validate Event**: <10ms (changeset validation only, no DB)
- **Form Updates**: <50ms (DOM updates via LiveView diff)
- **Memory Per Session**: ~1MB per active snippet editor (max snippet size)

### Database Persistence

- **Save Event**: <500ms target
  - Snippet INSERT: ~10ms
  - Tag lookups/inserts: ~5ms per tag (max 10 tags = 50ms)
  - Join table INSERTs: ~5ms per tag (max 10 tags = 50ms)
  - Total: ~110ms typical, <500ms worst case

### Syntax Highlighting

- **Client-Side Rendering**: <100ms for typical snippets (<10KB)
- **Large Snippets** (near 1MB): <500ms
- **Impact**: No server load; handled entirely by client browser

---

## Security Considerations

### XSS Prevention

1. **Code Content**: Displayed in `<pre><code>` with Phoenix auto-escaping
2. **Title/Description**: HTML stripped via HtmlSanitizeEx in changeset
3. **Tag Names**: Auto-escaped by Phoenix templates
4. **No eval()**: Syntax highlighting does not execute code

### Privacy Enforcement

1. **Database Level**: Authorization query filters in context
2. **LiveView Level**: get_snippet/2 checks ownership or public visibility
3. **Router Level**: Requires authentication via live_session
4. **Query Scoping**: All queries filter by user_id or visibility

### CSRF Protection

- **Automatic**: Phoenix LiveView provides CSRF token in socket connection
- **No Additional Action Required**: Standard Phoenix security

### Rate Limiting

- **Not Implemented in MVP**: Consider for future if abuse occurs
- **Potential Approach**: Limit snippets per user per hour

---

## Testing Contracts

### Unit Tests (Context)

Test the context functions directly:
```elixir
test "create_snippet/2 with valid data creates snippet" do
  user = insert(:user)
  scope = %Scope{user: user}
  attrs = %{code: "puts 'hello'", language: "ruby", visibility: "private"}
  
  assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(scope, attrs)
  assert snippet.code == "puts 'hello'"
  assert snippet.language == "ruby"
  assert snippet.user_id == user.id
end
```

### Integration Tests (LiveView)

Test the full LiveView flow:
```elixir
test "creating a new snippet with all fields", %{conn: conn} do
  {:ok, lv, _html} = live(conn, ~p"/snippets/new")
  
  assert lv
    |> form("#snippet-form", snippet: %{
        code: "console.log('test')",
        language: "javascript",
        title: "Test Snippet",
        description: "A test",
        tags: ["test", "javascript"],
        visibility: "public"
      })
    |> render_submit()
  
  assert_redirect(lv, ~p"/snippets/#{snippet_id}")
  
  snippet = Repo.get!(Snippet, snippet_id)
  assert snippet.code == "console.log('test')"
  assert snippet.language == "javascript"
  assert length(snippet.tags) == 2
end
```

---

## Future Contract Extensions

### Edit Snippet

**New Event**: `handle_event("update", params, socket)`  
**Path**: `/snippets/:id/edit`  
**Similar to Save**: But calls Snippets.update_snippet/3 instead of create

### Delete Snippet

**New Event**: `handle_event("delete", params, socket)`  
**Confirmation**: Client-side confirm dialog  
**Success**: Redirect to snippets list

### Share Snippet

**New Event**: `handle_event("copy_share_link", params, socket)`  
**Purpose**: Copy public snippet URL to clipboard  
**Requires**: Snippet visibility == "public"

### Fork Snippet

**New Event**: `handle_event("fork", params, socket)`  
**Purpose**: Create a copy of another user's public snippet  
**Implementation**: Copy code/language/title, set new user_id, reset visibility to private
