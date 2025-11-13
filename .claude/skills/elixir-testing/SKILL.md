---
name: elixir-testing
description: ExUnit testing patterns for Elixir/Phoenix. Use when writing tests for contexts, LiveViews, GenServers, or any Elixir code.
version: 1.0.0
---

# Elixir Testing Strategy

Comprehensive guide to writing thorough, maintainable test suites with ExUnit.

## Core Principles

1. **Test behavior, not implementation**: Focus on what code does, not how
2. **One assertion per test**: Each test should verify one specific behavior
3. **AAA pattern**: Arrange → Act → Assert
4. **Isolation**: Tests should not depend on each other
5. **Fast feedback**: Keep tests fast with `async: true` when possible

## Test Structure

### Basic Template
```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase, async: true

  alias MyApp.Accounts

  describe "create_user/1" do
    test "creates user with valid attributes" do
      # Arrange
      attrs = %{email: "test@example.com", password: "secure123"}

      # Act
      assert {:ok, user} = Accounts.create_user(attrs)

      # Assert
      assert user.email == "test@example.com"
      assert user.hashed_password
      refute user.password
    end

    test "returns error with invalid email format" do
      attrs = %{email: "invalid", password: "secure123"}

      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "has invalid format" in errors_on(changeset).email
    end
  end
end
```

### Using `describe` Blocks

Group related tests:
```elixir
describe "list_users/0" do
  test "returns all users" do
    # test implementation
  end

  test "returns empty list when no users" do
    # test implementation
  end
end

describe "get_user/1" do
  test "returns user when exists" do
    # test implementation
  end

  test "returns error when not found" do
    # test implementation
  end
end
```

## Context Testing
```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase, async: true

  alias MyApp.Accounts

  describe "list_users/0" do
    test "returns all users" do
      user1 = insert(:user)
      user2 = insert(:user)

      users = Accounts.list_users()

      assert length(users) == 2
      assert user1 in users
      assert user2 in users
    end
  end

  describe "update_user/2" do
    test "updates user with valid attrs" do
      user = insert(:user, email: "old@example.com")

      assert {:ok, updated} = Accounts.update_user(user, %{email: "new@example.com"})
      assert updated.email == "new@example.com"
    end

    test "returns error with invalid attrs" do
      user = insert(:user)

      assert {:error, changeset} = Accounts.update_user(user, %{email: "invalid"})
      assert "has invalid format" in errors_on(changeset).email
    end
  end
end
```

## LiveView Testing
```elixir
defmodule MyAppWeb.UserLive.IndexTest do
  use MyAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    test "displays users", %{conn: conn} do
      user = insert(:user, email: "test@example.com")

      {:ok, view, _html} = live(conn, ~p"/users")

      assert has_element?(view, "#user-#{user.id}")
      assert render(view) =~ "test@example.com"
    end

    test "deletes user on button click", %{conn: conn} do
      user = insert(:user)

      {:ok, view, _html} = live(conn, ~p"/users")

      view
      |> element("#user-#{user.id} button[phx-click='delete']")
      |> render_click()

      refute has_element?(view, "#user-#{user.id}")
    end

    test "navigates to edit page", %{conn: conn} do
      user = insert(:user)

      {:ok, view, _html} = live(conn, ~p"/users")

      {:ok, _, html} =
        view
        |> element("#user-#{user.id} a", "Edit")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Edit User"
    end
  end
end
```

### LiveView Form Testing
```elixir
test "validates form on change", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/users/new")

  # Submit invalid form
  view
  |> form("#user-form", user: %{email: "invalid"})
  |> render_change()

  assert render(view) =~ "has invalid format"
end

test "creates user on form submit", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/users/new")

  {:ok, _, html} =
    view
    |> form("#user-form", user: %{email: "test@example.com", password: "secure123"})
    |> render_submit()
    |> follow_redirect(conn)

  assert html =~ "User created successfully"
end
```

## GenServer Testing
```elixir
defmodule MyApp.JobProcessorTest do
  use ExUnit.Case, async: true

  alias MyApp.JobProcessor

  setup do
    {:ok, pid} = JobProcessor.start_link(max_concurrent: 2)
    %{processor: pid}
  end

  test "processes job", %{processor: pid} do
    job = %{id: "123", type: :email}

    JobProcessor.add_job(pid, job)

    assert_receive {:job_completed, "123"}, 1000
  end

  test "processes multiple jobs in parallel", %{processor: pid} do
    jobs = [
      %{id: "1", type: :email},
      %{id: "2", type: :email}
    ]

    for job <- jobs do
      JobProcessor.add_job(pid, job)
    end

    assert_receive {:job_completed, "1"}, 1000
    assert_receive {:job_completed, "2"}, 1000
  end

  test "respects max concurrent limit", %{processor: pid} do
    # Add 3 jobs (limit is 2)
    for id <- 1..3 do
      JobProcessor.add_job(pid, %{id: to_string(id), type: :slow})
    end

    state = :sys.get_state(pid)
    assert MapSet.size(state.processing) == 2
    assert length(state.queue) == 1
  end
end
```

