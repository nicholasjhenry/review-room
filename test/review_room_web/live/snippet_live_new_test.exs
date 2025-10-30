defmodule ReviewRoomWeb.SnippetLive.NewTest do
  use ReviewRoomWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ReviewRoom.SnippetsFixtures

  setup [:register_and_log_in_user]
  setup :stub_buffer

  describe "new snippet form" do
    test "queues snippet and shows confirmation", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")

      form =
        form(lv, "#snippet-form",
          snippet: valid_snippet_attrs() |> Map.put("tags", "phoenix, liveview")
        )

      assert render_submit(form) =~ "Snippet queued (position 3)"
      assert has_element?(lv, "#snippet-confirmation", "Refactoring Phoenix contexts")
    end

    test "displays inline errors when required fields missing", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/snippets/new")

      form =
        form(lv, "#snippet-form",
          snippet: %{
            "title" => "",
            "description" => "",
            "body" => "",
            "syntax" => "",
            "visibility" => ""
          }
        )

      html = render_change(form)

      assert html =~ "can&#39;t be blank"
      assert html =~ "input-error"
      assert html =~ "textarea-error"
      assert html =~ "select-error"
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
