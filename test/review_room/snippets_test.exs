defmodule ReviewRoom.SnippetsTest do
  use ReviewRoom.DataCase

  alias ReviewRoom.Snippets
  alias ReviewRoom.Accounts.Scope

  import ReviewRoom.AccountsFixtures
  import ReviewRoom.SnippetsFixtures

  describe "when creating a snippet" do
    setup do
      user = user_fixture()
      scope = %Scope{user: user}
      {:ok, scope: scope, user: user}
    end

    test "given valid attributes then snippet is created", %{scope: scope, user: user} do
      attrs = %{
        "title" => "Test Snippet",
        "code" => "defmodule Test do\nend"
      }

      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.title == "Test Snippet"
      assert snippet.code == "defmodule Test do\nend"
      assert snippet.visibility == :private
      assert snippet.user_id == user.id
      assert snippet.slug != nil
    end

    test "given missing title then error is returned", %{scope: scope} do
      attrs = %{"code" => "test"}
      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "given missing code then error is returned", %{scope: scope} do
      attrs = %{"title" => "Test"}
      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert %{code: ["can't be blank"]} = errors_on(changeset)
    end

    test "given title over 200 characters then error is returned", %{scope: scope} do
      attrs = %{
        "title" => String.duplicate("a", 201),
        "code" => "test"
      }

      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert %{title: ["should be at most 200 character(s)"]} = errors_on(changeset)
    end

    test "given code over 500KB then error is returned", %{scope: scope} do
      attrs = %{
        "title" => "Large Snippet",
        "code" => String.duplicate("a", 512_001)
      }

      assert {:error, changeset} = Snippets.create_snippet(scope, attrs)
      assert %{code: [_]} = errors_on(changeset)
    end

    test "given no visibility then defaults to private", %{scope: scope} do
      attrs = %{
        "title" => "Test Snippet",
        "code" => "test code"
      }

      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.visibility == :private
    end

    test "given valid attributes then snippet is associated with user", %{
      scope: scope,
      user: user
    } do
      attrs = %{
        "title" => "Test Snippet",
        "code" => "test code"
      }

      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.user_id == user.id
    end

    test "given valid title then slug is generated automatically", %{scope: scope} do
      attrs = %{
        "title" => "My Test Snippet",
        "code" => "test code"
      }

      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.slug =~ ~r/my-test-snippet-/
    end

    test "given tags as comma-separated string then tags are parsed", %{scope: scope} do
      attrs = %{
        "title" => "Tagged Snippet",
        "code" => "test code",
        "tags" => "elixir, phoenix, web"
      }

      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.tags == ["elixir", "phoenix", "web"]
    end

    test "given mixed-case tags then tags are normalized", %{scope: scope} do
      attrs = %{
        "title" => "Tagged Snippet",
        "code" => "test code",
        "tags" => "Elixir, PHOENIX,  web , elixir"
      }

      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.tags == ["elixir", "phoenix", "web"]
    end

    test "given XSS in title then content is stored as-is", %{scope: scope} do
      attrs = %{
        "title" => "<script>alert('xss')</script>",
        "code" => "test"
      }

      # Phoenix auto-escapes in templates - just verify storage
      assert {:ok, snippet} = Snippets.create_snippet(scope, attrs)
      assert snippet.title == "<script>alert('xss')</script>"
      # XSS prevention happens at template level, not storage
    end
  end

  describe "when getting a snippet" do
    test "given public snippet then any user can access" do
      owner = user_fixture()
      owner_scope = %Scope{user: owner}
      snippet = public_snippet_fixture(owner_scope)

      other_user = user_fixture()
      scope = %Scope{user: other_user}

      assert {:ok, found} = Snippets.get_snippet(scope, snippet.slug)
      assert found.id == snippet.id
    end

    test "given private snippet and owner then snippet is returned" do
      user = user_fixture()
      scope = %Scope{user: user}
      snippet = snippet_fixture(scope, visibility: "private")

      assert {:ok, found} = Snippets.get_snippet(scope, snippet.slug)
      assert found.id == snippet.id
    end

    test "given private snippet and non-owner then not found is returned" do
      owner = user_fixture()
      owner_scope = %Scope{user: owner}
      snippet = snippet_fixture(owner_scope, visibility: "private")

      other_user = user_fixture()
      scope = %Scope{user: other_user}

      assert {:error, :not_found} = Snippets.get_snippet(scope, snippet.slug)
    end

    test "given unlisted snippet then anyone with link can access" do
      owner = user_fixture()
      owner_scope = %Scope{user: owner}
      snippet = snippet_fixture(owner_scope, visibility: "unlisted")

      other_user = user_fixture()
      scope = %Scope{user: other_user}

      assert {:ok, found} = Snippets.get_snippet(scope, snippet.slug)
      assert found.id == snippet.id
    end
  end

  describe "when listing snippets" do
    test "given multiple users then only user's snippets are listed" do
      user = user_fixture()
      scope = %Scope{user: user}

      # Different user
      other_user = user_fixture()
      other_scope = %Scope{user: other_user}
      _other_snippet = snippet_fixture(other_scope)
      my_snippet = snippet_fixture(scope)

      snippets = Snippets.list_snippets(scope)
      assert length(snippets) == 1
      assert hd(snippets).id == my_snippet.id
    end

    test "given tag filter then only matching snippets are listed" do
      user = user_fixture()
      scope = %Scope{user: user}

      tagged = snippet_fixture(scope, tags: "elixir,test")
      _untagged = snippet_fixture(scope)

      snippets = Snippets.list_snippets(scope, tag: "elixir")
      assert length(snippets) == 1
      assert hd(snippets).id == tagged.id
    end
  end
end
