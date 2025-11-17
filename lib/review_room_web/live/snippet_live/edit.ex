defmodule ReviewRoomWeb.SnippetLive.Edit do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    scope = socket.assigns.current_scope

    case Snippets.get_snippet(scope, slug) do
      {:ok, snippet} ->
        changeset = Snippets.change_snippet(snippet)

        {:ok,
         socket
         |> assign(:page_title, "Edit Snippet")
         |> assign(:snippet, snippet)
         |> assign(:form, to_form(changeset))}

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
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    changeset =
      socket.assigns.snippet
      |> Snippets.change_snippet(snippet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    scope = socket.assigns.current_scope
    snippet = socket.assigns.snippet

    case Snippets.update_snippet(scope, snippet, snippet_params) do
      {:ok, snippet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet updated successfully")
         |> push_navigate(to: ~p"/s/#{snippet.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp language_options do
    supported_languages = Snippets.supported_languages()

    Enum.map(supported_languages, fn lang ->
      {String.capitalize(lang), lang}
    end)
  end
end
