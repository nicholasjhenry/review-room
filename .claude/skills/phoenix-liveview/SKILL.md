---
name: phoenix-liveview-patterns
description: Phoenix LiveView best practices including navigation, streams, testing, form handling, and component patterns. Use when building LiveView features, handling real-time updates, or working with LiveView streams and forms.
version: 1.0.0
---

# Phoenix LiveView Patterns and Best Practices

Comprehensive patterns for building robust Phoenix LiveView applications.

---

## Navigation: Modern Link and Push Functions

### NEVER Use Deprecated Navigation Functions

**Use modern `<.link>` component and push functions:**

```elixir
# ❌ DEPRECATED - never use these
def handle_event("go", _, socket) do
  {:noreply, live_redirect(socket, to: "/page")}      # DEPRECATED
end

def handle_event("update", _, socket) do
  {:noreply, live_patch(socket, to: "/page?tab=1")}   # DEPRECATED
end

# ✅ CORRECT - modern navigation
def handle_event("go", _, socket) do
  {:noreply, push_navigate(socket, to: ~p"/page")}
end

def handle_event("update", _, socket) do
  {:noreply, push_patch(socket, to: ~p"/page?tab=1")}
end
```

**In templates:**

```heex
<%!-- ❌ DEPRECATED - never use these --%>
<%= live_redirect "Go", to: "/page" %>
<%= live_patch "Tab", to: "/page?tab=1" %>

<%!-- ✅ CORRECT - use <.link> component --%>
<.link navigate={~p"/page"}>Go to Page</.link>
<.link patch={~p"/page?tab=1"}>Switch Tab</.link>
```

### Navigate vs Patch

**`navigate` (full LiveView mount):**
```heex
<%!-- New LiveView, full mount --%>
<.link navigate={~p"/users"}>Users</.link>
<.link navigate={~p"/posts/#{@post}"}>View Post</.link>
```

```elixir
# In LiveView
{:noreply, push_navigate(socket, to: ~p"/dashboard")}
```

**`patch` (same LiveView, handle_params called):**
```heex
<%!-- Same LiveView, update params --%>
<.link patch={~p"/posts?page=#{@page}"}>Next Page</.link>
<.link patch={~p"/posts/#{@post}/edit"}>Edit</.link>
```

```elixir
# In LiveView
{:noreply, push_patch(socket, to: ~p"/posts?filter=#{filter}")}
```

---

## LiveView Naming and Router Configuration

### Naming Convention: Always Use `Live` Suffix

```elixir
# ✅ CORRECT - LiveView naming
defmodule MyAppWeb.WeatherLive do
  use MyAppWeb, :live_view
end

defmodule MyAppWeb.UserLive.Index do
  use MyAppWeb, :live_view
end

defmodule MyAppWeb.PostLive.Show do
  use MyAppWeb, :live_view
end

# ❌ WRONG - missing Live suffix
defmodule MyAppWeb.Weather do
  use MyAppWeb, :live_view
end
```

### Router Configuration: Use Short Names

**The `:browser` scope already aliases `MyAppWeb`, so use short names:**

```elixir
# router.ex
scope "/", MyAppWeb do
  pipe_through :browser
  
  # ✅ CORRECT - short names (MyAppWeb already aliased)
  live "/weather", WeatherLive
  live "/users", UserLive.Index
  live "/users/:id", UserLive.Show
  
  # ❌ WRONG - full module name (redundant)
  live "/weather", MyAppWeb.WeatherLive
end
```

---

## LiveComponents: Avoid Unless Necessary

**AVOID LiveComponents unless you have a strong, specific need:**

```elixir
# ❌ AVOID - unnecessary LiveComponent
defmodule MyAppWeb.UserCardComponent do
  use MyAppWeb, :live_component
  
  def render(assigns) do
    ~H"""
    <div>{@user.name}</div>
    """
  end
end

# ✅ BETTER - use function component instead
defmodule MyAppWeb.CoreComponents do
  def user_card(assigns) do
    ~H"""
    <div>{@user.name}</div>
    """
  end
end
```

**When LiveComponents ARE appropriate:**
- Component has its own state/lifecycle
- Component needs to handle its own events
- Component is very complex and needs isolation
- Multiple instances with independent state on same page

