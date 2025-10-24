defmodule ReviewRoomWeb.SnippetLive.Edit do
  use ReviewRoomWeb, :live_view

  alias Phoenix.PubSub
  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoomWeb.SnippetLive.Components

  @moduledoc """
  LiveView for editing existing snippets with authorization safeguards,
  optimistic UI updates, and polished form interactions.
  """

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    snippet = Snippets.get_snippet!(id)
    scope = socket.assigns[:current_scope]

    if Snippets.can_edit?(scope, snippet) do
      changeset = Snippet.update_changeset(snippet, %{})

      {:ok,
       socket
       |> assign(:snippet, snippet)
       |> assign(:page_title, "Edit Snippet")
       |> assign(:form, to_form(changeset))}
    else
      {:ok,
       socket
       |> put_flash(:error, "You do not have permission to edit this snippet.")
       |> redirect(to: ~p"/s/#{snippet.id}")}
    end
  end

  @impl true
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    changeset =
      socket.assigns.snippet
      |> Snippet.update_changeset(snippet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    snippet = socket.assigns.snippet
    scope = socket.assigns[:current_scope]

    case Snippets.update_snippet(scope, snippet, snippet_params) do
      {:ok, updated} ->
        PubSub.broadcast(
          ReviewRoom.PubSub,
          "snippet:#{updated.id}",
          {:snippet_updated, %{id: updated.id}}
        )

        {:noreply,
         socket
         |> assign(:snippet, updated)
         |> put_flash(:info, "Snippet updated successfully")
         |> push_navigate(to: ~p"/s/#{updated.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to update snippet. Please fix the highlighted issues.")
         |> assign(:form, to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You do not have permission to edit this snippet.")
         |> push_navigate(to: ~p"/s/#{snippet.id}")}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    snippet = socket.assigns.snippet
    scope = socket.assigns[:current_scope]

    case Snippets.delete_snippet(scope, snippet) do
      {:ok, deleted} ->
        PubSub.broadcast(
          ReviewRoom.PubSub,
          "snippet:#{deleted.id}",
          {:snippet_deleted, %{id: deleted.id}}
        )

        {:noreply,
         socket
         |> put_flash(:info, "Snippet deleted successfully")
         |> push_navigate(to: ~p"/snippets/my")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You do not have permission to delete this snippet.")
         |> push_navigate(to: ~p"/s/#{snippet.id}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <Components.snippet_form
        title="Edit Snippet"
        description="Update your code snippet details below. Changes will be reflected in real time for active viewers."
        form={@form}
        snippet={@snippet}
        id="snippet-edit-form"
        cancel_href={~p"/s/#{@snippet.id}"}
        submit_label="Save changes"
        submit_disable_with="Saving..."
        show_delete?={true}
        delete_button_id={"delete-snippet-#{@snippet.id}"}
        delete_event="delete"
        delete_confirm="Are you sure you want to delete this snippet? This action cannot be undone."
      />
    </Layouts.app>
    """
  end
end
