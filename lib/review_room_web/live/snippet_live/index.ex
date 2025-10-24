defmodule ReviewRoomWeb.SnippetLive.Index do
  use ReviewRoomWeb, :live_view

  alias ReviewRoom.Snippets
  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoomWeb.Components.DesignSystem.GalleryComponents

  @moduledoc """
  Public discovery gallery for snippets with filtering, search, responsive layouts, and
  skeleton loading states for a polished browsing experience.
  """

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
    languages = Snippets.supported_languages()

    socket =
      socket
      |> assign(:page_title, "Discover Snippets")
      |> assign(:language_filter, nil)
      |> assign(:search_query, "")
      |> assign(:languages, languages)
      |> assign(:next_cursor, nil)
      |> assign(:snippets_empty?, true)
      |> assign(:loading?, true)
      |> assign(:gallery_layout, :grid)
      |> assign(:gallery_metrics, gallery_metrics(languages))
      |> assign(:filter_summary, default_filter_summary())
      |> assign(:active_filter_count, 0)
      |> stream(:snippets, [], reset: true)
      |> assign_filter_form()
      |> assign_search_form()
      |> assign_filter_summary()

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
      |> assign_filter_summary()
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
      |> assign_filter_summary()
      |> refresh_gallery(reset: true)

    {:noreply, socket}
  end

  def handle_event("clear_search", _params, socket) do
    socket =
      socket
      |> assign(:search_query, "")
      |> assign_search_form()
      |> assign_filter_summary()
      |> refresh_gallery(reset: true)

    {:noreply, socket}
  end

  def handle_event("set_layout", %{"layout" => layout}, socket) do
    layout_atom = normalize_layout(layout)

    socket =
      case layout_atom do
        nil -> socket
        normalized -> assign(socket, :gallery_layout, normalized)
      end

    {:noreply, socket}
  end

  def handle_event("set_layout", _params, socket), do: {:noreply, socket}

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
        <GalleryComponents.hero
          layout={@gallery_layout}
          metrics={@gallery_metrics}
          featured_languages={@gallery_metrics[:featured_languages] || []}
          cta_href={~p"/snippets/new"}
        />

        <section class="grid gap-4 lg:grid-cols-[minmax(0,320px)_minmax(0,1fr)]">
          <div class="space-y-3">
            <button
              id="gallery-filters-trigger"
              type="button"
              class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-300 hover:text-slate-900 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900"
            >
              <.icon name="hero-adjustments-vertical" class="h-4 w-4" /> Filters
              <span
                :if={@active_filter_count > 0}
                class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-slate-900 text-xs font-semibold text-white"
              >
                {@active_filter_count}
              </span>
            </button>

            <section
              id="gallery-filter-panel"
              phx-hook="FilterPanelToggle"
              phx-update="ignore"
              data-trigger="#gallery-filters-trigger"
              data-close-on-outside="true"
              data-state="closed"
              data-open-classes="translate-y-0 opacity-100 pointer-events-auto block"
              data-closed-classes="-translate-y-4 opacity-0 pointer-events-none hidden"
              class="gallery-filter-panel pointer-events-none -translate-y-4 opacity-0 hidden"
            >
              <div class="rounded-3xl border border-white/10 bg-white/95 p-5 shadow-2xl backdrop-blur-xl dark:border-slate-800 dark:bg-slate-900/95">
                <header class="mb-4 flex items-center justify-between">
                  <div>
                    <p class="text-sm font-semibold text-slate-900 dark:text-white">Language focus</p>
                    <p class="text-xs text-slate-500">
                      Filters apply instantly to the gallery stream
                    </p>
                  </div>
                  <span class="hidden text-[0.55rem] uppercase tracking-[0.4em] text-slate-400 sm:inline-flex">
                    Instant
                  </span>
                </header>

                <.form
                  for={@filter_form}
                  id="language-filter-form"
                  phx-change="filter"
                  class="space-y-3"
                >
                  <.input
                    field={@filter_form[:language]}
                    type="select"
                    prompt="All languages"
                    class="w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-700 shadow-inner focus:border-slate-900 focus:ring-slate-900"
                    options={language_options(@languages)}
                  />
                </.form>

                <p class="mt-4 text-xs text-slate-500">
                  Tip: Combine language filters with search keywords to generate curated boards.
                </p>
              </div>
            </section>

            <p
              id="gallery-filter-summary"
              class="text-xs font-medium uppercase tracking-[0.3em] text-slate-500"
            >
              {@filter_summary}
            </p>
          </div>

          <.form
            for={@search_form}
            id="snippet-search-form"
            phx-submit="search"
            class="flex flex-col gap-4 rounded-3xl border border-slate-200 bg-white p-5 shadow-sm"
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
                phx-debounce="350"
                class="flex-1 rounded-2xl border border-slate-200 px-4 py-2 text-sm shadow-inner focus:border-slate-900 focus:ring-slate-900"
              />

              <button
                type="submit"
                class="inline-flex items-center gap-2 rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800"
                phx-submit-loading="opacity-75"
              >
                <.icon name="hero-magnifying-glass" class="h-4 w-4" /> Search
              </button>

              <button
                type="button"
                phx-click="clear_search"
                class="inline-flex items-center gap-2 rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition hover:border-slate-400 hover:text-slate-800"
                phx-click-loading="opacity-50"
              >
                Clear
              </button>
            </div>
          </.form>
        </section>

        <div :if={@loading?} class="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
          <GalleryComponents.skeleton_card
            :for={index <- 1..6}
            id={"snippet-gallery-skeleton-#{index}"}
          />
        </div>

        <div
          id="gallery-stream"
          class={[
            "grid gap-6",
            @gallery_layout == :grid && "md:grid-cols-2 xl:grid-cols-3",
            @gallery_layout == :list && "grid-cols-1"
          ]}
          phx-update="stream"
        >
          <div
            id="gallery-empty"
            class="col-span-full hidden rounded-3xl border border-dashed border-slate-200 bg-white/80 px-5 py-10 text-center text-sm text-slate-500 only:flex only:flex-col only:items-center only:justify-center"
          >
            <span :if={not @loading? and @snippets_empty?}>
              No public snippets match your filters yet. Adjust the search or language filter to discover a new wave.
            </span>
          </div>

          <GalleryComponents.card
            :for={{dom_id, snippet} <- @streams.snippets}
            id={dom_id}
            snippet={snippet}
            layout={@gallery_layout}
            language_label={display_language(snippet.language)}
            owner_label={owner_label(snippet)}
            activity_label={format_inserted_at(snippet.inserted_at)}
          />
        </div>

        <div :if={@next_cursor} class="flex justify-center">
          <button
            id="load-more"
            type="button"
            phx-click="load_more"
            phx-value-cursor={@next_cursor}
            class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-5 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-300 hover:text-slate-900"
            phx-click-loading="opacity-60 cursor-progress"
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

    socket = if reset?, do: assign(socket, :loading?, true), else: socket

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
    |> assign(:loading?, false)
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

  defp assign_filter_summary(socket) do
    active =
      []
      |> maybe_add_filter(:language, socket.assigns[:language_filter])
      |> maybe_add_filter(:search, socket.assigns[:search_query])

    summary =
      case active do
        [] ->
          default_filter_summary()

        filters ->
          labels =
            filters
            |> Enum.map(&filter_label/1)
            |> Enum.join(" + ")

          "Filtered by #{labels}"
      end

    assign(socket,
      filter_summary: summary,
      active_filter_count: length(active)
    )
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

  defp normalize_layout(layout) when layout in ["grid", "list"],
    do: String.to_existing_atom(layout)

  defp normalize_layout("Grid"), do: :grid
  defp normalize_layout("List"), do: :list
  defp normalize_layout(_), do: nil

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

  defp owner_label(%Snippet{user: %{email: email}}), do: email
  defp owner_label(_), do: "Community spotlight"

  defp default_filter_summary, do: "Showing all curated snippets"

  defp gallery_metrics(languages) do
    featured =
      languages
      |> Enum.take(4)
      |> Enum.map(&humanize_language/1)

    %{
      languages_supported: length(languages),
      active_creators: "24K+",
      featured_languages: featured
    }
  end

  defp maybe_add_filter(filters, _label, nil), do: filters

  defp maybe_add_filter(filters, :search, query) do
    if has_search?(query) do
      [:search | filters]
    else
      filters
    end
  end

  defp maybe_add_filter(filters, _label, value) when value in ["", nil], do: filters
  defp maybe_add_filter(filters, label, _value), do: [label | filters]

  defp filter_label(:language), do: "language"
  defp filter_label(:search), do: "search"
end