**Example of valid LiveComponent use:**
```elixir
# ✅ Valid - complex component with own state
defmodule MyAppWeb.ChatWindowComponent do
  use MyAppWeb, :live_component
  
  def update(assigns, socket) do
    {:ok, 
     socket
     |> assign(assigns)
     |> assign(messages: [], typing: false)}
  end
  
  def handle_event("send_message", %{"text" => text}, socket) do
    # Component handles its own events
    {:noreply, assign(socket, messages: [text | socket.assigns.messages])}
  end
end
```

---

## Hooks and DOM Management

### CRITICAL: Use phx-update="ignore" with Custom Hooks

**When using `phx-hook` that manages its own DOM, ALWAYS set `phx-update="ignore"`:**

```heex
<%!-- ❌ WRONG - hook will break when LiveView updates --%>
<div id="chart" phx-hook="ChartHook">
</div>

<%!-- ✅ CORRECT - phx-update="ignore" protects hook's DOM --%>
<div id="chart" phx-hook="ChartHook" phx-update="ignore">
</div>

<%!-- ✅ Example with map library --%>
<div 
  id="map" 
  phx-hook="MapHook" 
  phx-update="ignore"
  data-lat={@latitude}
  data-lng={@longitude}
>
</div>

<%!-- ✅ Example with chart library --%>
<canvas 
  id="revenue-chart" 
  phx-hook="ChartJS" 
  phx-update="ignore"
>
</canvas>
```

**Why?** Without `phx-update="ignore"`, LiveView will replace the DOM on updates, destroying the hook's custom DOM elements.

---

## Scripts: Never Embed in HEEx

**NEVER write `<script>` tags in HEEx templates:**

```heex
<%!-- ❌ WRONG - never embed scripts in templates --%>
<script>
  console.log("Don't do this!");
  window.myFunction = function() { ... };
</script>

<%!-- ❌ WRONG - inline event handlers --%>
<button onclick="alert('bad')">Click</button>
```

**✅ CORRECT - write scripts in assets/js:**

```javascript
// assets/js/hooks.js
export const MyHook = {
  mounted() {
    console.log("Hook mounted", this.el);
    this.el.addEventListener("click", () => {
      this.pushEvent("clicked", {});
    });
  }
};

// assets/js/app.js
import { MyHook } from "./hooks";

let Hooks = { MyHook };

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken }
});
```

**In template:**
```heex
<div id="my-element" phx-hook="MyHook" phx-update="ignore">
  Content
</div>
```

---

## LiveView Streams: Critical for Collections

### ALWAYS Use Streams for Collections

**Streams prevent memory bloat and runtime termination:**

```elixir
# ❌ BAD - list assigns cause memory issues with large collections
def mount(_params, _session, socket) do
  messages = list_messages()  # Could be thousands
  {:ok, assign(socket, :messages, messages)}  # Keeps ALL in memory
end

# ✅ GOOD - streams handle large collections efficiently
def mount(_params, _session, socket) do
  messages = list_messages()
  {:ok, stream(socket, :messages, messages)}
end
```

### Stream Operations

**Basic append:**
```elixir
def handle_info({:new_message, msg}, socket) do
  {:noreply, stream(socket, :messages, [msg])}
end
```

**Reset entire stream (filtering, refreshing):**
```elixir
def handle_event("filter", %{"status" => status}, socket) do
  messages = list_messages(status: status)
  
  {:noreply,
   socket
   |> assign(:messages_empty?, messages == [])
   |> stream(:messages, messages, reset: true)}
end
```

**Prepend to beginning:**
```elixir
def handle_event("add_priority", %{"msg" => msg}, socket) do
  {:noreply, stream(socket, :messages, [msg], at: -1)}
end
```

**Delete from stream:**
```elixir
def handle_event("delete", %{"id" => id}, socket) do
  msg = get_message!(id)
  delete_message(msg)
  
  {:noreply, stream_delete(socket, :messages, msg)}
end
```

### Stream Template Requirements

**Template MUST follow this pattern:**

```heex
<%!-- Parent div requires: 
     1. phx-update="stream" 
     2. id attribute --%>
<div id="messages" phx-update="stream">
  <%!-- Child divs require:
       1. :for binding as {id, item}
       2. id={id} attribute --%>
  <div :for={{id, msg} <- @streams.messages} id={id}>
    {msg.text}
  </div>
</div>
```

