---
name: phoenix-heex-patterns
description: Phoenix HEEx template syntax, form building, and HTML best practices. Use when writing Phoenix templates, forms, components, or working with HEEx syntax.
version: 1.0.0
---

# Phoenix HEEx Patterns and Best Practices

Essential patterns for writing Phoenix HEEx templates and components.

---

## HEEx Sigils: Always Use ~H

**ALWAYS use `~H` sigil or `.html.heex` files. NEVER use `~E`:**

```elixir
# ✅ CORRECT - HEEx sigil
def render(assigns) do
  ~H"""
  <div>Hello, {@name}</div>
  """
end

# ✅ CORRECT - .html.heex file
# my_live.html.heex
<div>Hello, {@name}</div>

# ❌ WRONG - ~E is deprecated
def render(assigns) do
  ~E"""
  <div>Hello, <%= @name %></div>
  """
end
```

**Why?**
- `~H` is the modern HEEx sigil with better syntax
- `~E` (EEx) is deprecated for Phoenix templates
- HEEx provides compile-time validation and better interpolation

---

## Form Building: Modern Phoenix.Component Functions

### ALWAYS Use Phoenix.Component.form/1

**NEVER use the deprecated `form_for`:**

```elixir
# ❌ WRONG - deprecated Phoenix.HTML.form_for
<%= form_for @changeset, @action, fn f -> %>
  <%= text_input f, :name %>
<% end %>

# ❌ WRONG - deprecated Phoenix.HTML.inputs_for
<%= inputs_for f, :addresses, fn a -> %>
  <%= text_input a, :street %>
<% end %>

# ✅ CORRECT - Phoenix.Component.form/1
<.form for={@form} phx-submit="save" id="user-form">
  <.input field={@form[:name]} label="Name" />
</.form>

# ✅ CORRECT - Phoenix.Component.inputs_for/1
<.inputs_for :let={address} field={@form[:addresses]}>
  <.input field={address[:street]} label="Street" />
</.inputs_for>
```

### Use to_form/2 for Form Assignment

**ALWAYS use `Phoenix.Component.to_form/2`:**

```elixir
# In LiveView mount/handle_event
def mount(_params, _session, socket) do
  changeset = User.changeset(%User{}, %{})
  
  # ✅ CORRECT - use to_form/2
  socket = assign(socket, :form, to_form(changeset))
  
  {:ok, socket}
end

def handle_event("save", %{"user" => params}, socket) do
  case Accounts.create_user(params) do
    {:ok, user} ->
      {:noreply, push_navigate(socket, to: ~p"/users/#{user}")}
    
    {:error, changeset} ->
      # ✅ CORRECT - wrap changeset in to_form
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end
```

**In template:**

```heex
<%!-- ✅ CORRECT - access form fields with bracket syntax --%>
<.form for={@form} phx-submit="save" id="user-form">
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:name]} label="Name" />
  <.input field={@form[:bio]} type="textarea" label="Bio" />
  
  <:actions>
    <.button>Save</.button>
  </:actions>
</.form>
```

**Complete form pattern:**

```elixir
# LiveView
def render(assigns) do
  ~H"""
  <.form for={@form} phx-submit="save" id="user-form">
    <.input field={@form[:email]} label="Email" required />
    <.input field={@form[:password]} type="password" label="Password" required />
    <.button>Submit</.button>
  </.form>
  """
end

def mount(_params, _session, socket) do
  changeset = Accounts.change_user(%User{})
  {:ok, assign(socket, form: to_form(changeset))}
end

def handle_event("save", %{"user" => user_params}, socket) do
  case Accounts.create_user(user_params) do
    {:ok, user} ->
      {:noreply, push_navigate(socket, to: ~p"/users/#{user}")}
    {:error, changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

---

## DOM IDs: Always Add for Testing

**ALWAYS add unique DOM IDs to key elements:**

```heex
<%!-- ✅ GOOD - IDs for testing --%>
<.form for={@form} phx-submit="save" id="product-form">
  <.input field={@form[:name]} label="Name" id="product-name-input" />
  <.button id="product-submit-button">Save Product</.button>
</.form>

<div id="product-list">
  <%= for product <- @products do %>
    <div id={"product-#{product.id}"}>
      <span>{product.name}</span>
      <button phx-click="delete" phx-value-id={product.id} id={"delete-product-#{product.id}"}>
        Delete
      </button>
    </div>
  <% end %>
</div>

