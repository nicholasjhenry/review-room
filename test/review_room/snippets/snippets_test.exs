defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase, async: false

  import ReviewRoom.SnippetsFixtures

  alias ReviewRoom.Snippets

  describe "when validating snippet input" do
    test "given blank attributes then required field errors surface" do
      scope = scope_fixture()

      changeset = Snippets.change_snippet(scope, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).description
      assert "can't be blank" in errors_on(changeset).body
      # Syntax and visibility have defaults, so they won't be blank
      assert Ecto.Changeset.get_field(changeset, :syntax) == "plaintext"
      assert Ecto.Changeset.get_field(changeset, :visibility) == "personal"
    end

    test "given valid attributes then changeset is marked valid" do
      scope = scope_fixture()

      assert Snippets.change_snippet(scope, valid_snippet_attrs()).valid?
    end

    test "given oversized fields then length errors are returned" do
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

  describe "when enqueueing a snippet" do
    test "given buffer failure then error tuple bubbles up" do
      scope = scope_fixture()

      swap_buffer(__MODULE__.FailureBuffer, fn ->
        assert {:error, :boom} = Snippets.enqueue(scope, valid_snippet_attrs())
      end)
    end
  end

  describe "when normalizing tags" do
    test "given tags with mixed case and whitespace then tags are normalized" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("tags", ["  Elixir  ", "TESTING", "Phoenix"])

      changeset = Snippets.change_snippet(scope, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :tags) == ["elixir", "testing", "phoenix"]
    end

    test "given duplicate tags then duplicates are removed" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("tags", ["elixir", "Elixir", "ELIXIR", "testing", "testing"])

      changeset = Snippets.change_snippet(scope, attrs)

      assert changeset.valid?
      tags = Ecto.Changeset.get_field(changeset, :tags)
      assert length(tags) == 2
      assert "elixir" in tags
      assert "testing" in tags
    end
  end

  describe "when validating tag count" do
    test "given more than 10 tags then error is returned" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("tags", Enum.map(1..11, &"tag#{&1}"))

      changeset = Snippets.change_snippet(scope, attrs)

      refute changeset.valid?
      assert "cannot have more than 10 tags" in errors_on(changeset).tags
    end

    test "given empty tags list then changeset is valid" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("tags", [])

      changeset = Snippets.change_snippet(scope, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :tags) == []
    end

    test "given no tags then default empty list is used" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.delete("tags")

      changeset = Snippets.change_snippet(scope, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :tags) == []
    end
  end

  describe "when validating visibility" do
    test "given valid visibility value then changeset is valid" do
      scope = scope_fixture()

      for visibility <- ["personal", "team", "organization"] do
        attrs =
          valid_snippet_attrs()
          |> Map.put("visibility", visibility)

        changeset = Snippets.change_snippet(scope, attrs)

        assert changeset.valid?
        assert Ecto.Changeset.get_field(changeset, :visibility) == visibility
      end
    end

    test "given invalid visibility value then error is returned" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("visibility", "invalid_visibility")

      changeset = Snippets.change_snippet(scope, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).visibility
    end

    test "given no visibility then default is personal" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.delete("visibility")

      changeset = Snippets.change_snippet(scope, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :visibility) == "personal"
    end

    test "given empty visibility then default is personal" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("visibility", "")

      changeset = Snippets.change_snippet(scope, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :visibility) == "personal"
    end
  end

  describe "when validating syntax" do
    test "given valid syntax from registry then changeset is valid" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("syntax", "elixir")

      changeset = Snippets.change_snippet(scope, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :syntax) == "elixir"
    end

    test "given invalid syntax then error is returned" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.put("syntax", "invalid-unknown-language")

      changeset = Snippets.change_snippet(scope, attrs)

      refute changeset.valid?
      assert "is not supported" in errors_on(changeset).syntax
    end

    test "given no syntax then default is plaintext" do
      scope = scope_fixture()

      attrs =
        valid_snippet_attrs()
        |> Map.delete("syntax")

      changeset = Snippets.change_snippet(scope, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :syntax) == "plaintext"
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