**Complete example:**
```heex
<div id="tasks" phx-update="stream">
  <div 
    :for={{id, task} <- @streams.tasks} 
    id={id}
    class="task-item"
  >
    <span>{task.name}</span>
    <button phx-click="delete" phx-value-id={task.id}>
      Delete
    </button>
  </div>
</div>
```

### Stream Limitations and Solutions

#### Streams Are Not Enumerable

**❌ WRONG - can't use Enum functions on streams:**
```elixir
# This will error - streams don't implement Enumerable
def handle_event("count", _, socket) do
  count = Enum.count(socket.assigns.streams.messages)  # ERROR
  {:noreply, assign(socket, :count, count)}
end
```

**✅ CORRECT - refetch and reset:**
```elixir
def handle_event("filter", %{"filter" => filter}, socket) do
  # Re-fetch with filter applied
  messages = list_messages(filter)
  
  {:noreply,
   socket
   |> assign(:messages_empty?, messages == [])
   |> stream(:messages, messages, reset: true)}
end
```

#### Counting and Empty States

**Streams don't support counting - track separately:**

```elixir
def mount(_params, _session, socket) do
  messages = list_messages()
  
  {:ok,
   socket
   |> assign(:message_count, length(messages))
   |> assign(:messages_empty?, messages == [])
   |> stream(:messages, messages)}
end

def handle_info({:new_message, msg}, socket) do
  {:noreply,
   socket
   |> update(:message_count, &(&1 + 1))
   |> assign(:messages_empty?, false)
   |> stream(:messages, [msg])}
end
```

**Template with count and empty state:**
```heex
<div>
  <h2>Messages ({@message_count})</h2>
  
  <div id="messages" phx-update="stream">
    <%!-- Empty state using Tailwind --%>
    <div class="hidden only:block">
      No messages yet
    </div>
    
    <div :for={{id, msg} <- @streams.messages} id={id}>
      {msg.text}
    </div>
  </div>
</div>
```

**Note:** The `only:` modifier only works when the empty state is the ONLY sibling alongside the stream comprehension.

### NEVER Use Deprecated phx-update

**❌ DEPRECATED - don't use these:**
```heex
<div id="messages" phx-update="append">
  ...
</div>

<div id="messages" phx-update="prepend">
  ...
</div>
```

**✅ Use streams instead:**
```heex
<div id="messages" phx-update="stream">
  <div :for={{id, msg} <- @streams.messages} id={id}>
    ...
  </div>
</div>
```

---

## LiveView Testing

### Test Setup

```elixir
defmodule MyAppWeb.PostLive.IndexTest do
  use MyAppWeb.ConnCase
  
  import Phoenix.LiveViewTest
  # LazyHTML included for assertions
  
  test "displays posts", %{conn: conn} do
    post = insert(:post, title: "Test Post")
    
    {:ok, view, _html} = live(conn, ~p"/posts")
    
    # ✅ CORRECT - test with has_element?
    assert has_element?(view, "#post-#{post.id}")
  end
end
```

### ALWAYS Use Element Selectors

**❌ WRONG - testing raw HTML strings:**
```elixir
test "shows post title", %{conn: conn} do
  post = insert(:post, title: "My Post")
  {:ok, _view, html} = live(conn, ~p"/posts")
  
  assert html =~ "My Post"  # Fragile - breaks if text changes
end
```

**✅ CORRECT - use element selectors:**
```elixir
test "shows post title", %{conn: conn} do
  post = insert(:post, title: "My Post")
  {:ok, view, _html} = live(conn, ~p"/posts")
  
  # Test for element presence, not text content
  assert has_element?(view, "#post-#{post.id}")
  assert has_element?(view, "[data-role='post-title']")
end
```

### Reference Template IDs

**ALWAYS use IDs from your templates:**

```heex
<%!-- In template --%>
<div id="posts">
  <div :for={post <- @posts} id={"post-#{post.id}"}>
    <button id={"delete-#{post.id}"} phx-click="delete" phx-value-id={post.id}>
      Delete
    </button>
  </div>
</div>
```

```elixir
# In test - reference those IDs
test "deletes post", %{conn: conn} do
  post = insert(:post)
  {:ok, view, _html} = live(conn, ~p"/posts")
  
  # Use the IDs from template
  view
  |> element("#delete-#{post.id}")
  |> render_click()
  
  refute has_element?(view, "#post-#{post.id}")
end
```

### Form Testing

**Use render_submit and render_change:**