<%!-- ❌ BAD - no IDs make testing difficult --%>
<.form for={@form} phx-submit="save">
  <.input field={@form[:name]} label="Name" />
  <.button>Save</.button>
</.form>
```

**Why IDs matter:**

```elixir
# In tests - IDs make element selection reliable
test "deletes product", %{conn: conn} do
  product = insert(:product)
  {:ok, view, _html} = live(conn, ~p"/products")
  
  # ✅ Easy with IDs
  view
  |> element("#delete-product-#{product.id}")
  |> render_click()
  
  refute has_element?(view, "#product-#{product.id}")
end
```

---

## Template Imports: html_helpers Block

**For app-wide imports, use the `html_helpers` block in `my_app_web.ex`:**

```elixir
# lib/my_app_web.ex
defmodule MyAppWeb do
  def html_helpers do
    quote do
      # HTML escaping and rendering
      import Phoenix.HTML
      
      # Core components (forms, buttons, etc.)
      import MyAppWeb.CoreComponents
      
      # Shortcut for generating routes
      use Phoenix.VerifiedRoutes,
        endpoint: MyAppWeb.Endpoint,
        router: MyAppWeb.Router
      
      # ✅ Add your custom imports here
      import MyAppWeb.FormHelpers
      import MyAppWeb.IconHelpers
      alias MyAppWeb.CustomComponents
      
      # Any function imported here is available in ALL:
      # - LiveViews
      # - LiveComponents  
      # - Any module using `use MyAppWeb, :html`
    end
  end
  
  def html do
    quote do
      use Phoenix.Component
      unquote(html_helpers())
    end
  end
end
```

**Usage in LiveView:**

```elixir
defmodule MyAppWeb.ProductLive.Index do
  use MyAppWeb, :live_view
  # Now has access to everything in html_helpers()
  
  def render(assigns) do
    ~H"""
    <%!-- Can use imported helpers without explicit import --%>
    <.custom_component />
    <CustomComponents.special_button />
    """
  end
end
```

---

## Conditionals: No else if in Elixir

**CRITICAL: Elixir has NO `else if` or `elsif` syntax:**

```heex
<%!-- ❌ INVALID - else if doesn't exist --%>
<%= if @status == :pending do %>
  <p>Pending...</p>
<% else if @status == :processing %>
  <p>Processing...</p>
<% else %>
  <p>Complete</p>
<% end %>

<%!-- ✅ CORRECT - use cond --%>
<%= cond do %>
  <% @status == :pending -> %>
    <p>Pending...</p>
  <% @status == :processing -> %>
    <p>Processing...</p>
  <% @status == :completed -> %>
    <p>Complete</p>
  <% true -> %>
    <p>Unknown status</p>
<% end %>

<%!-- ✅ ALSO CORRECT - use case --%>
<%= case @status do %>
  <% :pending -> %>
    <p>Pending...</p>
  <% :processing -> %>
    <p>Processing...</p>
  <% :completed -> %>
    <p>Complete</p>
  <% _ -> %>
    <p>Unknown status</p>
<% end %>
```

**Pattern matching in case:**

```heex
<%= case @result do %>
  <% {:ok, data} -> %>
    <div>Success: {data.message}</div>
  
  <% {:error, :not_found} -> %>
    <div>Item not found</div>
  
  <% {:error, reason} -> %>
    <div>Error: {inspect(reason)}</div>
<% end %>
```

**When to use each:**

- **`if/else`**: Binary choice (2 branches)
- **`cond`**: Multiple conditions (like if/else if chain)
- **`case`**: Pattern matching on a value

---

## Curly Braces in Code Blocks

**Use `phx-no-curly-interpolation` for literal curly braces:**

```heex
<%!-- ❌ WRONG - HEEx tries to interpret {key: "val"} as Elixir --%>
<code>
  let obj = {key: "val"}
</code>

<%!-- ✅ CORRECT - disable curly interpolation --%>
<code phx-no-curly-interpolation>
  let obj = {key: "val"}
  function example() {
    return {success: true};
  }
</code>

<%!-- You can still use <%= %> inside phx-no-curly-interpolation --%>
<pre phx-no-curly-interpolation>
  const example = {
    name: "<%= @dynamic_value %>",
    count: 42
  }
</pre>
```

**Common use cases:**

```heex
<%!-- JavaScript code examples --%>
<code phx-no-curly-interpolation>
  const config = {
    apiKey: "xxx",
    timeout: 5000
  };
