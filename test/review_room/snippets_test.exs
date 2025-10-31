defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase, async: true

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  import ReviewRoom.AccountsFixtures

  describe "when creating a snippet" do
    test "given valid params then snippet is persisted" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(\"hello\")",
        language: "elixir",
        tags: ["examples"]
      }

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.code == "IO.puts(\"hello\")"
      assert snippet.language == "elixir"
      assert snippet.tags == ["examples"]
      assert snippet.user_id == scope.user.id
    end

    test "given missing code then error changeset is returned" do
      scope = user_scope_fixture()

      attrs = %{
        language: "elixir"
      }

      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert "can't be blank" in errors_on(changeset).code
    end

    test "given missing language then error changeset is returned" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.inspect(:missing_language)"
      }

      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert "can't be blank" in errors_on(changeset).language
    end

    test "given unsupported language then error changeset is returned" do
      scope = user_scope_fixture()

      attrs = %{
        code: "print('oops')",
        language: "brainfuck"
      }

      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert "Selected language is not supported." in errors_on(changeset).language
    end
  end

  describe "when fetching a snippet" do
    test "given owner scope then snippet is returned" do
      scope = user_scope_fixture()

      {:ok, snippet} =
        Snippets.create_snippet(scope, %{
          code: "IO.puts(:owner)",
          language: "elixir"
        })

      assert ^snippet = Snippets.get_snippet(scope, snippet.id)
    end
  end
end
