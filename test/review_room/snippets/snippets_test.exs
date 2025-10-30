defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase, async: false

  import ReviewRoom.SnippetsFixtures

  alias ReviewRoom.Snippets

  describe "change_snippet/2" do
    test "requires title, description, body, syntax, and visibility" do
      scope = scope_fixture()

      changeset = Snippets.change_snippet(scope, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).description
      assert "can't be blank" in errors_on(changeset).body
      assert "can't be blank" in errors_on(changeset).syntax
      assert "can't be blank" in errors_on(changeset).visibility
    end

    test "produces valid changeset for well-formed attributes" do
      scope = scope_fixture()

      assert Snippets.change_snippet(scope, valid_snippet_attrs()).valid?
    end

    test "respects length caps for title, description, and body" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("title", String.duplicate("t", 121))
        |> Map.put("description", String.duplicate("d", 501))
        |> Map.put("body", String.duplicate("b", 10_001))

      changeset = Snippets.change_snippet(scope, attrs)

      assert "should be at most 120 character(s)" in errors_on(changeset).title
      assert "should be at most 500 character(s)" in errors_on(changeset).description
      assert "should be at most 10000 character(s)" in errors_on(changeset).body
    end
  end

  describe "enqueue/2" do
    test "returns error when buffer rejects payload" do
      scope = scope_fixture()

      swap_buffer(__MODULE__.FailureBuffer, fn ->
        assert {:error, :boom} = Snippets.enqueue(scope, valid_snippet_attrs())
      end)
    end
  end

  defmodule FailureBuffer do
    def enqueue(scope, payload, opts \\ [])
    def enqueue(%ReviewRoom.Accounts.Scope{}, _payload, _opts), do: {:error, :boom}

    def enqueue(other, _payload, _opts) do
      raise ArgumentError, "expected scope as first argument, got: #{inspect(other)}"
    end

    def flush_now(_scope), do: :ok
  end

  defp swap_buffer(buffer_module, fun) do
    original =
      Application.get_env(:review_room, :snippet_buffer_module, ReviewRoom.Snippets.Buffer)

    Application.put_env(:review_room, :snippet_buffer_module, buffer_module)

    try do
      fun.()
    after
      Application.put_env(:review_room, :snippet_buffer_module, original)
    end
  end
end