## Test Helpers and Factories

### Using ExMachina
```elixir
# test/support/factory.ex
defmodule MyApp.Factory do
  use ExMachina.Ecto, repo: MyApp.Repo

  def user_factory do
    %MyApp.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      hashed_password: Bcrypt.hash_pwd_salt("password123"),
      role: :user
    }
  end

  def admin_factory do
    struct!(
      user_factory(),
      %{role: :admin}
    )
  end

  def post_factory do
    %MyApp.Content.Post{
      title: "Test Post",
      body: "Test content",
      user: build(:user)
    }
  end
end

# In tests
user = insert(:user)
admin = insert(:admin, email: "admin@example.com")
posts = insert_list(3, :post)
```

### Custom Test Helpers
```elixir
# test/support/conn_case.ex
defmodule MyAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import MyAppWeb.ConnCase

      alias MyAppWeb.Router.Helpers, as: Routes
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def log_in_user(conn, user) do
    token = MyApp.Accounts.generate_user_session_token(user)
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end

# Usage in tests
test "requires authentication", %{conn: conn} do
  conn = get(conn, ~p"/dashboard")
  assert redirected_to(conn) == ~p"/login"
end

test "shows dashboard when logged in", %{conn: conn} do
  user = insert(:user)
  conn = log_in_user(conn, user)

  conn = get(conn, ~p"/dashboard")
  assert html_response(conn, 200) =~ "Dashboard"
end
```

## Async vs Sync Tests
```elixir
# Async: Database sandbox isolates each test
defmodule MyApp.AccountsTest do
  use MyApp.DataCase, async: true  # ← Safe for database tests
end

# Sync: Shared state or external services
defmodule MyApp.EmailTest do
  use ExUnit.Case  # ← Not async (mocking external service)

  import Mox

  setup :verify_on_exit!
end
```

## Mocking with Mox
```elixir
# Define behavior
defmodule MyApp.EmailService do
  @callback send_email(String.t(), map()) :: :ok | {:error, term()}
end

# In config/test.exs
config :my_app, :email_service, MyApp.EmailServiceMock

# In test
defmodule MyApp.NotifierTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  test "sends welcome email" do
    expect(MyApp.EmailServiceMock, :send_email, fn email, _opts ->
      assert email == "test@example.com"
      :ok
    end)

    MyApp.Notifier.send_welcome_email("test@example.com")
  end
end
```

## Coverage and Quality

### Running Tests
```bash
# All tests
mix test

# Specific file
mix test test/my_app/accounts_test.exs

# Specific line
mix test test/my_app/accounts_test.exs:23

# With coverage
mix test --cover

# Watch mode (with mix_test_watch)
mix test.watch
```

### Test Tags
```elixir
@tag :slow
test "expensive operation" do
  # ...
end

@tag :external
test "calls third-party API" do
  # ...
end

# Run only tagged tests
# mix test --only slow
# mix test --exclude external
```

## Common Patterns

### Testing Error Cases
```elixir
test "handles not found error" do
  assert {:error, :not_found} = Accounts.get_user(99999)
end

test "handles validation errors" do
  assert {:error, changeset} = Accounts.create_user(%{})
  assert %{email: ["can't be blank"]} = errors_on(changeset)
end
```

### Testing Side Effects
```elixir
test "sends notification on user creation" do
  # Use process mailbox
  attrs = %{email: "test@example.com", password: "secure123"}

  assert {:ok, user} = Accounts.create_user(attrs)

  assert_receive {:notification_sent, ^user}, 1000
end
```

### Testing Time-Dependent Code
```elixir
test "expires after timeout" do
  {:ok, session} = Session.create(%{user_id: 1})

  # Fast-forward time
  :timer.sleep(100)

  assert Session.expired?(session)
end
```

## Integration with CLAUDE.md

Check CLAUDE.md for:
- Factory conventions
- Test helper patterns
- Mocking strategies
- Coverage requirements
- Test organization
