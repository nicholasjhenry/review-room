# LiveView Routes Contract

**Feature**: Snippet Creation  
**Date**: 2025-11-13

## Overview

This contract defines the LiveView routes and their expected behaviors for the snippet management feature. Phoenix LiveView provides server-rendered, real-time interfaces without requiring a separate API.

## Route Definitions

### Authenticated Routes (Require Login)

#### List Snippets

```elixir
live "/snippets", ReviewRoomWeb.SnippetLive.Index, :index
```

**Purpose**: Display all snippets owned by the current user

**Authorization**: Requires authenticated user (via `:require_authenticated_user` live_session)

**Mount Parameters**:
- None

**Query Parameters** (optional):
- `tag`: Filter snippets by tag name (e.g., `/snippets?tag=authentication`)

**Assigns**:
```elixir
%{
  current_scope: %Scope{user: %User{}},  # From on_mount
  snippets_empty?: boolean(),             # For empty state
  page_title: "Snippets"
}
```

**Streams**:
```elixir
@streams.snippets  # Stream of snippet records
```

**Events**:

1. **`delete`**
   - **Params**: `%{"id" => snippet_id}`
   - **Action**: Delete snippet and remove from stream
   - **Response**: Update stream via `stream_delete/3`

2. **`filter`** (optional - for tag filtering)
   - **Params**: `%{"tag" => tag_name}`
   - **Action**: Filter snippets by tag
   - **Response**: Reset stream with filtered snippets

**Template Elements**:
```heex
<div id="snippets" phx-update="stream">
  <div :for={{id, snippet} <- @streams.snippets} id={id}>
    <h3>{snippet.title}</h3>
    <button phx-click="delete" phx-value-id={snippet.id}>Delete</button>
  </div>
</div>
```

---

#### Create Snippet

```elixir
live "/snippets/new", ReviewRoomWeb.SnippetLive.Form, :new
```

**Purpose**: Create a new snippet

**Authorization**: Requires authenticated user

**Mount Parameters**:
- None

**Assigns**:
```elixir
%{
  current_scope: %Scope{user: %User{}},
  form: to_form(changeset),
  page_title: "New Snippet",
  supported_languages: [{code, name}, ...]
}
```

**Events**:

1. **`validate`**
   - **Params**: `%{"snippet" => snippet_params}`
   - **Action**: Validate form and update changeset
   - **Response**: Assign updated form with errors

2. **`save`**
   - **Params**: `%{"snippet" => snippet_params}`
   - **Action**: Create snippet in database
   - **Response**: 
     - Success: Redirect to `/snippets/:id` with flash message
     - Error: Re-render form with errors

**Form Schema**:
```elixir
%{
  "title" => string (required, 1-200 chars),
  "description" => string (optional, max 2000 chars),
  "code" => text (required, 1-500KB),
  "language" => string (optional, from supported list),
  "visibility" => enum (optional, default: "private"),
  "tags" => string (optional, comma-separated) | list (optional, array of strings)
}
```

**Validation Rules**:
- Title: required, 1-200 characters
- Description: optional, max 2000 characters  
- Code: required, min 1 character, max 500KB
- Language: optional, must be from supported languages config
- Visibility: optional, one of "private", "public", "unlisted"
- Tags: optional, accepts comma-separated string or array, normalized to lowercase array

**Template Elements**:
```heex
<.form for={@form} id="snippet-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:title]} type="text" label="Title" required />
  <.input field={@form[:description]} type="textarea" label="Description" />
  <.input field={@form[:code]} type="textarea" label="Code" required />
  <.input field={@form[:language]} type="select" label="Language" 
          options={@supported_languages} prompt="Select language..." />
  <.input field={@form[:visibility]} type="select" label="Visibility"
          options={[{"Private", "private"}, {"Public", "public"}, {"Unlisted", "unlisted"}]} />
  <.input field={@form[:tags]} type="text" label="Tags" 
          placeholder="e.g. authentication, database" 
          help="Separate tags with commas" />
  <.button type="submit">Save Snippet</.button>
</.form>
```

