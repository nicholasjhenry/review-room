defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Accounts.User
  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.PresenceTracker
  alias ReviewRoomWeb.Components.DesignSystem.NavigationComponents, as: DSNavigation

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
        last_cursor_update_at: nil,
        workspace_loading?: true,
        workspace_state: "loading",
        activity_entries: [],
        chrome: %{active_item: :workspace}
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
        |> assign(:workspace_loading?, false)
        |> assign(:workspace_state, "ready")
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:header_meta, workspace_meta(assigns.snippet))
      |> assign(:header_breadcrumbs, workspace_breadcrumbs(assigns.snippet))
      |> assign(:header_subtitle, workspace_subtitle(assigns.snippet))
      |> assign(:presence_entries, presence_entries(assigns.presences))
      |> assign(:presence_count, map_size(assigns.presences))
      |> assign(:activity_empty?, Enum.empty?(assigns.activity_entries || []))
      |> assign(
        :updated_label,
        format_timestamp(assigns.snippet.updated_at || assigns.snippet.inserted_at)
      )

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} chrome={@chrome}>
      <DSNavigation.page_header
        id="workspace-header"
        eyebrow="Workspace"
        title={@snippet.title || "Code Snippet"}
        subtitle={@header_subtitle}
        breadcrumbs={@header_breadcrumbs}
        meta={@header_meta}
      >
        <:actions>
          <.link
            navigate={~p"/snippets"}
            class="inline-flex items-center gap-2 rounded-full border border-white/35 bg-white/10 px-4 py-2 text-sm font-semibold text-white transition hover:bg-white/20"
          >
            <.icon name="hero-arrow-uturn-left" class="h-4 w-4" /> Back to gallery
          </.link>
          <.link
            :if={@can_edit?}
            navigate={~p"/s/#{@snippet.id}/edit"}
            class="inline-flex items-center gap-2 rounded-full bg-white px-4 py-2 text-sm font-semibold text-slate-900 shadow transition hover:shadow-lg"
          >
            <.icon name="hero-pencil-square" class="h-4 w-4" /> Edit snippet
          </.link>
        </:actions>
      </DSNavigation.page_header>

      <section
        id="workspace-shell"
        data-state={@workspace_state}
        class="workspace-shell space-y-8"
      >
        <%= if @workspace_loading? do %>
          <DSNavigation.workspace_skeleton />
        <% else %>
          <div
            id="workspace-content"
            class="workspace-grid grid gap-8 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]"
          >
            <div class="workspace-main rounded-3xl border border-slate-200/70 bg-white/95 p-6 shadow-sm shadow-slate-200/50 lg:p-7">
              <div class="flex flex-wrap items-center gap-3 text-xs font-semibold uppercase tracking-[0.3em] text-slate-500">
                <span class="inline-flex items-center gap-2 rounded-full bg-slate-900/5 px-3 py-1 text-[0.65rem] font-semibold uppercase tracking-[0.35em] text-slate-600">
                  <.icon name="hero-command-line" class="h-3.5 w-3.5" />
                  {language_label(@snippet.language)}
                </span>
                <span class={[
                  "inline-flex items-center gap-2 rounded-full px-3 py-1 text-[0.65rem] font-semibold uppercase tracking-[0.35em]",
                  visibility_class(@snippet.visibility)
                ]}>
                  <.icon name="hero-eye" class="h-3.5 w-3.5" />
                  {visibility_label(@snippet.visibility)}
                </span>
                <span class="inline-flex items-center gap-2 rounded-full bg-slate-900/5 px-3 py-1 text-[0.65rem] font-semibold uppercase tracking-[0.35em] text-slate-600">
                  <.icon name="hero-clock" class="h-3.5 w-3.5" /> Updated {@updated_label}
                </span>
              </div>

              <p
                :if={@snippet.description}
                class="mt-5 text-base leading-relaxed text-slate-600"
              >
                {@snippet.description}
              </p>

              <p class="mt-3 text-sm text-slate-500">
                {default_workspace_tagline()}
              </p>

              <div class="relative mt-6">
                <div
                  id="cursor-tracker"
                  phx-hook="CursorTracker"
                  class="relative"
                >
                  <div
                    id="presence-overlay"
                    phx-hook="PresenceRenderer"
                    data-presences={Jason.encode!(@presences)}
                    class="absolute inset-0 pointer-events-none z-20"
                  >
                  </div>

                  <div
                    :if={@connection_status == :reconnecting}
                    class="absolute inset-0 z-30 flex items-center justify-center bg-white/85 backdrop-blur-sm"
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
                    class="overflow-hidden rounded-2xl border border-slate-200/60 bg-slate-950 shadow-sm"
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
                  class="absolute right-4 top-4 z-40 inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white/95 px-4 py-1.5 text-xs font-semibold text-slate-600 shadow transition duration-150 hover:-translate-y-0.5 hover:border-blue-200 hover:text-blue-600"
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

                <div id="snippet-code-content" class="sr-only" aria-hidden="true">
                  {@snippet.code}
                </div>
              </div>

              <div class="mt-8 flex flex-wrap items-center gap-3 text-sm font-semibold text-slate-600">
                <.link
                  navigate={~p"/snippets/new"}
                  class="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-1.5 transition hover:border-slate-300 hover:text-slate-900"
                >
                  <.icon name="hero-sparkles" class="h-4 w-4" /> Create new snippet
                </.link>
                <.link
                  :if={@can_edit?}
                  navigate={~p"/s/#{@snippet.id}/edit"}
                  class="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-1.5 transition hover:border-slate-300 hover:text-slate-900"
                >
                  <.icon name="hero-adjustments-horizontal" class="h-4 w-4" /> Refine design
                </.link>
                <.link
                  :if={@current_scope && @current_scope.user}
                  navigate={~p"/snippets/my"}
                  class="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-1.5 transition hover:border-slate-300 hover:text-slate-900"
                >
                  <.icon name="hero-folder" class="h-4 w-4" /> My dashboard
                </.link>
              </div>
            </div>

            <aside class="workspace-rail space-y-6">
              <section
                class="rounded-3xl border border-slate-200/70 bg-white/95 p-6 shadow-sm shadow-slate-200/50"
                id="workspace-activity"
              >
                <header class="flex items-center justify-between gap-3">
                  <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.35em] text-slate-400">
                      Activity
                    </p>
                    <h2 class="mt-1 text-lg font-semibold text-slate-900">
                      Timeline highlights
                    </h2>
                  </div>
                </header>

                <DSNavigation.empty_state
                  :if={@activity_empty?}
                  id="workspace-activity-empty"
                  context="timeline"
                  icon="hero-sparkles"
                  title="Timeline is warming up"
                  message="Updates land here once collaborators edit, share, or adjust visibility."
                  class="mt-6"
                />
              </section>

              <section class="rounded-3xl border border-slate-200/70 bg-white/95 p-6 shadow-sm shadow-slate-200/50">
                <header class="flex items-center justify-between gap-3">
                  <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.35em] text-slate-400">
                      Collaborators
                    </p>
                    <h2 class="mt-1 text-lg font-semibold text-slate-900">
                      Active Viewers ({@presence_count})
                    </h2>
                  </div>
                </header>

                <div
                  id="presence-list"
                  class="mt-4 divide-y divide-slate-200 text-sm text-slate-600"
                >
                  <p
                    :if={@presence_entries == []}
                    class="py-4 text-center italic text-slate-400"
                  >
                    No active viewers
                  </p>

                  <div
                    :for={{user_id, meta} <- @presence_entries}
                    id={"presence-#{user_id}"}
                    class="flex items-center gap-4 py-4"
                  >
                    <div
                      class="h-3.5 w-3.5 rounded-full"
                      style={"background-color: #{meta[:color] || "#6B7280"}"}
                      title={"Viewer color: #{meta[:color] || "#6B7280"}"}
                    >
                    </div>
                    <div class="min-w-0 flex-1">
                      <p class="truncate font-semibold text-slate-900">
                        {meta.display_name}
                      </p>
                      <div class="mt-1 flex flex-wrap gap-3 text-xs text-slate-500">
                        <span :if={meta[:cursor]} class="inline-flex items-center gap-1">
                          <.icon name="hero-cursor-arrow-rays" class="h-3 w-3" />
                          Line {meta.cursor.line}, Col {meta.cursor.column}
                        </span>
                        <span :if={meta[:selection]} class="inline-flex items-center gap-1">
                          <.icon name="hero-document-text" class="h-3 w-3" />
                          L{meta.selection.start.line}:{meta.selection.start.column} →
                          L{meta.selection.end.line}:{meta.selection.end.column}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </section>
            </aside>
          </div>
        <% end %>
      </section>
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

  defp workspace_subtitle(%{description: desc}) when is_binary(desc) and desc != "", do: desc
  defp workspace_subtitle(_), do: default_workspace_tagline()

  defp default_workspace_tagline do
    "Collaborate in real-time with presence-aware editing, clipboard polish, and stream-friendly updates tuned for Spec 003."
  end

  defp workspace_meta(snippet) do
    [
      visibility_meta(snippet.visibility),
      language_meta(snippet.language),
      updated_meta(snippet.updated_at || snippet.inserted_at)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp visibility_meta(nil), do: nil

  defp visibility_meta(visibility) do
    %{icon: "hero-eye", label: "Visibility · #{visibility_label(visibility)}"}
  end

  defp language_meta(nil), do: %{icon: "hero-command-line", label: "Language · AUTO"}

  defp language_meta(language) do
    %{icon: "hero-command-line", label: "Language · #{language_label(language)}"}
  end

  defp updated_meta(nil), do: nil

  defp updated_meta(datetime),
    do: %{icon: "hero-clock", label: "Updated #{format_timestamp(datetime)}"}

  defp workspace_breadcrumbs(snippet) do
    [
      %{label: "Discover", href: ~p"/snippets"},
      %{label: "Workspace", href: ~p"/snippets/my"},
      %{label: snippet.title || "Code Snippet", href: ~p"/s/#{snippet.id}", current?: true}
    ]
  end

  defp presence_entries(presences) do
    presences
    |> Enum.map(fn
      {user_id, %{metas: [meta | _]}} -> {user_id, meta}
      {user_id, %{metas: []}} -> {user_id, %{}}
    end)
    |> Enum.sort_by(fn {_id, meta} ->
      meta
      |> Map.get(:display_name, "")
      |> String.downcase()
    end)
  end

  defp visibility_label(:public), do: "Public"
  defp visibility_label(:private), do: "Private"
  defp visibility_label(:unlisted), do: "Unlisted"

  defp visibility_label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp visibility_label(value) when is_atom(value), do: visibility_label(Atom.to_string(value))
  defp visibility_label(_), do: "Private"

  defp visibility_class(:public), do: "bg-emerald-50 text-emerald-700"
  defp visibility_class(:private), do: "bg-slate-100 text-slate-600"
  defp visibility_class(:unlisted), do: "bg-amber-50 text-amber-700"
  defp visibility_class(_), do: "bg-slate-100 text-slate-600"

  defp language_label(nil), do: "AUTO"

  defp language_label(language) when is_binary(language) do
    language
    |> String.trim()
    |> String.upcase()
  end

  defp language_label(language) when is_atom(language),
    do: language |> Atom.to_string() |> language_label()

  defp language_label(_), do: "AUTO"

  defp format_timestamp(nil), do: "moments ago"

  defp format_timestamp(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y %H:%M")
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
