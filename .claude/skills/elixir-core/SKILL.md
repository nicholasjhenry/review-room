---
name: elixir-core-patterns
description: Elixir language fundamentals, idioms, and best practices. Use when writing Elixir code, pattern matching, error handling, function design, or working with data structures and standard library.
version: 1.0.0

---

# Elixir Core Patterns and Best Practices

Essential patterns and idioms for writing idiomatic Elixir code.

---

## Pattern Matching

Pattern matching is a core feature of Elixir. Use it extensively.

### Prefer Pattern Matching Over Conditionals

**✅ Good - Pattern match in function heads:**

```elixir
def process_result({:ok, data}), do: transform(data)
def process_result({:error, reason}), do: log_error(reason)

def calculate_price(%{discount: discount} = item) when discount > 0 do
  item.price * (1 - discount)
end
def calculate_price(%{price: price}), do: price
```

**❌ Avoid - Conditional logic in function body:**

```elixir
def process_result(result) do
  if elem(result, 0) == :ok do
    transform(elem(result, 1))
  else
    log_error(elem(result, 1))
  end
end
```

### Critical: Empty Map Matching

**`%{}` matches ANY map, not just empty maps:**

```elixir
# ❌ Wrong - this matches ALL maps
def handle_data(%{}) do
  "empty map"
end
def handle_data(map) do
  "map with data"
end

# ✅ Correct - use guard to check for truly empty maps
def handle_data(map) when map_size(map) == 0 do
  "empty map"
end
def handle_data(map) do
  "map with data"
end
```

---

## Error Handling

Elixir uses tagged tuples for error handling, not exceptions.

### Standard Error Tuple Pattern

**Always use `{:ok, result}` and `{:error, reason}` for operations that can fail:**

```elixir
@spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()
end

@spec fetch_data(id :: integer()) :: {:ok, map()} | {:error, :not_found | :timeout}
def fetch_data(id) do
  case HTTPClient.get("/api/data/#{id}") do
    {:ok, %{status: 200, body: body}} -> {:ok, body}
    {:ok, %{status: 404}} -> {:error, :not_found}
    {:error, _} -> {:error, :timeout}
  end
end
```

### Avoid Raising Exceptions for Control Flow

**✅ Good - Return error tuples:**

```elixir
def divide(a, b) when b == 0, do: {:error, :division_by_zero}
def divide(a, b), do: {:ok, a / b}
```

**❌ Avoid - Raising exceptions for expected errors:**

```elixir
def divide(a, 0), do: raise(ArithmeticError, "division by zero")
def divide(a, b), do: a / b
```

**Note:** Exceptions are for truly exceptional circumstances (bugs, configuration errors, system failures).

### Use `with` for Chaining Operations

**✅ Good - `with` for multiple operations:**

```elixir
def create_order(user_id, items) do
  with {:ok, user} <- get_user(user_id),
       {:ok, validated_items} <- validate_items(items),
       {:ok, order} <- insert_order(user, validated_items),
       {:ok, _email} <- send_confirmation(user, order) do
    {:ok, order}
  else
    {:error, :not_found} -> {:error, "User not found"}
    {:error, :invalid_items} -> {:error, "Invalid items"}
    {:error, reason} -> {:error, reason}
  end
end
```

**❌ Avoid - Nested case statements:**

```elixir
def create_order(user_id, items) do
  case get_user(user_id) do
    {:ok, user} ->
      case validate_items(items) do
        {:ok, validated_items} ->
          case insert_order(user, validated_items) do
            {:ok, order} -> {:ok, order}
            {:error, reason} -> {:error, reason}
          end
        {:error, reason} -> {:error, reason}
      end
    {:error, reason} -> {:error, reason}
  end
end
```

---

## Common Mistakes to Avoid

### No Return Statement

**Elixir has no `return` keyword. The last expression is always returned:**

```elixir
# ❌ Wrong - `return` doesn't exist
def calculate(x) do
  if x > 0 do
    return x * 2  # Error: undefined function return/1
  end
  0
end

# ✅ Correct - last expression is returned
def calculate(x) do
  if x > 0 do
    x * 2  # This value is returned
  else
    0      # Or this value is returned
  end
end

# ✅ Better - pattern matching
def calculate(x) when x > 0, do: x * 2
def calculate(_x), do: 0
```

### Enum vs Stream

**Use `Stream` for large collections or infinite sequences:**

