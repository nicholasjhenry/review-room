defmodule ReviewRoomWeb.Components.DesignSystem.GalleryComponents do
  @moduledoc """
  Shared design system components for the public snippet gallery.

  These components embrace the Spec 003 token and motion guidelines to deliver
  the premium hero, stats, cards, and skeletons outlined in the redesign.
  """

  use ReviewRoomWeb, :html

  import ReviewRoomWeb.CoreComponents

  alias Phoenix.Naming
  alias ReviewRoom.Snippets.Snippet

  @type layout :: :grid | :list

  attr :layout, :atom, values: [:grid, :list], default: :grid
  attr :metrics, :map, default: %{}
  attr :featured_languages, :list, default: []
  attr :cta_href, :string, default: "#"

  slot :layout_toggle, doc: "Optional custom layout toggle controls"

  def hero(assigns) do
    assigns =
      assigns
      |> assign_new(:metrics, fn -> %{} end)
      |> assign_new(:featured_languages, fn -> [] end)
      |> assign(:grid_active?, assigns.layout == :grid)
      |> assign(:list_active?, assigns.layout == :list)

    ~H"""
    <section
      id="gallery-hero"
      class="gallery-hero overflow-hidden rounded-[32px] border border-white/5 px-6 py-8 text-white shadow-[0_30px_80px_rgba(8,15,52,0.45)] lg:px-10 lg:py-12"
    >
      <div class="grid gap-10 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <div class="space-y-6">
          <p class="text-[0.65rem] uppercase tracking-[0.65em] text-white/60">
            Snippet Gallery
          </p>
          <h1 class="text-4xl font-semibold leading-tight tracking-tight text-white sm:text-5xl">
            World-Class Snippet Library
          </h1>
          <p class="text-base text-white/80 sm:text-lg">
            Curated, real-time snippets from the ReviewRoom community with responsive previews,
            expressive metadata, and motion tuned for delight.
          </p>

          <div class="flex flex-wrap items-center gap-3">
            <.link
              navigate={@cta_href}
              class="inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-amber-300 via-amber-200 to-white px-5 py-2.5 text-sm font-semibold text-slate-900 shadow-lg shadow-amber-500/30 transition hover:scale-[1.01]"
            >
              <.icon name="hero-plus" class="h-4 w-4" /> Share a snippet
            </.link>

            <span class="inline-flex items-center gap-2 text-xs font-medium uppercase tracking-[0.3em] text-white/70">
              <span class="h-2 w-2 rounded-full bg-emerald-300 animate-pulse" /> Live sync &lt; 200ms
            </span>
          </div>

          <div
            id="gallery-layout-toggle"
            class="inline-flex items-center gap-2 rounded-full border border-white/20 p-1 text-xs font-semibold text-white/80"
          >
            <button
              type="button"
              data-layout="grid"
              phx-click="set_layout"
              phx-value-layout="grid"
              aria-pressed={to_string(@grid_active?)}
              class={[
                "inline-flex items-center gap-2 rounded-full px-3 py-1.5 transition",
                @grid_active? && "bg-white/90 text-slate-900 shadow-lg"
              ]}
            >
              <.icon name="hero-squares-2x2" class="h-4 w-4" /> Grid view
            </button>

            <button
              type="button"
              data-layout="list"
              phx-click="set_layout"
              phx-value-layout="list"
              aria-pressed={to_string(@list_active?)}
              class={[
                "inline-flex items-center gap-2 rounded-full px-3 py-1.5 transition",
                @list_active? && "bg-white/90 text-slate-900 shadow-lg"
              ]}
            >
              <.icon name="hero-bars-4" class="h-4 w-4" /> List view
            </button>
          </div>
        </div>

        <div class="grid gap-4 sm:grid-cols-2" id="gallery-stats">
          <div class="glass-panel">
            <p class="text-xs uppercase tracking-[0.25em] text-white/60">Languages</p>
            <p class="mt-3 text-4xl font-semibold">
              {@metrics[:languages_supported] || 0}
            </p>
            <p class="mt-1 text-sm text-white/80">
              Supported with curated tokens
            </p>
          </div>

          <div class="glass-panel">
            <p class="text-xs uppercase tracking-[0.25em] text-white/60">Creators</p>
            <p class="mt-3 text-4xl font-semibold">
              {@metrics[:active_creators] || "∞"}
            </p>
            <p class="mt-1 text-sm text-white/80">
              Active each week refining snippets
            </p>
          </div>

          <div class="glass-panel sm:col-span-2">
            <p class="text-xs uppercase tracking-[0.25em] text-white/60">Featured stacks</p>
            <div class="mt-3 flex flex-wrap gap-2 text-sm font-medium text-slate-950">
              <span
                :for={lang <- @featured_languages}
                class="rounded-full bg-white/90 px-3 py-1 text-xs font-semibold text-slate-900"
              >
                {lang}
              </span>
            </div>
            <p class="mt-2 text-sm text-white/80">
              Refined design tokens guarantee WCAG AA contrast
            </p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :id, :string, default: nil
  attr :snippet, Snippet, required: true
  attr :layout, :atom, values: [:grid, :list], default: :grid
  attr :language_label, :string, default: ""
  attr :owner_label, :string, default: "Community"
  attr :activity_label, :string, default: ""
  attr :cta_href, :string, default: "#"

  def card(assigns) do
    assigns =
      assigns
      |> assign_new(:cta_href, fn -> ~p"/s/#{assigns.snippet.id}" end)
      |> assign(:visibility, assigns.snippet.visibility || :public)

    ~H"""
    <article
      id={@id}
      data-role="gallery-card"
      class={[
        "ds-card relative flex h-full flex-col justify-between gap-6 overflow-hidden border border-slate-200/70 bg-white/95 p-6 transition",
        @layout == :list && "md:flex-row md:items-center"
      ]}
    >
      <div class="flex flex-1 flex-col gap-4">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <span
            data-role="gallery-language"
            class="inline-flex items-center gap-2 rounded-full bg-slate-900/5 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-slate-600"
          >
            <.icon name="hero-command-line" class="h-3.5 w-3.5" />
            {@language_label}
          </span>

          <span class={[
            "inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[0.65rem] font-semibold uppercase tracking-[0.25em]",
            @visibility == :public && "bg-emerald-50 text-emerald-700",
            @visibility == :private && "bg-slate-100 text-slate-500",
            @visibility == :unlisted && "bg-amber-50 text-amber-700"
          ]}>
            {Naming.humanize(@visibility)}
          </span>
        </div>

        <div class="space-y-3">
          <h3 class="text-xl font-semibold text-slate-900 line-clamp-2">
            {@snippet.title || "Untitled snippet"}
          </h3>
          <p class="text-sm leading-relaxed text-slate-600 line-clamp-3">
            {@snippet.description ||
              "Deploy this snippet instantly with our real-time collaboration canvas."}
          </p>
        </div>
      </div>

      <div class="flex flex-col gap-3 text-xs text-slate-500">
        <div class="flex items-center gap-2 font-medium text-slate-600">
          <span class="inline-flex h-2 w-2 rounded-full bg-emerald-400" />
          {@activity_label}
        </div>
        <div
          data-role="gallery-card-owner"
          class="inline-flex items-center gap-2 rounded-full bg-slate-900/5 px-3 py-1 text-sm font-semibold text-slate-700"
        >
          <.icon name="hero-user-circle" class="h-4 w-4 text-slate-500" />
          {@owner_label}
        </div>
      </div>

      <.link
        navigate={@cta_href}
        class="inline-flex items-center gap-2 rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900"
      >
        Open snippet <.icon name="hero-arrow-right" class="h-4 w-4" />
      </.link>
    </article>
    """
  end

  attr :id, :string, default: nil

  def skeleton_card(assigns) do
    ~H"""
    <div
      id={@id}
      class="ds-card animate-pulse border border-slate-200 bg-white/80 p-6 shadow-inner"
    >
      <div class="flex justify-between gap-3">
        <div class="h-4 w-24 rounded-full bg-slate-200" />
        <div class="h-4 w-16 rounded-full bg-slate-200" />
      </div>
      <div class="mt-6 space-y-3">
        <div class="h-6 w-9/12 rounded-xl bg-slate-100" />
        <div class="h-6 w-8/12 rounded-xl bg-slate-100" />
        <div class="h-6 w-7/12 rounded-xl bg-slate-100" />
      </div>
      <div class="mt-8 flex justify-between gap-3">
        <div class="h-3 w-20 rounded-full bg-slate-100" />
        <div class="h-3 w-24 rounded-full bg-slate-100" />
      </div>
    </div>
    """
  end
end
