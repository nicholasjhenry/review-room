defmodule ReviewRoomWeb.SnippetLive.NewTest do
  use ReviewRoomWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ReviewRoom.SnippetsFixtures

  setup [:register_and_log_in_user]
  setup :stub_buffer

  describe "when submitting a snippet" do
    test "given valid form input then confirmation is shown", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")

      form =
        form(lv, "#snippet-form",
          snippet: valid_snippet_attrs() |> Map.put("tags", "phoenix, liveview")
        )

      assert render_submit(form) =~ "Snippet queued (position 3)"
      assert has_element?(lv, "#snippet-confirmation", "Refactoring Phoenix contexts")
    end

    test "given missing required fields then errors render inline", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")

      form =
        form(lv, "#snippet-form",
          snippet: %{
            "title" => "",
            "description" => "",
            "body" => ""
            # syntax and visibility have defaults, so we don't test them as blank
          }
        )

      html = render_change(form)

      assert html =~ "can&#39;t be blank"
      assert html =~ "input-error"
      assert html =~ "textarea-error"
      # No select-error expected since syntax and visibility have defaults
    end
  end

  defmodule StubBuffer do
    def enqueue(scope, payload, opts \\ [])

    def enqueue(%ReviewRoom.Accounts.Scope{}, _payload, _opts) do
      {:ok,
       %{buffer_token: "fake-token", position: 3, estimated_flush_at: ~U[2025-10-30 20:00:00Z]}}
    end

    def enqueue(other, _payload, _opts) do
      raise ArgumentError, "expected scope as first argument, got: #{inspect(other)}"
    end

    def flush_now(_scope), do: :ok
  end

  defp stub_buffer(_context) do
    original =
      Application.get_env(:review_room, :snippet_buffer_module, ReviewRoom.Snippets.Buffer)

    Application.put_env(:review_room, :snippet_buffer_module, __MODULE__.StubBuffer)

    on_exit(fn ->
      Application.put_env(:review_room, :snippet_buffer_module, original)
    end)

    :ok
  end
end
