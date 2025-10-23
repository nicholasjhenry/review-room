defmodule ReviewRoomWeb.SnippetLive.NewTest do
  use ReviewRoomWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ReviewRoom.AccountsFixtures

  alias ReviewRoom.Snippets

  describe "New snippet page" do
    test "mount displays form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/snippets/new")

      assert html =~ "New Snippet"
      assert has_element?(view, "form#snippet-form")
      assert has_element?(view, "textarea[name='snippet[code]']")
      assert has_element?(view, "input[name='snippet[title]']")
      assert has_element?(view, "textarea[name='snippet[description]']")
      assert has_element?(view, "select[name='snippet[language]']")
      assert has_element?(view, "select[name='snippet[visibility]']")
    end

    test "validate event updates changeset on code change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      # Valid code
      view
      |> form("#snippet-form", snippet: %{code: "def hello, do: :world"})
      |> render_change()

      # Should not show errors
      refute view |> element("#snippet-form") |> render() =~ "can&#39;t be blank"
    end

    test "validate event shows errors for invalid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      # Empty code (invalid)
      html =
        view
        |> form("#snippet-form", snippet: %{code: "", title: "Test"})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "save event creates snippet and redirects on valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      # Submit valid snippet
      {:ok, _view, html} =
        view
        |> form("#snippet-form",
          snippet: %{
            code: "def hello, do: :world",
            title: "Hello Function",
            language: "elixir"
          }
        )
        |> render_submit()
        |> follow_redirect(conn)

      # Should redirect to show page
      assert html =~ "def hello, do: :world"
      assert html =~ "Hello Function"
    end

    test "save event shows validation errors on invalid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      # Submit without code
      html =
        view
        |> form("#snippet-form", snippet: %{title: "No Code"})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      # Should stay on same page
      assert has_element?(view, "form#snippet-form")
    end

    test "supports language selection dropdown", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/snippets/new")

      # Check for common languages in dropdown
      assert html =~ "elixir"
      assert html =~ "python"
      assert html =~ "javascript"
      assert html =~ "ruby"
    end

    test "supports visibility selection (public/private)", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/snippets/new")

      # Check for visibility options
      assert html =~ "public"
      assert html =~ "private"
    end

    test "authenticated user associations snippet with account", %{conn: conn} do
      user = user_fixture()

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/snippets/new")

      {:ok, _show_view, _html} =
        view
        |> form("#snippet-form",
          snippet: %{
            code: "defmodule Example do\n  def hello, do: :world\nend",
            title: "Owned Snippet",
            language: "elixir"
          }
        )
        |> render_submit()
        |> follow_redirect(conn)

      snippets = Snippets.list_user_snippets(user.id, limit: 5)
      assert Enum.any?(snippets, &(&1.title == "Owned Snippet"))
    end
  end
end
