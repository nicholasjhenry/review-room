---
name: phoenix-auth-patterns
description: Phoenix authentication flow patterns using phx.gen.auth conventions. Use when adding routes, implementing authentication requirements, or working with current_scope/current_user assigns.
version: 1.0.0
---

# Phoenix Authentication Patterns

This skill teaches proper authentication handling in Phoenix applications using `phx.gen.auth` conventions.

## Core Principles

1. **Handle authentication at the router level** with proper redirects
2. **Never duplicate `live_session` names** - each can only be defined once
3. **Use `@current_scope.user`** in templates, never `@current_user`
4. **Pass `current_scope` to context functions** as the first argument
5. **Always explain router placement decisions** when adding routes

---

## Router Architecture (phx.gen.auth)

Phoenix generators create a structured authentication system with:

### Plugs

**`:fetch_current_scope_for_user`**
- Included in default `:browser` pipeline
- Makes current user available without requiring authentication
- Assigns `@current_scope` to connection/socket

**`:require_authenticated_user`**
- Redirects to login page when user is not authenticated
- Used in pipeline for protected routes

**`:redirect_if_user_is_authenticated`**
- Redirects authenticated users to default path
- Used for registration/login pages

### Live Sessions

**`live_session :current_user`**
- For routes that need current user but don't require authentication
- Similar to `:fetch_current_scope_for_user` plug
- Assigns `@current_scope` to socket

**`live_session :require_authenticated_user`**
- For routes that require authentication
- Similar to `:require_authenticated_user` plug
- Assigns `@current_scope` to socket

---

## Important: current_scope vs. current_user

**What `phx.gen.auth` assigns:**
- ✅ `@current_scope` (with nested `.user`)
- ❌ **Not** `@current_user`

**In templates/LiveViews:**
```elixir
# ✅ Correct
<%= @current_scope.user.email %>

# ❌ Wrong - will cause errors
<%= @current_user.email %>
```

**In context functions:**
```elixir
# ✅ Correct - pass current_scope as first arg
def list_user_posts(current_scope, filters) do
  Post
  |> where([p], p.user_id == ^current_scope.user.id)
  |> Repo.all()
end

# ❌ Wrong - don't access Repo directly in LiveView
def mount(_params, _session, socket) do
  posts = Repo.all(Post)  # No current_scope filtering
end
```

---

## Pattern 1: Routes Requiring Authentication

### LiveView Routes

