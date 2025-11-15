defmodule ReviewRoomWeb.SnippetLive.Show do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    snippet = Snippets.get_snippet!(id, socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, snippet.title)
     |> assign(:snippet, snippet)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <.header>
        {@snippet.title}
        <:subtitle :if={@snippet.description}>
          {@snippet.description}
        </:subtitle>
        <:actions>
          <.link
            :if={@current_scope && @current_scope.user && @current_scope.user.id == @snippet.user_id}
            navigate={~p"/snippets/#{@snippet.id}/edit"}
          >
            <.button>Edit</.button>
          </.link>
        </:actions>
      </.header>

      <div class="mt-6 space-y-4">
        <div class="flex gap-4 items-center text-sm text-gray-600">
          <span :if={@snippet.language} class="px-3 py-1 bg-gray-100 rounded-md">
            {@snippet.language}
          </span>
          <span class="px-3 py-1 bg-blue-100 text-blue-800 rounded-md">
            {@snippet.visibility}
          </span>
          <span>
            Created {format_date(@snippet.inserted_at)}
          </span>
        </div>

        <div :if={@snippet.tags != []} class="flex gap-2 flex-wrap">
          <span
            :for={tag <- @snippet.tags}
            class="px-3 py-1 bg-gray-100 text-gray-700 rounded-md text-sm"
          >
            {tag}
          </span>
        </div>

        <div class="mt-6">
          <div class="bg-gray-50 rounded-lg p-6 overflow-x-auto">
            <%= if @snippet.language do %>
              {Phoenix.HTML.raw(highlight_code(@snippet.code, @snippet.language))}
            <% else %>
              <pre class="text-sm"><code>{@snippet.code}</code></pre>
            <% end %>
          </div>
        </div>
      </div>

      <div class="mt-8">
        <.link navigate={~p"/snippets"} class="text-blue-600 hover:underline">
          ← Back to snippets
        </.link>
      </div>
    </div>
    """
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  defp highlight_code(code, language) do
    try do
      Autumn.highlight!(code, lang: language)
    rescue
      _ ->
        escaped = Phoenix.HTML.html_escape(code) |> Phoenix.HTML.safe_to_string()
        "<pre><code>#{escaped}</code></pre>"
    end
  end
end
