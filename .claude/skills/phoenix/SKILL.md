---
name: phoenix-router-basics
description: Phoenix router scope aliasing and deprecated features. Use when working with Phoenix router scope blocks, defining routes, or encountering Phoenix.View references.
version: 1.0.0
---

# Phoenix Router and Deprecated Features

Essential patterns for Phoenix router scope blocks and awareness of deprecated features.

---

## Router Scope Aliasing

### Scope Blocks Include Automatic Aliasing

**Phoenix router `scope` blocks provide automatic module aliasing:**

```elixir
# router.ex

# The second argument to scope is the alias prefix
scope "/admin", MyAppWeb.Admin do
  pipe_through :browser
  
  # ✅ Short module name - scope provides MyAppWeb.Admin prefix
  live "/users", UserLive, :index
  # Routes to: MyAppWeb.Admin.UserLive
  
  live "/products", ProductLive, :index
  # Routes to: MyAppWeb.Admin.ProductLive
end

scope "/", MyAppWeb do
  pipe_through :browser
  
  # ✅ Short module name - scope provides MyAppWeb prefix
  live "/", HomeLive, :index
  # Routes to: MyAppWeb.HomeLive
end
```

### NEVER Duplicate Module Prefixes

**Always be mindful of the scope alias to avoid duplication:**

```elixir
scope "/admin", MyAppWeb.Admin do
  pipe_through :browser
  
  # ❌ WRONG - duplicates the prefix
  live "/users", MyAppWeb.Admin.UserLive, :index
  # Results in: MyAppWeb.Admin.MyAppWeb.Admin.UserLive (WRONG!)
  
  # ❌ WRONG - adds extra prefix
  live "/users", Admin.UserLive, :index
  # Results in: MyAppWeb.Admin.Admin.UserLive (WRONG!)
  
  # ✅ CORRECT - scope provides the prefix
  live "/users", UserLive, :index
  # Results in: MyAppWeb.Admin.UserLive
end
```

### Never Create Your Own Alias

**The scope provides the alias - don't add your own:**

```elixir
scope "/admin", MyAppWeb.Admin do
  pipe_through :browser
  
  # ❌ WRONG - unnecessary alias
  alias MyAppWeb.Admin.UserLive
  live "/users", UserLive, :index
  
  # ✅ CORRECT - scope handles aliasing
  live "/users", UserLive, :index
  live "/products", ProductLive, :index
  live "/orders", OrderLive, :index
end
```

---

## Phoenix.View Is Deprecated

**Phoenix.View is no longer needed or included:**

```elixir
# ❌ WRONG - Phoenix.View is deprecated
defmodule MyAppWeb.UserView do
  use Phoenix.View
  # ...
end

# ❌ WRONG - don't import or reference Phoenix.View
import Phoenix.View

# ✅ Modern Phoenix uses Phoenix.Component for view logic
defmodule MyAppWeb.CoreComponents do
  use Phoenix.Component
  
  def user_card(assigns) do
    ~H"""
    <div>{@user.name}</div>
    """
  end
end
```

---

## Quick Reference

### Router Scope Checklist
- ✅ Scope second argument provides module alias prefix
- ✅ Use short module names in routes (UserLive, not MyAppWeb.Admin.UserLive)
- ❌ Never duplicate the scope prefix in route definitions
- ❌ Never create manual aliases for routes within scopes

### Deprecated Features
- ❌ Don't use Phoenix.View
- ✅ Use Phoenix.Component instead

---

## Summary

**Router scopes:**
- Scope blocks automatically alias modules
- Use short names: `UserLive` not `MyAppWeb.Admin.UserLive`
- Never add manual aliases - the scope handles it

**Deprecated:**
- Phoenix.View is no longer used
- Use Phoenix.Component for view logic
