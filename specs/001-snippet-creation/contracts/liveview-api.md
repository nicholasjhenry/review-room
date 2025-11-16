# LiveView API Contract: Snippet Creation

**Feature**: Snippet Creation  
**Branch**: `001-snippet-creation`  
**Date**: 2025-11-16

## Overview

This document defines the API contract between LiveView modules and the Snippets context for the snippet creation feature. Since this is a Phoenix LiveView application, the API is function-based rather than REST/HTTP.

---

## Context API: `ReviewRoom.Snippets`

### Public Functions

#### `list_snippets(scope, opts \\ [])`

Lists snippets for the current user.

**Parameters:**
- `scope` (`Accounts.Scope`) - Authorization scope containing current user
- `opts` (`keyword()`) - Optional filters and pagination
  - `:page` - Page number (default: 1)
  - `:per_page` - Results per page (default: 20, max: 100)
  - `:tag` - Filter by tag name (string)
  - `:visibility` - Filter by visibility (atom: :private | :public | :unlisted)

**Returns:**
- `[%Snippet{}]` - List of snippets (with preloaded tags)

**Example:**
```elixir
# List all user snippets
Snippets.list_snippets(scope)

# List with pagination
Snippets.list_snippets(scope, page: 2, per_page: 50)

# Filter by tag
Snippets.list_snippets(scope, tag: "elixir")
```

---

#### `list_public_snippets(opts \\ [])`

Lists public snippets for discovery/browsing.

**Parameters:**
- `opts` (`keyword()`) - Optional filters and pagination
  - `:page` - Page number (default: 1)
  - `:per_page` - Results per page (default: 20, max: 100)
  - `:tag` - Filter by tag name (string)

**Returns:**
- `[%Snippet{}]` - List of public snippets (with preloaded tags and user)

**Example:**
```elixir
# List recent public snippets
Snippets.list_public_snippets()

# Filter public snippets by tag
Snippets.list_public_snippets(tag: "phoenix")
```

---

#### `get_snippet(slug, scope)`

Retrieves a single snippet by slug with visibility enforcement.

**Parameters:**
- `slug` (`string()`) - URL-friendly snippet identifier
- `scope` (`Accounts.Scope`) - Authorization scope containing current user

**Returns:**
- `{:ok, %Snippet{}}` - Snippet found and accessible
- `{:error, :not_found}` - Snippet doesn't exist or not accessible

**Authorization Rules:**
- Public snippets: Accessible to anyone
- Unlisted snippets: Accessible to anyone with the link
- Private snippets: Accessible only to creator

**Example:**
```elixir
case Snippets.get_snippet("my-snippet-abc123", scope) do
  {:ok, snippet} -> # Display snippet
  {:error, :not_found} -> # Show 404
end
```

---

#### `create_snippet(attrs, scope)`

Creates a new snippet for the current user.

**Parameters:**
- `attrs` (`map()`) - Snippet attributes
  - `"title"` (required) - Snippet title (string, 1-200 chars)
  - `"code"` (required) - Code content (string, 1-500KB bytes)
  - `"description"` (optional) - Description (string, max 2000 chars)
  - `"language"` (optional) - Programming language (string, from supported list)
  - `"visibility"` (optional) - Access control (string: "private", "public", "unlisted", default: "private")
  - `"tags"` (optional) - Comma-separated tag names (string, e.g., "elixir, phoenix, web") OR array of strings

- `scope` (`Accounts.Scope`) - Authorization scope containing current user

**Returns:**
- `{:ok, %Snippet{}}` - Snippet created successfully (tags stored in array column)
- `{:error, %Ecto.Changeset{}}` - Validation failed

**Validations:**
- Title: Required, 1-200 characters
- Code: Required, 1-512,000 bytes (500 KB)
- Description: Optional, max 2,000 characters
- Language: Optional, must be in supported languages list
- Visibility: Must be "private", "public", or "unlisted"
- Tags: Array of strings, each 1-50 chars, lowercase, alphanumeric + hyphens only
- Tags are automatically normalized (lowercase, trimmed, deduplicated)