---

#### Edit Snippet

```elixir
live "/snippets/:id/edit", ReviewRoomWeb.SnippetLive.Form, :edit
```

**Purpose**: Edit an existing snippet

**Authorization**: Requires authenticated user who owns the snippet

**Mount Parameters**:
- `id`: Snippet ID (string)

**Assigns**:
```elixir
%{
  current_scope: %Scope{user: %User{}},
  snippet: %Snippet{},  # Preloaded snippet
  form: to_form(changeset),
  page_title: "Edit Snippet",
  supported_languages: [{code, name}, ...]
}
```

**Events**: Same as Create (validate, save)

**Authorization Check**:
- On mount, verify `snippet.user_id == current_scope.user.id`
- If not authorized, redirect to `/snippets` with error flash

**Form Pre-population**:
```elixir
# In mount/3
snippet = Snippets.get_snippet!(id, socket.assigns.current_scope)

# Convert tags array to comma-separated string for form display
tags_display = Enum.join(snippet.tags, ", ")

changeset = Snippets.change_snippet(snippet, %{})

assign(socket, 
  form: to_form(changeset), 
  snippet: snippet,
  tags_display: tags_display
)

# Note: The form will accept the tags_display string and normalize it back to array
```

---

### Public Routes (No Auth Required)

#### View Snippet

```elixir
live "/snippets/:id", ReviewRoomWeb.SnippetLive.Show, :show
```

**Purpose**: View a single snippet (respects visibility rules)

**Authorization**: 
- Public: Anyone can view
- Unlisted: Anyone with URL can view
- Private: Only owner can view

**Mount Parameters**:
- `id`: Snippet ID (string)

**Assigns**:
```elixir
%{
  current_scope: %Scope{user: %User{} | nil},  # May be nil for guests
  snippet: %Snippet{},  # Preloaded with tags
  page_title: snippet.title
}
```

**Visibility Check**:
```elixir
# In mount/3
snippet = Snippets.get_snippet!(id, socket.assigns.current_scope)
# get_snippet!/2 raises Ecto.NoResultsError if unauthorized
# This is caught and renders 404 page
```

**Events**: None (read-only view)

**Template Elements**:
```heex
<div>
  <h1>{@snippet.title}</h1>
  <p>{@snippet.description}</p>
  
  <div phx-hook="SyntaxHighlighter" phx-update="ignore">
    <pre><code class={"language-#{@snippet.language}"}>
{@snippet.code}
    </code></pre>
  </div>
  
  <div class="tags">
    <%= for tag <- @snippet.tags do %>
      <.link patch={~p"/snippets?tag=#{tag}"} class="tag">
        {tag}
      </.link>
    <% end %>
  </div>
  
  <%= if @current_scope.user && @current_scope.user.id == @snippet.user_id do %>
    <.link navigate={~p"/snippets/#{@snippet}/edit"}>Edit</.link>
  <% end %>
</div>
```

---

## Router Configuration

```elixir
# In lib/review_room_web/router.ex

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
    # Public/unlisted snippet viewing
    live "/snippets/:id", SnippetLive.Show, :show
  end
end
```

**Routing Decision Rationale**:
- Create/Edit/List require authentication (in `:require_authenticated_user` session)
- Show respects visibility but doesn't require auth (in `:current_user` session)
- Authorization happens in mount via `get_snippet!/2` visibility check

---

## Error Handling

### Validation Errors

**Trigger**: Form validation fails (missing required fields, length violations, etc.)

**Response**:
```elixir
{:noreply, assign(socket, form: to_form(changeset))}
# Changeset errors automatically displayed via <.input> components
```

**User Experience**: Inline error messages on form fields

---

### Authorization Errors

**Trigger**: User tries to edit/delete snippet they don't own

