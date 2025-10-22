defmodule ReviewRoom.Snippets.PresenceTrackerTest do
  use ReviewRoom.DataCase, async: true

  alias ReviewRoom.Snippets.PresenceTracker

  @snippet_id "test123"
  @user_id_1 "user_abc"
  @user_id_2 "user_xyz"

  describe "track_user/3" do
    test "adds user to topic with metadata" do
      user_meta = %{display_name: "Alice", cursor: nil}

      assert {:ok, _ref} = PresenceTracker.track_user(@snippet_id, @user_id_1, user_meta)

      presences = PresenceTracker.list_presences(@snippet_id)
      assert Map.has_key?(presences, @user_id_1)
      assert [meta] = presences[@user_id_1].metas
      assert meta.display_name == "Alice"
      assert meta.cursor == nil
    end

    test "tracks multiple users on same topic" do
      user_meta_1 = %{display_name: "Alice", cursor: nil}
      user_meta_2 = %{display_name: "Bob", cursor: nil}

      assert {:ok, _ref1} =
               PresenceTracker.track_user(@snippet_id, @user_id_1, user_meta_1)

      assert {:ok, _ref2} =
               PresenceTracker.track_user(@snippet_id, @user_id_2, user_meta_2)

      presences = PresenceTracker.list_presences(@snippet_id)
      assert map_size(presences) == 2
      assert Map.has_key?(presences, @user_id_1)
      assert Map.has_key?(presences, @user_id_2)
    end
  end

  describe "update_cursor/3" do
    setup do
      user_meta = %{display_name: "Alice", cursor: nil}
      {:ok, _} = PresenceTracker.track_user(@snippet_id, @user_id_1, user_meta)
      :ok
    end

    test "updates cursor metadata for tracked user" do
      cursor_meta = %{cursor: %{line: 10, column: 5}}

      assert {:ok, _ref} =
               PresenceTracker.update_cursor(@snippet_id, @user_id_1, cursor_meta)

      # Allow time for tracker to process update
      :timer.sleep(50)

      presences = PresenceTracker.list_presences(@snippet_id)
      [meta] = presences[@user_id_1].metas
      assert meta.cursor == %{line: 10, column: 5}
    end

    test "updates selection metadata" do
      selection_meta = %{selection: %{start: %{line: 5, column: 0}, end: %{line: 8, column: 10}}}

      assert {:ok, _ref} =
               PresenceTracker.update_cursor(@snippet_id, @user_id_1, selection_meta)

      # Allow time for tracker to process update
      :timer.sleep(50)

      presences = PresenceTracker.list_presences(@snippet_id)
      [meta] = presences[@user_id_1].metas
      assert meta.selection.start == %{line: 5, column: 0}
      assert meta.selection.end == %{line: 8, column: 10}
    end
  end

  describe "list_presences/1" do
    test "returns empty map when no users tracked" do
      presences = PresenceTracker.list_presences("empty_snippet")
      assert presences == %{}
    end

    test "returns all tracked users for a topic" do
      user_meta_1 = %{display_name: "Alice", cursor: nil}
      user_meta_2 = %{display_name: "Bob", cursor: nil}

      {:ok, _} = PresenceTracker.track_user(@snippet_id, @user_id_1, user_meta_1)
      {:ok, _} = PresenceTracker.track_user(@snippet_id, @user_id_2, user_meta_2)

      presences = PresenceTracker.list_presences(@snippet_id)

      assert map_size(presences) == 2
      assert Map.has_key?(presences, @user_id_1)
      assert Map.has_key?(presences, @user_id_2)
    end
  end

  describe "automatic cleanup" do
    test "removes user when process dies" do
      user_meta = %{display_name: "Alice", cursor: nil}

      # Track user from a separate process (not linked to test process)
      pid =
        spawn(fn ->
          PresenceTracker.track_user(@snippet_id, @user_id_1, user_meta)

          receive do
            :exit -> :ok
          end
        end)

      # Wait for tracking to complete
      :timer.sleep(50)

      # Verify user is tracked
      presences = PresenceTracker.list_presences(@snippet_id)
      assert Map.has_key?(presences, @user_id_1)

      # Kill the process
      Process.exit(pid, :kill)

      # Wait for cleanup (tracker needs time to detect process exit)
      :timer.sleep(150)

      # Verify user was removed
      presences = PresenceTracker.list_presences(@snippet_id)
      refute Map.has_key?(presences, @user_id_1)
    end
  end
end
