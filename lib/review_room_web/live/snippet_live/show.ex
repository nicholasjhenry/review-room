defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    scope = socket.assigns.current_scope

    case Snippets.get_snippet(scope, slug) do
      {:ok, snippet} ->
        {:ok, assign(socket, :snippet, snippet)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Snippet not found")
         |> push_navigate(to: ~p"/snippets")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    scope = socket.assigns.current_scope
    snippet = socket.assigns.snippet

    case Snippets.delete_snippet(scope, snippet) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet deleted successfully")
         |> push_navigate(to: ~p"/snippets")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete snippet")}
    end
  end
end
