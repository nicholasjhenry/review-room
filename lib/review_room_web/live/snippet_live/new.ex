defmodule ReviewRoomWeb.SnippetLive.New do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: scope}} = socket) do
    changeset = Snippets.change_snippet(scope, %{})

    socket =
      socket
      |> assign(:current_scope, scope)
      |> assign(:last_submission, nil)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"snippet" => snippet_params}, socket) do
    changeset =
      socket.assigns.current_scope
      |> Snippets.change_snippet(normalize_params(snippet_params))
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"snippet" => snippet_params}, socket) do
    params = normalize_params(snippet_params)

    case Snippets.enqueue(socket.assigns.current_scope, params) do
      {:ok, meta} ->
        {:noreply, handle_success(socket, meta, params)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to queue snippet. Please try again.")
         |> assign(:last_submission, nil)}
    end
  end

  defp handle_success(socket, meta, params) do
    scope = socket.assigns.current_scope

    confirmation = %{
      position: meta[:position],
      buffer_token: meta[:buffer_token],
      estimated_flush_at: meta[:estimated_flush_at],
      title: params["title"],
      description: params["description"],
      visibility: params["visibility"]
    }

    socket
    |> put_flash(:info, "Snippet queued (position #{meta[:position]})")
    |> assign(:last_submission, confirmation)
    |> assign_form(Snippets.change_snippet(scope, %{}))
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp normalize_params(params) do
    params
    |> Map.update("tags", [], fn
      tags when is_binary(tags) ->
        tags
        |> String.split([",", "\n"], trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      tags ->
        tags
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-6">
      <div class="card bg-base-100 shadow-md">
        <div class="card-body">
          <.header>
            New Snippet
            <:subtitle>Draft a snippet and queue it for persistence.</:subtitle>
          </.header>

          <.form for={@form} id="snippet-form" phx-change="validate" phx-submit="save">
            <.input field={@form[:title]} type="text" label="Title" />
            <.input field={@form[:description]} type="textarea" label="Description" />
            <.input field={@form[:body]} type="textarea" label="Code / Body" />
            <.input field={@form[:syntax]} type="text" label="Syntax" />
            <.input
              field={@form[:visibility]}
              type="select"
              label="Visibility"
              options={[
                {"Only me", "personal"},
                {"Team", "team"},
                {"Organization", "organization"}
              ]}
              prompt="Select visibility"
            />
            <.input
              field={@form[:tags]}
              type="text"
              label="Tags"
              placeholder="Comma separated tags"
            />

            <div class="mt-4 flex gap-3">
              <.button type="submit" id="snippet-save-button">Save Snippet</.button>
            </div>
          </.form>
        </div>
      </div>

      <div :if={@last_submission} id="snippet-confirmation" class="alert alert-success">
        <div>
          <p>Snippet queued (position {@last_submission.position})</p>
          <h3 class="font-semibold">{@last_submission.title}</h3>
          <p>
            Visibility: {@last_submission.visibility}
          </p>
          <p :if={@last_submission.position}>
            Position in buffer: {@last_submission.position}
          </p>
        </div>
      </div>
    </div>
    """
  end
end
