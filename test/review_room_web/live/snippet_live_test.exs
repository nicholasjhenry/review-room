defmodule ReviewRoomWeb.SnippetLiveTest do
  use ReviewRoomWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias ReviewRoom.SnippetsFixtures

  describe "Form LiveView" do
    setup :register_and_log_in_user

    test "form renders with title and code fields", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/snippets/new")

      assert html =~ "New Snippet"
      assert has_element?(view, "#snippet-form")
      assert has_element?(view, "#snippet-form input[name='snippet[title]']")
      assert has_element?(view, "#snippet-form textarea[name='snippet[code]']")
    end

    test "form submission with valid data creates snippet", %{conn: conn, scope: scope} do
      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      assert view
             |> form("#snippet-form",
               snippet: %{
                 title: "Test Snippet",
                 code: "IO.puts(\"Hello\")",
                 description: "A test snippet"
               }
             )
             |> render_submit()

      # Verify snippet was created
      snippets = ReviewRoom.Snippets.list_snippets(scope)
      assert length(snippets) == 1
      snippet = hd(snippets)
      assert snippet.title == "Test Snippet"

      # Should redirect to show page
      assert_redirect(view, ~p"/snippets/#{snippet.id}")
    end

    test "form submission without title shows validation error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      html =
        view
        |> form("#snippet-form", snippet: %{title: "", code: "test"})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Index LiveView" do
    setup :register_and_log_in_user

    test "lists user's snippets", %{conn: conn, scope: scope} do
      snippet1 = SnippetsFixtures.snippet_fixture(scope, %{title: "First Snippet"})
      snippet2 = SnippetsFixtures.snippet_fixture(scope, %{title: "Second Snippet"})

      {:ok, _view, html} = live(conn, ~p"/snippets")

      assert html =~ "First Snippet"
      assert html =~ "Second Snippet"
      assert html =~ snippet1.id
      assert html =~ snippet2.id
    end

    test "displays empty state when no snippets exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/snippets")

      assert html =~ "No snippets"
    end
  end

  describe "Show LiveView" do
    setup :register_and_log_in_user

    test "displays snippet title, description, and code", %{conn: conn, scope: scope} do
      snippet =
        SnippetsFixtures.snippet_fixture(scope, %{
          title: "My Snippet",
          description: "This is a test snippet",
          code: "IO.puts(\"Hello, World!\")",
          visibility: :public
        })

      {:ok, _view, html} = live(conn, ~p"/snippets/#{snippet.id}")

      assert html =~ "My Snippet"
      assert html =~ "This is a test snippet"
      assert html =~ "IO.puts(&quot;Hello, World!&quot;)"
    end

    test "guest can view public snippet", %{scope: scope} do
      snippet =
        SnippetsFixtures.snippet_fixture(scope, %{
          title: "Public Snippet",
          visibility: :public
        })

      # Create new unauthenticated connection
      conn = build_conn()
      {:ok, _view, html} = live(conn, ~p"/snippets/#{snippet.id}")

      assert html =~ "Public Snippet"
    end

    test "guest cannot view private snippet", %{scope: scope} do
      snippet =
        SnippetsFixtures.snippet_fixture(scope, %{
          title: "Private Snippet",
          visibility: :private
        })

      # Create new unauthenticated connection
      conn = build_conn()

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/snippets/#{snippet.id}")
      end
    end
  end
end
