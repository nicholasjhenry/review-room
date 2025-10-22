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

  describe "Real-time cursor collaboration" do
    test "cursor_moved event updates presence tracker", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Simulate cursor movement
      render_hook(view, "cursor_moved", %{"line" => 5, "column" => 10})

      # Allow time for tracker update
      :timer.sleep(50)

      # Verify presence was tracked with cursor position
      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      assert map_size(presences) == 1

      [user_id] = Map.keys(presences)
      [meta] = presences[user_id].metas
      assert meta.cursor == %{line: 5, column: 10}
    end

    test "text_selected event updates tracker with selection", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Simulate text selection
      render_hook(view, "text_selected", %{
        "start" => %{"line" => 1, "column" => 0},
        "end" => %{"line" => 3, "column" => 5}
      })

      # Allow time for tracker update
      :timer.sleep(50)

      # Verify selection was tracked
      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      [user_id] = Map.keys(presences)
      [meta] = presences[user_id].metas
      assert meta.selection.start == %{line: 1, column: 0}
      assert meta.selection.end == %{line: 3, column: 5}
    end

    test "selection_cleared event clears selection metadata", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      # First set a selection
      render_hook(view, "text_selected", %{
        "start" => %{"line" => 1, "column" => 0},
        "end" => %{"line" => 3, "column" => 5}
      })

      :timer.sleep(50)

      # Then clear it
      render_hook(view, "selection_cleared", %{})

      :timer.sleep(50)

      # Verify selection was cleared
      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      [user_id] = Map.keys(presences)
      [meta] = presences[user_id].metas
      assert meta.selection == nil
    end

    test "presence_diff broadcast updates assigns", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Simulate another user joining via presence_diff message (as list of tuples from Tracker)
      send(
        view.pid,
        {:presence_diff,
         %{
           joins: [
             {"user_xyz", %{display_name: "Bob", cursor: %{line: 10, column: 5}}}
           ],
           leaves: []
         }}
      )

      # Allow LiveView to process message
      :timer.sleep(50)

      # Verify presences were updated in assigns by checking the state
      # Note: We don't check HTML content since presence UI (T031) hasn't been implemented yet
      presences = :sys.get_state(view.pid).socket.assigns.presences
      assert map_size(presences) >= 1
      assert Map.has_key?(presences, "user_xyz")
    end

    test "multiple viewers receive presence updates", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      # Connect two viewers
      {:ok, view1, _html} = live(conn, ~p"/s/#{snippet.id}")
      {:ok, _view2, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Move cursor in first viewer
      render_hook(view1, "cursor_moved", %{"line" => 15, "column" => 20})

      # Allow time for presence broadcast
      :timer.sleep(100)

      # Verify both viewers see the presence update
      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      assert map_size(presences) == 2
    end

    test "subscribes to snippet topic on mount when connected", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, _view, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Verify presence tracking started
      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      assert map_size(presences) == 1
    end
  end
end
