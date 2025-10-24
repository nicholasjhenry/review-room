defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Accounts.User
  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.PresenceTracker

  @moduledoc """
  Displays an individual snippet with collaborative enhancements including syntax highlighting,
  presence-aware cursors, clipboard shortcuts, and resilient reconnection handling.
  """

  @cursor_throttle_ms 75

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
        can_edit?: Snippets.can_edit?(scope, snippet),
        connection_status: :connected,
        viewer_meta: nil,
        last_cursor: nil,
        last_selection: nil,
        last_cursor_update_at: nil
      )

    socket =
      if connected?(socket) do
        # Subscribe to snippet topic for presence updates
        Phoenix.PubSub.subscribe(ReviewRoom.PubSub, "snippet:#{id}")

        # Track this user's presence
        presences_before = PresenceTracker.list_presences(id)
        user_id = get_user_id(socket, session)
        identity = build_presence_identity(socket, user_id, presences_before)
        color = assign_random_color()

        viewer_meta = %{
          display_name: identity.display_name,
          anonymous_number: identity.anonymous_number,
          color: color
        }

        {:ok, _ref} =
          PresenceTracker.track_user(
            id,
            user_id,
            Map.merge(viewer_meta, %{cursor: nil, selection: nil})
          )

        # Load initial presences
        presences = PresenceTracker.list_presences(id)

        socket
        |> assign(presences: presences)
        |> assign(user_id: user_id)
        |> assign(viewer_meta: viewer_meta)
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
              :if={@connection_status == :reconnecting}
              class="absolute inset-0 z-20 flex items-center justify-center bg-white/80 backdrop-blur-sm"
              role="status"
              aria-live="polite"
            >
              <div class="inline-flex items-center gap-3 rounded-full bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow">
                <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin text-blue-500" />
                <span>Reconnecting&hellip;</span>
              </div>
            </div>

            <% lines = String.split(@snippet.code || "", "\n") %>
            <div
              id="code-display"
              phx-hook="SyntaxHighlight"
              phx-update="ignore"
              class="relative z-0 overflow-hidden rounded-xl border border-slate-200 bg-slate-950 shadow-sm"
            >
              <div class="flex text-[13px] leading-6 text-slate-100">
                <div class="hidden select-none border-r border-slate-800/60 bg-slate-950/60 px-4 py-4 text-right font-mono text-[11px] uppercase tracking-wide text-slate-500 sm:block">
                  <div
                    :for={{_line, index} <- Enum.with_index(lines, 1)}
                    data-role="line-number"
                    class="tabular-nums"
                  >
                    {index}
                  </div>
                </div>
                <div class="w-full overflow-auto">
                  <pre
                    phx-no-curly-interpolation
                    class="min-h-[320px] bg-transparent px-4 py-4 font-mono text-sm text-slate-100"
                  ><code class={[
                    "block min-w-full whitespace-pre",
                    language_class(@snippet.language)
                  ]}><%= @snippet.code %></code></pre>
                </div>
              </div>
            </div>
          </div>

          <button
            type="button"
            phx-hook="ClipboardCopy"
            data-clipboard-target="#snippet-code-content"
            data-state="default"
            id="snippet-copy-button"
            class="absolute right-3 top-3 z-30 inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white/90 px-4 py-1.5 text-xs font-semibold text-slate-600 shadow transition hover:translate-y-[-1px] hover:border-blue-200 hover:text-blue-600"
          >
            <span data-default-state class="flex items-center gap-2">
              <.icon name="hero-clipboard" class="h-3.5 w-3.5" /> Copy
            </span>
            <span data-success-state class="hidden items-center gap-2 text-emerald-600">
              <.icon name="hero-check" class="h-3.5 w-3.5" /> Copied!
            </span>
            <span data-error-state class="hidden items-center gap-2 text-red-500">
              <.icon name="hero-exclamation-triangle" class="h-3.5 w-3.5" /> Retry
            </span>
          </button>

          <div id="snippet-code-content" class="sr-only" aria-hidden="true">{@snippet.code}</div>
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

        <div class="mt-6 flex gap-4 items-center flex-wrap">
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
          <.link
            :if={@current_scope && @current_scope.user}
            navigate={~p"/snippets/my"}
            class="text-gray-600 hover:text-gray-800"
          >
            My Snippets
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
    socket = assign(socket, :last_cursor, %{line: line, column: column})

    if rate_limited?(socket) or is_nil(socket.assigns.user_id) do
      {:noreply, socket}
    else
      user_id = socket.assigns.user_id
      snippet_id = socket.assigns.snippet.id

      {:ok, _ref} =
        PresenceTracker.update_cursor(snippet_id, user_id, %{
          cursor: %{line: line, column: column}
        })

      {:noreply, assign(socket, :last_cursor_update_at, System.monotonic_time(:millisecond))}
    end
  end

  @impl true
  def handle_event("text_selected", %{"start" => start, "end" => end_pos}, socket) do
    selection = %{
      start: %{line: start["line"], column: start["column"]},
      end: %{line: end_pos["line"], column: end_pos["column"]}
    }

    socket = assign(socket, :last_selection, selection)

    if socket.assigns.user_id do
      user_id = socket.assigns.user_id
      snippet_id = socket.assigns.snippet.id

      {:ok, _ref} =
        PresenceTracker.update_cursor(snippet_id, user_id, %{
          selection: selection
        })
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("selection_cleared", _params, socket) do
    socket = assign(socket, :last_selection, nil)

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
  def handle_event("connection_status", %{"status" => "disconnected"}, socket) do
    {:noreply, assign(socket, :connection_status, :reconnecting)}
  end

  def handle_event("connection_status", %{"status" => "connected"}, socket) do
    socket =
      socket
      |> maybe_restore_presence()
      |> assign(:connection_status, :connected)

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

  defp rate_limited?(socket) do
    now = System.monotonic_time(:millisecond)

    case socket.assigns[:last_cursor_update_at] do
      nil -> false
      last when is_integer(last) -> now - last < @cursor_throttle_ms
    end
  end

  defp maybe_restore_presence(%{assigns: %{user_id: nil}} = socket), do: socket

  defp maybe_restore_presence(%{assigns: %{user_id: _user_id, viewer_meta: nil}} = socket) do
    snippet_id = socket.assigns.snippet.id
    presences = PresenceTracker.list_presences(snippet_id)
    assign(socket, :presences, presences)
  end

  defp maybe_restore_presence(socket) do
    snippet_id = socket.assigns.snippet.id
    user_id = socket.assigns.user_id
    viewer_meta = socket.assigns.viewer_meta

    metadata =
      viewer_meta
      |> Map.merge(%{
        cursor: socket.assigns.last_cursor,
        selection: socket.assigns.last_selection
      })

    result = PresenceTracker.update_cursor(snippet_id, user_id, metadata)

    case result do
      {:ok, _ref} -> :ok
      {:error, _reason} -> PresenceTracker.track_user(snippet_id, user_id, metadata)
    end

    assign(socket, :presences, PresenceTracker.list_presences(snippet_id))
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

  defp build_presence_identity(socket, user_id, presences) do
    case socket.assigns.current_user do
      %User{} = user ->
        %{display_name: user_display_name(user), anonymous_number: nil}

      _ ->
        anonymous_presence_identity(user_id, presences)
    end
  end

  defp user_display_name(%User{email: email}) when is_binary(email), do: email
  defp user_display_name(_user), do: "User"

  defp anonymous_presence_identity(user_id, presences) do
    case Map.get(presences, user_id) do
      %{metas: [meta | _]} ->
        %{
          display_name: meta[:display_name] || anonymous_label(presences),
          anonymous_number: extract_anonymous_number(meta)
        }

      _ ->
        number = next_available_anonymous_number(presences)

        %{
          display_name: "Anonymous User #{number}",
          anonymous_number: number
        }
    end
  end

  defp anonymous_label(presences) do
    number = next_available_anonymous_number(presences)
    "Anonymous User #{number}"
  end

  defp next_available_anonymous_number(presences) do
    used_numbers =
      presences
      |> Map.values()
      |> Enum.flat_map(fn %{metas: metas} -> metas end)
      |> Enum.map(&extract_anonymous_number/1)
      |> Enum.filter(&is_integer/1)
      |> MapSet.new()

    Stream.iterate(1, &(&1 + 1))
    |> Enum.find(fn number -> not MapSet.member?(used_numbers, number) end)
  end

  defp extract_anonymous_number(meta) when is_map(meta) do
    cond do
      is_integer(meta[:anonymous_number]) ->
        meta[:anonymous_number]

      is_binary(meta[:display_name]) ->
        case meta[:display_name] do
          "Anonymous User " <> rest ->
            case Integer.parse(rest) do
              {number, ""} -> number
              _ -> nil
            end

          _ ->
            nil
        end

      true ->
        nil
    end
  end

  defp extract_anonymous_number(_), do: nil

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
