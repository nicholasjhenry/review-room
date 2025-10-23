defmodule ReviewRoomWeb.SnippetLive.New do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  @impl true
  def mount(_params, _session, socket) do
    changeset = Snippets.change_snippet(%Snippet{})

    {:ok,
     socket
     |> assign(:current_user, current_user(socket))
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
    current_user = socket.assigns.current_user

    case Snippets.create_snippet(snippet_params, current_user) do
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
      <div class="mx-auto max-w-4xl px-4 py-8">
        <h1 class="text-3xl font-bold mb-8">New Snippet</h1>

        <.form
          for={@form}
          id="snippet-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <div>
            <.input
              field={@form[:code]}
              type="textarea"
              label="Code"
              required
              rows="25"
              phx-debounce="300"
              class="font-mono text-sm min-h-[500px]"
            />
          </div>

          <div>
            <.input field={@form[:title]} type="text" label="Title (optional)" />
          </div>

          <div>
            <.input
              field={@form[:description]}
              type="textarea"
              label="Description (optional)"
              rows="3"
            />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <.input
                field={@form[:language]}
                type="select"
                label="Language"
                options={language_options()}
                prompt="Auto-detect"
              />
            </div>

            <div>
              <.input
                field={@form[:visibility]}
                type="select"
                label="Visibility"
                options={[{"Private (link only)", :private}, {"Public (discoverable)", :public}]}
              />
            </div>
          </div>

          <div class="flex gap-4">
            <.button type="submit" phx-disable-with="Creating...">
              Create Snippet
            </.button>
            <.link
              navigate={~p"/"}
              class="px-4 py-2 text-sm font-semibold text-gray-700 hover:text-gray-900"
            >
              Cancel
            </.link>
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