```elixir
test "creates post with valid data", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/posts/new")
  
  # Validate on change
  view
  |> form("#post-form", post: %{title: "Test"})
  |> render_change()
  
  # Submit form
  {:ok, _, html} =
    view
    |> form("#post-form", post: %{title: "Test", body: "Content"})
    |> render_submit()
    |> follow_redirect(conn)
  
  assert html =~ "Post created"
end

test "shows validation errors", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/posts/new")
  
  view
  |> form("#post-form", post: %{title: ""})
  |> render_change()
  
  assert has_element?(view, "#post-form")
  # Test for error message element, not text
  assert has_element?(view, "[phx-feedback-for='post[title]']")
end
```

### Test Structure Best Practices

```elixir
# ✅ GOOD - small, focused tests
describe "POST /posts" do
  test "shows empty state when no posts", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/posts")
    assert has_element?(view, "#empty-state")
  end
  
  test "displays post list when posts exist", %{conn: conn} do
    post = insert(:post)
    {:ok, view, _html} = live(conn, ~p"/posts")
    assert has_element?(view, "#post-#{post.id}")
  end
  
  test "filters posts by status", %{conn: conn} do
    insert(:post, status: :published)
    insert(:post, status: :draft)
    
    {:ok, view, _html} = live(conn, ~p"/posts")
    
    view
    |> element("#filter-published")
    |> render_click()
    
    assert has_element?(view, "[data-status='published']")
    refute has_element?(view, "[data-status='draft']")
  end
end
```

### Debugging Test Failures

**Use LazyHTML to inspect actual HTML:**

```elixir
test "complex selector", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/posts")
  
  # Get rendered HTML
  html = render(view)
  
  # Parse and filter
  document = LazyHTML.from_fragment(html)
  matches = LazyHTML.filter(document, "#your-complex-selector")
  
  IO.inspect(matches, label: "Matches")
  
  # Now you can see what's actually in the HTML
  assert has_element?(view, "#corrected-selector")
end
```

### Testing Principles

- ✅ **Test outcomes, not implementation**
- ✅ **Use element IDs, not text content**
- ✅ **Split into small, isolated test files**
- ✅ **Start with simple existence tests, add interactions**
- ✅ **Test against actual HTML structure**
- ❌ **Never test raw HTML strings**
- ❌ **Don't rely on text that can change**

---

## Form Handling

### Creating Forms from Params

**Use `to_form/1` with params map:**

```elixir
def handle_event("submitted", params, socket) do
  {:noreply, assign(socket, form: to_form(params))}
end

# With nested params
def handle_event("submitted", %{"user" => user_params}, socket) do
  {:noreply, assign(socket, form: to_form(user_params, as: :user))}
end
```

### Creating Forms from Changesets

**Use `to_form/1` with changesets:**

```elixir
def mount(_params, _session, socket) do
  changeset = Accounts.change_user(%User{})
  
  {:ok, assign(socket, form: to_form(changeset))}
end

def handle_event("validate", %{"user" => params}, socket) do
  changeset = 
    %User{}
    |> Accounts.change_user(params)
    |> Map.put(:action, :validate)
  
  {:noreply, assign(socket, form: to_form(changeset))}
end

def handle_event("save", %{"user" => params}, socket) do
  case Accounts.create_user(params) do
    {:ok, user} ->
      {:noreply, push_navigate(socket, to: ~p"/users/#{user}")}
    
    {:error, changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

### CRITICAL: Form Template Rules

**ALWAYS do this:**

```heex
<%!-- ✅ CORRECT - form assigned via to_form/2 --%>
<.form for={@form} id="user-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:name]} label="Name" />
  
  <:actions>
    <.button>Save</.button>
  </:actions>
</.form>
```

**NEVER do this:**

```heex
<%!-- ❌ FORBIDDEN - accessing changeset in template causes errors --%>
<.form for={@changeset} id="user-form">
  <.input field={@changeset[:email]} type="email" />
</.form>

<%!-- ❌ FORBIDDEN - using let={f} is deprecated --%>
<.form let={f} for={@form} id="user-form">
  <.input field={f[:email]} type="email" />
