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

    test "given title and description then snippet stores metadata" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(:metadata)",
        language: "elixir",
        title: "Helpful snippet",
        description: "Explains how metadata is handled"
      }

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.title == "Helpful snippet"
      assert snippet.description == "Explains how metadata is handled"
    end

    test "given missing title then snippet stores default nil title" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(:no_title)",
        language: "elixir",
        description: "Snippet without a title"
      }

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.title == nil
      assert snippet.description == "Snippet without a title"
    end

    test "given html in metadata then snippet sanitizes fields" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(:sanitize)",
        language: "elixir",
        title: "<b>Bold</b>",
        description: "<script>alert('xss')</script>Safe"
      }

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.title == "Bold"
      refute String.contains?(snippet.title, "<")
      refute String.contains?(snippet.description, "<")
      assert snippet.description =~ "Safe"
    end

    test "given title exceeding limit then error changeset is returned" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(:too_long)",
        language: "elixir",
        title: String.duplicate("a", 256)
      }

      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert "should be at most 255 character(s)" in errors_on(changeset).title
    end

    test "given tags array then snippet stores all tags" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(:tags)",
        language: "elixir",
        tags: ["phoenix", "elixir", "liveview"]
      }

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.tags == ["phoenix", "elixir", "liveview"]
    end

    test "given more than allowed tags then error changeset is returned" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(:too_many_tags)",
        language: "elixir",
        tags: Enum.map(1..11, &"tag#{&1}")
      }

      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert "Maximum 10 tags allowed" in errors_on(changeset).tags
    end

    test "given tags with whitespace and duplicates then tags are normalized" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(:normalize_tags)",
        language: "elixir",
        tags: [" elixir ", "phoenix", "elixir", "  phoenix  "]
      }

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.tags == ["elixir", "phoenix"]
    end

    test "given missing tags then snippet persists with empty list" do
      scope = user_scope_fixture()

      attrs = %{
        code: "IO.puts(:no_tags)",
        language: "elixir"
      }

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.tags == []
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

  describe "when listing tags" do
    test "given persisted snippets then list_all_tags returns unique tags" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()

      {:ok, _} =
        Snippets.create_snippet(scope, %{
          code: "IO.puts(:first)",
          language: "elixir",
          tags: ["elixir", "phoenix"]
        })

      {:ok, _} =
        Snippets.create_snippet(other_scope, %{
          code: "IO.puts(:second)",
          language: "elixir",
          tags: ["phoenix", "liveview"]
        })

      assert Snippets.list_all_tags() == ["elixir", "liveview", "phoenix"]
    end

    test "given tag name then list_snippets_by_tag filters accessible snippets" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()

      {:ok, own_private} =
        Snippets.create_snippet(scope, %{
          code: "IO.puts(:private_match)",
          language: "elixir",
          tags: ["elixir", "private"]
        })

      {:ok, other_public} =
        Snippets.create_snippet(other_scope, %{
          code: "IO.puts(:public_match)",
          language: "elixir",
          tags: ["elixir", "shared"],
          visibility: "public"
        })

      {:ok, _non_matching} =
        Snippets.create_snippet(scope, %{
          code: "IO.puts(:different)",
          language: "elixir",
          tags: ["phoenix"]
        })

      results =
        Snippets.list_snippets_by_tag(scope, "elixir")
        |> Enum.map(& &1.id)
        |> Enum.sort()

      expected_ids =
        [other_public.id, own_private.id]
        |> Enum.sort()

      assert results == expected_ids
    end
  end
end
