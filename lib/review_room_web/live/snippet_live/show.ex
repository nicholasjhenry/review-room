defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Snippets.get_snippet(socket.assigns.current_scope, id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Snippet not found or you do not have access.")
         |> redirect(to: ~p"/")}

      snippet ->
        {:ok,
         socket
         |> assign(:snippet, snippet)
         |> assign(:language_label, Snippets.language_label(snippet.language))
         |> assign(:page_title, snippet.title || "Snippet")
         |> assign(:display_title, display_title(snippet))}
    end
  end

  defp display_title(%{title: nil}), do: "Snippet"
  defp display_title(%{title: ""}), do: "Snippet"
  defp display_title(%{title: title}), do: title
end
