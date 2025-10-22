defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase, async: true

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  import ReviewRoom.AccountsFixtures
  import ReviewRoom.SnippetsFixtures

  describe "create_snippet/2" do
    test "creates snippet with valid attributes" do
      attrs = %{
        code: "def hello, do: :world",
        title: "Hello Function",
        description: "A simple hello function",
        language: "elixir",
        visibility: :private
      }

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(attrs)
      assert snippet.code == "def hello, do: :world"
      assert snippet.title == "Hello Function"
      assert snippet.description == "A simple hello function"
      assert snippet.language == "elixir"
      assert snippet.visibility == :private
      assert String.length(snippet.id) == 8
    end

    test "creates snippet with user association" do
      user = user_fixture()
      attrs = %{code: "def hello, do: :world"}

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(attrs, user)
      assert snippet.user_id == user.id
    end

    test "creates anonymous snippet when user is nil" do
      attrs = %{code: "def hello, do: :world"}

      assert {:ok, %Snippet{} = snippet} = Snippets.create_snippet(attrs, nil)
      assert snippet.user_id == nil
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{title: "No code"}

      assert {:error, %Ecto.Changeset{}} = Snippets.create_snippet(attrs)
    end

    test "generates unique nanoid for each snippet" do
      attrs = %{code: "code"}

      assert {:ok, snippet1} = Snippets.create_snippet(attrs)
      assert {:ok, snippet2} = Snippets.create_snippet(attrs)

      assert snippet1.id != snippet2.id
      assert String.length(snippet1.id) == 8
      assert String.length(snippet2.id) == 8
    end
  end

  describe "get_snippet!/1" do
    test "returns the snippet with given id" do
      snippet = snippet_fixture()
      assert Snippets.get_snippet!(snippet.id).id == snippet.id
    end

    test "raises Ecto.NoResultsError if snippet does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Snippets.get_snippet!("nonexist")
      end
    end
  end

  describe "get_snippet/1" do
    test "returns the snippet with given id" do
      snippet = snippet_fixture()
      assert Snippets.get_snippet(snippet.id).id == snippet.id
    end

    test "returns nil if snippet does not exist" do
      assert Snippets.get_snippet("nonexist") == nil
    end
  end

  describe "change_snippet/2" do
    test "returns a snippet changeset" do
      snippet = snippet_fixture()
      assert %Ecto.Changeset{} = Snippets.change_snippet(snippet)
    end

    test "returns changeset with given attributes" do
      snippet = snippet_fixture()
      attrs = %{title: "New Title"}
      changeset = Snippets.change_snippet(snippet, attrs)

      assert changeset.changes.title == "New Title"
    end
  end
end
