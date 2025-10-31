defmodule ReviewRoomWeb.SnippetLiveTest do
  use ReviewRoomWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ReviewRoom.SnippetsFixtures
  alias ReviewRoom.Snippets

  describe "when creating a snippet" do
    setup [:register_and_log_in_user]

    test "given authenticated user then new snippet form is shown", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")

      assert has_element?(lv, "#snippet-form")
      assert has_element?(lv, "#snippet-form [name='snippet[code]']")
      assert has_element?(lv, "#snippet-form [name='snippet[language]']")
    end

    test "given valid params then snippet is persisted and displayed", %{conn: conn, scope: scope} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")

      form_params = %{
        code: "IO.puts(:ok)",
        language: "elixir",
        title: "Sample snippet",
        description: "Elixir example",
        visibility: "private"
      }

      form = form(lv, "#snippet-form", snippet: form_params)

      result = render_submit(form)

      [snippet] = Snippets.list_my_snippets(scope)
      expected_path = ~p"/snippets/#{snippet}"

      assert {:error, {:live_redirect, %{to: ^expected_path}}} = result

      {:ok, _conn, html} = follow_redirect(result, conn, expected_path)

      assert html =~ "Sample snippet"
      assert html =~ "IO.puts(:ok)"
      assert snippet.title == "Sample snippet"
      assert snippet.description == "Elixir example"
    end

    test "given metadata params then snippet persists sanitized title and description", %{
      conn: conn,
      scope: scope
    } do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")

      form_params = %{
        code: "IO.puts(:metadata)",
        language: "elixir",
        title: "<b>Important</b> snippet",
        description: "<p>Keep this handy</p>"
      }

      lv
      |> form("#snippet-form", snippet: form_params)
      |> render_submit()

      [snippet] = Snippets.list_my_snippets(scope)
      assert snippet.title == "Important snippet"
      assert snippet.description == "Keep this handy"
    end

    test "given invalid params then validation errors are shown", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")

      lv
      |> form("#snippet-form", snippet: %{code: "", language: ""})
      |> render_submit()

      assert has_element?(lv, "#snippet-form .text-error", "can't be blank")
    end
  end

  describe "when viewing a snippet" do
    setup [:register_and_log_in_user]

    test "given snippet exists then code is rendered with syntax highlighting hook", %{
      conn: conn,
      scope: scope
    } do
      snippet = snippet_fixture(scope, %{language: "elixir", code: "IO.puts(:highlight)"})

      {:ok, lv, _html} = live(conn, ~p"/snippets/#{snippet}")

      assert has_element?(lv, "#snippet-display[phx-hook='SyntaxHighlighter']")
      assert has_element?(lv, "#snippet-code[data-language='elixir']", "IO.puts(:highlight)")
    end

    test "given snippet with title and description then metadata is displayed", %{
      conn: conn,
      scope: scope
    } do
      snippet =
        snippet_fixture(scope, %{
          title: "<b>Metadata</b>",
          description: "<p>Displayed description</p>"
        })

      {:ok, _lv, html} = live(conn, ~p"/snippets/#{snippet}")

      assert html =~ "Metadata"
      assert html =~ "Displayed description"
    end
  end
end
