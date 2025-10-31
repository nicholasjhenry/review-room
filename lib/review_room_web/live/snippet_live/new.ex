defmodule ReviewRoomWeb.SnippetLive.New do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  @impl true
  def mount(_params, _session, socket) do
    languages = Snippets.supported_language_options()

    changeset = Snippets.change_snippet(%Snippet{})

    {:ok,
     socket
     |> assign(:page_title, "Create Snippet")
     |> assign(:language_options, languages)
     |> assign(:visibility_options, visibility_options())
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"snippet" => params}, socket) do
    changeset =
      %Snippet{}
      |> Snippets.change_snippet(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"snippet" => params}, socket) do
    case Snippets.create_snippet(socket.assigns.current_scope, params) do
      {:ok, snippet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet saved successfully")
         |> push_navigate(to: ~p"/snippets/#{snippet}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp visibility_options do
    [
      {"Private", "private"},
      {"Public", "public"}
    ]
  end
end
