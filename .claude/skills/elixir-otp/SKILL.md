---
name: elixir-otp
description: OTP architecture patterns for GenServers, Supervisors, and GenStateMachines. Use when designing concurrent systems, state management, or supervision trees.
version: 1.0.0
---

# Elixir OTP Design Principles

Comprehensive patterns for building fault-tolerant, concurrent systems with OTP.

## Choosing the Right Abstraction

### GenServer
**Use for:** Stateful processes that need to handle synchronous and asynchronous calls

**Examples:**
- Session store
- Cache manager
- Rate limiter
- Job queue

### Supervisor
**Use for:** Managing child processes with restart strategies

**Strategies:**
- `:one_for_one` - Restart only failed child (most common)
- `:one_for_all` - Restart all children if one fails (interdependent processes)
- `:rest_for_one` - Restart failed child and any started after it (order matters)

### GenStateMachine
**Use for:** Complex state transitions with multiple states

**Examples:**
- Order processing (pending → paid → shipped → delivered)
- Connection manager (disconnected → connecting → connected)
- Game state (lobby → playing → ended)

### Task / Task.Supervisor
**Use for:** Short-lived concurrent work

**Examples:**
- Parallel API calls
- Batch processing
- Background computations

## GenServer Patterns

### Basic Structure
```elixir
defmodule MyApp.Workers.JobProcessor do
  use GenServer
  require Logger

  # Type definitions
  @type state :: %{
    queue: [job()],
    processing: MapSet.t(job_id()),
    max_concurrent: pos_integer()
  }

  @type job :: %{id: String.t(), type: atom(), payload: map()}
  @type job_id :: String.t()

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add_job(server \\ __MODULE__, job) do
    GenServer.cast(server, {:add_job, job})
  end

  # Server Callbacks
  @impl true
  @spec init(keyword()) :: {:ok, state()}
  def init(opts) do
    max_concurrent = Keyword.get(opts, :max_concurrent, 5)

    state = %{
      queue: [],
      processing: MapSet.new(),
      max_concurrent: max_concurrent
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:add_job, job}, state) do
    state = %{state | queue: state.queue ++ [job]}
    {:noreply, maybe_process_job(state)}
  end

  @impl true
  def handle_info({:job_complete, job_id}, state) do
    state = %{state | processing: MapSet.delete(state.processing, job_id)}
    {:noreply, maybe_process_job(state)}
  end

  # Private Helpers
  defp maybe_process_job(%{processing: processing, queue: []} = state)
      when map_size(processing) == 0 do
    # No jobs to process
    state
  end

  defp maybe_process_job(%{processing: processing, max_concurrent: max} = state)
      when map_size(processing) >= max do
    # At capacity
    state
  end

  defp maybe_process_job(%{queue: [job | rest]} = state) do
    # Start processing job
    Task.start(fn -> process_job(job) end)

    %{state |
      queue: rest,
      processing: MapSet.put(state.processing, job.id)
    }
  end

  defp process_job(job) do
    # Do work...
    send(self(), {:job_complete, job.id})
  end
end
```

### Named Processes

**Using module name:**
```elixir
GenServer.start_link(__MODULE__, opts, name: __MODULE__)
```

**Using Registry:**
```elixir
def start_link(user_id) do
  GenServer.start_link(__MODULE__, user_id, name: via_tuple(user_id))
end

defp via_tuple(user_id) do
  {:via, Registry, {MyApp.Registry, {:user_session, user_id}}}
end
```

## Supervision Patterns

### Application Supervisor
```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Database
      MyApp.Repo,

      # PubSub
      {Phoenix.PubSub, name: MyApp.PubSub},

      # Registry for dynamic processes
      {Registry, keys: :unique, name: MyApp.Registry},

      # Your supervisors
      MyApp.JobSupervisor,
      MyApp.CacheSupervisor,

      # Endpoint
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Dynamic Supervisor
```elixir
defmodule MyApp.SessionSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_session(user_id) do
    spec = {MyApp.Session, user_id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
```

## Telemetry Integration
```elixir
def handle_call(:get_status, _from, state) do
  :telemetry.execute(
    [:my_app, :job_processor, :status_check],
    %{queue_size: length(state.queue), processing: MapSet.size(state.processing)},
    %{processor: __MODULE__}
  )

  {:reply, state, state}
end
```

## Graceful Shutdown
```elixir
@impl true
def terminate(reason, state) do
  Logger.info("Shutting down JobProcessor: #{inspect(reason)}")

  # Persist queue to disk or DB
  persist_queue(state.queue)

  :ok
end
```

## Testing Patterns
```elixir
defmodule MyApp.JobProcessorTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = JobProcessor.start_link([])
    %{processor: pid}
  end

  test "processes job and sends completion message", %{processor: pid} do
    job = %{id: "123", type: :email, payload: %{}}
    JobProcessor.add_job(pid, job)

    assert_receive {:job_complete, "123"}, 1000
  end

  test "handles errors gracefully", %{processor: pid} do
    bad_job = %{id: "456", type: :invalid, payload: nil}
    JobProcessor.add_job(pid, bad_job)

    # Processor should not crash
    assert Process.alive?(pid)
  end
end
```

## Common Pitfalls

**❌ Don't:** Block GenServer with long operations
```elixir
def handle_call(:sync_large_file, _from, state) do
  result = download_100mb_file()  # BLOCKS ALL OTHER CALLS
  {:reply, result, state}
end
```

**✅ Do:** Use async tasks
```elixir
def handle_call(:sync_large_file, _from, state) do
  task = Task.async(fn -> download_100mb_file() end)
  {:reply, {:ok, task}, state}
end
```

**❌ Don't:** Ignore errors in handle_info
```elixir
def handle_info(unknown_message, state) do
  {:noreply, state}  # Silently ignores
end
```

**✅ Do:** Log unexpected messages
```elixir
def handle_info(message, state) do
  Logger.warning("Unexpected message: #{inspect(message)}")
  {:noreply, state}
end
```

## Integration with CLAUDE.md

Check CLAUDE.md for:
- Project-specific supervision tree structure
- Telemetry event naming conventions
- Process naming patterns (Registry, via tuples)
- Timeout standards
