defmodule ReviewRoomWeb.SnippetLive.Form do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  @impl true
  def mount(params, _session, socket) do
    supported_languages = Application.get_env(:review_room, :supported_languages, [])

    {:ok,
     socket
     |> assign(:supported_languages, supported_languages)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    changeset = Snippets.change_snippet(%Snippet{})

    socket
    |> assign(:page_title, "New Snippet")
    |> assign(:snippet, %Snippet{})
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    snippet = Snippets.get_snippet!(id, socket.assigns.current_scope)
    changeset = Snippets.change_snippet(snippet)

    socket
    |> assign(:page_title, "Edit Snippet")
    |> assign(:snippet, snippet)
    |> assign(:form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    changeset =
      socket.assigns.snippet
      |> Snippets.change_snippet(snippet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    save_snippet(socket, socket.assigns.live_action, snippet_params)
  end

  defp save_snippet(socket, :new, snippet_params) do
    case Snippets.create_snippet(snippet_params, socket.assigns.current_scope) do
      {:ok, snippet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet created successfully")
         |> push_navigate(to: ~p"/snippets/#{snippet.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_snippet(socket, :edit, snippet_params) do
    case Snippets.update_snippet(
           socket.assigns.snippet,
           snippet_params,
           socket.assigns.current_scope
         ) do
      {:ok, snippet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet updated successfully")
         |> push_navigate(to: ~p"/snippets/#{snippet.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to edit this snippet")
         |> push_navigate(to: ~p"/snippets")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
      <:subtitle>
        {if @live_action == :new, do: "Create a new code snippet", else: "Update your code snippet"}
      </:subtitle>
    </.header>

    <.form for={@form} id="snippet-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:title]} type="text" label="Title" required />
      <.input field={@form[:description]} type="textarea" label="Description" />
      <.input
        field={@form[:code]}
        type="textarea"
        label="Code"
        required
        phx-debounce="300"
      />
      <.input
        field={@form[:language]}
        type="select"
        label="Language"
        options={[{"Select language...", nil}] ++ @supported_languages}
      />
      <.input
        field={@form[:visibility]}
        type="select"
        label="Visibility"
        options={[
          {"Private (only you)", "private"},
          {"Public (anyone)", "public"},
          {"Unlisted (anyone with link)", "unlisted"}
        ]}
      />
      <.input
        field={@form[:tags]}
        type="text"
        label="Tags"
        placeholder="e.g. elixir, authentication, database"
      />

      <div class="mt-6 flex gap-2">
        <.button phx-disable-with="Saving...">Save Snippet</.button>
        <.link navigate={~p"/snippets"} class="px-4 py-2">
          Cancel
        </.link>
      </div>
    </.form>
    """
  end
end