**Example:**
```elixir
attrs = %{
  "title" => "Authentication Helper",
  "code" => "defmodule Auth do...",
  "description" => "Helper functions for authentication",
  "language" => "elixir",
  "visibility" => "private",
  "tags" => "elixir, authentication, helpers"  # Will be parsed to ["elixir", "authentication", "helpers"]
}

case Snippets.create_snippet(attrs, scope) do
  {:ok, snippet} -> # Redirect to snippet show (snippet.tags is ["elixir", "authentication", "helpers"])
  {:error, changeset} -> # Show errors
end
```

---

#### `update_snippet(snippet, attrs, scope)`

Updates an existing snippet.

**Parameters:**
- `snippet` (`%Snippet{}`) - The snippet to update
- `attrs` (`map()`) - Updated attributes (same as create_snippet)
- `scope` (`Accounts.Scope`) - Authorization scope containing current user

**Returns:**
- `{:ok, %Snippet{}}` - Snippet updated successfully
- `{:error, %Ecto.Changeset{}}` - Validation failed
- `{:error, :unauthorized}` - User is not the creator

**Authorization:**
- Only the creator can update their snippet

**Example:**
```elixir
case Snippets.update_snippet(snippet, %{"visibility" => "public"}, scope) do
  {:ok, updated_snippet} -> # Show success message
  {:error, %Ecto.Changeset{} = changeset} -> # Show errors
  {:error, :unauthorized} -> # Show access denied
end
```

---

#### `delete_snippet(snippet, scope)`

Deletes a snippet.

**Parameters:**
- `snippet` (`%Snippet{}`) - The snippet to delete
- `scope` (`Accounts.Scope`) - Authorization scope containing current user

**Returns:**
- `{:ok, %Snippet{}}` - Snippet deleted successfully
- `{:error, %Ecto.Changeset{}}` - Delete failed
- `{:error, :unauthorized}` - User is not the creator

**Authorization:**
- Only the creator can delete their snippet

**Example:**
```elixir
case Snippets.delete_snippet(snippet, scope) do
  {:ok, _snippet} -> # Redirect to snippet list
  {:error, :unauthorized} -> # Show access denied
end
```

---

#### `change_snippet(snippet, attrs \\ %{})`

Creates a changeset for validation (used for LiveView forms).

**Parameters:**
- `snippet` (`%Snippet{}`) - The snippet struct (can be new or existing)
- `attrs` (`map()`) - Attributes to validate (default: empty map)

**Returns:**
- `%Ecto.Changeset{}` - Changeset for form binding and validation

**Example:**
```elixir
# For new snippet form
changeset = Snippets.change_snippet(%Snippet{})

# For validation during typing
changeset = Snippets.change_snippet(%Snippet{}, attrs)
  |> Map.put(:action, :validate)
```

---

#### `list_all_tags()`

Lists all unique tags across all snippets (for autocomplete/suggestions).

**Parameters:** None

**Returns:**
- `[string()]` - List of unique tag names (alphabetically sorted)

**Example:**
```elixir
tags = Snippets.list_all_tags()
# => ["authentication", "elixir", "phoenix", "web", ...]
```

**Implementation Note:**
Uses PostgreSQL's `unnest` function to extract and deduplicate tags from all snippet arrays.

---

#### `supported_languages()`

Returns list of supported programming languages.

**Parameters:** None

**Returns:**
- `[string()]` - List of language identifiers

**Example:**
```elixir
languages = Snippets.supported_languages()
# => ["elixir", "javascript", "python", "ruby", ...]
```

---

## LiveView Routes

### Routes Definition

