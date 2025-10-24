defmodule ReviewRoomWeb.SnippetLive.Components do
  use ReviewRoomWeb, :html

  alias ReviewRoom.Snippets.Snippet

  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :form, :any, required: true
  attr :snippet, Snippet, default: %Snippet{}
  attr :id, :string, default: "snippet-form"
  attr :change_event, :string, default: "validate"
  attr :submit_event, :string, default: "save"
  attr :submit_label, :string, default: "Save changes"
  attr :submit_disable_with, :string, default: "Saving..."
  attr :cancel_href, :string, required: true
  attr :show_delete?, :boolean, default: false
  attr :delete_button_id, :string, default: nil
  attr :delete_event, :string, default: nil
  attr :delete_confirm, :string, default: "Delete this snippet permanently?"
  attr :delete_disable_with, :string, default: "Deleting..."
  attr :button_class, :string, default: "min-w-[150px]"

  def snippet_form(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-8 space-y-8">
      <div>
        <h1 class="text-3xl font-bold tracking-tight text-gray-900">{@title}</h1>
        <p :if={@description} class="mt-2 text-sm text-gray-600">
          {@description}
        </p>
      </div>

      <.form
        for={@form}
        id={@id}
        phx-change={@change_event}
        phx-submit={@submit_event}
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
            class="w-full font-mono text-sm min-h-[400px] border border-gray-300 rounded-lg shadow-sm px-4 py-3 focus:border-blue-500 focus:ring-blue-500"
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
          <.button
            type="submit"
            data-loading-button="true"
            class={"inline-flex items-center justify-center gap-2 #{@button_class}"}
          >
            <span class="submit-default-label inline-flex items-center gap-2">
              <.icon name="hero-code-bracket" class="h-4 w-4" />
              {@submit_label}
            </span>
            <span class="submit-loading-label hidden items-center gap-2">
              <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin" />
              {@submit_disable_with}
            </span>
          </.button>

          <.link
            navigate={@cancel_href}
            class="inline-flex items-center justify-center rounded-md border border-gray-300 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition"
          >
            Cancel
          </.link>

          <button
            :if={@show_delete?}
            type="button"
            id={@delete_button_id}
            phx-click={@delete_event}
            phx-value-id={@snippet.id}
            phx-disable-with={@delete_disable_with}
            phx-confirm={@delete_confirm}
            class="inline-flex items-center justify-center rounded-md border border-red-200 bg-red-50 px-4 py-2 text-sm font-semibold text-red-700 hover:bg-red-100 transition"
            phx-click-loading="opacity-60 cursor-not-allowed"
          >
            Delete snippet
          </button>
        </div>
      </.form>
    </div>
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
end
