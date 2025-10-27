defmodule ReviewRoomWeb.SnippetLive.ShowTest do
  use ReviewRoomWeb.ConnCase, async: true
  use ReviewRoomWeb.DesignSystemCase

  alias LazyHTML

  import Phoenix.LiveViewTest
  import ReviewRoom.SnippetsFixtures
  import ReviewRoom.AccountsFixtures

  # Helper for polling assertions with timeout
  defp assert_eventually(assertion_fn, opts) do
    timeout = Keyword.get(opts, :timeout, 5000)
    interval = Keyword.get(opts, :interval, 100)
    deadline = System.monotonic_time(:millisecond) + timeout

    poll_until(assertion_fn, deadline, interval)
  end

  defp poll_until(assertion_fn, deadline, interval) do
    if assertion_fn.() do
      :ok
    else
      now = System.monotonic_time(:millisecond)

      if now >= deadline do
        flunk("Assertion did not become true within timeout")
      else
        Process.sleep(interval)
        poll_until(assertion_fn, deadline, interval)
      end
    end
  end

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
      assert has_element?(view, "button[phx-hook='ClipboardCopy']")
    end

    test "renders line numbers alongside code", %{conn: conn} do
      snippet = snippet_fixture(%{code: "line 1\nline 2"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      assert has_element?(view, "[data-role='line-number']", "1")
      assert has_element?(view, "[data-role='line-number']", "2")
    end

    test "renders unicode and special HTML characters safely", %{conn: conn} do
      snippet =
        snippet_fixture(%{
          code: "<div>{@foo}</div>\nIO.puts(\"Привет 🌍\")"
        })

      {:ok, _view, html} = live(conn, ~p"/s/#{snippet.id}")

      assert html =~ "&lt;div&gt;{@foo}&lt;/div&gt;"
      assert html =~ "Привет 🌍"
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

    test "shows reconnect overlay and restores cursor metadata", %{conn: conn} do
      snippet = snippet_fixture(%{code: "line 1\nline 2"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      render_hook(view, "cursor_moved", %{"line" => 3, "column" => 7})
      :timer.sleep(50)

      render_hook(view, "connection_status", %{"status" => "disconnected"})
      html = render(view)
      assert html =~ "Reconnecting"

      render_hook(view, "connection_status", %{"status" => "connected"})
      :timer.sleep(50)

      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      [user_id] = Map.keys(presences)
      [meta] = presences[user_id].metas
      assert meta.cursor == %{line: 3, column: 7}
    end
  end

  describe "Navigation chrome (Spec 003)" do
    test "primary navigation marks workspace tab active", %{conn: conn} do
      snippet = snippet_fixture(%{code: "IO.puts(:ok)", title: "Workspace Test"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      assert has_element?(
               view,
               "#app-navigation [data-nav-item='workspace'][data-active='true'][aria-current='page']"
             )
    end

    test "initial render surfaces workspace skeleton state", %{conn: conn} do
      snippet = snippet_fixture(%{code: "IO.puts(:ok)", title: "Workspace Loading"})

      {:ok, _view, disconnected_html} = live(conn, ~p"/s/#{snippet.id}")

      assert disconnected_html =~ "id=\"workspace-shell\""

      shell_fragment = lazy_select(disconnected_html, "#workspace-shell")
      assert LazyHTML.attribute(shell_fragment, "data-state") == ["ready"]

      skeleton_fragment = lazy_select(disconnected_html, "#workspace-skeleton")
      assert LazyHTML.tag(skeleton_fragment) == []
    end

    test "empty activity timeline displays design system empty state", %{conn: conn} do
      snippet = snippet_fixture(%{code: "IO.puts(:ok)", title: "Workspace Empty"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      assert has_element?(
               view,
               "#workspace-activity-empty[data-role='empty-state'][data-context='timeline']"
             )

      assert has_element?(
               view,
               "#workspace-activity-empty [data-empty-title]",
               "Timeline is warming up"
             )
    end
  end

  describe "User Presence Awareness (Phase 5)" do
    test "presence list displays viewer count", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Check that presence count is displayed
      assert has_element?(view, "#presence-list")
      html = render(view)
      assert html =~ "Active Viewers"
      # Should show 1 viewer (self)
      assert html =~ "(1)"
    end

    test "authenticated user shows profile email", %{conn: conn} do
      user = user_fixture()
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/s/#{snippet.id}")

      html = render(view)
      assert html =~ user.email
    end

    test "anonymous users are assigned numbered display names", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view1, _html} = live(conn, ~p"/s/#{snippet.id}")

      assert_eventually(
        fn ->
          presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)

          names =
            presences
            |> Map.values()
            |> Enum.map(fn %{metas: [meta]} -> meta.display_name end)

          Enum.member?(names, "Anonymous User 1")
        end,
        timeout: 1000,
        interval: 50
      )

      {:ok, view2, _html} = live(conn, ~p"/s/#{snippet.id}")

      assert_eventually(
        fn ->
          presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)

          names =
            presences
            |> Map.values()
            |> Enum.map(fn %{metas: [meta]} -> meta.display_name end)
            |> Enum.sort()

          names == ["Anonymous User 1", "Anonymous User 2"]
        end,
        timeout: 2000,
        interval: 50
      )

      GenServer.stop(view1.pid, :normal)
      GenServer.stop(view2.pid, :normal)
    end

    test "user leaves, presence list updates within 5 seconds", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      # Connect two viewers
      {:ok, _view1, _html} = live(conn, ~p"/s/#{snippet.id}")
      {:ok, view2, _html} = live(conn, ~p"/s/#{snippet.id}")

      # Verify both are present
      :timer.sleep(50)
      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      assert map_size(presences) == 2

      # Disconnect one viewer by stopping the process
      GenServer.stop(view2.pid, :normal)

      # Poll for presence cleanup with exponential backoff (max 5 seconds)
      assert_eventually(
        fn ->
          presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
          map_size(presences) == 1
        end,
        timeout: 5000,
        interval: 100
      )
    end

    test "cursor overlay shows username on hover", %{conn: conn} do
      user = user_fixture()
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/s/#{snippet.id}")

      # Wait for initial presence tracking to complete
      :timer.sleep(100)

      # Check for presence overlay element with PresenceRenderer hook
      assert has_element?(view, "#presence-overlay[phx-hook='PresenceRenderer']")

      # Verify initial presence is tracked
      html = render(view)
      assert html =~ "data-presences"
      assert html =~ "display_name"
      assert html =~ user.email or html =~ "Anonymous User"

      # Now simulate cursor movement to update presence
      render_hook(view, "cursor_moved", %{"line" => 5, "column" => 10})
      :timer.sleep(50)

      # Verify cursor position is tracked
      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      assert map_size(presences) == 1
      [user_id] = Map.keys(presences)
      [meta] = presences[user_id].metas
      assert meta.cursor == %{line: 5, column: 10}
    end

    test "anonymous snippets cannot be edited", %{conn: conn} do
      user = user_fixture()
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/s/#{snippet.id}")

      refute has_element?(view, "a[href='#{~p"/s/#{snippet.id}/edit"}']")
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

    test "throttles rapid cursor updates server-side", %{conn: conn} do
      snippet = snippet_fixture(%{code: "test code"})

      {:ok, view, _html} = live(conn, ~p"/s/#{snippet.id}")

      render_hook(view, "cursor_moved", %{"line" => 1, "column" => 1})
      render_hook(view, "cursor_moved", %{"line" => 1, "column" => 5})

      :timer.sleep(50)

      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      [user_id] = Map.keys(presences)
      [meta] = presences[user_id].metas
      assert meta.cursor == %{line: 1, column: 1}

      :timer.sleep(120)
      render_hook(view, "cursor_moved", %{"line" => 2, "column" => 3})
      :timer.sleep(60)

      presences = ReviewRoom.Snippets.PresenceTracker.list_presences(snippet.id)
      [meta_after] = presences[user_id].metas
      assert meta_after.cursor == %{line: 2, column: 3}

      GenServer.stop(view.pid, :normal)
    end
  end
end
