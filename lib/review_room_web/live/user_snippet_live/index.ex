defmodule ReviewRoomWeb.UserSnippetLive.Index do
  use ReviewRoomWeb, :live_view

  alias Phoenix.PubSub
  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoomWeb.Components.DesignSystem.NavigationComponents, as: DSNavigation

  @moduledoc """
  LiveView dashboard for managing a user’s snippets with visibility toggles, deletion controls,
  and real-time updates synchronized with collaborative sessions.
  """

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns[:current_scope]
    user = scope && scope.user

    if is_nil(user) do
      {:ok,
       socket
       |> put_flash(:error, "You must be signed in to view your snippets.")
       |> redirect(to: ~p"/users/log-in")}
    else
      snippets = Snippets.list_user_snippets(scope)

      {:ok,
       socket
       |> assign(:user, user)
       |> assign(:page_title, "My Snippets")
       |> assign(:chrome, %{active_item: :workspace})
       |> stream(:snippets, snippets, reset: true)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    scope = socket.assigns[:current_scope]

    with %Snippet{} = snippet <- Snippets.get_snippet!(id),
         {:ok, deleted} <- Snippets.delete_snippet(scope, snippet) do
      PubSub.broadcast(
        ReviewRoom.PubSub,
        "snippet:#{deleted.id}",
        {:snippet_deleted, %{id: deleted.id}}
      )

      {:noreply,
       socket
       |> stream_delete(:snippets, deleted)
       |> put_flash(:info, "Snippet deleted successfully")}
    else
      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You do not have permission to delete this snippet.")}
    end
  end

  @impl true
  def handle_event("toggle_visibility", %{"id" => id}, socket) do
    scope = socket.assigns[:current_scope]
    snippet = Snippets.get_snippet!(id)

    case Snippets.toggle_visibility(scope, snippet) do
      {:ok, updated} ->
        PubSub.broadcast(
          ReviewRoom.PubSub,
          "snippet:#{updated.id}",
          {:snippet_updated, %{id: updated.id}}
        )

        {:noreply,
         socket
         |> stream_insert(:snippets, updated)
         |> put_flash(:info, "Snippet visibility updated")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You do not have permission to update this snippet.")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Unable to update snippet. Please review the details and try again."
         )}
    end
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :snippet_count, map_size(assigns.streams.snippets))

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} chrome={@chrome}>
      <DSNavigation.page_header
        id="dashboard-header"
        eyebrow="Workspace"
        title="My Snippets"
        subtitle="Change visibility, polish copy, and share with collaborators from one focused dashboard."
        breadcrumbs={[
          %{label: "Workspace", href: ~p"/snippets/my", current?: true}
        ]}
        meta={[
          %{icon: "hero-queue-list", label: "Snippets · #{@snippet_count}"}
        ]}
      >
        <:actions>
          <.link
            navigate={~p"/snippets/new"}
            class="inline-flex items-center gap-2 rounded-full bg-white px-4 py-2 text-sm font-semibold text-slate-900 shadow transition hover:shadow-lg"
          >
            <.icon name="hero-plus" class="h-4 w-4" /> New snippet
          </.link>
        </:actions>
      </DSNavigation.page_header>

      <div
        id="user-snippets"
        phx-update="stream"
        class="dashboard-grid grid gap-6 lg:grid-cols-2 xl:grid-cols-3"
      >
        <DSNavigation.empty_state
          id="user-snippets-empty"
          context="dashboard"
          icon="hero-sparkles"
          title="You have no snippets yet"
          message="Craft your first snippet to light up this dashboard with presence-aware cards."
          class="col-span-full hidden only:flex"
        >
          <:actions>
            <.link
              navigate={~p"/snippets/new"}
              class="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-1.5 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
            >
              <.icon name="hero-plus" class="h-4 w-4" /> Create snippet
            </.link>
          </:actions>
        </DSNavigation.empty_state>

        <article
          :for={{dom_id, snippet} <- @streams.snippets}
          id={dom_id}
          data-snippet-id={snippet.id}
          class="flex h-full flex-col justify-between gap-5 rounded-3xl border border-slate-200/70 bg-white/95 p-6 shadow-sm shadow-slate-200/50 transition hover:-translate-y-1 hover:shadow-lg"
        >
          <div class="space-y-4">
            <header class="flex flex-wrap items-center justify-between gap-3">
              <h2 class="text-xl font-semibold tracking-tight text-slate-900 line-clamp-1">
                {snippet.title || "Untitled Snippet"}
              </h2>
              <span class={[
                "inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-[0.3em]",
                snippet.visibility == :public && "bg-emerald-50 text-emerald-700",
                snippet.visibility == :private && "bg-slate-100 text-slate-600",
                snippet.visibility == :unlisted && "bg-amber-50 text-amber-700"
              ]}>
                {visibility_label(snippet.visibility)}
              </span>
            </header>

            <p class="text-sm leading-relaxed text-slate-600 line-clamp-3">
              {snippet.description ||
                "No description provided yet — polish your snippet details to delight reviewers."}
            </p>

            <div class="flex flex-wrap items-center gap-3 text-xs font-semibold text-slate-500">
              <span class="inline-flex items-center gap-1.5 rounded-full bg-slate-900/5 px-3 py-1">
                <.icon name="hero-clock" class="h-3.5 w-3.5" />
                Updated {format_timestamp(snippet.updated_at || snippet.inserted_at)}
              </span>
              <span
                :if={snippet.language}
                class="inline-flex items-center gap-1.5 rounded-full bg-slate-900/5 px-3 py-1"
              >
                <.icon name="hero-code-bracket-square" class="h-3.5 w-3.5" />
                {String.upcase(snippet.language)}
              </span>
            </div>
          </div>

          <footer class="flex flex-wrap items-center justify-between gap-4">
            <div class="flex items-center gap-3 text-sm font-semibold">
              <.link
                navigate={~p"/s/#{snippet.id}"}
                class="inline-flex items-center gap-2 rounded-full border border-slate-200 px-3 py-1.5 transition hover:border-slate-300 hover:text-slate-900"
              >
                <.icon name="hero-eye" class="h-4 w-4" /> View
              </.link>
              <.link
                navigate={~p"/s/#{snippet.id}/edit"}
                class="inline-flex items-center gap-2 rounded-full border border-slate-200 px-3 py-1.5 transition hover:border-slate-300 hover:text-slate-900"
              >
                <.icon name="hero-pencil-square" class="h-4 w-4" /> Edit
              </.link>
            </div>

            <div class="flex items-center gap-3">
              <button
                type="button"
                id={"toggle-visibility-#{snippet.id}"}
                phx-click="toggle_visibility"
                phx-value-id={snippet.id}
                class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
                phx-click-loading="opacity-60"
              >
                {if snippet.visibility == :public, do: "Make private", else: "Make public"}
              </button>

              <button
                type="button"
                id={"delete-snippet-#{snippet.id}"}
                phx-click="delete"
                phx-value-id={snippet.id}
                phx-confirm="Delete this snippet permanently?"
                class="inline-flex items-center gap-2 rounded-full border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-700 transition hover:bg-red-100"
                phx-click-loading="opacity-60"
              >
                Delete
              </button>
            </div>
          </footer>
        </article>
      </div>
    </Layouts.app>
    """
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

  defp format_timestamp(nil), do: "moments ago"

  defp format_timestamp(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y %H:%M")
  end
end