**Response**:
```elixir
# In mount/3 or handle_event
case Snippets.get_snippet!(id, current_scope) do
  snippet when snippet.user_id == current_scope.user.id ->
    # Authorized - proceed
  _ ->
    # Not authorized
    {:noreply,
     socket
     |> put_flash(:error, "You are not authorized to access this snippet")
     |> redirect(to: ~p"/snippets")}
end
```

---

### Not Found Errors

**Trigger**: Snippet ID doesn't exist or user doesn't have access

**Response**:
```elixir
# Ecto.NoResultsError raised by get_snippet!/2
# Caught by Phoenix error view
# Renders 404 page (not 403, to avoid leaking snippet existence)
```

---

## Real-time Features

### Form Validation

**Trigger**: User types in any form field

**Event**: `phx-change="validate"`

**Behavior**:
1. Capture form params
2. Build changeset with validations
3. Return updated form with inline errors
4. No database write occurs

---

### Stream Updates

**Trigger**: User deletes snippet from list

**Event**: `phx-click="delete"`

**Behavior**:
1. Delete from database
2. Remove from stream via `stream_delete(socket, :snippets, snippet)`
3. DOM automatically updated by LiveView
4. No page reload required

---

## Performance Considerations

**N+1 Query Prevention**:
- Always preload `:tags` association: `Repo.preload(snippet, :tags)`
- Preload in list queries: `|> preload(:tags)`

**Stream vs Assign**:
- Use streams for snippet lists (can grow large)
- Prevents memory bloat from large collections

**Debouncing**:
- Consider `phx-debounce="300"` on code textarea for large snippets
- Prevents excessive validation calls during typing

---

## Test Contracts

### Required Test Coverage

**Index LiveView**:
```elixir
test "lists all user snippets", %{conn: conn} do
  snippet = snippet_fixture()
  {:ok, _view, html} = live(conn, ~p"/snippets")
  assert html =~ snippet.title
end

test "filters snippets by tag", %{conn: conn} do
  snippet1 = snippet_fixture(tags: ["elixir", "phoenix"])
  snippet2 = snippet_fixture(tags: ["python"])
  {:ok, view, _html} = live(conn, ~p"/snippets?tag=elixir")
  assert has_element?(view, "#snippets-#{snippet1.id}")
  refute has_element?(view, "#snippets-#{snippet2.id}")
end

test "deletes snippet", %{conn: conn} do
  snippet = snippet_fixture()
  {:ok, view, _html} = live(conn, ~p"/snippets")
  assert view |> element("#snippet-#{snippet.id} button", "Delete") |> render_click()
  refute has_element?(view, "#snippet-#{snippet.id}")
end
```

**Form LiveView**:
```elixir
test "creates snippet with valid data", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/snippets/new")
  
  assert view
         |> form("#snippet-form", snippet: %{title: "Test", code: "code"})
         |> render_submit()
  
  assert_redirected(view, ~p"/snippets/#{snippet.id}")
end

test "shows validation errors", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/snippets/new")
  
  html = view
         |> form("#snippet-form", snippet: %{title: "", code: ""})
         |> render_submit()
  
  assert html =~ "can&#39;t be blank"
end
```

**Show LiveView**:
```elixir
test "displays public snippet to guest", %{conn: conn} do
  snippet = snippet_fixture(visibility: :public)
  {:ok, _view, html} = live(conn, ~p"/snippets/#{snippet}")
  assert html =~ snippet.title
  assert html =~ snippet.code
end

test "denies access to private snippet", %{conn: conn} do
  snippet = snippet_fixture(visibility: :private)
  assert_raise Ecto.NoResultsError, fn ->
    live(conn, ~p"/snippets/#{snippet}")
  end
end
```

---

## Summary

This contract defines:
- 4 LiveView routes (index, new, edit, show)
- Authorization patterns (authenticated vs public)
- Event handlers and their behaviors
- Form validation and error handling
- Real-time updates via streams
- Test expectations for each route

All routes follow Phoenix LiveView best practices and the ReviewRoom authentication patterns established by `phx.gen.auth`.