</code>

<%!-- JSON examples --%>
<pre phx-no-curly-interpolation>
  {
    "user": {
      "name": "Alice",
      "id": 123
    }
  }
</pre>

<%!-- CSS with media queries --%>
<style phx-no-curly-interpolation>
  @media (max-width: 768px) {
    .container { padding: 1rem; }
  }
</style>
```

---

## Class Attributes: Always Use List Syntax

**ALWAYS use list `[...]` syntax for class attributes:**

```heex
<%!-- ✅ CORRECT - list syntax with multiple classes --%>
<a class={[
  "px-2 text-white",
  @active && "bg-blue-500",
  if(@highlighted, do: "border-red-500", else: "border-blue-100"),
  @disabled && "opacity-50 cursor-not-allowed"
]}>
  Link Text
</a>

<%!-- ✅ CORRECT - wrap if in parens --%>
<button class={[
  "btn",
  if(@primary, do: "btn-primary", else: "btn-secondary")
]}>
  Click Me
</button>

<%!-- ❌ WRONG - missing list brackets, causes syntax error --%>
<a class={
  "px-2 text-white",
  @some_flag && "py-5"
}>
  Text
</a>

<%!-- ❌ WRONG - if without parens in class list --%>
<div class={[
  "base-class",
  if @condition do "extra-class" else "other-class" end
]}>
</div>
```

**Dynamic class patterns:**

```heex
<%!-- Conditional classes --%>
<div class={[
  "card",
  @selected && "ring-2 ring-blue-500",
  @disabled && "opacity-50",
  !@enabled && "hidden"
]}>
  Content
</div>

<%!-- Combining static and dynamic --%>
<span class={[
  "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium",
  case @status do
    :active -> "bg-green-100 text-green-800"
    :inactive -> "bg-gray-100 text-gray-800"
    :error -> "bg-red-100 text-red-800"
  end
]}>
  {@status}
</span>

<%!-- Multiple conditions --%>
<article class={[
  "prose",
  @large && "prose-lg",
  @dark_mode && "prose-invert",
  @centered && "mx-auto"
]}>
  Content
</article>
```

---

## Template Iteration: Always Use for

**NEVER use `Enum.each` in templates. ALWAYS use `for` comprehension:**

```heex
<%!-- ❌ WRONG - Enum.each doesn't render in templates --%>
<% Enum.each(@items, fn item -> %>
  <div>{item.name}</div>
<% end) %>

<%!-- ✅ CORRECT - for comprehension --%>
<%= for item <- @items do %>
  <div>{item.name}</div>
<% end %>

<%!-- ✅ With index --%>
<%= for {item, index} <- Enum.with_index(@items) do %>
  <div class="item-{index}">
    {index + 1}. {item.name}
  </div>
<% end %>

<%!-- ✅ With filtering --%>
<%= for item <- @items, item.published do %>
  <div>{item.title}</div>
<% end %>

<%!-- ✅ Nested loops --%>
<%= for category <- @categories do %>
  <div class="category">
    <h3>{category.name}</h3>
    <%= for product <- category.products do %>
      <div class="product">{product.name}</div>
    <% end %>
  </div>
<% end %>
```

**Why `for` not `Enum.each`?**
- `for` returns the generated HTML
- `Enum.each` returns `:ok` (nothing renders)
- Templates need return values to build the HTML

---

## HTML Comments: Use HEEx Syntax

**ALWAYS use HEEx HTML comment syntax `<%!-- comment --%>`:**

```heex
<%!-- ✅ CORRECT - HEEx comments --%>
<%!-- This is a comment that won't appear in rendered HTML --%>
<div>Content</div>

<%!-- 
Multi-line comment
Can span multiple lines
--%>

<%!-- ❌ WRONG - regular HTML comments appear in output --%>
<!-- This appears in the rendered HTML source -->
<div>Content</div>

<%!-- Note: HTML comments are visible in page source,
     HEEx comments are completely removed during compilation --%>
```

**When to use each:**

```heex
<%!-- Developer notes - use HEEx comments --%>
<%!-- TODO: Refactor this section --%>
<%!-- NOTE: This component expects @user to be preloaded --%>

