defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    snippet = Snippets.get_snippet!(id)
    {:ok, assign(socket, snippet: snippet, page_title: snippet.title || "Code Snippet")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-6xl px-4 py-8">
        <div class="mb-6">
          <div class="flex items-center justify-between mb-2">
            <h1 class="text-3xl font-bold">
              {@snippet.title || "Code Snippet"}
            </h1>
            <div class="flex gap-2 text-sm text-gray-600">
              <span :if={@snippet.language} class="px-2 py-1 bg-gray-100 rounded">
                {@snippet.language}
              </span>
              <span class="px-2 py-1 bg-gray-100 rounded">
                {if @snippet.visibility == :public, do: "Public", else: "Private"}
              </span>
            </div>
          </div>

          <p :if={@snippet.description} class="text-gray-600 mt-2">
            {@snippet.description}
          </p>
        </div>

        <div class="relative">
          <div
            id="code-display"
            phx-hook="SyntaxHighlight"
            phx-update="ignore"
            class="rounded-lg overflow-hidden border border-gray-200"
          >
            <pre class="p-4 bg-gray-50 overflow-x-auto"><code class={language_class(@snippet.language)}><%= @snippet.code %></code></pre>
          </div>

          <button
            type="button"
            phx-click={JS.dispatch("phx:copy", to: "#snippet-code-content")}
            class="absolute top-2 right-2 px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-50"
          >
            Copy
          </button>

          <div id="snippet-code-content" class="hidden">{@snippet.code}</div>
        </div>

        <div class="mt-6 flex gap-4">
          <.link navigate={~p"/snippets/new"} class="text-blue-600 hover:text-blue-800">
            Create New Snippet
          </.link>
          <.link navigate={~p"/"} class="text-gray-600 hover:text-gray-800">
            Home
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp language_class(nil), do: ""
  defp language_class(lang), do: "language-#{lang}"
end
