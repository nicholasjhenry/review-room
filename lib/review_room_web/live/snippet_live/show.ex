defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.PresenceTracker

  @impl true
  def mount(%{"id" => id}, session, socket) do
    snippet = Snippets.get_snippet!(id)

    socket =
      socket
      |> assign(snippet: snippet, page_title: snippet.title || "Code Snippet")
      |> assign(presences: %{})
      |> assign(user_id: nil)

    socket =
      if connected?(socket) do
        # Subscribe to snippet topic for presence updates
        Phoenix.PubSub.subscribe(ReviewRoom.PubSub, "snippet:#{id}")

        # Track this user's presence
        user_id = get_user_id(socket, session)
        display_name = get_display_name(socket)

        {:ok, _ref} =
          PresenceTracker.track_user(id, user_id, %{
            display_name: display_name,
            cursor: nil,
            selection: nil
          })

        # Load initial presences
        presences = PresenceTracker.list_presences(id)

        socket
        |> assign(presences: presences)
        |> assign(user_id: user_id)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-6xl px-4 py-8">
        <div class="mb-6">
          <div class="flex items-center justify-between mb-2">
            <h1 class="text-3xl font-bold">
              {@snippet.title || "Code Snippet"}
            </h1>
            <div class="flex gap-2 text-sm text-gray-600">
              <span :if={@snippet.language} class="px-2 py-1 bg-gray-100 rounded">
                {@snippet.language}
              </span>
              <span class="px-2 py-1 bg-gray-100 rounded">
                {if @snippet.visibility == :public, do: "Public", else: "Private"}
              </span>
            </div>
          </div>

          <p :if={@snippet.description} class="text-gray-600 mt-2">
            {@snippet.description}
          </p>
        </div>

        <div class="relative">
          <div
            id="cursor-tracker"
            phx-hook="CursorTracker"
            class="relative"
          >
            <div
              id="code-display"
              phx-hook="SyntaxHighlight"
              phx-update="ignore"
              class="rounded-lg overflow-hidden border border-gray-200"
            >
              <pre class="p-4 bg-gray-50 overflow-x-auto"><code class={language_class(@snippet.language)}><%= @snippet.code %></code></pre>
            </div>
          </div>

          <button
            type="button"
            phx-click={JS.dispatch("phx:copy", to: "#snippet-code-content")}
            class="absolute top-2 right-2 px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-50"
          >
            Copy
          </button>

          <div id="snippet-code-content" class="hidden">{@snippet.code}</div>
        </div>

        <div class="mt-6 flex gap-4">
          <.link navigate={~p"/snippets/new"} class="text-blue-600 hover:text-blue-800">
            Create New Snippet
          </.link>
          <.link navigate={~p"/"} class="text-gray-600 hover:text-gray-800">
            Home
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("cursor_moved", %{"line" => line, "column" => column}, socket) do
    if socket.assigns.user_id do
      user_id = socket.assigns.user_id
      snippet_id = socket.assigns.snippet.id

      {:ok, _ref} =
        PresenceTracker.update_cursor(snippet_id, user_id, %{
          cursor: %{line: line, column: column}
        })
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("text_selected", %{"start" => start, "end" => end_pos}, socket) do
    if socket.assigns.user_id do
      user_id = socket.assigns.user_id
      snippet_id = socket.assigns.snippet.id

      {:ok, _ref} =
        PresenceTracker.update_cursor(snippet_id, user_id, %{
          selection: %{
            start: %{line: start["line"], column: start["column"]},
            end: %{line: end_pos["line"], column: end_pos["column"]}
          }
        })
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("selection_cleared", _params, socket) do
    if socket.assigns.user_id do
      user_id = socket.assigns.user_id
      snippet_id = socket.assigns.snippet.id

      {:ok, _ref} =
        PresenceTracker.update_cursor(snippet_id, user_id, %{
          selection: nil
        })
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:presence_diff, %{joins: joins, leaves: leaves}}, socket) do
    # Convert joins (list of tuples) to map format
    joins_map =
      Enum.into(joins, %{}, fn {user_id, meta} ->
        {user_id, %{metas: [meta]}}
      end)

    # Get leave keys
    leave_keys = Enum.map(leaves, fn {user_id, _meta} -> user_id end)

    presences =
      socket.assigns.presences
      |> Map.merge(joins_map)
      |> Map.drop(leave_keys)

    {:noreply, assign(socket, presences: presences)}
  end

  defp language_class(nil), do: ""
  defp language_class(lang), do: "language-#{lang}"

  defp get_user_id(socket, session) do
    cond do
      Map.has_key?(socket.assigns, :current_user) and socket.assigns.current_user != nil ->
        "user_#{socket.assigns.current_user.id}"

      Map.has_key?(session, "live_socket_id") ->
        session["live_socket_id"]

      true ->
        # Generate a unique ID for anonymous users
        "anon_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
    end
  end

  defp get_display_name(socket) do
    if Map.has_key?(socket.assigns, :current_user) and socket.assigns.current_user != nil do
      socket.assigns.current_user.email
    else
      "Anonymous User"
    end
  end
end
