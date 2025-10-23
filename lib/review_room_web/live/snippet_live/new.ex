defmodule ReviewRoomWeb.SnippetLive.New do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoomWeb.SnippetLive.Components

  @impl true
  def mount(_params, _session, socket) do
    changeset = Snippets.change_snippet(%Snippet{})

    {:ok,
     socket
     |> assign(:snippet, %Snippet{})
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    changeset =
      %Snippet{}
      |> Snippets.change_snippet(snippet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    case Snippets.create_snippet(socket.assigns[:current_scope], snippet_params) do
      {:ok, snippet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet created successfully")
         |> push_navigate(to: ~p"/s/#{snippet.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <Components.snippet_form
        title="New Snippet"
        description="Craft a new snippet to share or collaborate with your team instantly."
        form={@form}
        snippet={@snippet}
        id="snippet-form"
        submit_label="Create Snippet"
        submit_disable_with="Creating..."
        cancel_href={~p"/"}
      />
    </Layouts.app>
    """
  end
end
