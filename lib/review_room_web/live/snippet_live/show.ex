defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.PresenceTracker

  @impl true
  def mount(%{"id" => id}, session, socket) do
    snippet = Snippets.get_snippet!(id)
    scope = socket.assigns[:current_scope]
    current_user = current_user(socket)

    socket =
      socket
      |> assign(
        snippet: snippet,
        page_title: snippet.title || "Code Snippet",
        presences: %{},
        user_id: nil,
        current_user: current_user,
        can_edit?: Snippets.can_edit?(scope, snippet)
      )

    socket =
      if connected?(socket) do
        # Subscribe to snippet topic for presence updates
        Phoenix.PubSub.subscribe(ReviewRoom.PubSub, "snippet:#{id}")

        # Track this user's presence
        user_id = get_user_id(socket, session)
        display_name = get_display_name(socket)
        color = assign_random_color()

        {:ok, _ref} =
          PresenceTracker.track_user(id, user_id, %{
            display_name: display_name,
            color: color,
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
            <%!-- Presence Overlay for cursor and selection rendering --%>
            <div
              id="presence-overlay"
              phx-hook="PresenceRenderer"
              data-presences={Jason.encode!(@presences)}
              class="absolute inset-0 pointer-events-none z-10"
            >
            </div>

            <div
              id="code-display"
              phx-hook="SyntaxHighlight"
              phx-update="ignore"
              class="rounded-lg overflow-hidden border border-gray-200 relative z-0"
            >
              <pre class="p-4 bg-gray-50 overflow-x-auto"><code class={language_class(@snippet.language)}><%= @snippet.code %></code></pre>
            </div>
          </div>

          <button
            type="button"
            phx-click={JS.dispatch("phx:copy", to: "#snippet-code-content")}
            class="absolute top-2 right-2 px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-50 z-20"
          >
            Copy
          </button>

          <div id="snippet-code-content" class="hidden">{@snippet.code}</div>
        </div>

        <%!-- Polished Presence List --%>
        <div id="presence-list" class="mt-6">
          <div class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
            <div class="px-4 py-3 bg-gray-50 border-b border-gray-200">
              <h3 class="text-sm font-semibold text-gray-900 flex items-center gap-2">
                <svg
                  class="w-4 h-4 text-gray-500"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                  />
                </svg>
                <span>Active Viewers ({map_size(@presences)})</span>
              </h3>
            </div>
            <ul class="divide-y divide-gray-200">
              <%= if map_size(@presences) == 0 do %>
                <li class="px-4 py-3 text-sm text-gray-500 italic">
                  No active viewers
                </li>
              <% else %>
                <%= for {_user_id, %{metas: metas}} <- @presences do %>
                  <% [meta] = metas %>
                  <li class="px-4 py-3 flex items-center gap-3 hover:bg-gray-50 transition-colors">
                    <div
                      class="w-3 h-3 rounded-full flex-shrink-0"
                      style={"background-color: #{meta[:color] || "#6B7280"}"}
                      title={"Viewer color: #{meta[:color] || "#6B7280"}"}
                    >
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-medium text-gray-900 truncate">
                        {meta.display_name}
                      </p>
                      <div class="flex gap-3 text-xs text-gray-500 mt-1">
                        <%= if meta[:cursor] do %>
                          <span class="flex items-center gap-1">
                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122"
                              />
                            </svg>
                            Line {meta.cursor.line}, Col {meta.cursor.column}
                          </span>
                        <% end %>
                        <%= if meta[:selection] do %>
                          <span class="flex items-center gap-1">
                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"
                              />
                            </svg>
                            Selected: L{meta.selection.start.line}:{meta.selection.start.column} → L{meta.selection.end.line}:{meta.selection.end.column}
                          </span>
                        <% end %>
                      </div>
                    </div>
                  </li>
                <% end %>
              <% end %>
            </ul>
          </div>
        </div>

        <div class="mt-6 flex gap-4 items-center">
          <.link navigate={~p"/snippets/new"} class="text-blue-600 hover:text-blue-800">
            Create New Snippet
          </.link>
          <.link
            :if={@can_edit?}
            navigate={~p"/s/#{@snippet.id}/edit"}
            class="text-gray-600 hover:text-gray-800"
          >
            Edit Snippet
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

    # Get leave keys - only drop users that are leaving but not re-joining (true leaves)
    # If a user appears in both leaves and joins, it's an update, not a leave
    join_keys = MapSet.new(Map.keys(joins_map))

    true_leave_keys =
      leaves
      |> Enum.map(fn {user_id, _meta} -> user_id end)
      |> Enum.reject(fn user_id -> MapSet.member?(join_keys, user_id) end)

    presences =
      socket.assigns.presences
      |> Map.drop(true_leave_keys)
      |> Map.merge(joins_map)

    {:noreply, assign(socket, presences: presences)}
  end

  @impl true
  def handle_info({:snippet_updated, %{id: snippet_id}}, socket) do
    if socket.assigns.snippet.id == snippet_id do
      snippet = Snippets.get_snippet!(snippet_id)
      can_edit? = Snippets.can_edit?(socket.assigns[:current_scope], snippet)

      {:noreply, assign(socket, snippet: snippet, can_edit?: can_edit?)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:snippet_deleted, %{id: snippet_id}}, socket) do
    if socket.assigns.snippet.id == snippet_id do
      {:noreply,
       socket
       |> put_flash(:error, "This snippet is no longer available.")
       |> push_navigate(to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  defp language_class(nil), do: ""
  defp language_class(lang), do: "language-#{lang}"

  defp get_user_id(socket, session) do
    cond do
      socket.assigns.current_user ->
        "user_#{socket.assigns.current_user.id}"

      Map.has_key?(session, "live_socket_id") ->
        session["live_socket_id"]

      true ->
        # Generate a unique ID for anonymous users
        "anon_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
    end
  end

  defp get_display_name(socket) do
    if socket.assigns.current_user do
      socket.assigns.current_user.email
    else
      "Anonymous User"
    end
  end

  defp current_user(socket) do
    case socket.assigns[:current_scope] do
      %{user: user} -> user
      _ -> nil
    end
  end

  # Assigns a random color from a palette of visually distinct colors
  defp assign_random_color do
    colors = [
      # Blue
      "#3B82F6",
      # Green
      "#10B981",
      # Amber
      "#F59E0B",
      # Red
      "#EF4444",
      # Purple
      "#8B5CF6",
      # Pink
      "#EC4899",
      # Teal
      "#14B8A6",
      # Orange
      "#F97316",
      # Cyan
      "#06B6D4",
      # Lime
      "#84CC16"
    ]

    Enum.random(colors)
  end
end
