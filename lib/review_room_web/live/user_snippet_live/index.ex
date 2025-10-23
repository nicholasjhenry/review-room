defmodule ReviewRoomWeb.UserSnippetLive.Index do
  use ReviewRoomWeb, :live_view

  alias Phoenix.PubSub
  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  @impl true
  def mount(_params, _session, socket) do
    user = current_user(socket)

    if is_nil(user) do
      {:ok,
       socket
       |> put_flash(:error, "You must be signed in to view your snippets.")
       |> redirect(to: ~p"/users/log-in")}
    else
      snippets = Snippets.list_user_snippets(user.id)

      {:ok,
       socket
       |> assign(:user, user)
       |> assign(:page_title, "My Snippets")
       |> stream(:snippets, snippets, reset: true)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    with %Snippet{} = snippet <- Snippets.get_snippet!(id),
         {:ok, deleted} <- Snippets.delete_snippet(snippet, socket.assigns.user) do
      PubSub.broadcast(
        ReviewRoom.PubSub,
        "snippet:#{deleted.id}",
        {:snippet_deleted, %{id: deleted.id}}
      )

      {:noreply,
       socket
       |> stream_delete(:snippets, deleted)
       |> put_flash(:info, "Snippet deleted")}
    else
      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You do not have permission to delete this snippet.")}
    end
  end

  @impl true
  def handle_event("toggle_visibility", %{"id" => id}, socket) do
    snippet = Snippets.get_snippet!(id)

    case Snippets.toggle_visibility(snippet, socket.assigns.user) do
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
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-5xl px-4 py-8 space-y-8">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold tracking-tight text-gray-900">My Snippets</h1>
            <p class="mt-2 text-sm text-gray-600">
              Manage your snippets, toggle their visibility, or remove ones you no longer need.
            </p>
          </div>
          <.link
            navigate={~p"/snippets/new"}
            class="inline-flex items-center justify-center rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 transition"
          >
            New Snippet
          </.link>
        </div>

        <div
          id="user-snippets"
          phx-update="stream"
          class="grid gap-4 md:grid-cols-2"
        >
          <div
            id="user-snippets-empty"
            class="col-span-full text-sm text-gray-500 italic only:block"
          >
            You have no snippets yet. Create your first snippet to see it here.
          </div>

          <div
            :for={{dom_id, snippet} <- @streams.snippets}
            id={dom_id}
            data-snippet-id={snippet.id}
            class="relative overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm transition hover:shadow-md"
          >
            <div class="p-5 space-y-3">
              <div class="flex items-center justify-between">
                <h2 class="text-lg font-semibold text-gray-900 truncate">
                  {snippet.title || "Untitled Snippet"}
                </h2>
                <span class={[
                  "inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold",
                  snippet.visibility == :public && "bg-emerald-50 text-emerald-700",
                  snippet.visibility == :private && "bg-gray-100 text-gray-600"
                ]}>
                  {if snippet.visibility == :public, do: "Public", else: "Private"}
                </span>
              </div>

              <p class="text-sm text-gray-500 line-clamp-3">
                {snippet.description || "No description provided."}
              </p>

              <div class="flex flex-wrap items-center gap-2 text-xs text-gray-500">
                <span class="flex items-center gap-1">
                  <.icon name="hero-clock" class="w-4 h-4" />
                  Updated {format_timestamp(snippet.updated_at || snippet.inserted_at)}
                </span>
                <span :if={snippet.language} class="flex items-center gap-1">
                  <.icon name="hero-code-bracket" class="w-4 h-4" />
                  {snippet.language}
                </span>
              </div>
            </div>

            <div class="flex flex-wrap items-center justify-between gap-3 bg-gray-50 px-5 py-3">
              <div class="flex items-center gap-3">
                <.link
                  navigate={~p"/s/#{snippet.id}"}
                  class="text-sm font-semibold text-blue-600 hover:text-blue-700"
                >
                  View
                </.link>
                <.link
                  navigate={~p"/s/#{snippet.id}/edit"}
                  class="text-sm font-semibold text-gray-600 hover:text-gray-800"
                >
                  Edit
                </.link>
              </div>
              <div class="flex items-center gap-3">
                <button
                  type="button"
                  id={"toggle-visibility-#{snippet.id}"}
                  phx-click="toggle_visibility"
                  phx-value-id={snippet.id}
                  class="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-1 text-xs font-semibold text-gray-700 hover:bg-gray-100 transition"
                >
                  {if snippet.visibility == :public, do: "Make private", else: "Make public"}
                </button>

                <button
                  type="button"
                  id={"delete-snippet-#{snippet.id}"}
                  phx-click="delete"
                  phx-value-id={snippet.id}
                  phx-confirm="Delete this snippet permanently?"
                  class="inline-flex items-center rounded-md border border-red-200 bg-red-50 px-3 py-1 text-xs font-semibold text-red-700 hover:bg-red-100 transition"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp current_user(socket) do
    case socket.assigns[:current_scope] do
      %{user: user} -> user
      _ -> nil
    end
  end

  defp format_timestamp(nil), do: "moments ago"

  defp format_timestamp(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y %H:%M")
  end
end
