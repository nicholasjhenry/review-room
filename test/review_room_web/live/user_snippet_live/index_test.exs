defmodule ReviewRoomWeb.UserSnippetLive.IndexTest do
  use ReviewRoomWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ReviewRoom.AccountsFixtures
  import ReviewRoom.SnippetsFixtures

  alias ReviewRoom.Snippets

  test "mount requires authentication", %{conn: conn} do
    assert {:error, {:redirect, %{to: to_path}}} = live(conn, ~p"/snippets/my")
    assert to_path =~ "/users/log-in"
  end

  describe "authenticated user" do
    setup %{conn: conn} do
      user = user_fixture()
      snippet_one = snippet_fixture_with_user(user, %{title: "First Snippet"})
      snippet_two = snippet_fixture_with_user(user, %{title: "Second Snippet"})

      %{conn: log_in_user(conn, user), user: user, snippets: [snippet_one, snippet_two]}
    end

    test "displays user's snippets as stream", %{conn: conn, snippets: snippets} do
      {:ok, view, _html} = live(conn, ~p"/snippets/my")

      Enum.each(snippets, fn snippet ->
        assert has_element?(view, "[data-snippet-id='#{snippet.id}']")
        assert render(view) =~ snippet.title
      end)
    end

    test "delete event removes snippet from stream", %{conn: conn, snippets: [snippet | _]} do
      {:ok, view, _html} = live(conn, ~p"/snippets/my")

      view
      |> element("#delete-snippet-#{snippet.id}")
      |> render_click()

      refute has_element?(view, "[data-snippet-id='#{snippet.id}']")
      assert Snippets.get_snippet(snippet.id) == nil
    end

    test "toggle_visibility event updates snippet", %{conn: conn, snippets: [snippet | _]} do
      {:ok, view, _html} = live(conn, ~p"/snippets/my")

      view
      |> element("#toggle-visibility-#{snippet.id}")
      |> render_click()

      updated = Snippets.get_snippet!(snippet.id)
      assert updated.visibility == :public

      html = render(view)
      assert html =~ "Public"
    end
  end
end
