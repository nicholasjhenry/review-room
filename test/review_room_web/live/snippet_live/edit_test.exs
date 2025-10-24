defmodule ReviewRoomWeb.SnippetLive.EditTest do
  use ReviewRoomWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ReviewRoom.AccountsFixtures
  import ReviewRoom.SnippetsFixtures

  alias ReviewRoom.Snippets

  setup %{conn: conn} do
    owner = user_fixture()
    snippet = snippet_fixture_with_user(owner, %{title: "Original Title"})
    %{conn: conn, owner: owner, snippet: snippet}
  end

  test "mount blocks non-owner", %{conn: conn, snippet: snippet} do
    other_user = user_fixture()

    assert {:error, {:redirect, %{to: redirect_path, flash: %{"error" => message}}}} =
             conn
             |> log_in_user(other_user)
             |> live(~p"/s/#{snippet.id}/edit")

    assert redirect_path == ~p"/s/#{snippet.id}"
    assert message =~ "do not have permission"
  end

  test "save updates snippet", %{conn: conn, owner: owner, snippet: snippet} do
    Phoenix.PubSub.subscribe(ReviewRoom.PubSub, "snippet:#{snippet.id}")

    {:ok, view, _html} =
      conn
      |> log_in_user(owner)
      |> live(~p"/s/#{snippet.id}/edit")

    {:ok, _view, html} =
      view
      |> form("#snippet-edit-form",
        snippet: %{
          code: "def updated, do: :ok",
          title: "Updated Title",
          description: "Updated description",
          language: "elixir",
          visibility: "private"
        }
      )
      |> render_submit()
      |> follow_redirect(conn)

    assert html =~ "Snippet updated successfully"
    assert html =~ "Updated Title"

    updated_snippet = Snippets.get_snippet!(snippet.id)
    assert updated_snippet.title == "Updated Title"

    assert_receive {:snippet_updated, %{id: received_id}}
    assert received_id == snippet.id
  end

  test "save with errors shows messages", %{conn: conn, owner: owner, snippet: snippet} do
    {:ok, view, _html} =
      conn
      |> log_in_user(owner)
      |> live(~p"/s/#{snippet.id}/edit")

    html =
      view
      |> form("#snippet-edit-form", snippet: %{code: "", title: ""})
      |> render_submit()

    assert html =~ "can&#39;t be blank"
    assert html =~ "Unable to update snippet"
  end
end
