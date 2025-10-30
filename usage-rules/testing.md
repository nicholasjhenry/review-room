# Elixir Test Guidelines

## Mandatory Testing
- All code **MUST** be tested. Do not write production code without writing tests.

## Test Structure Template
Use this exact template for all ExUnit tests:

```elixir
describe "when [USE_CASE_AS_A_GERUND]" do
  test "given [INITIAL_STATE] then [EXPECTED_STATE]" do
    # Add test code
  end
end
```

## Examples

### ✅ Good
```elixir
describe "when enqueuing a job" do
  test "given valid params then job is queued" do
    assert {:ok, job} = JobQueue.enqueue(%{type: "email", data: %{}})
    assert job.status == :queued
  end

  test "given invalid params then error is returned" do
    assert {:error, :invalid_params} = JobQueue.enqueue(%{})
  end
end

describe "when processing a payment" do
  test "given sufficient balance then payment succeeds" do
    account = insert(:account, balance: 100)
    assert {:ok, payment} = Payments.process(account, amount: 50)
    assert payment.status == :completed
  end
end
```

### ❌ Bad
```elixir
test "enqueue/2 works correctly" do
  # Don't use function names
end

test "processes payment" do
  # Missing context: when/given/then structure
end

@doc """
Tests the enqueue/2 function
"""
test "enqueue test" do
  # Don't use docstrings with function names
end
```

## Test Docstrings
- Do NOT write docstrings for tests using function names (e.g., `enqueue/2`, `User.create/1`)
- Test names should be self-documenting following the template above
- If you need to add context, use inline comments within the test body

## Test Organization
- Group related tests using `describe` blocks
- Each `describe` should represent a specific behavior or use case
- Use present participle (gerund) for describe blocks: "when creating", "when validating", "when processing"
