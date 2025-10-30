defmodule ReviewRoom.Snippets.Buffer do
  @moduledoc """
  Manages deferred snippet persistence with size and idle flush triggers.
  """

  use GenServer

  alias __MODULE__.Entry
  alias ReviewRoom.Accounts.Scope
  alias ReviewRoom.Accounts.User
  alias ReviewRoom.Repo
  alias ReviewRoom.Snippets.Snippet

  defmodule Entry do
    @enforce_keys [:buffer_token, :payload, :queued_at, :attempts, :scope_key]
    defstruct [:buffer_token, :payload, :queued_at, :attempts, :scope_key, :last_error]
  end

  defmodule State do
    @enforce_keys [:config, :repo]
    defstruct config: %{},
              repo: Repo,
              queues: %{},
              timers: %{},
              dead_letters: []
  end

  @type server_option :: {:server, GenServer.server()}

  @doc false
  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    %{
      id: name,
      start: {__MODULE__, :start_link, [Keyword.put(opts, :name, name)]}
    }
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Enqueues snippet attributes for the given scope.

  Returns position metadata used for UI confirmation.
  """
  @spec enqueue(Scope.t(), map(), [server_option() | {:timeout, non_neg_integer()}]) ::
          {:ok, map()} | {:error, term()}
  def enqueue(%Scope{} = scope, attrs, opts \\ []) when is_map(attrs) do
    server = Keyword.get(opts, :server, __MODULE__)
    timeout = Keyword.get(opts, :timeout, 5_000)
    GenServer.call(server, {:enqueue, scope, attrs}, timeout)
  end

  @doc """
  Forces a flush for the provided scope.
  """
  @spec flush_now(Scope.t(), [server_option()]) :: :ok
  def flush_now(%Scope{} = scope, opts \\ []) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:flush_now, scope})
  end

  @doc """
  Debug helper used in tests to inspect in-memory state.
  """
  @spec debug_state(GenServer.server()) :: State.t()
  def debug_state(server \\ __MODULE__) do
    GenServer.call(server, :debug_state)
  end

  @impl true
  def init(opts) do
    config =
      default_config()
      |> Map.merge(
        Map.take(Map.new(opts), [:flush_count, :flush_idle_ms, :max_attempts, :retry_backoff_ms])
      )

    repo = Keyword.get(opts, :repo, Repo)

    {:ok, %State{config: config, repo: repo}}
  end

  @impl true
  def handle_call({:enqueue, scope, attrs}, _from, %State{} = state) do
    with {:ok, scope_key, normalized_attrs} <- normalize(scope, attrs) do
      entry = %Entry{
        buffer_token: Ecto.UUID.generate(),
        payload: normalized_attrs,
        queued_at: DateTime.utc_now(:second),
        attempts: 0,
        scope_key: scope_key
      }

      {queue, state} = append_entry(state, scope_key, entry)
      position = Enum.count(queue)

      state =
        if position >= state.config.flush_count do
          state
          |> schedule_idle_flush(scope_key, cancel_only: true)
          |> flush_scope(scope_key, {:threshold, entry.queued_at})
        else
          state
        end

      meta = %{
        buffer_token: entry.buffer_token,
        position: position
      }

      {:reply, {:ok, meta}, state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:flush_now, scope}, _from, %State{} = state) do
    {:ok, scope_key, _attrs} = normalize(scope, %{})
    {:reply, :ok, flush_scope(state, scope_key, :manual)}
  end

  def handle_call(:debug_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:flush, scope_key, reason}, %State{} = state) do
    {:noreply, flush_scope(state, scope_key, reason)}
  end

  defp append_entry(%State{} = state, scope_key, entry) do
    queue = Map.get(state.queues, scope_key, [])
    new_queue = queue ++ [entry]

    state =
      state
      |> put_queue(scope_key, new_queue)
      |> schedule_idle_flush(scope_key)

    {new_queue, state}
  end

  defp flush_scope(%State{} = state, scope_key, reason) do
    queue = Map.get(state.queues, scope_key, [])

    if queue == [] do
      state
    else
      state = cancel_timer(state, scope_key)

      case persist_batch(state.repo, queue) do
        {:ok, _persisted} ->
          state
          |> put_queue(scope_key, [])

        {:error, error} ->
          handle_flush_failure(state, scope_key, queue, error, reason)
      end
    end
  end

  defp schedule_idle_flush(%State{} = state, scope_key, opts \\ []) do
    cancel_only = Keyword.get(opts, :cancel_only, false)
    state = cancel_timer(state, scope_key)

    cond do
      cancel_only ->
        state

      state.config.flush_idle_ms == :infinity ->
        state

      true ->
        ref =
          Process.send_after(self(), {:flush, scope_key, :idle}, state.config.flush_idle_ms)

        put_timer(state, scope_key, ref)
    end
  end

  defp cancel_timer(%State{} = state, scope_key) do
    case Map.pop(state.timers, scope_key) do
      {nil, timers} ->
        %State{state | timers: timers}

      {ref, timers} ->
        Process.cancel_timer(ref, async: true, info: false)
        %State{state | timers: timers}
    end
  end

  defp put_timer(%State{} = state, scope_key, ref) do
    %State{state | timers: Map.put(state.timers, scope_key, ref)}
  end

  defp put_queue(%State{} = state, scope_key, queue) do
    %State{state | queues: Map.put(state.queues, scope_key, queue)}
  end

  defp handle_flush_failure(%State{} = state, scope_key, queue, error, reason) do
    {retry_entries, dead_letters} =
      Enum.reduce(queue, {[], []}, fn %Entry{} = entry, {retry_acc, dead_acc} ->
        attempts = entry.attempts + 1
        updated = %Entry{entry | attempts: attempts, last_error: {error, reason}}

        if attempts >= state.config.max_attempts do
          {retry_acc, [updated | dead_acc]}
        else
          {[updated | retry_acc], dead_acc}
        end
      end)

    state =
      state
      |> append_dead_letters(Enum.reverse(dead_letters), {error, reason})
      |> put_queue(scope_key, Enum.reverse(retry_entries))

    case retry_entries do
      [] ->
        state

      entries ->
        delay =
          entries
          |> Enum.map(&retry_delay(state.config.retry_backoff_ms, &1.attempts))
          |> Enum.max()

        ref = Process.send_after(self(), {:flush, scope_key, :retry}, delay)

        state
        |> put_timer(scope_key, ref)
    end
  end

  defp append_dead_letters(%State{} = state, [], _reason), do: state

  defp append_dead_letters(%State{} = state, entries, _reason) do
    %State{state | dead_letters: state.dead_letters ++ entries}
  end

  defp persist_batch(repo, entries) do
    now = DateTime.utc_now(:second)

    repo.transaction(fn ->
      for entry <- entries do
        params =
          entry.payload
          |> Map.put(:buffer_token, entry.buffer_token)
          |> Map.put_new(:queued_at, entry.queued_at)
          |> Map.put(:persisted_at, now)

        %Snippet{}
        |> Snippet.base_changeset(params)
        |> repo.insert!()
      end
    end)
  rescue
    error -> {:error, error}
  end

  defp retry_delay(base, attempts) do
    trunc(:math.pow(2, attempts - 1) * base)
  end

  defp normalize(%Scope{user: %User{id: id}}, attrs) when is_binary(id) do
    scope_key = {:user, id}
    {:ok, scope_key, attrs}
  end

  defp normalize(_scope, _attrs), do: {:error, :invalid_scope}

  defp default_config do
    env = Application.get_env(:review_room, ReviewRoom.Snippets, [])

    buffer =
      env
      |> Keyword.get(:buffer, [])
      |> Enum.into(%{})

    %{
      flush_count: Map.get(buffer, :flush_count, 10),
      flush_idle_ms: Map.get(buffer, :flush_idle_ms, 5_000),
      max_attempts: Map.get(buffer, :max_attempts, 3),
      retry_backoff_ms: Map.get(buffer, :retry_backoff_ms, 1_000)
    }
  end
end