```elixir
# ❌ Inefficient - builds intermediate lists
File.stream!("large_file.txt")
|> Enum.map(&String.upcase/1)
|> Enum.filter(&String.contains?(&1, "ERROR"))
|> Enum.take(10)

# ✅ Efficient - lazy evaluation
File.stream!("large_file.txt")
|> Stream.map(&String.upcase/1)
|> Stream.filter(&String.contains?(&1, "ERROR"))
|> Enum.take(10)  # Only materializes when needed
```

### Avoid Nested Case Statements

**Refactor to `with`, single `case`, or separate functions:**

```elixir
# ❌ Avoid - nested case
def process(data) do
  case parse(data) do
    {:ok, parsed} ->
      case validate(parsed) do
        {:ok, valid} ->
          case save(valid) do
            {:ok, saved} -> {:ok, saved}
            error -> error
          end
        error -> error
      end
    error -> error
  end
end

# ✅ Good - use with
def process(data) do
  with {:ok, parsed} <- parse(data),
       {:ok, valid} <- validate(parsed),
       {:ok, saved} <- save(valid) do
    {:ok, saved}
  end
end
```

### Never Convert User Input to Atoms

**Atoms are not garbage collected - memory leak risk:**

```elixir
# ❌ DANGEROUS - user input to atom
def set_status(user_provided_status) do
  String.to_atom(user_provided_status)  # Memory leak!
end

# ✅ Safe - use String.to_existing_atom/1 with known values
def set_status(status) when status in ~w(active inactive pending) do
  String.to_existing_atom(status)  # Only converts if atom already exists
end
def set_status(_), do: {:error, :invalid_status}

# ✅ Better - pattern match on strings
def set_status("active"), do: :active
def set_status("inactive"), do: :inactive
def set_status("pending"), do: :pending
def set_status(_), do: {:error, :invalid_status}
```

### Lists Cannot Be Indexed with Brackets

**CRITICAL: Elixir lists do not support index-based access via bracket syntax.**

```elixir
# ❌ INVALID - bracket access doesn't work on lists
i = 0
mylist = ["blue", "green"]
mylist[i]  # Error: lists don't implement the Access protocol

# ✅ Correct - use Enum.at
i = 0
mylist = ["blue", "green"]
Enum.at(mylist, i)  # Returns "blue"

# ✅ Correct - pattern matching
[first | _rest] = mylist  # first = "blue"

# ✅ Correct - List module functions
List.first(mylist)  # Returns "blue"
List.last(mylist)   # Returns "green"

# ✅ Correct - Enum.fetch returns {:ok, value} or :error
case Enum.fetch(mylist, i) do
  {:ok, value} -> value
  :error -> nil
end
```

### Variable Rebinding in Block Expressions

**Variables are immutable but can be rebound. You MUST bind the result of block expressions:**

```elixir
# ❌ INVALID - rebinding inside if, result never assigned
socket = initial_socket()

if connected?(socket) do
  socket = assign(socket, :val, val)  # This rebinding is lost!
end

# socket still has old value here - the assignment inside if was discarded

# ✅ CORRECT - bind the result of the if expression
socket = initial_socket()

socket =
  if connected?(socket) do
    assign(socket, :val, val)
  else
    socket
  end

# socket now has the updated value

# This applies to all block expressions:
# ❌ INVALID - case rebinding lost
case result do
  {:ok, data} -> data = transform(data)
  _ -> data = []
end

# ✅ CORRECT - bind case result
data =
  case result do
    {:ok, d} -> transform(d)
    _ -> []
  end

# ❌ INVALID - cond rebinding lost
cond do
  x > 0 -> value = x * 2
  true -> value = 0
end

# ✅ CORRECT - bind cond result
value =
  cond do
    x > 0 -> x * 2
    true -> 0
  end
```

**Key principle:** The last expression in a block is its return value. If you want to use it, bind it to a variable.

### Prefer Enum Functions Over Manual Recursion

**Use standard library functions when available:**

```elixir
# ❌ Unnecessary recursion
def sum_list([]), do: 0
def sum_list([head | tail]), do: head + sum_list(tail)

# ✅ Better - use Enum
def sum_list(list), do: Enum.sum(list)

# Another example
# ❌ Manual recursion
def filter_even([]), do: []
def filter_even([head | tail]) when rem(head, 2) == 0 do
  [head | filter_even(tail)]
end
def filter_even([_head | tail]), do: filter_even(tail)

# ✅ Better - use Enum
def filter_even(list), do: Enum.filter(list, &(rem(&1, 2) == 0))
```

