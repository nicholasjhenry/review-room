defmodule ReviewRoomWeb.SnippetFormLiveTest do
  use ReviewRoomWeb.ConnCase, async: true
  use ReviewRoomWeb.DesignSystemCase

  import Phoenix.LiveViewTest
  import ReviewRoom.AccountsFixtures
  alias Phoenix.Controller

  describe "design system shell" do
    test "renders hero metrics and clipboard-enabled share actions", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())

      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      assert has_element?(view, "#snippet-form-hero h1", "Confident Snippet Management")

      assert has_element?(
               view,
               "#snippet-form-hero [data-role='form-metric']",
               "WCAG AA ready"
             )

      assert has_element?(view, "#snippet-share-toolbar[phx-hook='ClipboardCopy']")
      assert has_element?(view, "#snippet-share-toolbar [data-success-state]")
      assert has_element?(view, "#snippet-form-shell[data-layout='balanced']")
    end
  end

  describe "validation experience" do
    test "inline helper text and errors follow design system markup", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())
      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      view
      |> form("#snippet-form", snippet: %{code: ""})
      |> render_change()

      assert has_element?(
               view,
               "[data-role='field-error'][data-field='code']",
               "Code can't be blank"
             )

      assert has_element?(
               view,
               "[data-role='field-helper'][data-field='code']",
               "Paste or compose your snippet. We highlight syntax automatically."
             )

      assert has_element?(
               view,
               "textarea[name='snippet[code]'][aria-describedby='field-code-helper field-code-error']"
             )
    end
  end

  describe "accessibility landmarks" do
    test "links hero content to the primary form region", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())
      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      assert has_element?(view, "#snippet-form[aria-labelledby='snippet-form-hero-title']")
    end
  end

  describe "success feedback" do
    test "announces form confirmations via aria-live toast", %{conn: conn} do
      conn =
        conn
        |> log_in_user(user_fixture())
        |> Controller.fetch_flash()
        |> Controller.put_flash(:info, "Snippet saved with new design system styles.")

      {:ok, view, _html} = live(conn, ~p"/snippets/new")

      assert has_element?(view, "#snippet-form-toast[role='status'][aria-live='polite']")
      assert has_element?(view, "#snippet-form-toast[data-reduced-motion-target='form-toast']")
      assert has_element?(view, "#snippet-form-toast button[data-action='dismiss']")
    end
  end
end
