defmodule ReviewRoomWeb.SnippetLive.Edit do
  use ReviewRoomWeb, :live_view

  alias Phoenix.PubSub
  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    snippet = Snippets.get_snippet!(id)
    current_user = current_user(socket)

    if Snippets.can_edit?(snippet, current_user) do
      changeset = Snippet.update_changeset(snippet, %{})

      {:ok,
       socket
       |> assign(:snippet, snippet)
       |> assign(:current_user, current_user)
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
    current_user = socket.assigns.current_user

    case Snippets.update_snippet(snippet, snippet_params, current_user) do
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
        {:noreply, assign(socket, :form, to_form(changeset))}

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
    current_user = socket.assigns.current_user

    case Snippets.delete_snippet(snippet, current_user) do
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
      <div class="mx-auto max-w-4xl px-4 py-8 space-y-8">
        <div>
          <h1 class="text-3xl font-bold tracking-tight text-gray-900">Edit Snippet</h1>
          <p class="mt-2 text-sm text-gray-600">
            Update your code snippet details below. Changes will be reflected in real time for active viewers.
          </p>
        </div>

        <.form
          for={@form}
          id="snippet-edit-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6 bg-white border border-gray-200 rounded-xl shadow-sm p-6"
        >
          <div>
            <.input
              field={@form[:code]}
              type="textarea"
              label="Code"
              required
              rows="20"
              phx-debounce="300"
              class="font-mono text-sm min-h-[400px]"
            />
          </div>

          <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
            <div>
              <.input field={@form[:title]} type="text" label="Title (optional)" />
            </div>

            <div>
              <.input
                field={@form[:language]}
                type="select"
                label="Language"
                options={language_options()}
                prompt="Auto-detect"
              />
            </div>
          </div>

          <div>
            <.input
              field={@form[:description]}
              type="textarea"
              label="Description (optional)"
              rows="3"
            />
          </div>

          <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
            <div>
              <.input
                field={@form[:visibility]}
                type="select"
                label="Visibility"
                options={[
                  {"Private (link only)", :private},
                  {"Public (discoverable)", :public}
                ]}
              />
            </div>
            <div class="flex items-end">
              <span class="text-sm text-gray-500">
                Public snippets appear in the discoverable gallery instantly.
              </span>
            </div>
          </div>

          <div class="flex flex-wrap gap-4">
            <.button type="submit" phx-disable-with="Saving..." class="min-w-[150px]">
              Save changes
            </.button>

            <.link
              navigate={~p"/s/#{@snippet.id}"}
              class="inline-flex items-center justify-center rounded-md border border-gray-300 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition"
            >
              Cancel
            </.link>

            <button
              type="button"
              id={"delete-snippet-#{@snippet.id}"}
              phx-click="delete"
              phx-confirm="Are you sure you want to delete this snippet? This action cannot be undone."
              class="inline-flex items-center justify-center rounded-md border border-red-200 bg-red-50 px-4 py-2 text-sm font-semibold text-red-700 hover:bg-red-100 transition"
            >
              Delete snippet
            </button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  defp language_options do
    [
      {"Elixir", "elixir"},
      {"Erlang", "erlang"},
      {"JavaScript", "javascript"},
      {"TypeScript", "typescript"},
      {"Python", "python"},
      {"Ruby", "ruby"},
      {"Go", "go"},
      {"Rust", "rust"},
      {"Java", "java"},
      {"Kotlin", "kotlin"},
      {"Swift", "swift"},
      {"C", "c"},
      {"C++", "cpp"},
      {"C#", "csharp"},
      {"PHP", "php"},
      {"SQL", "sql"},
      {"HTML", "html"},
      {"CSS", "css"},
      {"SCSS", "scss"},
      {"JSON", "json"},
      {"YAML", "yaml"},
      {"Markdown", "markdown"},
      {"Shell", "shell"},
      {"Bash", "bash"},
      {"Dockerfile", "dockerfile"},
      {"XML", "xml"},
      {"Plain Text", "plaintext"}
    ]
  end

  defp current_user(socket) do
    case socket.assigns[:current_scope] do
      %{user: user} -> user
      _ -> nil
    end
  end
end