**When recursion IS necessary, use pattern matching for base cases:**

```elixir
# ✅ Good - recursive with pattern matching
def flatten([]), do: []
def flatten([head | tail]) when is_list(head) do
  flatten(head) ++ flatten(tail)
end
def flatten([head | tail]) do
  [head | flatten(tail)]
end
```

### Avoid Process Dictionary

**The process dictionary is typically a sign of unidiomatic code:**

```elixir
# ❌ Avoid - process dictionary
def bad_counter do
  count = Process.get(:count, 0)
  Process.put(:count, count + 1)
  count
end

# ✅ Better - use GenServer or Agent for state
defmodule Counter do
  use Agent

  def start_link(initial \\ 0) do
    Agent.start_link(fn -> initial end, name: __MODULE__)
  end

  def increment do
    Agent.get_and_update(__MODULE__, fn count -> {count, count + 1} end)
  end
end
```

### Only Use Macros When Explicitly Requested

**Macros are powerful but complex. Avoid unless necessary:**

```elixir
# ❌ Unnecessary macro
defmacro double(x) do
  quote do
    unquote(x) * 2
  end
end

# ✅ Better - simple function
def double(x), do: x * 2
```

**Valid macro use cases:**

- DSLs (like Ecto queries, Phoenix routes)
- Code generation at compile time
- When explicitly requested by user

---

## Function Design

### Use Guard Clauses

**Guards make code clearer and catch errors early:**

```elixir
def calculate_discount(price, percent) 
    when is_number(price) and is_number(percent) 
    and price > 0 and percent >= 0 and percent <= 100 do
  price * (percent / 100)
end
```

**Common guards:**

- `is_atom/1`, `is_binary/1`, `is_boolean/1`, `is_integer/1`, `is_float/1`
- `is_list/1`, `is_map/1`, `is_tuple/1`
- `is_nil/1`, `is_number/1`
- `byte_size/1`, `map_size/1`, `tuple_size/1`
- `in/2` for membership checks

### Multiple Function Clauses Over Complex Conditionals

```elixir
# ✅ Good - multiple clauses
def status_message(:pending), do: "Your order is pending"
def status_message(:processing), do: "We're processing your order"
def status_message(:shipped), do: "Your order has shipped"
def status_message(:delivered), do: "Your order was delivered"
def status_message(_), do: "Unknown status"

# ❌ Avoid - complex conditional
def status_message(status) do
  cond do
    status == :pending -> "Your order is pending"
    status == :processing -> "We're processing your order"
    status == :shipped -> "Your order has shipped"
    status == :delivered -> "Your order was delivered"
    true -> "Unknown status"
  end
end
```

### Descriptive Function Names

```elixir
# ✅ Good - descriptive names
def calculate_total_price(items, tax_rate)
def fetch_user_by_email(email)
def validate_credit_card(card_number)

# ❌ Avoid - cryptic abbreviations
def calc(i, t)
def get(e)
def chk(n)
```

### Predicate Function Naming

**Predicate functions should end with `?` and NOT start with `is`:**

```elixir
# ✅ Good - predicate functions
def valid?(user), do: user.age >= 18
def empty?(list), do: list == []
def admin?(user), do: user.role == :admin

# ❌ Avoid - `is_` prefix
def is_valid?(user), do: user.age >= 18

# ✅ Reserve `is_thing` for guards
defguard is_positive(num) when is_number(num) and num > 0
```

---

## Data Structures

### Use Structs for Known Shapes

**Structs provide compile-time guarantees:**

```elixir
# ✅ Good - struct for known shape
defmodule User do
  defstruct [:id, :name, :email, :role]
  
  @type t :: %__MODULE__{
    id: integer() | nil,
    name: String.t(),
    email: String.t(),
    role: :admin | :user
  }
end

user = %User{name: "Alice", email: "alice@example.com", role: :user}

# ❌ Wrong - using struct incorrectly
user = %User{invalid_field: "value"}  # Compile error - good!
```

### CRITICAL: Struct Field Access

**Never use map access syntax (`[]`) on structs - they don't implement Access by default:**

