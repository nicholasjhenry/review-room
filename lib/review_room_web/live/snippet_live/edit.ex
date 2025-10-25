defmodule ReviewRoomWeb.SnippetLive.Edit do
  use ReviewRoomWeb, :live_view

  alias Phoenix.PubSub
  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoomWeb.SnippetLive.Components
  alias ReviewRoomWeb.SnippetLive.FormContext

  @moduledoc """
  LiveView for editing existing snippets with authorization safeguards,
  optimistic UI updates, and polished form interactions.
  """

  @hero_title "Refine your snippet"
  @hero_description "Track visibility, validation, and micro-interactions before sharing updates with your team."

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    snippet = Snippets.get_snippet!(id)
    scope = socket.assigns[:current_scope]

    if Snippets.can_edit?(scope, snippet) do
      changeset = Snippet.update_changeset(snippet, %{})

      socket =
        socket
        |> assign(:snippet, snippet)
        |> assign(:page_title, "Edit Snippet")
        |> assign(:hero_title, @hero_title)
        |> assign(:hero_description, @hero_description)
        |> assign(:share_label, "Share the live snippet URL once saving completes.")
        |> assign(:share_url, share_url_for(snippet))
        |> assign(:form_layout, "balanced")
        |> assign(:submit_label, "Save changes")
        |> assign(:submit_disable_with, "Saving...")
        |> assign(:cancel_href, ~p"/s/#{snippet.id}")
        |> assign(:show_delete?, true)
        |> assign(:delete_button_id, "delete-snippet-#{snippet.id}")
        |> assign(:delete_event, "delete")
        |> assign(
          :delete_confirm,
          "Are you sure you want to delete this snippet? This action cannot be undone."
        )

      {:ok, assign_form_state(socket, changeset, snippet)}
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

    preview = FormContext.preview_snippet(socket.assigns.snippet, snippet_params)

    {:noreply, assign_form_state(socket, changeset, preview)}
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
         |> assign(:share_url, share_url_for(updated))
         |> put_flash(:info, "Snippet updated successfully")
         |> push_navigate(to: ~p"/s/#{updated.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        preview = FormContext.preview_snippet(snippet, snippet_params)

        {:noreply,
         socket
         |> put_flash(:error, "Unable to update snippet. Please fix the highlighted issues.")
         |> assign_form_state(changeset, preview)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You do not have permission to edit this snippet.")
         |> push_navigate(to: ~p"/s/#{snippet.id}")}
    end
  end

  @impl true
  def handle_event("dismiss_toast", _params, socket) do
    {:noreply, clear_flash(socket, :info)}
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
        flash={@flash}
        title={@hero_title}
        description={@hero_description}
        form={@form}
        snippet={@snippet}
        id="snippet-edit-form"
        layout={@form_layout}
        share_label={@share_label}
        share_url={@share_url}
        guidance_panels={@guidance_panels}
        safety_pulses={@safety_pulses}
        cancel_href={@cancel_href}
        submit_label={@submit_label}
        submit_disable_with={@submit_disable_with}
        show_delete?={@show_delete?}
        delete_button_id={@delete_button_id}
        delete_event={@delete_event}
        delete_confirm={@delete_confirm}
      />
    </Layouts.app>
    """
  end

  defp assign_form_state(socket, changeset, preview) do
    socket
    |> assign(:preview_snippet, preview)
    |> assign(:guidance_panels, FormContext.guidance_panels(preview))
    |> assign(:safety_pulses, FormContext.safety_pulses(preview))
    |> assign(:form, to_form(changeset))
  end

  defp share_url_for(%Snippet{id: id}) when is_binary(id), do: url(~p"/s/#{id}")
  defp share_url_for(_snippet), do: url(~p"/snippets/new?preview=1")
end
