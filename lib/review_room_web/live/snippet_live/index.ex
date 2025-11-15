defmodule ReviewRoomWeb.SnippetLive.Index do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets

  @impl true
  def mount(_params, _session, socket) do
    snippets = Snippets.list_snippets(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Snippets")
     |> assign(:snippets_empty?, snippets == [])
     |> stream(:snippets, snippets)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Snippets")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    snippet = Snippets.get_snippet!(id, socket.assigns.current_scope)
    {:ok, _} = Snippets.delete_snippet(snippet, socket.assigns.current_scope)

    {:noreply, stream_delete(socket, :snippets, snippet)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Snippets
      <:actions>
        <.link navigate={~p"/snippets/new"}>
          <.button>New Snippet</.button>
        </.link>
      </:actions>
    </.header>

    <div :if={@snippets_empty?} class="mt-8 text-center text-gray-500">
      <p>No snippets yet. Create your first snippet to get started!</p>
    </div>

    <div id="snippets" phx-update="stream" class="mt-8 space-y-4">
      <div
        :for={{id, snippet} <- @streams.snippets}
        id={id}
        class="border rounded-lg p-4 hover:bg-gray-50"
      >
        <div class="flex justify-between items-start">
          <div class="flex-1">
            <.link navigate={~p"/snippets/#{snippet.id}"} class="block">
              <h3 class="text-lg font-semibold text-gray-900 hover:text-blue-600">
                {snippet.title}
              </h3>
              <p :if={snippet.description} class="mt-1 text-sm text-gray-600">
                {snippet.description}
              </p>
              <div class="mt-2 flex gap-2 items-center text-sm text-gray-500">
                <span :if={snippet.language} class="px-2 py-1 bg-gray-100 rounded">
                  {snippet.language}
                </span>
                <span>{format_date(snippet.inserted_at)}</span>
                <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs">
                  {snippet.visibility}
                </span>
              </div>
              <div :if={snippet.tags != []} class="mt-2 flex gap-2">
                <span
                  :for={tag <- snippet.tags}
                  class="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs"
                >
                  {tag}
                </span>
              </div>
            </.link>
          </div>
          <div class="flex gap-2">
            <.link navigate={~p"/snippets/#{snippet.id}/edit"}>
              <.button type="button" class="text-sm">Edit</.button>
            </.link>
            <.button
              type="button"
              phx-click="delete"
              phx-value-id={snippet.id}
              data-confirm="Are you sure?"
              class="text-sm bg-red-600 hover:bg-red-700"
            >
              Delete
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end
end