</.form>
```

### Form Assignment Pattern

**Complete pattern:**

```elixir
# LiveView
defmodule MyAppWeb.UserLive.New do
  use MyAppWeb, :live_view
  
  alias MyApp.Accounts
  alias MyApp.Accounts.User
  
  def mount(_params, _session, socket) do
    # ✅ Create changeset, wrap in to_form
    changeset = Accounts.change_user(%User{})
    
    {:ok, assign(socket, form: to_form(changeset))}
  end
  
  def handle_event("validate", %{"user" => params}, socket) do
    # ✅ Validate, wrap in to_form
    changeset =
      %User{}
      |> Accounts.change_user(params)
      |> Map.put(:action, :validate)
    
    {:noreply, assign(socket, form: to_form(changeset))}
  end
  
  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created")
         |> push_navigate(to: ~p"/users/#{user}")}
      
      {:error, changeset} ->
        # ✅ On error, wrap changeset in to_form
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
```

```heex
<%!-- Template --%>
<div>
  <h1>New User</h1>
  
  <%!-- ✅ ALWAYS: use @form, never @changeset --%>
  <.form for={@form} id="user-form" phx-change="validate" phx-submit="save">
    <.input field={@form[:email]} type="email" label="Email" required />
    <.input field={@form[:name]} label="Name" required />
    <.input field={@form[:bio]} type="textarea" label="Bio" />
    
    <:actions>
      <.button phx-disable-with="Saving...">Save User</.button>
    </:actions>
  </.form>
</div>
```

### Form Params Naming

**When using schemas, `:as` is computed automatically:**

```elixir
# Schema definition
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  # ...
end

# Create changeset and form
%MyApp.Accounts.User{}
|> Ecto.Changeset.change()
|> to_form()

# Params will be available as %{"user" => user_params}
# The form name is derived from the schema: User -> "user"
```

---

## Quick Reference

### Navigation Checklist
- ✅ Use `<.link navigate={}>` and `<.link patch={}>`
- ✅ Use `push_navigate/2` and `push_patch/2`
- ❌ Never use `live_redirect` or `live_patch` (deprecated)

### Naming Checklist
- ✅ LiveViews end with `Live` suffix: `WeatherLive`
- ✅ Use short names in router: `live "/path", WeatherLive`
- ❌ Avoid LiveComponents unless necessary

### Hooks and Scripts Checklist
- ✅ Add `phx-update="ignore"` when using `phx-hook`
- ✅ Write scripts in `assets/js/`, never in templates
- ❌ Never embed `<script>` tags in HEEx

### Streams Checklist
- ✅ Use `stream/3` for collections
- ✅ Template needs `phx-update="stream"` on parent
- ✅ Template needs `id={id}` on each child
- ✅ Use `:for={{id, item} <- @streams.name}`
- ✅ Track counts/empty state separately
- ✅ Use `reset: true` to refresh/filter
- ❌ Never use `phx-update="append"` or `"prepend"`
- ❌ Streams are not enumerable

### Testing Checklist
- ✅ Use `has_element?` and `element/2`
- ✅ Reference IDs from templates
- ✅ Test element presence, not text
- ✅ Use `render_submit` and `render_change` for forms
- ❌ Never test raw HTML strings
- ❌ Don't rely on text content

### Forms Checklist
- ✅ Always use `to_form/2` to wrap changesets
- ✅ Access fields with `@form[:field]`
- ✅ Add unique `id` to every form
- ❌ FORBIDDEN: Never use `@changeset` in templates
- ❌ FORBIDDEN: Never use `let={f}`

---

## Integration with CLAUDE.md

Check CLAUDE.md for:
- Project-specific LiveView patterns
- Custom hooks and their configurations
- Stream usage conventions
- Test helper functions
- Form component customizations

---

## Summary

**Modern LiveView development:**
1. **Navigation**: Use `<.link navigate/patch>` and `push_navigate/push_patch`
2. **Naming**: `ModuleLive` suffix, short router names
3. **Components**: Avoid LiveComponents unless necessary
4. **Hooks**: Always use `phx-update="ignore"` with custom hooks
5. **Scripts**: Write in `assets/js/`, never in templates
6. **Streams**: Use for all collections, track counts separately
7. **Testing**: Use element selectors, never raw HTML
8. **Forms**: Always `to_form/2`, access via `@form[:field]`

**Critical rules:**
- ❌ NEVER access `@changeset` in templates
- ❌ NEVER use deprecated navigation functions
- ✅ ALWAYS wrap changesets with `to_form/2`
- ✅ ALWAYS use streams for collections
- ✅ ALWAYS add DOM IDs for testing