```elixir
# lib/review_room_web/router.ex
scope "/", ReviewRoomWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{ReviewRoomWeb.UserAuth, :ensure_authenticated}] do
    
    # Snippet management (authenticated users)
    live "/snippets", SnippetLive.Index, :index
    live "/snippets/new", SnippetLive.New, :new
    live "/snippets/:slug/edit", SnippetLive.Edit, :edit
  end
end

scope "/", ReviewRoomWeb do
  pipe_through :browser

  # Public snippet viewing (no auth required for public/unlisted)
  live "/s/:slug", SnippetLive.Show, :show
end
```

---

### LiveView Modules

#### `ReviewRoomWeb.SnippetLive.Index`

Lists user's snippets.

**Mount:**
```elixir
def mount(_params, _session, socket) do
  scope = socket.assigns.current_scope
  snippets = Snippets.list_snippets(scope)
  
  {:ok, assign(socket, snippets: snippets, page_title: "My Snippets")}
end
```

**Handles:**
- `"delete"` - Delete a snippet
- `"filter_tag"` - Filter by tag

---

#### `ReviewRoomWeb.SnippetLive.New`

Creates a new snippet.

**Mount:**
```elixir
def mount(_params, _session, socket) do
  changeset = Snippets.change_snippet(%Snippet{})
  
  {:ok, 
    socket
    |> assign(:changeset, changeset)
    |> assign(:page_title, "New Snippet")
    |> assign(:languages, Snippets.supported_languages())}
end
```

**Handles:**
- `"validate"` - Real-time form validation
- `"save"` - Create snippet

---

#### `ReviewRoomWeb.SnippetLive.Show`

Displays a single snippet (public or authenticated).

**Mount:**
```elixir
def mount(%{"slug" => slug}, _session, socket) do
  scope = socket.assigns[:current_scope] || %{user: nil}
  
  case Snippets.get_snippet(slug, scope) do
    {:ok, snippet} ->
      {:ok, 
        socket
        |> assign(:snippet, snippet)
        |> assign(:page_title, snippet.title)}
    
    {:error, :not_found} ->
      {:ok, redirect(socket, to: ~p"/404")}
  end
end
```

**Handles:**
- `"copy_code"` - Copy code to clipboard (client-side)

---

#### `ReviewRoomWeb.SnippetLive.Edit`

Edits an existing snippet.

**Mount:**
```elixir
def mount(%{"slug" => slug}, _session, socket) do
  scope = socket.assigns.current_scope
  
  case Snippets.get_snippet(slug, scope) do
    {:ok, snippet} ->
      if snippet.user_id == scope.user.id do
        changeset = Snippets.change_snippet(snippet)
        
        {:ok,
          socket
          |> assign(:snippet, snippet)
          |> assign(:changeset, changeset)
          |> assign(:page_title, "Edit: #{snippet.title}")
          |> assign(:languages, Snippets.supported_languages())}
      else
        {:ok, redirect(socket, to: ~p"/403")}
      end
    
    {:error, :not_found} ->
      {:ok, redirect(socket, to: ~p"/404")}
  end
end
```

**Handles:**
- `"validate"` - Real-time form validation
- `"save"` - Update snippet
- `"delete"` - Delete snippet

---

## Event Handling

### Form Validation Event

**Event:** `"validate"`

**Payload:**
```elixir
%{"snippet" => %{
  "title" => "...",
  "code" => "...",
  "description" => "...",
  "language" => "...",
  "visibility" => "...",
  "tags" => "..."
}}
```

**Handler:**
```elixir
def handle_event("validate", %{"snippet" => snippet_params}, socket) do
  changeset =
    socket.assigns.snippet
    |> Snippets.change_snippet(snippet_params)
    |> Map.put(:action, :validate)
  
  {:noreply, assign(socket, :changeset, changeset)}
end
```

---

### Create/Update Snippet Event

**Event:** `"save"`

**Payload:** Same as validation

**Handler (Create):**
```elixir
def handle_event("save", %{"snippet" => snippet_params}, socket) do
  scope = socket.assigns.current_scope
  
  case Snippets.create_snippet(snippet_params, scope) do
    {:ok, snippet} ->
      {:noreply,
        socket
        |> put_flash(:info, "Snippet created successfully")
        |> redirect(to: ~p"/s/#{snippet.slug}")}
    
    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, changeset: changeset)}
  end
end
```

