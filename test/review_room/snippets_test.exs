defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase, async: true

  alias ReviewRoom.Snippets
  alias ReviewRoom.SnippetsFixtures
  alias ReviewRoom.AccountsFixtures
  alias ReviewRoom.Accounts.Scope

  describe "create_snippet/2" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = Scope.for_user(user)
      %{scope: scope}
    end

    test "with valid data succeeds", %{scope: scope} do
      valid_attrs = %{
        title: "Authentication Helper",
        description: "Helper function for user authentication",
        code: "def authenticate(user, password), do: ...",
        language: "elixir",
        tags: ["elixir", "auth"]
      }

      assert {:ok, snippet} = Snippets.create_snippet(valid_attrs, scope)
      assert snippet.title == "Authentication Helper"
      assert snippet.description == "Helper function for user authentication"
      assert snippet.code == "def authenticate(user, password), do: ..."
      assert snippet.language == "elixir"
      assert snippet.tags == ["elixir", "auth"]
      assert snippet.user_id == scope.user.id
      assert snippet.visibility == :private
    end

    test "with invalid data returns error", %{scope: scope} do
      invalid_attrs = %{title: "", code: ""}

      assert {:error, changeset} = Snippets.create_snippet(invalid_attrs, scope)
      assert %{title: ["can't be blank"], code: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "list_snippets/1" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = Scope.for_user(user)
      %{scope: scope}
    end

    test "returns only current user's snippets", %{scope: scope} do
      # Create snippets for current user
      snippet1 = SnippetsFixtures.snippet_fixture(scope, %{title: "User 1 Snippet 1"})
      snippet2 = SnippetsFixtures.snippet_fixture(scope, %{title: "User 1 Snippet 2"})

      # Create snippets for another user
      other_user = AccountsFixtures.user_fixture()
      other_scope = Scope.for_user(other_user)
      _other_snippet = SnippetsFixtures.snippet_fixture(other_scope, %{title: "User 2 Snippet"})

      snippets = Snippets.list_snippets(scope)

      snippet_ids = Enum.map(snippets, & &1.id)
      assert snippet1.id in snippet_ids
      assert snippet2.id in snippet_ids
      assert length(snippets) == 2
    end
  end

  describe "get_snippet!/2" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = Scope.for_user(user)
      %{scope: scope}
    end

    test "retrieves snippet with visibility check", %{scope: scope} do
      snippet = SnippetsFixtures.snippet_fixture(scope, %{title: "My Snippet"})

      retrieved = Snippets.get_snippet!(snippet.id, scope)
      assert retrieved.id == snippet.id
      assert retrieved.title == "My Snippet"
    end

    test "raises error when snippet not found", %{scope: scope} do
      assert_raise Ecto.NoResultsError, fn ->
        Snippets.get_snippet!(Ecto.UUID.generate(), scope)
      end
    end

    test "raises error for private snippet owned by another user" do
      # User 1 creates a private snippet
      user1 = AccountsFixtures.user_fixture()
      scope1 = Scope.for_user(user1)

      snippet =
        SnippetsFixtures.snippet_fixture(scope1, %{title: "Private", visibility: :private})

      # User 2 tries to access it
      user2 = AccountsFixtures.user_fixture()
      scope2 = Scope.for_user(user2)

      assert_raise Ecto.NoResultsError, fn ->
        Snippets.get_snippet!(snippet.id, scope2)
      end
    end
  end
end
