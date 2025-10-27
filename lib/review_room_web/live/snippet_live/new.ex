defmodule ReviewRoomWeb.SnippetLive.New do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoomWeb.SnippetLive.Components
  alias ReviewRoomWeb.SnippetLive.FormContext

  @hero_title "Confident Snippet Management"
  @hero_description "Compose, validate, and share beautifully formatted snippets with real-time feedback."

  @moduledoc """
  LiveView for composing new snippets with the Spec 003 design system, polished helper text,
  and accessible feedback states.
  """

  @impl true
  def mount(_params, _session, socket) do
    snippet = %Snippet{}
    changeset = Snippets.change_snippet(snippet)

    socket =
      socket
      |> assign(:snippet, snippet)
      |> assign(:hero_title, @hero_title)
      |> assign(:hero_description, @hero_description)
      |> assign(:share_label, "Share the preview link with collaborators before publishing.")
      |> assign(:share_url, onboarding_share_url())
      |> assign(:form_layout, "balanced")
      |> assign(:submit_label, "Create snippet")
      |> assign(:submit_disable_with, "Publishing...")
      |> assign(:cancel_href, ~p"/snippets/my")

    {:ok, assign_form_state(socket, changeset, snippet)}
  end

  @impl true
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    changeset =
      %Snippet{}
      |> Snippets.change_snippet(snippet_params)
      |> Map.put(:action, :validate)

    preview = FormContext.preview_snippet(socket.assigns.snippet, snippet_params)

    {:noreply, assign_form_state(socket, changeset, preview)}
  end

  @impl true
  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    case Snippets.create_snippet(socket.assigns[:current_scope], snippet_params) do
      {:ok, snippet} ->
        {:noreply,
         socket
         |> assign(:snippet, snippet)
         |> assign(:share_url, share_url_for(snippet))
         |> put_flash(:info, "Snippet created successfully")
         |> push_navigate(to: ~p"/s/#{snippet.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        preview = FormContext.preview_snippet(socket.assigns.snippet, snippet_params)

        {:noreply,
         socket
         |> put_flash(:error, "Unable to create snippet. Please fix the errors and try again.")
         |> assign_form_state(changeset, preview)}
    end
  end

  @impl true
  def handle_event("dismiss_toast", _params, socket) do
    {:noreply, clear_flash(socket, :info)}
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
        layout={@form_layout}
        share_label={@share_label}
        share_url={@share_url}
        guidance_panels={@guidance_panels}
        safety_pulses={@safety_pulses}
        id="snippet-form"
        submit_label={@submit_label}
        submit_disable_with={@submit_disable_with}
        cancel_href={@cancel_href}
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
  defp share_url_for(_snippet), do: onboarding_share_url()

  defp onboarding_share_url, do: url(~p"/snippets/new?preview=1")
end
