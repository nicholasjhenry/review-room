# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ReviewRoom.Repo.insert!(%ReviewRoom.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ReviewRoom.Repo
alias ReviewRoom.Accounts.User
alias ReviewRoom.Snippets.Snippet

# Create demo users
demo_user =
  Repo.insert!(%User{
    email: "demo@example.com",
    hashed_password: Bcrypt.hash_pwd_salt("password123"),
    confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
  })

# Create demo snippets with various visibility levels and tags
now = DateTime.utc_now() |> DateTime.truncate(:second)

demo_snippets = [
  %{
    title: "Elixir Pattern Matching",
    description: "Example of pattern matching in Elixir function heads",
    body: """
    def process_result({:ok, value}), do: value
    def process_result({:error, reason}), do: {:error, reason}
    def process_result(value), do: value
    """,
    syntax: "elixir",
    tags: ["elixir", "pattern-matching", "utility"],
    visibility: "personal",
    author_id: demo_user.id,
    buffer_token: Ecto.UUID.generate(),
    queued_at: now,
    persisted_at: now
  },
  %{
    title: "Phoenix LiveView Counter",
    description: "Simple counter implementation using Phoenix LiveView",
    body: """
    def mount(_params, _session, socket) do
      {:ok, assign(socket, count: 0)}
    end

    def handle_event("increment", _params, socket) do
      {:noreply, update(socket, :count, &(&1 + 1))}
    end
    """,
    syntax: "elixir",
    tags: ["phoenix", "liveview", "web"],
    visibility: "team",
    author_id: demo_user.id,
    buffer_token: Ecto.UUID.generate(),
    queued_at: now,
    persisted_at: now
  },
  %{
    title: "SQL Query Optimization",
    description: "Example of optimizing a slow SQL query with proper indexing",
    body: """
    -- Before: Slow query
    SELECT * FROM users WHERE lower(email) = 'test@example.com';

    -- Create functional index
    CREATE INDEX idx_users_email_lower ON users(lower(email));

    -- After: Fast query using index
    SELECT * FROM users WHERE lower(email) = 'test@example.com';
    """,
    syntax: "sql",
    tags: ["database", "performance", "sql"],
    visibility: "organization",
    author_id: demo_user.id,
    buffer_token: Ecto.UUID.generate(),
    queued_at: now,
    persisted_at: now
  },
  %{
    title: "JavaScript Async/Await Pattern",
    description: "Modern asynchronous JavaScript using async/await",
    body: """
    async function fetchUserData(userId) {
      try {
        const response = await fetch(`/api/users/${userId}`);
        const data = await response.json();
        return data;
      } catch (error) {
        console.error('Error fetching user:', error);
        throw error;
      }
    }
    """,
    syntax: "javascript",
    tags: ["javascript", "async", "api"],
    visibility: "personal",
    author_id: demo_user.id,
    buffer_token: Ecto.UUID.generate(),
    queued_at: now,
    persisted_at: now
  },
  %{
    title: "Python List Comprehension",
    description: "Efficient list processing with comprehensions",
    body: """
    # Filter and transform in one line
    squared_evens = [x**2 for x in range(10) if x % 2 == 0]

    # Nested comprehension for matrix operations
    matrix = [[i*j for j in range(3)] for i in range(3)]
    """,
    syntax: "python",
    tags: ["python", "algorithm", "utility"],
    visibility: "team",
    author_id: demo_user.id,
    buffer_token: Ecto.UUID.generate(),
    queued_at: now,
    persisted_at: now
  }
]

Enum.each(demo_snippets, fn attrs ->
  Repo.insert!(struct!(Snippet, attrs))
end)

IO.puts("✓ Seeded #{length(demo_snippets)} demo snippets for user #{demo_user.email}")
