defmodule ReviewRoomWeb.SnippetLive.Index do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet

  @page_size 20
  @language_labels %{
    "css" => "CSS",
    "html" => "HTML",
    "json" => "JSON",
    "yaml" => "YAML",
    "sql" => "SQL",
    "php" => "PHP",
    "xml" => "XML",
    "scss" => "SCSS",
    "csharp" => "C#",
    "cpp" => "C++",
    "go" => "Go",
    "elixir" => "Elixir",
    "erlang" => "Erlang",
    "python" => "Python",
    "ruby" => "Ruby",
    "bash" => "Bash",
    "shell" => "Shell"
  }

  @doc false
  def page_size, do: @page_size

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Discover Snippets")
      |> assign(:language_filter, nil)
      |> assign(:search_query, "")
      |> assign(:languages, Snippets.supported_languages())
      |> assign(:next_cursor, nil)
      |> assign(:snippets_empty?, true)
      |> stream(:snippets, [], reset: true)
      |> assign_filter_form()
      |> assign_search_form()

    socket = if connected?(socket), do: refresh_gallery(socket, reset: true), else: socket

    {:ok, socket}
  end

  @impl true
  def handle_event("filter", %{"filters" => %{"language" => language}}, socket) do
    language = normalize_language_param(language)

    socket =
      socket
      |> assign(:language_filter, language)
      |> assign_filter_form()
      |> refresh_gallery(reset: true)

    {:noreply, socket}
  end

  def handle_event("filter", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    query = normalize_query(query)

    socket =
      socket
      |> assign(:search_query, query)
      |> assign_search_form()
      |> refresh_gallery(reset: true)

    {:noreply, socket}
  end

  def handle_event("clear_search", _params, socket) do
    socket =
      socket
      |> assign(:search_query, "")
      |> assign_search_form()
      |> refresh_gallery(reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_more", %{"cursor" => cursor}, socket) do
    cursor = String.trim(cursor || "")

    cond do
      cursor == "" -> {:noreply, socket}
      is_nil(socket.assigns.next_cursor) -> {:noreply, socket}
      true -> {:noreply, refresh_gallery(socket, cursor: cursor)}
    end
  end

  def handle_event("load_more", _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto max-w-6xl px-4 py-10 space-y-10">
        <div class="flex flex-wrap items-start justify-between gap-6">
          <div class="space-y-3 max-w-3xl">
            <h1 class="text-4xl font-semibold tracking-tight text-slate-900">
              Discover World-Class Code Snippets
            </h1>
            <p class="text-base text-slate-600 leading-relaxed">
              Browse community-contributed snippets with instant syntax highlighting, curated by
              language and recency. Toggle languages, search by intent, and jump straight into live
              collaboration.
            </p>
          </div>

          <.link
            navigate={~p"/snippets/new"}
            class="inline-flex items-center gap-2 rounded-full bg-blue-600 px-5 py-2.5 text-sm font-semibold text-white shadow-md transition hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
          >
            <.icon name="hero-plus-small" class="h-4 w-4" /> Share a Snippet
          </.link>
        </div>

        <div class="grid gap-4 md:grid-cols-[minmax(0,280px)_minmax(0,1fr)] items-start">
          <.form
            for={@filter_form}
            id="language-filter-form"
            phx-change="filter"
            class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <h2 class="text-sm font-semibold text-slate-700">Language</h2>
            <p class="mt-1 text-xs text-slate-500">
              Refine the gallery by primary language. Public snippets update instantly.
            </p>

            <.input
              field={@filter_form[:language]}
              type="select"
              class="mt-4 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm shadow-inner focus:border-blue-500 focus:ring-blue-500"
              options={language_options(@languages)}
              prompt="All languages"
            />
          </.form>

          <.form
            for={@search_form}
            id="snippet-search-form"
            phx-submit="search"
            class="flex flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <label class="text-sm font-semibold text-slate-700" for="search-query">
              Search public snippets
            </label>

            <div class="flex flex-wrap items-center gap-3">
              <.input
                id="search-query"
                field={@search_form[:query]}
                type="text"
                placeholder={"Try \"phoenix liveview\" or \"graph traversal\""}
                phx-debounce="400"
                class="flex-1 rounded-xl border border-slate-200 px-4 py-2 text-sm shadow-inner focus:border-blue-500 focus:ring-blue-500"
              />

              <button
                type="submit"
                class="inline-flex items-center gap-2 rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800"
              >
                <.icon name="hero-magnifying-glass" class="h-4 w-4" /> Search
              </button>

              <button
                type="button"
                phx-click="clear_search"
                class="inline-flex items-center gap-2 rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition hover:border-slate-400 hover:text-slate-800"
              >
                Clear
              </button>
            </div>
          </.form>
        </div>

        <div
          id="snippet-gallery"
          class="grid gap-6 md:grid-cols-2 xl:grid-cols-3"
          phx-update="stream"
        >
          <div
            id="snippet-gallery-empty"
            class="col-span-full text-center text-sm text-slate-500 italic only:block"
          >
            <span :if={@snippets_empty?}>
              No public snippets match your filters yet. Toggle the language or clear the search to explore new ideas.
            </span>
          </div>

          <article
            :for={{dom_id, snippet} <- @streams.snippets}
            id={dom_id}
            class="relative flex h-full flex-col justify-between rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-1 hover:shadow-lg"
          >
            <div class="space-y-3">
              <div class="flex items-start justify-between gap-3">
                <h3 class="text-lg font-semibold text-slate-900 line-clamp-2">
                  {snippet.title || "Untitled Snippet"}
                </h3>
                <span
                  :if={snippet.language}
                  class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-slate-600"
                >
                  {display_language(snippet.language)}
                </span>
              </div>

              <p class="text-sm text-slate-600 line-clamp-3">
                {snippet.description || "This snippet is ready to explore in real-time."}
              </p>
            </div>

            <div class="mt-6 flex items-center justify-between text-xs text-slate-500">
              <div class="flex items-center gap-2">
                <div class="h-2 w-2 rounded-full bg-emerald-400" />
                <span>
                  {format_inserted_at(snippet.inserted_at)}
                </span>
              </div>
              <div :if={snippet.user} class="flex items-center gap-2 text-slate-600">
                <.icon name="hero-user" class="h-4 w-4" />
                <span>{snippet.user.email}</span>
              </div>
            </div>

            <.link
              navigate={~p"/s/#{snippet.id}"}
              class="mt-6 inline-flex items-center gap-2 rounded-full bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700 transition hover:bg-blue-100"
            >
              View snippet <.icon name="hero-arrow-right" class="h-4 w-4" />
            </.link>
          </article>
        </div>

        <div :if={@next_cursor} class="flex justify-center">
          <button
            id="load-more"
            type="button"
            phx-click="load_more"
            phx-value-cursor={@next_cursor}
            class="inline-flex items-center gap-2 rounded-full border border-slate-300 bg-white px-5 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-400 hover:text-slate-900"
          >
            Load more snippets <.icon name="hero-chevron-double-down" class="h-4 w-4" />
          </button>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp refresh_gallery(socket, opts) do
    reset? = Keyword.get(opts, :reset, false)
    cursor = Keyword.get(opts, :cursor)

    {snippets, next_cursor} = fetch_snippets(socket, cursor: cursor)

    empty_state? =
      if cursor do
        socket.assigns[:snippets_empty?]
      else
        snippets == []
      end

    socket
    |> assign(:next_cursor, next_cursor)
    |> assign(:snippets_empty?, empty_state?)
    |> stream_snippets(snippets, reset?)
  end

  defp fetch_snippets(socket, opts) do
    merged_opts = Keyword.merge(base_fetch_opts(socket), opts)

    results =
      if has_search?(socket.assigns.search_query) do
        Snippets.search_snippets(socket.assigns.search_query, merged_opts)
      else
        Snippets.list_public_snippets(merged_opts)
      end

    {results, next_cursor_from(results)}
  end

  defp base_fetch_opts(socket) do
    opts = [limit: @page_size]

    case socket.assigns.language_filter do
      nil -> opts
      language -> Keyword.put(opts, :language, language)
    end
  end

  defp has_search?(query) do
    query
    |> normalize_query()
    |> case do
      "" -> false
      _ -> true
    end
  end

  defp next_cursor_from([]), do: nil

  defp next_cursor_from(snippets) do
    case List.last(snippets) do
      %Snippet{id: id, inserted_at: %DateTime{} = dt} ->
        encode_cursor(dt, id)

      %Snippet{id: id, inserted_at: %NaiveDateTime{} = ndt} ->
        ndt
        |> DateTime.from_naive!("Etc/UTC")
        |> encode_cursor(id)

      _ ->
        nil
    end
  end

  defp encode_cursor(%DateTime{} = dt, id) do
    dt
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
    |> Kernel.<>("::" <> id)
  end

  defp stream_snippets(socket, snippets, true),
    do: stream(socket, :snippets, snippets, reset: true)

  defp stream_snippets(socket, snippets, false), do: stream(socket, :snippets, snippets)

  defp assign_filter_form(socket) do
    form =
      socket.assigns[:language_filter]
      |> language_form_value()
      |> to_form(as: :filters)

    assign(socket, :filter_form, form)
  end

  defp assign_search_form(socket) do
    form =
      socket.assigns[:search_query]
      |> search_form_value()
      |> to_form(as: :search)

    assign(socket, :search_form, form)
  end

  defp language_form_value(nil), do: %{"language" => ""}
  defp language_form_value(language), do: %{"language" => language}

  defp search_form_value(query), do: %{"query" => query || ""}

  defp normalize_language_param(language) when language in [nil, ""], do: nil

  defp normalize_language_param(language) when is_binary(language) do
    normalized = language |> String.trim() |> String.downcase()

    if normalized in Snippets.supported_languages() do
      normalized
    else
      nil
    end
  end

  defp normalize_language_param(_), do: nil

  defp normalize_query(nil), do: ""

  defp normalize_query(query) when is_binary(query) do
    query
    |> String.trim()
  end

  defp normalize_query(_), do: ""

  defp language_options(languages) do
    Enum.map(languages, fn language ->
      {display_language(language), language}
    end)
  end

  defp display_language(language) when is_binary(language) do
    Map.get(@language_labels, language, humanize_language(language))
  end

  defp display_language(_), do: "Auto"

  defp humanize_language(language) do
    language
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp format_inserted_at(nil), do: "Just now"

  defp format_inserted_at(%DateTime{} = datetime) do
    Calendar.strftime(DateTime.truncate(datetime, :second), "%b %-d, %Y · %H:%M UTC")
  end

  defp format_inserted_at(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> format_inserted_at()
  end
end