<!-- User-visible HTML comments - rarely needed -->
<!-- IE conditional comments or special browser instructions -->
```

---

## Interpolation Syntax: {} vs <%= %>

### CRITICAL Rules for Interpolation

**1. Tag attributes: ALWAYS use `{...}`**
**2. Tag body values: ALWAYS use `{...}`**
**3. Tag body blocks: ALWAYS use `<%= ... %>`**

```heex
<%!-- ✅ CORRECT interpolation --%>
<div id={@id} class={@class_name}>
  <%!-- Simple values in body: use {...} --%>
  {@name}
  {length(@items)}
  
  <%!-- Blocks in body: use <%= ... %> --%>
  <%= if @show_message do %>
    <p>Message here</p>
  <% end %>
  
  <%= for item <- @items do %>
    <div>{item.name}</div>
  <% end %>
  
  <%= case @status do %>
    <% :active -> %><span>Active</span>
    <% :inactive -> %><span>Inactive</span>
  <% end %>
</div>

<%!-- ❌ WRONG - <%= %> in attributes causes syntax error --%>
<div id="<%= @invalid_interpolation %>">
  Content
</div>

<%!-- ❌ WRONG - {...} for blocks causes syntax error --%>
<div>
  {if @condition do}
    <p>Content</p>
  {end}
</div>
```

### Complete Examples

**Simple values:**
```heex
<div>
  <%!-- ✅ All of these work --%>
  {@user.name}
  {String.upcase(@title)}
  {Enum.count(@items)}
  {@count + 1}
</div>
```

**Block constructs:**
```heex
<div>
  <%!-- ✅ Conditionals --%>
  <%= if @authenticated do %>
    <p>Welcome!</p>
  <% else %>
    <p>Please log in</p>
  <% end %>
  
  <%!-- ✅ Loops --%>
  <%= for user <- @users do %>
    <p>{user.email}</p>
  <% end %>
  
  <%!-- ✅ Case statements --%>
  <%= case @role do %>
    <% :admin -> %>
      <button>Admin Panel</button>
    <% :user -> %>
      <button>Dashboard</button>
    <% _ -> %>
      <button>Home</button>
  <% end %>
</div>
```

**Attributes:**
```heex
<%!-- ✅ All attribute interpolation uses {...} --%>
<div
  id={@dom_id}
  class={@css_classes}
  data-value={@data_value}
  phx-click={@click_handler}
  aria-label={@label}
>
  Content
</div>
```

---

## Quick Reference

### Form Building Checklist
- ✅ Use `<.form>` from Phoenix.Component
- ✅ Use `to_form/2` to wrap changesets
- ✅ Access fields with bracket syntax: `@form[:field]`
- ✅ Use `<.inputs_for>` for nested forms
- ❌ Never use deprecated `form_for` or `inputs_for`

### Template Syntax Checklist
- ✅ Use `~H` sigil or `.html.heex` files
- ✅ Add DOM IDs to all testable elements
- ✅ Import helpers in `html_helpers` block
- ❌ Never use `~E` sigil
- ❌ Never use `else if` (use `cond` or `case`)

### HEEx Features Checklist
- ✅ Use `phx-no-curly-interpolation` for code blocks with `{}`
- ✅ Use list syntax `[...]` for class attributes
- ✅ Wrap `if` in parens inside class lists
- ✅ Use `for` comprehensions for iteration
- ✅ Use `<%!-- --%>` for HEEx comments
- ❌ Never use `Enum.each` in templates

### Interpolation Checklist
- ✅ Attributes: use `{@value}`
- ✅ Body values: use `{@value}`
- ✅ Body blocks: use `<%= if/for/case %>`
- ❌ Never use `<%= %>` in attributes
- ❌ Never use `{...}` for block constructs

---

## Integration with CLAUDE.md

Check CLAUDE.md for:
- Project-specific component conventions
- Custom form components and helpers
- CSS framework usage (Tailwind, etc.)
- Testing ID naming patterns
- Template organization preferences

---

## Summary

**Modern Phoenix templates use:**
1. **HEEx** (`~H` sigil or `.html.heex`) - never `~E`
2. **`<.form>` and `to_form/2`** - never `form_for`
3. **`cond` or `case`** for multiple conditions - no `else if`
4. **`{...}` in attributes** and for values
5. **`<%= ... %>` for blocks** (if, for, case)
6. **`for` comprehensions** - never `Enum.each`
7. **List syntax for classes** - always `[...]`
8. **DOM IDs everywhere** - for testing
9. **`<%!-- --%>` for comments** - HEEx syntax

**Remember:** HEEx is strict about syntax. Follow these patterns exactly to avoid compilation errors.