```elixir
user = %User{name: "Alice", email: "alice@example.com"}

# ❌ INVALID - bracket access doesn't work on structs
user_name = user[:name]  # Error: User struct doesn't implement Access

# ✅ CORRECT - use dot notation
user_name = user.name

# For Ecto changesets, use the API functions:
changeset = User.changeset(%User{}, attrs)

# ❌ INVALID - bracket access on changeset
email = changeset[:email]

# ✅ CORRECT - use Ecto.Changeset functions
email = Ecto.Changeset.get_field(changeset, :email)
email = Ecto.Changeset.get_change(changeset, :email)

# For pattern matching on structs
def process_user(%User{name: name, role: :admin}) do
  # Use pattern matching to extract fields
end
```

**Use maps for dynamic data:**

```elixir
# ✅ Good - map for dynamic data
config = %{
  "api_key" => key,
  "timeout" => 5000,
  "retries" => 3
}

# Maps DO support bracket access
timeout = config["timeout"]  # This works for maps
```

### Module Organization

**NEVER nest multiple modules in the same file - causes cyclic dependencies:**

```elixir
# ❌ INVALID - nested modules in same file
defmodule MyApp.Accounts do
  defmodule User do
    defstruct [:name, :email]
  end
  
  defmodule Session do
    defstruct [:token, :user_id]
  end
  
  def create_user(attrs), do: # ...
end

# ✅ CORRECT - separate files
# lib/my_app/accounts.ex
defmodule MyApp.Accounts do
  alias MyApp.Accounts.User
  alias MyApp.Accounts.Session
  
  def create_user(attrs), do: # ...
end

# lib/my_app/accounts/user.ex
defmodule MyApp.Accounts.User do
  defstruct [:name, :email]
end

# lib/my_app/accounts/session.ex
defmodule MyApp.Accounts.Session do
  defstruct [:token, :user_id]
end
```

**Why:** Nested modules can cause compilation order issues and make it harder to resolve cyclic dependencies.

### Keyword Lists for Options

**Keyword lists are the idiomatic way to pass options:**

```elixir
# ✅ Good - keyword list for options
def fetch_data(url, opts \\ []) do
  timeout = Keyword.get(opts, :timeout, 5000)
  retries = Keyword.get(opts, :retries, 3)
  # ...
end

fetch_data("http://api.example.com", timeout: 10_000, retries: 5)

# Also good - with defaults
def fetch_data(url, opts \\ [timeout: 5000, retries: 3]) do
  # ...
end
```

### List Operations: Prepend vs Append

**Prepending is O(1), appending is O(n):**

```elixir
# ✅ Efficient - prepend
def add_item(item, list), do: [item | list]

# ❌ Inefficient - append
def add_item(item, list), do: list ++ [item]

# If order doesn't matter, prepend then reverse at the end
defp build_list(items, acc \\ [])
defp build_list([], acc), do: Enum.reverse(acc)
defp build_list([item | rest], acc) do
  build_list(rest, [process(item) | acc])
end
```

---

## Standard Library and Dependencies

### Date and Time Handling

**Elixir's standard library has complete date/time manipulation capabilities:**

```elixir
# ✅ Use standard library - Date, Time, DateTime, Calendar modules
today = Date.utc_today()
now = DateTime.utc_now()
future = DateTime.add(now, 7, :day)

# Check module documentation
# Date - for dates without time
# Time - for time without date  
# DateTime - for date + time with timezone
# Calendar - for calendar operations
# NaiveDateTime - for date + time without timezone

# ❌ Avoid - unnecessary dependencies
# Don't add timex, calendar, or other date/time libraries

# ✅ Exception - parsing from strings
# If you need to parse date/time strings, you can use:
# date_time_parser package
```

**Examples:**

```elixir
# Working with dates
date = ~D[2024-01-15]
Date.add(date, 7)
Date.diff(date, ~D[2024-01-01])

# Working with time
time = ~T[14:30:00]
Time.add(time, 3600, :second)

# Working with datetime
datetime = DateTime.utc_now()
DateTime.shift_zone(datetime, "America/New_York")
```

---

## Concurrency Patterns

### Task.async_stream for Concurrent Enumeration

**Use `Task.async_stream/3` for concurrent processing with backpressure:**

```elixir
# ✅ Good - concurrent with backpressure
users
|> Task.async_stream(
  fn user -> fetch_user_data(user) end,
  timeout: :infinity,  # Usually want this!
  max_concurrency: 10
)
|> Enum.to_list()

# Why timeout: :infinity?
# The default timeout is 5000ms, which often causes tasks to fail
# Use :infinity unless you have a specific timeout requirement

# Other useful options:
users
|> Task.async_stream(
  &process_user/1,
  timeout: :infinity,
  max_concurrency: System.schedulers_online() * 2,
  ordered: false  # If order doesn't matter, get results as they complete
)
|> Stream.filter(fn
  {:ok, result} -> result != nil
  {:exit, _reason} -> false
end)
|> Enum.map(fn {:ok, result} -> result end)

# ❌ Avoid - Task.async without backpressure
# This can spawn thousands of processes
tasks =
  Enum.map(users, fn user ->
    Task.async(fn -> fetch_user_data(user) end)
  end)

Enum.map(tasks, &Task.await(&1, :infinity))
```

