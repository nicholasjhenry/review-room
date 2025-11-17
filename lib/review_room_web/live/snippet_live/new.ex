defmodule ReviewRoomWeb.SnippetLive.New do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  @impl true
  def mount(_params, _session, socket) do
    changeset = Snippets.change_snippet(%Snippet{})

    {:ok,
     socket
     |> assign(:page_title, "New Snippet")
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    changeset =
      %Snippet{}
      |> Snippets.change_snippet(snippet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    scope = socket.assigns.current_scope

    case Snippets.create_snippet(scope, snippet_params) do
      {:ok, snippet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet created successfully")
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
