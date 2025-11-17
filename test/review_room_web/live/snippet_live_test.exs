defmodule ReviewRoomWeb.SnippetLiveTest do
  use ReviewRoomWeb.ConnCase

  import Phoenix.LiveViewTest
  import ReviewRoom.AccountsFixtures
  import ReviewRoom.SnippetsFixtures

  alias ReviewRoom.Accounts.Scope

  describe "when listing snippets" do
    setup :register_and_log_in_user

    test "given authenticated user then lists all user snippets", %{conn: conn, user: user} do
      scope = %Scope{user: user}
      snippet = snippet_fixture(scope)
      {:ok, _index_live, html} = live(conn, ~p"/snippets")

      assert html =~ "My Snippets"
      assert html =~ snippet.title
    end

    test "given existing snippet then deletes successfully", %{conn: conn, user: user} do
      scope = %Scope{user: user}
      snippet = snippet_fixture(scope)
      {:ok, index_live, _html} = live(conn, ~p"/snippets")

      assert index_live |> element("#snippets-#{snippet.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#snippets-#{snippet.id}")
    end
  end

  describe "when creating a snippet" do
    setup :register_and_log_in_user

    test "given new snippet page then renders form", %{conn: conn} do
      {:ok, _new_live, html} = live(conn, ~p"/snippets/new")

      assert html =~ "New Snippet"
      assert html =~ "Title"
      assert html =~ "Code"
    end

    test "given valid data then snippet is created", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/snippets/new")

      new_live
      |> form("#snippet-form",
        snippet: %{
          title: "Test Snippet",
          code: "defmodule Test do\nend",
          language: "elixir"
        }
      )
      |> render_submit()

      {_path, flash} = assert_redirect(new_live)
      assert flash["info"] == "Snippet created successfully"
    end

    test "given invalid data then shows validation errors", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/snippets/new")

      assert new_live
             |> form("#snippet-form", snippet: %{title: "", code: ""})
             |> render_change() =~ "can&#39;t be blank"
    end
  end

  describe "when viewing a snippet" do
    test "given public snippet and unauthenticated user then displays snippet", %{conn: conn} do
      owner = user_fixture()
      scope = %Scope{user: owner}
      snippet = public_snippet_fixture(scope)
      {:ok, _show_live, html} = live(conn, ~p"/s/#{snippet.slug}")

      assert html =~ snippet.title
      assert html =~ snippet.code
    end

    test "given private snippet and owner then displays snippet", %{conn: conn} do
      user = user_fixture()
      scope = %Scope{user: user}
      conn = log_in_user(conn, user)
      snippet = snippet_fixture(scope, visibility: "private")

      {:ok, _show_live, html} = live(conn, ~p"/s/#{snippet.slug}")
      assert html =~ snippet.title
    end

    test "given private snippet and non-owner then redirects with error", %{conn: conn} do
      owner = user_fixture()
      owner_scope = %Scope{user: owner}
      snippet = snippet_fixture(owner_scope, visibility: "private")

      other_user = user_fixture()
      conn = log_in_user(conn, other_user)

      assert {:error,
              {:live_redirect, %{to: "/snippets", flash: %{"error" => "Snippet not found"}}}} =
               live(conn, ~p"/s/#{snippet.slug}")
    end

    test "given snippet with language then displays syntax highlighting", %{conn: conn} do
      owner = user_fixture()
      scope = %Scope{user: owner}
      snippet = public_snippet_fixture(scope, language: "elixir")
      {:ok, _show_live, html} = live(conn, ~p"/s/#{snippet.slug}")

      assert html =~ "language-elixir"
      assert html =~ ~s(phx-hook="SyntaxHighlight")
    end
  end

  describe "when editing a snippet" do
    setup :register_and_log_in_user

    test "given valid data then snippet is updated", %{conn: conn, user: user} do
      scope = %Scope{user: user}
      snippet = snippet_fixture(scope)
      {:ok, edit_live, _html} = live(conn, ~p"/snippets/#{snippet.slug}/edit")

      edit_live
      |> form("#snippet-form", snippet: %{title: "Updated Title"})
      |> render_submit()

      {_path, flash} = assert_redirect(edit_live)
      assert flash["info"] == "Snippet updated successfully"
    end

    test "given non-owner then denies access", %{conn: conn} do
      owner = user_fixture()
      owner_scope = %Scope{user: owner}
      snippet = snippet_fixture(owner_scope)

      assert {:error,
              {:live_redirect, %{to: "/snippets", flash: %{"error" => "Snippet not found"}}}} =
               live(conn, ~p"/snippets/#{snippet.slug}/edit")
    end
  end
end