### OTP Process Naming

**OTP primitives like DynamicSupervisor and Registry require names in child specs:**

```elixir
# ✅ Correct - name in child spec
children = [
  {DynamicSupervisor, name: MyApp.JobSupervisor},
  {Registry, keys: :unique, name: MyApp.Registry}
]

opts = [strategy: :one_for_one, name: MyApp.Supervisor]
Supervisor.start_link(children, opts)

# Then use the name to interact with the process
DynamicSupervisor.start_child(MyApp.JobSupervisor, child_spec)
Registry.lookup(MyApp.Registry, key)

# ❌ Wrong - forgetting the name
children = [
  {DynamicSupervisor, []}  # Missing name!
]

# Won't be able to reference it later
```

**Registry pattern for dynamic process names:**

```elixir
# Start Registry
{Registry, keys: :unique, name: MyApp.Registry}

# Use via tuples for named processes
def start_link(user_id) do
  GenServer.start_link(__MODULE__, user_id, name: via_tuple(user_id))
end

defp via_tuple(user_id) do
  {:via, Registry, {MyApp.Registry, {:user_session, user_id}}}
end

# Look up processes
case Registry.lookup(MyApp.Registry, {:user_session, user_id}) do
  [{pid, _}] -> {:ok, pid}
  [] -> {:error, :not_found}
end
```

Mix is Elixir's build tool and task runner.

### Discovering Mix Tasks

```bash
# List all available tasks
mix help

# Get detailed help for a specific task
mix help test
mix help deps.get
mix help compile

# Always read full documentation before using a task
```

### Important: Read Task Documentation

Before using any Mix task:

1. Run `mix help task_name`
2. Read all available options
3. Understand what the task does
4. Check for any side effects (database changes, file modifications, etc.)

**Example:**

```bash
# Don't just run this blindly
mix ecto.reset

# First check what it does
mix help ecto.reset
# Shows: "Drops, creates and migrates the repository"
# Now you know it's destructive!
```

---

## Mix Tasks

Mix is Elixir's build tool and task runner.

### Discovering Mix Tasks

```bash
# List all available tasks
mix help

# Get detailed help for a specific task
mix help test
mix help deps.get
mix help compile

# Always read full documentation before using a task
```

### Important: Read Task Documentation

**Before using any Mix task:**

1. Run `mix help task_name`
2. Read all available options
3. Understand what the task does
4. Check for any side effects (database changes, file modifications, etc.)

**Example:**

```bash
# Don't just run this blindly
mix ecto.reset

# First check what it does
mix help ecto.reset
# Shows: "Drops, creates and migrates the repository"
# Now you know it's destructive!
```

### Dependency Management

**CRITICAL: `mix deps.clean --all` is almost never needed:**

```bash
# ❌ Avoid - rarely necessary and very slow
mix deps.clean --all

# ✅ Usually sufficient - recompile dependencies
mix deps.compile --force

# ✅ Or clean specific dependency
mix deps.clean some_dep

# ✅ Get dependencies
mix deps.get

# ✅ Update dependencies
mix deps.update --all
```

**When you might actually need `deps.clean --all`:**

- After changing Elixir/OTP versions
- When investigating truly bizarre compilation issues
- When explicitly instructed by library documentation

**Why avoid it?**

- Forces complete recompilation of all dependencies (very slow)
- Usually doesn't solve the actual problem
- Often used as "cargo cult" debugging

---

## Testing

### Running Tests

```bash
# All tests
mix test

# Specific file
mix test test/my_app/accounts_test.exs

# Specific test at line number
mix test test/my_app/accounts_test.exs:23

# Limit failed test output
mix test --max-failures 5

# DEBUGGING: Run only previously failed tests
mix test --failed

# Only show failed tests (hides passing tests)
mix test --only failed

# Run tests matching a pattern
mix test --only integration

# Verbose output
mix test --trace
```

**For debugging test failures:**

