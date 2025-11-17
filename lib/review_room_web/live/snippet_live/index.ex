defmodule ReviewRoomWeb.SnippetLive.Index do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    snippets = Snippets.list_snippets(scope)

    {:ok, stream(socket, :snippets, snippets)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"slug" => slug}, socket) do
    scope = socket.assigns.current_scope

    case Snippets.get_snippet(scope, slug) do
      {:ok, snippet} ->
        case Snippets.delete_snippet(scope, snippet) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Snippet deleted successfully")
             |> stream_delete(:snippets, snippet)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to delete snippet")}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Snippet not found")}
    end
  end
end