**Always place inside the EXISTING `live_session :require_authenticated_user` block** (don't create a new one):

```elixir
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}] do
    # phx.gen.auth generated routes
    live "/users/settings", UserLive.Settings, :edit
    live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    
    # Your routes requiring authentication
    live "/dashboard", DashboardLive, :index
    live "/posts/new", PostLive.New, :new
    live "/posts/:id/edit", PostLive.Edit, :edit
  end
end
```

**Why this placement:**
- Pipeline includes `:require_authenticated_user` plug
- `live_session` enforces authentication via `on_mount` hook
- Unauthenticated users redirected to login
- `@current_scope` available in LiveView

### Controller Routes

Place in scope with `:require_authenticated_user` plug:

```elixir
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  get "/profile", ProfileController, :show
  post "/posts", PostController, :create
  delete "/posts/:id", PostController, :delete
end
```

**Why this placement:**
- Plug redirects unauthenticated users to login
- `current_scope` available in `conn.assigns`
- Consistent with LiveView authentication approach

---

## Pattern 2: Routes Working With or Without Authentication

### LiveView Routes

**Always use the EXISTING `live_session :current_user` block** (don't create a new one):

```elixir
scope "/", MyAppWeb do
  pipe_through [:browser]

  live_session :current_user,
    on_mount: [{MyAppWeb.UserAuth, :mount_current_scope}] do
    # Your public routes with optional user context
    live "/", HomeLive, :index
    live "/posts", PostLive.Index, :index
    live "/posts/:id", PostLive.Show, :show
  end
end
```

**Why this placement:**
- No authentication requirement
- `@current_scope` still available (may be nil if not logged in)
- Can conditionally show content based on `@current_scope.user`
- Users can access without login

**In the LiveView:**
```elixir
def render(assigns) do
  ~H"""
  <div>
    <%= if @current_scope.user do %>
      <p>Welcome back, <%= @current_scope.user.email %>!</p>
      <.link navigate={~p"/dashboard"}>Dashboard</.link>
    <% else %>
      <.link navigate={~p"/users/register"}>Sign Up</.link>
      <.link navigate={~p"/users/log_in"}>Log In</.link>
    <% end %>
  </div>
  """
end
```

### Controller Routes

Controllers automatically have `current_scope` if they use `:browser` pipeline:

```elixir
scope "/", MyAppWeb do
  pipe_through [:browser]

  get "/about", PageController, :about
  get "/blog", BlogController, :index
end
```

**In controller:**
```elixir
def index(conn, _params) do
  # current_scope is available in conn.assigns
  if conn.assigns.current_scope.user do
    # Show personalized content
  else
    # Show public content
  end
  
  render(conn, :index)
end
```

---

## Pattern 3: Routes for Unauthenticated Users Only

For routes like registration/login that should redirect if already logged in:

```elixir
scope "/", MyAppWeb do
  pipe_through [:browser, :redirect_if_user_is_authenticated]

  live_session :redirect_if_user_is_authenticated,
    on_mount: [{MyAppWeb.UserAuth, :redirect_if_user_is_authenticated}] do
    live "/users/register", UserLive.Registration, :new
    live "/users/log_in", UserLive.Login, :new
    live "/users/reset-password", UserLive.ForgotPassword, :new
  end
end
```

**Why this placement:**
- Redirects authenticated users away from registration
- Prevents confusion (already logged in)
- `phx.gen.auth` creates this by default

---

## Common Mistakes and Fixes

### ❌ Mistake 1: Duplicating live_session Names

**Wrong:**
```elixir
# In one part of router
live_session :current_user do
  live "/", HomeLive
end

# Later in router - ERROR: duplicate live_session name
live_session :current_user do
  live "/posts", PostLive.Index
end
```

**Correct:**
```elixir
# All :current_user routes in one block
live_session :current_user,
  on_mount: [{MyAppWeb.UserAuth, :mount_current_scope}] do
  live "/", HomeLive
  live "/posts", PostLive.Index
  live "/posts/:id", PostLive.Show
end
```

### ❌ Mistake 2: Using @current_user Instead of @current_scope.user

**Wrong:**
```elixir
def render(assigns) do
  ~H"""
  <p>Welcome, <%= @current_user.email %></p>
  """
end
```

**Correct:**
```elixir
def render(assigns) do
  ~H"""
  <p>Welcome, <%= @current_scope.user.email %></p>
  """
end
```

### ❌ Mistake 3: Not Filtering by Current User in Contexts

**Wrong:**
```elixir
# In context module
def list_posts do
  Repo.all(Post)  # Returns ALL posts, not just user's
end

# In LiveView
def mount(_params, _session, socket) do
  posts = MyApp.Content.list_posts()  # Not filtered
  {:ok, assign(socket, posts: posts)}
end
```

**Correct:**
```elixir
# In context module
def list_user_posts(current_scope) do
  Post
  |> where([p], p.user_id == ^current_scope.user.id)
  |> Repo.all()
end

# In LiveView
def mount(_params, _session, socket) do
  posts = MyApp.Content.list_user_posts(socket.assigns.current_scope)
  {:ok, assign(socket, posts: posts)}
end
```

### ❌ Mistake 4: Wrong Pipeline/live_session Combination

**Wrong:**
```elixir
scope "/", MyAppWeb do
  pipe_through [:browser]  # No auth enforcement
  
  live_session :require_authenticated_user,  # But using auth live_session
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}] do
    live "/dashboard", DashboardLive
  end
end
```

**Correct:**
```elixir
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]  # Enforce at pipeline level
  
  live_session :require_authenticated_user,
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}] do
    live "/dashboard", DashboardLive
  end
end
```

---

## Troubleshooting Checklist

When encountering `current_scope` errors or authentication issues:

1. **Check router placement:**
   - Is route in correct `live_session` block?
   - Is correct pipeline applied?
   - Is `live_session` name duplicated elsewhere?

2. **Check assigns:**
   - Using `@current_scope.user`, not `@current_user`?
   - Passing `current_scope` to context functions?

3. **Check session scope:**
   - Protected route in `:require_authenticated_user` session?
   - Public route in `:current_user` session?

4. **Verify `on_mount` hooks:**
   - Does `live_session` have correct `on_mount` callback?
   - Is `UserAuth` module properly configured?

---

## Quick Reference

### Adding a New Protected Route

```elixir
# 1. Locate EXISTING :require_authenticated_user live_session
# 2. Add route inside that block
live_session :require_authenticated_user,
  on_mount: [{MyAppWeb.UserAuth, :require_authenticated}] do
  # Existing routes...
  
  # Your new route
  live "/my-protected-page", MyProtectedLive, :index
end

# 3. In LiveView, access user
def mount(_params, _session, socket) do
  current_user = socket.assigns.current_scope.user
  # current_user is guaranteed to exist (session enforces this)
end
```

### Adding a New Public Route

```elixir
# 1. Locate EXISTING :current_user live_session
# 2. Add route inside that block
live_session :current_user,
  on_mount: [{MyAppWeb.UserAuth, :mount_current_scope}] do
  # Existing routes...
  
  # Your new route
  live "/my-public-page", MyPublicLive, :index
end

# 3. In LiveView, check if user exists
def mount(_params, _session, socket) do
  if socket.assigns.current_scope.user do
    # User is logged in
  else
    # Anonymous user
  end
end
```

---

## Integration with CLAUDE.md

Check CLAUDE.md for:
- Project-specific authentication module name (e.g., `MyAppWeb.UserAuth`)
- Custom `current_scope` fields beyond `.user`
- Additional `live_session` scopes (beyond the standard three)
- Custom redirect paths after login/logout
- Multi-tenancy patterns (if applicable)

---

## Summary

**Always:**
- Place routes in existing `live_session` blocks (don't duplicate names)
- Use `@current_scope.user` in templates, never `@current_user`
- Pass `current_scope` as first argument to context functions
- Explain router placement decisions (which pipeline, which `live_session`, and why)

**Never:**
- Duplicate `live_session` names
- Access `current_user` directly (it doesn't exist)
- Query `Repo` directly in LiveViews without filtering by `current_scope.user`