1. Run `mix test` to see which tests fail
2. Run `mix test --failed` to re-run only the failed tests
3. Run `mix test path/to/test.exs:line_number` to focus on specific test
4. Use `--trace` for detailed output

### Using Tags

```elixir
# In test file
@tag :integration
test "integration with external API" do
  # ...
end

@tag :slow
test "expensive operation" do
  # ...
end

# Run only tagged tests
# mix test --only integration
# mix test --exclude slow
```

### Testing Exceptions

**Use `assert_raise` for expected exceptions:**

```elixir
test "raises on invalid input" do
  assert_raise ArgumentError, fn ->
    invalid_function(nil)
  end
  
  # With message matching
  assert_raise ArgumentError, "must be positive", fn ->
    calculate_discount(-10)
  end
end
```

### Full Test Documentation

```bash
# Get comprehensive test documentation
mix help test
```

---

## Debugging

### Use `dbg/1` for Quick Debugging

**`dbg/1` is the modern debugging tool in Elixir:**

```elixir
# Prints formatted value and location
def process_data(data) do
  data
  |> parse()
  |> dbg()  # Prints value here with file:line info
  |> validate()
  |> dbg()  # Prints value here
  |> transform()
end

# Output shows:
# [my_file.ex:23: MyModule.process_data/1]
# %{parsed: true, data: [...]}
```

**Alternative debugging approaches:**

```elixir
# IO.inspect with label (older approach, still valid)
data
|> parse()
|> IO.inspect(label: "after parse")
|> validate()

# IEx helpers (in iex -S mix)
iex> h(Enum.map)  # Help for function
iex> i(%User{})   # Inspect data structure
```

---

## Quick Reference

### Pattern Matching Checklist

- ✅ Use function head pattern matching
- ✅ Use guards for constraints
- ✅ Remember `%{}` matches any map (use `map_size(map) == 0` for empty)
- ❌ Avoid deep nesting in case/if

### Error Handling Checklist

- ✅ Return `{:ok, result}` | `{:error, reason}`
- ✅ Use `with` for operation chains
- ❌ Don't raise exceptions for control flow

### Function Design Checklist

- ✅ Use descriptive names
- ✅ Predicates end with `?` (not `is_`)
- ✅ Multiple clauses > complex conditionals
- ✅ Guards for type/value constraints

### Data Structure Checklist

- ✅ Structs for known shapes
- ✅ Maps for dynamic data
- ✅ Keyword lists for options
- ✅ Prepend to lists, not append
- ✅ Use dot notation for struct field access
- ❌ Never use bracket syntax `[]` on structs

### Common Pitfalls Checklist

- ❌ No `return` statement exists
- ❌ Don't convert user input to atoms
- ❌ Lists can't be indexed with `[]`
- ❌ Structs can't use bracket syntax `[]`
- ❌ Avoid process dictionary
- ❌ Prefer `Enum` over manual recursion
- ❌ Don't nest modules in same file
- ❌ Bind results of block expressions (`if`, `case`, `cond`)

### Concurrency Checklist

- ✅ Use `Task.async_stream` with `timeout: :infinity` for concurrent enumeration
- ✅ Name OTP processes in child specs (DynamicSupervisor, Registry)
- ✅ Use Registry with via tuples for dynamic process names

### Mix Tasks Checklist

- ✅ Always run `mix help task_name` first
- ✅ Use `mix test --failed` for debugging test failures
- ❌ Avoid `mix deps.clean --all` (almost never needed)
- ✅ Use `mix deps.compile --force` instead

### Standard Library Checklist

- ✅ Use Date/Time/DateTime/Calendar for date/time operations
- ❌ Don't add unnecessary date/time dependencies
- ✅ Use `Enum.at` for list access by index
- ✅ Use `dbg/1` for debugging

---

## Integration with CLAUDE.md

Check CLAUDE.md for:

- Project-specific naming conventions
- Custom error tuple shapes beyond standard `{:ok, _}` | `{:error, _}`
- Team preferences for `Enum` vs `Stream` usage
- Project-specific guard patterns
- Testing tag conventions

---

## Summary

Write idiomatic Elixir by:

1. **Pattern matching** everywhere (especially function heads)
2. **Error tuples** not exceptions
3. **Multiple function clauses** over complex conditionals
4. **Descriptive names** for functions
5. **Standard library** over manual solutions
6. **Structs** for known data shapes
7. **Reading documentation** before using Mix tasks

Remember: Elixir values clarity, immutability, and functional patterns. When in doubt, check if there's a standard library function that already does what you need.
