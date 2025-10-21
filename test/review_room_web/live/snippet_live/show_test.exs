defmodule ReviewRoomWeb.SnippetLive.ShowTest do
  use ReviewRoomWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ReviewRoom.SnippetsFixtures

  describe "Show snippet page" do
    test "mount loads snippet by ID", %{conn: conn} do
      snippet = snippet_fixture(%{code: "def hello, do: :world", title: "Test Snippet"})

      {:ok, _view, html} = live(conn, ~p"/s/#{snippet.id}")

      assert html =~ "Test Snippet"
      assert html =~ "def hello, do: :world"
    end

    test "displays code content with syntax highlighting element", %{conn: conn} do
      snippet = snippet_fixture(%{code: "puts 'Hello, Ruby!'", language: "ruby"})

      {:ok, view, html} = live(conn, ~p"/s/#{snippet.id}")

      assert html =~ "puts &#39;Hello, Ruby!&#39;"
      # Check for syntax highlighting hook
      assert has_element?(view, "#code-display[phx-hook='SyntaxHighlight']")
      assert has_element?(view, "code.language-ruby")
    end

    test "displays title and description when provided", %{conn: conn} do
      snippet =
        snippet_fixture(%{
          code: "code",
          title: "My Title",
          description: "My Description"
        })

      {:ok, _view, html} = live(conn, ~p"/s/#{snippet.id}")

      assert html =~ "My Title"
      assert html =~ "My Description"
    end

    test "handles missing title and description gracefully", %{conn: conn} do
      snippet = snippet_fixture(%{code: "code", title: nil, description: nil})

      {:ok, _view, html} = live(conn, ~p"/s/#{snippet.id}")

      assert html =~ "code"
      # Should not crash or show nil
      refute html =~ "nil"
    end

    test "shows 404 for invalid snippet ID", %{conn: conn} do
      assert_error_sent 404, fn ->
        live(conn, ~p"/s/invalid99")
      end
    end

    test "renders with correct language class for syntax highlighting", %{conn: conn} do
      snippet = snippet_fixture(%{code: "print('test')", language: "python"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      assert has_element?(view, "code.language-python")
    end

    test "handles nil language (auto-detection)", %{conn: conn} do
      snippet = snippet_fixture(%{code: "code", language: nil})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Should render without language class (auto-detect)
      assert has_element?(view, "code")
    end

    test "has syntax highlighting hook with phx-update=ignore", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Verify phx-update="ignore" is set (required for highlight.js)
      assert view
             |> element("#code-display")
             |> render() =~ "phx-update=\"ignore\""
    end
  end
end