**Handler (Update):**
```elixir
def handle_event("save", %{"snippet" => snippet_params}, socket) do
  scope = socket.assigns.current_scope
  snippet = socket.assigns.snippet
  
  case Snippets.update_snippet(snippet, snippet_params, scope) do
    {:ok, updated_snippet} ->
      {:noreply,
        socket
        |> put_flash(:info, "Snippet updated successfully")
        |> redirect(to: ~p"/s/#{updated_snippet.slug}")}
    
    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, changeset: changeset)}
    
    {:error, :unauthorized} ->
      {:noreply,
        socket
        |> put_flash(:error, "You are not authorized to update this snippet")
        |> redirect(to: ~p"/snippets")}
  end
end
```

---

### Delete Snippet Event

**Event:** `"delete"`

**Payload:**
```elixir
%{"id" => snippet_id}  # Or access from socket.assigns.snippet
```

**Handler:**
```elixir
def handle_event("delete", _params, socket) do
  scope = socket.assigns.current_scope
  snippet = socket.assigns.snippet
  
  case Snippets.delete_snippet(snippet, scope) do
    {:ok, _snippet} ->
      {:noreply,
        socket
        |> put_flash(:info, "Snippet deleted successfully")
        |> redirect(to: ~p"/snippets")}
    
    {:error, :unauthorized} ->
      {:noreply,
        socket
        |> put_flash(:error, "You are not authorized to delete this snippet")
        |> redirect(to: ~p"/snippets")}
  end
end
```

---

## Error Handling

### Validation Errors

**Format:**
```elixir
%Ecto.Changeset{
  errors: [
    title: {"can't be blank", [validation: :required]},
    code: {"should be at most %{count} byte(s)", [count: 512000, validation: :length, kind: :max, type: :bytes]}
  ]
}
```

**Display:**
```heex
<.error :for={msg <- Enum.map(@errors, &translate_error(&1))}>
  <%= msg %>
</.error>
```

---

### Authorization Errors

**Returns:**
- `{:error, :not_found}` - Return 404 (not 403) to avoid revealing existence
- `{:error, :unauthorized}` - User attempted action they're not allowed

**Handling:**
```elixir
case Snippets.get_snippet(slug, scope) do
  {:ok, snippet} -> # Success
  {:error, :not_found} -> redirect(socket, to: ~p"/404")
end
```

---

### Database Errors

**Timeout:** 5 seconds (configured in Repo)

**Handling:**
```elixir
# Automatic retry for transient failures
# Log error with context (user_id, snippet_id, error message)
# Display generic error to user: "Unable to save snippet, please try again"
```

---

## Client-Side Integration

### JavaScript Hooks

**SyntaxHighlight Hook:**
```javascript
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
```

**CodeInput Hook (size validation):**
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
```

---

## Summary

**Context Functions:**
- `list_snippets/2` - List user snippets with filtering
- `list_public_snippets/1` - List public snippets
- `get_snippet/2` - Get single snippet with visibility check
- `create_snippet/2` - Create new snippet (tags stored in array column)
- `update_snippet/3` - Update existing snippet
- `delete_snippet/2` - Delete snippet
- `change_snippet/2` - Create changeset for forms
- `list_all_tags/0` - List all unique tags across snippets
- `supported_languages/0` - List supported languages

**LiveView Routes:**
- `/snippets` - List user snippets (auth required)
- `/snippets/new` - Create snippet (auth required)
- `/snippets/:slug/edit` - Edit snippet (auth required)
- `/s/:slug` - View snippet (public access based on visibility)

**Event Handlers:**
- `"validate"` - Real-time form validation
- `"save"` - Create/update snippet
- `"delete"` - Delete snippet

**JavaScript Hooks:**
- `SyntaxHighlight` - Apply syntax highlighting
- `CodeInput` - Real-time size validation
