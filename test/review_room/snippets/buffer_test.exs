defmodule ReviewRoom.Snippets.BufferTest do
  use ReviewRoom.DataCase, async: false

  import ReviewRoom.SnippetsFixtures

  alias ReviewRoom.Snippets.{Buffer, Snippet}
  alias ReviewRoom.Accounts.Scope

  setup do
    scope = scope_fixture()
    %{scope: scope}
  end

  describe "enqueue/2" do
    test "flushes immediately when queue reaches configured size", %{scope: scope} do
      server = start_buffer!(flush_count: 2, flush_idle_ms: 5_000)

      attrs =
        scope
        |> scoped_snippet_attrs()
        |> Map.put(:title, "Queued snippet A")

      other_attrs =
        scope
        |> scoped_snippet_attrs()
        |> Map.put(:title, "Queued snippet B")

      assert {:ok, %{buffer_token: token_a, position: 1}} =
               Buffer.enqueue(scope, attrs, server: server)

      assert {:ok, %{buffer_token: token_b, position: 2}} =
               Buffer.enqueue(scope, other_attrs, server: server)

      assert token_a != token_b

      assert [%Snippet{title: "Queued snippet A"}, %Snippet{title: "Queued snippet B"}] =
               Snippet |> Repo.all() |> Enum.sort_by(& &1.title)

      assert Buffer.debug_state(server).queues |> Map.values() |> Enum.all?(&(&1 == []))
    end

    test "flushes on idle timeout when queue under threshold", %{scope: scope} do
      server = start_buffer!(flush_count: 99, flush_idle_ms: 25)

      attrs = scoped_snippet_attrs(scope)

      assert {:ok, %{buffer_token: _token, position: 1}} =
               Buffer.enqueue(scope, attrs, server: server)

      refute Repo.aggregate(Snippet, :count, :id) > 0

      Process.sleep(60)

      assert Repo.aggregate(Snippet, :count, :id) == 1
      assert Buffer.debug_state(server).queues |> Map.values() |> Enum.all?(&(&1 == []))
    end
  end

  describe "flush retries" do
    test "stops retrying after configured attempt cap", %{scope: scope} do
      server =
        start_buffer!(
          flush_count: 1,
          flush_idle_ms: 10,
          max_attempts: 3,
          retry_backoff_ms: 5
        )

      attrs =
        scoped_snippet_attrs(scope)
        |> Map.put(:visibility, "invalid")

      assert {:ok, %{buffer_token: token, position: 1}} =
               Buffer.enqueue(scope, attrs, server: server)

      await_dead_letter(server, token)

      assert Repo.aggregate(Snippet, :count, :id) == 0

      %{dead_letters: [dead_letter]} = Buffer.debug_state(server)
      assert dead_letter.buffer_token == token
      assert dead_letter.attempts == 3
    end
  end

  defp start_buffer!(opts) do
    name = :"buffer_#{System.unique_integer()}"
    pid = start_supervised!({Buffer, Keyword.put(opts, :name, name)})
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), pid)
    name
  end

  defp scoped_snippet_attrs(%Scope{user: user}) do
    valid_snippet_attrs()
    |> Map.new(fn {key, value} -> {String.to_existing_atom(key), value} end)
    |> Map.put(:author_id, user.id)
  end

  defp await_dead_letter(server, token) do
    retry(fn ->
      state = Buffer.debug_state(server)

      if Enum.any?(state.dead_letters, &(&1.buffer_token == token)) do
        {:ok, state}
      else
        {:error, :not_ready}
      end
    end)
  end

  defp retry(fun, attempts \\ 40)

  defp retry(fun, 0), do: fun.()

  defp retry(fun, attempts) do
    case fun.() do
      {:ok, result} ->
        result

      {:error, _reason} ->
        Process.sleep(10)
        retry(fun, attempts - 1)
    end
  end
end
